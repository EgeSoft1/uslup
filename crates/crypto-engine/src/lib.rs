// =============================================================================
// TurkiyeMesajlasma — Rust Crypto Engine (FFI Katmanı)
// Crate: crypto-engine
// Dosya: crates/crypto-engine/src/lib.rs
//
// Amaç: Mobil cihazlarda (iOS/Android) çalışacak, sıfır-tahsisatlı (zero-allocation)
// ve C uyumlu (FFI) Signal Protocol / Double Ratchet şifreleme motoru.
// Dart katmanı, mesajları buraya göndererek "ciphertext" elde eder.
// =============================================================================

use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_int, c_uchar};
use ring::aead;
use rand::RngCore;

// ─── HATA KODLARI ─────────────────────────────────────────────────────────────
pub const SUCCESS: c_int = 0;
pub const ERR_INVALID_INPUT: c_int = -1;
pub const ERR_ENCRYPTION_FAILED: c_int = -2;
pub const ERR_DECRYPTION_FAILED: c_int = -3;
pub const ERR_SESSION_NOT_FOUND: c_int = -4;

// ─── FFI STRUCT'LARI ──────────────────────────────────────────────────────────

#[repr(C)]
pub struct EncryptedResult {
    pub ciphertext: *mut c_uchar,
    pub ciphertext_len: usize,
    pub nonce: *mut c_uchar,
    pub nonce_len: usize,
    pub error_code: c_int,
}

#[repr(C)]
pub struct DecryptedResult {
    pub plaintext: *mut c_char,
    pub error_code: c_int,
}

// ─── FFI FONKSİYONLARI ────────────────────────────────────────────────────────

/// Cihazda saklanan Double Ratchet oturum state'ini (session state) kullanarak
/// plaintext mesajı şifreler (O(1) allocation).
/// 
/// Not: Gerçek Signal Protocol'de burada Diffie-Hellman ratcheting yapılır.
/// Burada konseptin FFI üzerinden nasıl çalıştığı örneklenmiştir.
#[no_mangle]
pub extern "C" fn encrypt_message(
    session_id: *const c_char,
    plaintext: *const c_char,
) -> EncryptedResult {
    if session_id.is_null() || plaintext.is_null() {
        return empty_enc_error(ERR_INVALID_INPUT);
    }

    let session_str = match unsafe { CStr::from_ptr(session_id) }.to_str() {
        Ok(s) => s,
        Err(_) => return empty_enc_error(ERR_INVALID_INPUT),
    };

    let msg_str = match unsafe { CStr::from_ptr(plaintext) }.to_str() {
        Ok(s) => s,
        Err(_) => return empty_enc_error(ERR_INVALID_INPUT),
    };

    // 1. Session state'i yükle (Isar DB'den Rust katmanına aktarılmış sayılır)
    // Gerçekte burada libsignal-protocol veya özel Double Ratchet state yüklenir
    let mut message_key = [0u8; 32];
    // Örnek: Key derivation kurgusu (HKDF ile)
    ring::hkdf::Salt::new(ring::hkdf::HKDF_SHA256, session_str.as_bytes())
        .extract(b"ratchet_key")
        .expand(&[b"message_keys"], &aead::AES_256_GCM)
        .unwrap()
        .fill(&mut message_key)
        .unwrap();

    // 2. AES-256-GCM ile şifreleme
    let unbound_key = aead::UnboundKey::new(&aead::AES_256_GCM, &message_key).unwrap();
    let less_safe_key = aead::LessSafeKey::new(unbound_key);

    // 96-bit (12 byte) rastgele IV / Nonce üretimi
    let mut nonce_bytes = [0u8; 12];
    rand::thread_rng().fill_bytes(&mut nonce_bytes);
    let nonce = aead::Nonce::assume_unique_for_key(nonce_bytes);

    let mut in_out = msg_str.as_bytes().to_vec();
    
    // AAD (Additional Authenticated Data): Metadata manipülasyonunu engellemek için
    let aad = aead::Aad::from(session_str.as_bytes());

    match less_safe_key.seal_in_place_append_tag(nonce, aad, &mut in_out) {
        Ok(_) => {
            // Başarılı: Veriyi heap'e al ve C'ye (Dart'a) pointer dön
            let mut ciphertext_buf = in_out.into_boxed_slice();
            let mut nonce_buf = Box::new(nonce_bytes);

            let res = EncryptedResult {
                ciphertext: ciphertext_buf.as_mut_ptr(),
                ciphertext_len: ciphertext_buf.len(),
                nonce: nonce_buf.as_mut_ptr(),
                nonce_len: nonce_buf.len(),
                error_code: SUCCESS,
            };

            // Belleğin Rust tarafından silinmesini engelle (Dart free yapacak)
            std::mem::forget(ciphertext_buf);
            std::mem::forget(nonce_buf);

            res
        }
        Err(_) => empty_enc_error(ERR_ENCRYPTION_FAILED),
    }
}

/// Dart katmanının (Garbage Collector'ın) Rust'ın allocate ettiği belleği 
/// güvenle iade etmesi (Memory leak önleme)
#[no_mangle]
pub extern "C" fn free_encrypted_result(result: EncryptedResult) {
    if !result.ciphertext.is_null() && result.ciphertext_len > 0 {
        unsafe {
            drop(Box::from_raw(std::slice::from_raw_parts_mut(
                result.ciphertext,
                result.ciphertext_len,
            )));
        }
    }
    if !result.nonce.is_null() && result.nonce_len > 0 {
        unsafe {
            drop(Box::from_raw(std::slice::from_raw_parts_mut(
                result.nonce,
                result.nonce_len,
            )));
        }
    }
}

// Yardımcı Hata Fonksiyonu
fn empty_enc_error(code: c_int) -> EncryptedResult {
    EncryptedResult {
        ciphertext: std::ptr::null_mut(),
        ciphertext_len: 0,
        nonce: std::ptr::null_mut(),
        nonce_len: 0,
        error_code: code,
    }
}
