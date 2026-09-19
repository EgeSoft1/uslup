// JavaScript derlemesinin Node.js'te denenmesi.
//
//   dart compile js -O2 example/web/uslup_js.dart -o example/web/uslup.js
//   node example/web/dene.js
//
// uslup.js tarayıcı için derlenir ve fonksiyonu `globalThis` üzerine koyar;
// Node'da da aynı nesne vardır, bu yüzden dosyayı çalıştırmak yeterlidir.
require('./uslup.js');

for (const metin of [
  'Bu fikre katılmıyorum',
  'sikerriimmo',
  'sen tam bir şerrefsizsin',
  'Bana "şerefsiz" dedi, çok üzüldüm',
  'Kaşar peyniri aldım',
]) {
  const s = JSON.parse(globalThis.uslupCozumle(metin));
  const neden = s.bulgular.map((b) => `${b.ifade} → ${b.kategori}`).join(', ');
  console.log(`${s.riskEtiketi.padEnd(11)} ${metin}${neden ? `   [${neden}]` : ''}`);
}
console.log(`civility_core ${globalThis.uslupSurum}`);
