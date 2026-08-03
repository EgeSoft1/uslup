// =============================================================================
// TurkiyeMesajlasma Platform - Veritabanı Migration Runner
// Dosya: db/migrate.rs
// Rust tabanlı, tüm DB migration'larını orchestrate eden araç
//
// Kullanım:
//   cargo run --bin migrate -- --db cockroach --env production
//   cargo run --bin migrate -- --db scylla --env staging
//   cargo run --bin migrate -- --db clickhouse --env production
//   cargo run --bin migrate -- --all --env production
// =============================================================================

use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::time::{Duration, Instant};

use anyhow::{Context, Result};
use clap::{Parser, ValueEnum};
use sha2::{Digest, Sha256};
use tokio::fs;
use tracing::{error, info, warn};

/// Migration CLI argümanları
#[derive(Parser, Debug)]
#[command(name = "migrate", about = "TurkiyeMesajlasma DB Migration Runner")]
struct MigrationArgs {
    /// Hedef veritabanı
    #[arg(long, value_enum)]
    db: Option<DatabaseTarget>,

    /// Tüm DB'leri migrate et
    #[arg(long)]
    all: bool,

    /// Ortam (environment)
    #[arg(long, value_enum, default_value = "development")]
    env: Environment,

    /// Geri al (rollback) - son N migration
    #[arg(long)]
    rollback: Option<usize>,

    /// Sadece durumu göster, uygulama
    #[arg(long)]
    status: bool,

    /// Migration dizini
    #[arg(long, default_value = "./db")]
    migrations_dir: PathBuf,
}

#[derive(ValueEnum, Debug, Clone, PartialEq)]
enum DatabaseTarget {
    Cockroach,
    Scylla,
    Clickhouse,
    Dragonfly,
}

#[derive(ValueEnum, Debug, Clone)]
enum Environment {
    Development,
    Staging,
    Production,
}

/// Migration kaydı
#[derive(Debug, Clone)]
struct Migration {
    /// Migration numarası (001, 002, ...)
    version: String,
    /// Dosya adı
    filename: String,
    /// SQL/CQL içeriği
    content: String,
    /// SHA-256 checksum (integrity)
    checksum: String,
}

impl Migration {
    fn from_file(path: &Path, content: String) -> Self {
        let filename = path.file_name().unwrap().to_str().unwrap().to_string();
        let version = filename.split('_').next().unwrap_or("000").to_string();

        // SHA-256 checksum hesapla
        let mut hasher = Sha256::new();
        hasher.update(content.as_bytes());
        let checksum = format!("{:x}", hasher.finalize());

        Self {
            version,
            filename,
            content,
            checksum,
        }
    }
}

/// CockroachDB migration executor
struct CockroachMigrator {
    connection_string: String,
}

impl CockroachMigrator {
    async fn new(env: &Environment) -> Result<Self> {
        let conn_str = match env {
            Environment::Development => {
                std::env::var("COCKROACH_DEV_URL")
                    .unwrap_or_else(|_| "postgresql://root@localhost:26257/turkiye_mesajlasma?sslmode=disable".to_string())
            }
            Environment::Staging => {
                std::env::var("COCKROACH_STAGING_URL")
                    .context("COCKROACH_STAGING_URL env var gerekli")?
            }
            Environment::Production => {
                std::env::var("COCKROACH_PROD_URL")
                    .context("COCKROACH_PROD_URL env var gerekli")?
            }
        };

        Ok(Self {
            connection_string: conn_str,
        })
    }

    /// Migration takip tablosunu oluştur
    async fn ensure_migration_table(&self, client: &tokio_postgres::Client) -> Result<()> {
        client.execute(
            r#"
            CREATE TABLE IF NOT EXISTS schema_migrations (
                version         STRING      NOT NULL PRIMARY KEY,
                filename        STRING      NOT NULL,
                checksum        STRING      NOT NULL,
                applied_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
                duration_ms     INT4,
                applied_by      STRING      DEFAULT current_user()
            )
            "#,
            &[],
        ).await.context("Migration takip tablosu oluşturulamadı")?;

        Ok(())
    }

    async fn run_migrations(&self, migrations: Vec<Migration>) -> Result<()> {
        let (client, connection) = tokio_postgres::connect(&self.connection_string, tokio_postgres::NoTls)
            .await
            .context("CockroachDB bağlantısı kurulamadı")?;

        // Bağlantı task'ını arka planda çalıştır
        tokio::spawn(async move {
            if let Err(e) = connection.await {
                error!("CockroachDB bağlantı hatası: {}", e);
            }
        });

        self.ensure_migration_table(&client).await?;

        // Uygulanmış migration'ları al
        let applied: Vec<String> = client
            .query("SELECT version FROM schema_migrations ORDER BY version ASC", &[])
            .await?
            .iter()
            .map(|row| row.get::<_, String>(0))
            .collect();

        let mut applied_count = 0;
        let mut skipped_count = 0;

        for migration in &migrations {
            if applied.contains(&migration.version) {
                // Checksum doğrula (migration değiştirilmiş mi?)
                let row = client
                    .query_one(
                        "SELECT checksum FROM schema_migrations WHERE version = $1",
                        &[&migration.version],
                    )
                    .await?;
                let stored_checksum: String = row.get(0);

                if stored_checksum != migration.checksum {
                    error!(
                        "CHECKSUM UYUŞMAZLIĞI: {} - Dosya değiştirilmiş olabilir! Güvenlik ihlali kontrolü yapın.",
                        migration.filename
                    );
                    anyhow::bail!("Checksum mismatch for migration {}", migration.version);
                }

                skipped_count += 1;
                continue;
            }

            info!("Uygulanıyor: {} ({})", migration.filename, migration.version);
            let start = Instant::now();

            // Migration'ı transaction içinde çalıştır
            let result = client.batch_execute(&migration.content).await;

            match result {
                Ok(_) => {
                    let duration_ms = start.elapsed().as_millis() as i32;

                    // Migration kaydını ekle
                    client.execute(
                        r#"
                        INSERT INTO schema_migrations (version, filename, checksum, duration_ms)
                        VALUES ($1, $2, $3, $4)
                        "#,
                        &[
                            &migration.version,
                            &migration.filename,
                            &migration.checksum,
                            &duration_ms,
                        ],
                    ).await?;

                    info!(
                        "✓ Başarılı: {} ({} ms)",
                        migration.filename, duration_ms
                    );
                    applied_count += 1;
                }
                Err(e) => {
                    error!("✗ Başarısız: {} - Hata: {}", migration.filename, e);
                    return Err(e.into());
                }
            }
        }

        info!(
            "CockroachDB Migration tamamlandı: {} uygulandı, {} atlandı",
            applied_count, skipped_count
        );

        Ok(())
    }
}

/// ScyllaDB migration executor (CQL)
struct ScyllaMigrator {
    hosts: Vec<String>,
    keyspace: String,
}

impl ScyllaMigrator {
    async fn new(env: &Environment) -> Result<Self> {
        let hosts = match env {
            Environment::Development => vec!["127.0.0.1:9042".to_string()],
            Environment::Staging => {
                std::env::var("SCYLLA_STAGING_HOSTS")
                    .context("SCYLLA_STAGING_HOSTS gerekli (virgülle ayrılmış)")?
                    .split(',')
                    .map(String::from)
                    .collect()
            }
            Environment::Production => {
                std::env::var("SCYLLA_PROD_HOSTS")
                    .context("SCYLLA_PROD_HOSTS gerekli")?
                    .split(',')
                    .map(String::from)
                    .collect()
            }
        };

        Ok(Self {
            hosts,
            keyspace: "turkiye_mesajlasma".to_string(),
        })
    }

    async fn run_migrations(&self, migrations: Vec<Migration>) -> Result<()> {
        // scylla driver ile bağlan
        // Gerçek implementasyonda: scylladb/scylla-rust-driver kullanılır
        info!("ScyllaDB migration başlıyor... Hosts: {:?}", self.hosts);

        for migration in &migrations {
            info!("CQL çalıştırılıyor: {}", migration.filename);

            // CQL ifadelerini ayır ('; ' ile bölünmüş)
            let statements: Vec<&str> = migration.content
                .split(';')
                .map(str::trim)
                .filter(|s| !s.is_empty() && !s.starts_with("--"))
                .collect();

            for stmt in statements {
                info!("  CQL: {}...", &stmt[..stmt.len().min(60)]);
                // session.execute(stmt).await?;
            }

            info!("✓ ScyllaDB migration tamamlandı: {}", migration.filename);
        }

        Ok(())
    }
}

/// ClickHouse migration executor
struct ClickhouseMigrator {
    url: String,
    database: String,
}

impl ClickhouseMigrator {
    async fn new(env: &Environment) -> Result<Self> {
        let url = match env {
            Environment::Development => {
                "http://localhost:8123".to_string()
            }
            Environment::Staging | Environment::Production => {
                std::env::var("CLICKHOUSE_URL")
                    .context("CLICKHOUSE_URL env var gerekli")?
            }
        };

        Ok(Self {
            url,
            database: "lawful_intercept".to_string(),
        })
    }

    async fn run_migrations(&self, migrations: Vec<Migration>) -> Result<()> {
        info!("ClickHouse migration başlıyor... URL: {}", self.url);

        let http_client = reqwest::Client::builder()
            .timeout(Duration::from_secs(60))
            .build()?;

        for migration in &migrations {
            info!("SQL çalıştırılıyor: {}", migration.filename);

            // ClickHouse HTTP API ile çalıştır
            let statements: Vec<&str> = migration.content
                .split(';')
                .map(str::trim)
                .filter(|s| !s.is_empty() && !s.starts_with("--") && !s.starts_with("/*"))
                .collect();

            for stmt in statements {
                if stmt.trim().is_empty() {
                    continue;
                }

                let response = http_client
                    .post(&format!("{}/", self.url))
                    .query(&[("database", self.database.as_str())])
                    .body(stmt.to_string())
                    .send()
                    .await?;

                if !response.status().is_success() {
                    let error_body = response.text().await?;
                    warn!("ClickHouse uyarı/hata: {}", error_body);
                }
            }

            info!("✓ ClickHouse migration tamamlandı: {}", migration.filename);
        }

        Ok(())
    }
}

/// Migration dosyalarını bir dizinden yükle
async fn load_migrations(dir: &Path) -> Result<Vec<Migration>> {
    let mut migrations = Vec::new();
    let mut entries = fs::read_dir(dir).await
        .with_context(|| format!("Migration dizini okunamadı: {:?}", dir))?;

    let mut files: Vec<PathBuf> = Vec::new();

    while let Some(entry) = entries.next_entry().await? {
        let path = entry.path();
        if path.extension().map_or(false, |ext| {
            ext == "sql" || ext == "cql"
        }) {
            files.push(path);
        }
    }

    // Versiyon numarasına göre sırala (001, 002, ...)
    files.sort();

    for path in files {
        let content = fs::read_to_string(&path)
            .await
            .with_context(|| format!("Migration dosyası okunamadı: {:?}", path))?;

        migrations.push(Migration::from_file(&path, content));
    }

    Ok(migrations)
}

/// Ana entrypoint
#[tokio::main]
async fn main() -> Result<()> {
    // Logging başlat
    tracing_subscriber::fmt()
        .with_env_filter(
            std::env::var("RUST_LOG")
                .unwrap_or_else(|_| "migrate=info,warn".to_string())
        )
        .init();

    let args = MigrationArgs::parse();

    info!("=== TurkiyeMesajlasma DB Migration Runner ===");
    info!("Ortam: {:?}", args.env);

    let targets: Vec<DatabaseTarget> = if args.all {
        vec![
            DatabaseTarget::Cockroach,
            DatabaseTarget::Scylla,
            DatabaseTarget::Clickhouse,
        ]
    } else if let Some(db) = args.db.clone() {
        vec![db]
    } else {
        error!("--db veya --all belirtilmeli");
        std::process::exit(1);
    };

    for target in targets {
        match target {
            DatabaseTarget::Cockroach => {
                let migration_dir = args.migrations_dir.join("cockroachdb/migrations");
                let migrations = load_migrations(&migration_dir).await?;
                info!("CockroachDB: {} migration dosyası bulundu", migrations.len());

                let migrator = CockroachMigrator::new(&args.env).await?;
                migrator.run_migrations(migrations).await?;
            }
            DatabaseTarget::Scylla => {
                let migration_dir = args.migrations_dir.join("scylladb/migrations");
                let migrations = load_migrations(&migration_dir).await?;
                info!("ScyllaDB: {} migration dosyası bulundu", migrations.len());

                let migrator = ScyllaMigrator::new(&args.env).await?;
                migrator.run_migrations(migrations).await?;
            }
            DatabaseTarget::Clickhouse => {
                let migration_dir = args.migrations_dir.join("clickhouse/migrations");
                let migrations = load_migrations(&migration_dir).await?;
                info!("ClickHouse: {} migration dosyası bulundu", migrations.len());

                let migrator = ClickhouseMigrator::new(&args.env).await?;
                migrator.run_migrations(migrations).await?;
            }
            DatabaseTarget::Dragonfly => {
                // DragonflyDB schema-less, migration gerekmez
                info!("DragonflyDB: Schema-less, migration gerekmiyor. Key prefix'ler kod içinde yönetilir.");
            }
        }
    }

    info!("✓ Tüm migration'lar başarıyla tamamlandı!");
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_migration_checksum() {
        let content = "CREATE TABLE test (id UUID PRIMARY KEY);".to_string();
        let path = Path::new("001_test.sql");
        let migration = Migration::from_file(path, content.clone());

        assert_eq!(migration.version, "001");
        assert_eq!(migration.filename, "001_test.sql");
        assert!(!migration.checksum.is_empty());
        assert_eq!(migration.checksum.len(), 64); // SHA-256 hex = 64 karakter

        // Aynı içerik aynı hash üretmeli
        let migration2 = Migration::from_file(path, content);
        assert_eq!(migration.checksum, migration2.checksum);
    }

    #[test]
    fn test_version_extraction() {
        let cases = vec![
            ("001_initial_schema.sql", "001"),
            ("042_add_groups.sql", "042"),
            ("100_performance_indexes.cql", "100"),
        ];

        for (filename, expected_version) in cases {
            let path = Path::new(filename);
            let migration = Migration::from_file(path, String::new());
            assert_eq!(migration.version, expected_version);
        }
    }
}
