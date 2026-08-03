# Temel imaj olarak rust tabanlı chef
FROM lukemathwalker/cargo-chef:latest-rust-1.76 AS chef
WORKDIR /app

# Planlama aşaması (bağımlılıkları toplamak için)
FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

# İnşa aşaması (caching ile)
FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json
# Önce sadece bağımlılıkları derle, cache'lemek için
RUN cargo chef cook --release --recipe-path recipe.json
# Şimdi kodu kopyala ve asıl projeyi derle
COPY . .
RUN cargo build --release --bin gateway-ws

# Çalışma zamanı için minimal debian imajı
FROM debian:bookworm-slim AS runtime
WORKDIR /app

# Gerekli bağımlılıkları yükle (openssl vs.)
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends openssl ca-certificates && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/gateway-ws /app/gateway-ws

# Gateway için gerekli portları dışa aç
EXPOSE 8080 9090 9091

# Uygulamayı başlat
ENTRYPOINT ["/app/gateway-ws"]
