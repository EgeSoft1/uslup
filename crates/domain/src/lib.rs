// =============================================================================
// TurkiyeMesajlasma — Domain Modelleri
// Crate: domain
// Dosya: crates/domain/src/lib.rs
//
// Tüm iş mantığı burada tanımlanır. Infrastructure ya da framework bağımlılığı yok.
// Clean Architecture: Domain katmanı dışarıya bağımlı değildir.
// =============================================================================

pub mod entities;
pub mod ports;
pub mod errors;
pub mod value_objects;
