// =============================================================================
// TurkiyeMesajlasma — Axum Router ve HTTP Handler'ları
// Dosya: crates/gateway-ws/src/router.rs
//
// Endpoint'ler:
//   GET  /ws           — WebSocket yükseltme (ana bağlantı noktası)
//   GET  /health       — Kubernetes liveness probe
//   GET  /ready        — Kubernetes readiness probe
//   GET  /metrics      — Prometheus (dahili, LoadBalancer'a kapalı)
// =============================================================================

use axum::{
    extract::{ConnectInfo, State, WebSocketUpgrade},
    http::{HeaderMap, StatusCode},
    middleware,
    response::{IntoResponse, Json, Response},
    routing::get,
    Router,
};
use std::net::SocketAddr;
use tracing::info;

use crate::{middleware as mw, AppState};

pub fn build_router(state: AppState) -> Router {
    Router::new()
        // ── WebSocket Endpoint ────────────────────────────────────────────────
        .route("/ws", get(ws_upgrade_handler))

        // ── Sağlık Kontrol Endpoint'leri (Kubernetes probe) ───────────────────
        .route("/health", get(health_check))
        .route("/ready", get(readiness_check))

        // ── Internal gRPC-Web (isteğe bağlı, internal traffic için) ──────────
        // .route("/internal/v1/*path", grpc_web_handler)

        // ── State ──────────────────────────────────────────────────────────────
        .with_state(state.clone())

        // ── Tower Middleware Katmanları ────────────────────────────────────────
        .layer(
            tower::ServiceBuilder::new()
                // 1. İstek tracing (her isteğe trace ID ekle)
                .layer(tower_http::trace::TraceLayer::new_for_http())

                // 2. Request ID (X-Request-ID header)
                .layer(tower_http::request_id::SetRequestIdLayer::x_request_id(
                    tower_http::request_id::MakeRequestUuid,
                ))

                // 3. Bağlantı hız limiti (IP bazlı, /ws için)
                .layer(middleware::from_fn_with_state(
                    state.clone(),
                    mw::connection_rate_limit,
                ))

                // 4. Güvenlik header'ları
                .layer(
                    tower_http::set_header::SetResponseHeaderLayer::overriding(
                        axum::http::header::X_CONTENT_TYPE_OPTIONS,
                        axum::http::HeaderValue::from_static("nosniff"),
                    ),
                )

                // 5. Sıkıştırma (HTTP response için, WS için uygulanmaz)
                .layer(tower_http::compression::CompressionLayer::new())
        )
}

// ─── WebSocket Yükseltme Handler'ı ───────────────────────────────────────────

/// HTTP → WebSocket yükseltme
/// 1. JWT token doğrulaması (Authorization: Bearer <token>)
/// 2. WebSocket yükseltme
/// 3. Bağlantı döngüsü başlatma
async fn ws_upgrade_handler(
    ws: WebSocketUpgrade,
    State(state): State<AppState>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    headers: HeaderMap,
    axum::extract::Query(query): axum::extract::Query<std::collections::HashMap<String, String>>,
) -> Response {
    // ── JWT Doğrulama ─────────────────────────────────────────────────────────
    // Token, URL parametresi veya header'dan alınabilir
    // Güvenlik: URL parametresi log'lara düşer; header tercih edilir
    let token = headers
        .get("Authorization")
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.strip_prefix("Bearer "))
        .map(|s| s.to_string())
        .or_else(|| query.get("token").cloned());

    let token = match token {
        Some(t) => t,
        None => {
            return (StatusCode::UNAUTHORIZED, "Authorization header veya token parametresi eksik")
                .into_response();
        }
    };

    // JWT'yi doğrula
    let claims = match state.services.auth.verify_jwt(&token).await {
        Ok(claims) => claims,
        Err(e) => {
            tracing::warn!("JWT doğrulama başarısız: {}", e);
            return (StatusCode::UNAUTHORIZED, format!("Geçersiz token: {}", e))
                .into_response();
        }
    };

    // IP hash'i (Lawful Intercept için, ham IP loglanmaz)
    let ip_hash = crate::middleware::hash_ip(&addr.ip().to_string());

    let peer = crate::connection::AuthenticatedPeer {
        user_id: claims.user_id,
        device_id: claims.device_id,
        region_code: claims.region_code,
        platform: claims.platform,
        connected_at: std::time::Instant::now(),
        ip_hash: std::sync::Arc::from(ip_hash.as_str()),
    };

    info!(
        user_id = %peer.user_id,
        device_id = %peer.device_id,
        platform = %peer.platform,
        "WebSocket yükseltme başlatılıyor"
    );

    // WebSocket yükseltmesi: Axum burada HTTP → WS protokolünü değiştirir
    // on_upgrade callback: yükseltme başarılı olunca çağrılır
    ws.on_upgrade(move |socket| {
        crate::connection::handle_websocket(socket, peer, state)
    })
}

// ─── Sağlık Kontrol Handler'ları ─────────────────────────────────────────────

/// Kubernetes Liveness Probe
/// Sunucu çalışıyor mu? (503 dönerse pod restart edilir)
async fn health_check(State(state): State<AppState>) -> impl IntoResponse {
    let conn_count = state.services.connections.connection_count();

    Json(serde_json::json!({
        "status": "healthy",
        "node_id": state.node_id.as_ref(),
        "active_connections": conn_count,
        "timestamp": chrono::Utc::now().to_rfc3339()
    }))
}

/// Kubernetes Readiness Probe
/// Trafik almaya hazır mı? (503 dönerse LB traffic göndermez)
async fn readiness_check(State(state): State<AppState>) -> impl IntoResponse {
    // DragonflyDB bağlantısını kontrol et
    let dragonfly_ok = state.services.dragonfly_ping().await.is_ok();
    // CockroachDB bağlantısını kontrol et
    let cockroach_ok = state.services.cockroach_ping().await.is_ok();

    let is_ready = dragonfly_ok && cockroach_ok;

    let status_code = if is_ready {
        StatusCode::OK
    } else {
        StatusCode::SERVICE_UNAVAILABLE
    };

    (
        status_code,
        Json(serde_json::json!({
            "ready": is_ready,
            "checks": {
                "dragonfly": dragonfly_ok,
                "cockroachdb": cockroach_ok,
            },
            "node_id": state.node_id.as_ref()
        })),
    )
}
