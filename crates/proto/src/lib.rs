// =============================================================================
// TurkiyeMesajlasma — Proto Crate
// Tonic tarafından üretilen Protobuf/gRPC Rust kodlarını re-export eder
// =============================================================================

pub mod messaging {
    tonic::include_proto!("turkiye_mesajlasma.v1");
}

// Re-export: gateway-ws doğrudan proto::ClientMessage yazabilsin
pub use messaging::*;
