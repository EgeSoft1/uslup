// =============================================================================
// TurkiyeMesajlasma — Tonic gRPC Build Script
// Dosya: crates/proto/build.rs
// =============================================================================

fn main() -> Result<(), Box<dyn std::error::Error>> {
    tonic_build::configure()
        .build_server(true)
        .build_client(true)
        // Prost: Rust struct'larına serde derive ekle
        .type_attribute(".", "#[derive(serde::Serialize, serde::Deserialize)]")
        // EncryptedEnvelope'u Hash + Eq yaparak HashMap key olarak kullanılabilir yap
        .type_attribute(
            "turkiye_mesajlasma.v1.EncryptedEnvelope",
            "#[derive(Hash, Eq, PartialEq)]",
        )
        // Proto dosyalarını derle
        .compile_protos(
            &["proto/messaging.proto"],
            &["proto/"],
        )?;

    // Proto dosyası değiştiğinde yeniden derle
    println!("cargo:rerun-if-changed=proto/messaging.proto");

    Ok(())
}
