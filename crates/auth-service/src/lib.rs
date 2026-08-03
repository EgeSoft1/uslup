use axum::{
    extract::{State, Json},
    routing::post,
    Router,
};
use serde::{Deserialize, Serialize};
use std::sync::Arc;

// --- Domain Models ---

#[derive(Debug, Serialize, Deserialize)]
pub struct DeviceRegistrationRequest {
    pub phone_hash: String,
    pub public_identity_key: String,
    pub signed_pre_key: String,
    pub one_time_pre_keys: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct DeviceRegistrationResponse {
    pub device_id: String,
    pub status: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PreKeyUploadRequest {
    pub device_id: String,
    pub one_time_pre_keys: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PreKeyUploadResponse {
    pub uploaded_count: usize,
}

// --- Domain Services ---

// Cihaz ve anahtar kaydı için servis arayüzü
#[async_trait::async_trait]
pub trait AuthDomainService: Send + Sync {
    async fn register_device(&self, req: &DeviceRegistrationRequest) -> Result<DeviceRegistrationResponse, String>;
    async fn upload_pre_keys(&self, req: &PreKeyUploadRequest) -> Result<PreKeyUploadResponse, String>;
}

// CockroachDB'ye yazacak teorik servis
pub struct CockroachAuthService {
    // db_pool: sqlx::PgPool
}

impl CockroachAuthService {
    pub fn new() -> Self {
        Self {}
    }
}

#[async_trait::async_trait]
impl AuthDomainService for CockroachAuthService {
    async fn register_device(&self, req: &DeviceRegistrationRequest) -> Result<DeviceRegistrationResponse, String> {
        // CockroachDB'ye cihaz ekleme mantığı
        // INSERT INTO devices (phone_hash, identity_key) VALUES ($1, $2)
        Ok(DeviceRegistrationResponse {
            device_id: "new-device-uuid".to_string(),
            status: "Success".to_string(),
        })
    }

    async fn upload_pre_keys(&self, req: &PreKeyUploadRequest) -> Result<PreKeyUploadResponse, String> {
        // CockroachDB'ye X3DH anahtarlarını ekleme
        Ok(PreKeyUploadResponse {
            uploaded_count: req.one_time_pre_keys.len(),
        })
    }
}

// --- Axum Handlers ---

pub struct AppState {
    pub auth_service: Arc<dyn AuthDomainService>,
}

pub async fn register_device_handler(
    State(state): State<Arc<AppState>>,
    Json(payload): Json<DeviceRegistrationRequest>,
) -> Json<Result<DeviceRegistrationResponse, String>> {
    let result = state.auth_service.register_device(&payload).await;
    Json(result)
}

pub async fn upload_pre_keys_handler(
    State(state): State<Arc<AppState>>,
    Json(payload): Json<PreKeyUploadRequest>,
) -> Json<Result<PreKeyUploadResponse, String>> {
    let result = state.auth_service.upload_pre_keys(&payload).await;
    Json(result)
}

// Yönlendirme (Router) oluşturma
pub fn create_router(auth_service: Arc<dyn AuthDomainService>) -> Router {
    let state = Arc::new(AppState { auth_service });
    Router::new()
        .route("/api/v1/auth/register", post(register_device_handler))
        .route("/api/v1/auth/keys", post(upload_pre_keys_handler))
        .with_state(state)
}
