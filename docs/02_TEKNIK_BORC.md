# Teknik Borç Envanteri

Bu belge, devralınan kod tabanının **doğrulanmış** durumunu kayda geçirir.
Amaç suçlama değil, teknik rapordaki iddiaların kanıtlanabilir olmasını
sağlamak. Jüriye "150 milyon eşzamanlı kullanıcı destekleyen backend"
denip derlenmeyen bir kod gösterilirse proje orada biter.

**Tarih:** 1 Ağustos 2026 · **Yöntem:** `cargo check`, `flutter analyze`,
`flutter test`, `flutter build apk` fiilen çalıştırıldı.

---

## 1. Flutter uygulaması

### ✅ Çözüldü — ilk tur
| Sorun | Durum |
|---|---|
| `contacts_screen.dart` bozuk liste tanımı → **25 derleme hatası**, uygulama derlenmiyordu | Düzeltildi. Proje artık **0 hata** ile derleniyor, APK üretiliyor. |

Bu hata sessizdi: `flutter analyze` çıktısı 298 satırdı ve hatalar listenin
başındaydı, sonuna bakınca görünmüyordu. Uygulamanın derlenmediği ancak
`flutter build apk` çalıştırılınca ortaya çıktı.

### ✅ Çözüldü — arayüz elden geçirme turu (2 Ağustos 2026)

**Statik analiz: 284 satır tanı → `No issues found!`**
(0 hata, 0 uyarı, 0 lint bilgisi. Doğrulama: `flutter analyze`.)

| Kategori | Önce | Sonra |
|---|---|---|
| Kullanımdan kalkmış API (`withOpacity` vb.) | 192 | 0 |
| Uyarı (kullanılmayan import/alan/değişken) | 12 | 0 |
| Lint bilgisi (`prefer_const` vb.) | 80 | 0 |
| Arayüz testi | 1 | 10 |

#### Bulunan ve düzeltilen **işlev** hataları
Bunlar kozmetik değil; hepsi kullanıcının gördüğü yanlış davranıştı.

| Dosya | Hata |
|---|---|
| `chat_screen.dart` | Liste `reverse: true` çiziliyor ama `_sendMessage` yeni mesajı `insert(0, …)` ile listenin **başına** koyuyordu → gönderilen her mesaj konuşmanın **en üstünde**, en eski mesajmış gibi beliriyordu. |
| `contacts_screen.dart` | Yalnızca `'A'` ve `'B'` harf grupları çiziliyordu → başka harfle başlayan hiçbir kişi **görünmüyordu**; "kişi ekle" ile eklenen kişi çoğu zaman kayboluyordu. |
| `contacts_screen.dart` | Sağdaki A–Z şeridi listeyi kaydırmak yerine arama kutusuna harfi **yazıyordu** (yani filtreliyordu). |
| `contacts_screen.dart` | `compareTo` bayt sırasına göre çalıştığı için "Çetin" "Zeynep"ten sonra sıralanıyordu. Türk alfabesi sırası uygulandı. |
| `active_sessions_screen.dart` | "Sonlandır" onay alıyor, bildirim gösteriyor ama oturumu **listeden kaldırmıyordu** — kullanıcı güvenlik önlemi aldığını sanıyordu. |
| `blocked_contacts_screen.dart` | "Engeli kaldır" ve "Yeni kişi engelle" düğmelerinin ikisi de `onTap: () {}` idi. |
| `conversations_screen.dart` | Yeni sohbet düğmesi (FAB) işleyicisi olmayan bir `Container`'dı; arama kutusunun `onChanged`'i yoktu; "Tümünü Gör" tıklanamayan düz metindi. |
| `calls_history_screen.dart` | Geri arama ve "yeni arama" düğmeleri işleyicisiz `Container`'dı. |
| `profile_screen.dart` | Başlıktaki isim sabitti; isim alanını düzenlemek onu değiştirmiyordu. Kamera, QR, çıkış ve **hesap silme** satırlarının hiçbirinde işleyici yoktu. |
| `qr_scanner_screen.dart` | Bir kod okunduktan sonra bayrak sıfırlanmadığı için **ikinci kod hiç okunamıyordu**; paylaş ve galeri düğmeleri ölüydü. |
| `home_shell.dart` | Alt çubuk `Stack`+`Positioned` ile içeriğin üstüne çiziliyordu; ekranlar elle 120 px boşluk koymak zorundaydı, koymayanlarda son satır çubuğun altında kalıyordu. Artık `Scaffold.bottomNavigationBar`. |
| `emoji_sticker_picker.dart` | Izgara aynı 10 emojiyi 5 kez tekrarlıyordu; arama kutusunun denetleyicisi yoktu. |
| `websocket_client.dart` | Her yeniden bağlanmada yeni dinleyici açılıyor, eskisi bırakılmıyordu → mesajlar birden çok kez işleniyordu. `dispose` yoktu. |
| `call_screen.dart` / `calls_history_screen.dart` | `CallType` enum'ı **iki dosyada birden** tanımlıydı. |
| `contacts_screen.dart` | Alt sayfadaki `TextEditingController`'lar hiç `dispose` edilmiyordu. |

#### Bulunan ve düzeltilen **yanlış iddialar**
Kanıtlanamayan iddia, kanıtlanabilir olanların da güvenilirliğini düşürür.

| Yer | Yazan | Gerçek |
|---|---|---|
| `about_screen.dart` | "Şifreleme: Uçtan uca (E2EE)" | `ffi_bridge.dart` sahte; E2EE **yok** |
| `about_screen.dart` | "Backend: Rust (Actix-web)" | Ağ geçidi Axum ile yazılmış, derlenmiyor, kapsam dışı |
| `about_screen.dart` | "Sunucu: Türkiye (İstanbul)" | Çalışan dağıtım yok |
| `chat_detail_screen.dart` | "Şifreleme · Uçtan uca şifreli" | Aynı sebeple yanlış |

Hakkında ekranı artık her bileşeni **Çalışıyor / Planlı / Kapsam dışı**
olarak işaretliyor.

#### Tasarım sistemi
Uygulamada **iki ayrı marka kırmızısı** (`#C8102E` 104 kez, `#E30A17` 10 kez),
üç ayrı gri ve dört ayrı "krem" dolaşıyordu; 430 satırda renk elle yazılmıştı.
Aynı öğe ekrandan ekrana farklı görünüyordu.

- `core/theme/app_palette.dart` — tek kaynak; anlamsal belirteçler
  (`surface`, `brandInk`, `textSecondary`…) `ThemeExtension` olarak.
- **Koyu tema eklendi.** Önceden `darkTheme => lightTheme` idi, yani yoktu.
  Ayarlar → Görünüm'den Açık / Sistem / Koyu seçilebiliyor.
- `AppAvatar` — `cached_network_image` bağımlılığı pubspec'te vardı ama
  **hiç kullanılmıyordu**; 13 yerde ham `Image.network` her kaydırmada
  yeniden indiriyordu. Artık disk önbellekli, görsel yoksa isimden üretilen
  baş harf gösteriliyor.
- `AppCard` / `AppTopBar` / `AppEmptyState` / `AppCountBadge` ile
  tekrarlanan kart ve başlık blokları tek yerde toplandı.
- Okunmamış rozeti `BoxShape.circle` + yatay dolgu ile çiziliyordu; iki haneli
  sayılarda daire rakamları kırpıyordu.

**Nezaket motoru artık sohbet mesaj kutusunda da çalışıyor.** Ürünün tezi
"gönderilmeden önce müdahale"; motor şimdiye dek yalnızca ayrı bir sekmede
çalışıyordu, oysa saldırganlık sohbette yazılır.

### ⚠️ Açık — mimari borç
| Sorun | Etki |
|---|---|
| `ChatBloc`, `WebSocketClient`, `ChatRepository`, `CryptoEngine` sınıfları tanımlı ama **hiçbir yerde kullanılmıyor** (tek bir `BlocProvider` yok) | Uygulama sahte veriyle çalışan bir maket. Ağ katmanı ölü kod. |
| `ffi_bridge.dart` — dosyanın kendi başlığında "MOCK YAPI" yazıyor; `encryptE2EEMessage` sadece `plaintext.codeUnits` döndürüyor | Uçtan uca şifreleme **yok**. Arayüz artık bunu doğru anlatıyor, ama işlev hâlâ eksik. |
| `chat_repository.dart` bellekte `List` tutuyor; `sqflite` bağımlı ama kullanılmıyor | Kalıcı depolama yok, uygulama kapanınca veri uçuyor. |
| Sohbet ve kişi listeleri demo veriden geliyor | `conversation_data.dart` ile arayüzden ayrıldı, ama arkasında depo yok. |
| Tema seçimi kalıcı değil | `ThemeController` bellekte; `shared_preferences` bağımlılığı yok, uygulama kapanınca seçim sıfırlanıyor. |
| Giriş akışı (splash / auth / OTP / profil oluşturma) koyu temaya taşınmadı | Tam ekran marka gradyanı üzerinde çalıştığı için görsel olarak sorun çıkarmıyor; yine de belirteç dışında kalan tek bölge. |

**Karar gerekiyor:** Kullanılmayan ağ/kripto katmanları (`data/`, `domain/`,
`presentation/chat/bloc/`) yeni ürüne taşınacak mı? Jüri kaynak kodu
inceleyebilir; bağlı olmayan sahte katmanlar kötü izlenim bırakır.
Öneri: taşınmayacaklar `legacy/` altına alınsın veya silinsin.

---

## 2. Rust backend — **derlenmiyor**

### Ortam engelleri
| Engel | Kanıt |
|---|---|
| MSVC bağlayıcısı yok | `cargo check` → `error: linker 'link.exe' not found` |
| `protoc` kurulu değil | `crates/proto/build.rs` tonic-build ile `.proto` derliyor; protoc olmadan bu adım başarısız |
| `target/debug` içinde **hiçbir ikili yok** | Yalnızca kilit dosyaları var — bu kod hiç derlenmemiş |

### Koddaki gerçek hatalar (ortam düzelse de geçmez)
| Dosya | Sorun |
|---|---|
| `infrastructure/src/message_router.rs:360` | `use tonic::{...}` — ama `infrastructure/Cargo.toml` içinde **tonic bağımlılığı yok**. Derleme burada durur. |
| `message_router.rs:517` | `metrics::get_message_rate()` — `metrics` crate'inde böyle bir fonksiyon yok, uydurma. |
| `connection.rs` (10+ yer) | `metrics::counter!("ad", 1)` — bu sözdizimi metrics 0.23'te **geçersiz**. Yeni API: `counter!("ad").increment(1)`. |
| `message_router.rs:203` | `self as *const _ as usize` — kullanılmayan unsafe pointer; `route_to_devices` (grup mesajı) placeholder döndürüyor, **implement edilmemiş**. |

### Mimari gerçek
`gateway-ws/src/main.rs:121-186` — dosyanın kendi başlığı: *"Prototip Mock
Servisler"*.

- `AuthMock::verify_jwt` **her token'ı kabul edip rastgele UUID döndürüyor**
  → kimlik doğrulama yok.
- `PresenceMock`, `RateLimiterMock`, `MessageRouterMock`, `MessageStoreMock`
  hepsi `Ok(())` dönüyor.
- Gerçek `infrastructure` implementasyonları hiçbir yere bağlı değil.
- Çalışan tek mesaj yolu (`connection.rs:561`): gelen JSON'u **bağlı tüm
  cihazlara broadcast** ediyor — sohbet değil, global oda.

---

## 3. Konu dışı ve riskli bileşen: Lawful Intercept

`infrastructure/src/db/clickhouse/lawful_intercept.rs` (161 satır) —
yasal dinleme/metaveri kayıt modülü.

**Bu bileşen NSosyal başvurusunda ağır risk taşıyor.** Şartname
*"kullanıcı mahremiyetini ön planda tutan"* çözümleri destekliyor;
bizim ürünümüzün temel iddiası *"metin cihazdan çıkmaz"*. Aynı depoda
bir dinleme altyapısı bulunması bu iddiayı çürütür.

**Öneri:** NSosyal teslimatının kapsamından çıkarılsın.

---

## 4. Süreç borcu

| Eksik | Etki |
|---|---|
| ~~**Git kurulu değil, depo yok**~~ | ✅ **Çözüldü (3 Ağustos).** Git 2.55.0.3 kuruldu, depo `main` dalında başlatıldı, ilk commit `a5eb597` (276 dosya, 3,4 MB). `.gitattributes` ile satır sonları LF'e sabitlendi. Kalan: uzak depoya push. |
| Test yok (yeni `test/ai/` hariç) | Devralınan 9.600 satır UI kodunun tek testi yok. |
| CI yok | Derlemenin bozulduğu fark edilmedi — nitekim bozulmuştu. |

---

## 5. Önerilen karar: backend kapsamı

Üç seçenek:

**A — Backend'i kapsam dışı bırak.** Ürün cihaz-üstü çalışıyor; sunucu
gerektirmiyor. Raporda "faz 2" olarak anlatılır. *En düşük risk, 24 günde
en gerçekçi.*

**B — Küçük ve gerçek bir servis yaz.** Yalnızca LLM yeniden yazma uç noktası.
Tek crate, ~300 satır, gerçekten derlenen ve çalışan. *Orta risk, yüksek getiri.*

**C — Mevcut backend'i onar.** MSVC + protoc kur, 4 derleme hatasını düzelt,
mock'ları gerçek implementasyonlarla değiştir. *Yüksek risk — mock'ları
gerçeğe çevirmek günler alır ve ürüne değer katmaz.*

**Önerim: B.** Şartname çalışan prototip istiyor; cihaz-üstü motor bunu
zaten karşılıyor. Küçük ve gerçek bir LLM servisi hem "Büyük Dil Modelleri"
maddesini karşılar hem de kanıtlanabilir olur. Mevcut Rust mimarisi raporda
"ölçeklenebilirlik yaklaşımı" olarak anlatılır — ama **çalışıyor diye
sunulmaz**.

### ⏪ KARAR GÜNCELLEMESİ: B geri alındı, A'ya dönüldü (3 Ağustos 2026)

Aşağıdaki B kararı uygulandı, çalıştı ve **kaldırıldı.** Servis yazıldı,
50 testle doğrulandı, mobil uygulamaya bağlandı — sonra kapsam dışına alındı.

Gerekçe iki maddede: üçüncü taraf bir dil modeline (ve ücretli API
anahtarına) bağımlılık, ve bulut kademesinin *"metin cihazdan çıkmaz"*
iddiasına eklediği istisna. İstisnasız bir mahremiyet iddiası, onay
diyaloğuyla iyi savunulan bir istisnadan güçlüdür.

Sonuç: **A seçeneği geçerli** — backend kapsam dışı, ürün tamamen cihaz
üstü. Ayrıntılı karar kaydı: `docs/03_LLM_SERVISI.md`.

Aşağıdaki bölüm tarihsel kayıt olarak korunuyor.

---

### ✅ KARAR: B uygulandı (1 Ağustos 2026) — *sonradan geri alındı*

Servis **Dart** ile yazıldı, Rust ile değil. Gerekçe iki katmanlı:

1. **Ortam engeli.** Rust bu makinede derlenemiyor: MSVC bağlayıcısı yok, GNU
   toolchain yarım kurulu (cargo bileşeni eksik), `gcc` hiçbir yerde yok.
   Derlenebilir hâle getirmek ~1 GB'lık MinGW-w64 kurulumu gerektiriyordu.
2. **Asıl gerekçe — mimari.** Dart seçimi, nezaket motorunun **sunucuda da
   çalışmasını** mümkün kıldı. Bu, servisin en güçlü teknik iddiasının
   temelidir: LLM'in ürettiği öneri, kullanıcıya ulaşmadan önce mobil
   uygulamadakiyle **birebir aynı motorla** yeniden ölçülür. Rust'ta bu
   doğrulama katmanını ikinci kez yazmak gerekirdi ve iki uygulamanın
   davranışının aynı kalacağının garantisi olmazdı.

Ayrıntı: `docs/03_LLM_SERVISI.md` ve `server/README.md`.

Devralınan Rust backend'i **kapsam dışıdır**. Raporda "faz 2 /
ölçeklenebilirlik yaklaşımı" olarak anlatılabilir, **çalışıyor diye
sunulamaz**.

---

## 6. ✅ Ortam borcu — çözüldü (3 Ağustos 2026)

Git kurulduktan sonra aşağıdaki sorun ortadan kalktı. Doğrulama:
`flutter --version` geçici çözüm ortam değişkeni **olmadan** çalışıyor
(Flutter 3.44.8 · Dart 3.12.2). Aşağıdaki bölüm tarihsel kayıt olarak duruyor.

---

Git kurulu olmadığı için Flutter'ın sarmalayıcı betiği (`flutter`, `dart`)
başarısız oluyordu:

```
update_engine_version.ps1: git : The term 'git' is not recognized...
Error: Unable to determine engine version...
```

`bin/internal/engine.version` dosyası mevcut; betik yalnızca dosyanın git
tarafından izlendiğini *doğrulamak* için git çağırıyor. İki geçici çözüm
doğrulandı:

```powershell
# 1. Sarmalayıcıyı atlat (saf Dart paketleri için — packages/, server/)
& "C:\flutter\bin\cache\dart-sdk\bin\dart.exe" test

# 2. Flutter komutları için git kontrolünü atla
$env:FLUTTER_PREBUILT_ENGINE_VERSION = (Get-Content "C:\flutter\bin\internal\engine.version").Trim()
flutter analyze
```

Bunlar **geçici çözümdür**. Git kurulumu (`winget install --id Git.Git -e`)
artık yalnızca sürüm kontrolü için değil, araç zincirinin çalışması için de
gerekli.
