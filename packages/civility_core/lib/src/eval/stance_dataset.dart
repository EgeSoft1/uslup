// =============================================================================
// İP-32 · SAVUNMA DİLİ KÜMESİ — düşmanca görüşü aktaran ve kınayan cümleler
// Dosya: packages/civility_core/lib/src/eval/stance_dataset.dart
//
// ── NEDEN ─────────────────────────────────────────────────────────────────
// Ürünün temel iddialarından biri: nefret filtreleri korumaya çalıştıkları
// grubu susturur, bu katman susturmaz. Kimlikten nötr söz eden cümlelerde
// bu tutuyor. Ama 13 Eylül'deki küme dışı taramada, düşmanca görüşü
// BAŞKASINA ATFEDEREK kınayan cümleler Yüksek risk (nefret) aldı:
//
//   "Ermenilerin yok edilmesini savunanlar yargılanmalı"
//   "Mültecilerin ülkesine dönmesini isteyen pankartlar kaldırılsın"
//   "Romanların bu mahallede yaşanmaz dendiği için dışlanması ayıp"
//
// Motor aynı ilkeyi "diyen" için zaten uygular ("sana salak diyen haksız"
// yumuşatılır); "isteyen", "savunan", "dendiği" listede yoktur.
//
// ── PROTOKOL VE SINIRI ────────────────────────────────────────────────────
// Hata sınıfı bilindikten sonra, düzeltme (docs/22, D8) yazılmadan ÖNCE
// yazıldı ve düzeltmeden önce commit edildi. Taramadaki cümleler alınmadı.
//
// Üç parça:
//   A. 20 masum — düşmanca görüşü aktarıp KINAYAN cümleler.
//   B. 10 saldırı — aynı yüklemlerin konuşanın KENDİ görüşü olarak kullanımı.
//   C. 10 saldırı — düşmanca görüşü aktarıp ONAYLAYAN cümleler. Aktarım
//      kuralı bunları da yumuşatır; bu parça D8'in BEDELİNİ ölçmek için
//      bilerek yazıldı ve düzeltmeden sonra kaçmaları beklenir.
//
// Tek etiketleyicilidir.
// =============================================================================

import '../lexicon/toxicity_lexicon.dart';
import 'gold_case.dart';

abstract final class StanceDataset {
  static const List<GoldCase> cases = [
    // ═══ A · Aktarıp kınayan (masum, 20) ════════════════════════════════════
    GoldCase.clean(text: 'Kürtlerin bu ülkeden gitmesini isteyenlere hiç hak vermiyorum', group: GoldGroup.baglam, note: 'A · isteyenler'),
    GoldCase.clean(text: 'Suriyelilerin yok edilmesini savunan hesaplar kapatılmalı', group: GoldGroup.baglam, note: 'A · savunan'),
    GoldCase.clean(text: 'Afganların sınır dışı edilmesini isteyen yorumlar beni çok üzdü', group: GoldGroup.baglam, note: 'A · isteyen'),
    GoldCase.clean(text: 'Alevilerin burada istenmediğini söyleyenler utanmalı', group: GoldGroup.baglam, note: 'A · söyleyenler'),
    GoldCase.clean(text: 'Ermenilerin hain olduğunu iddia edenler tarihi bilmiyor', group: GoldGroup.baglam, note: 'A · iddia edenler'),
    GoldCase.clean(text: 'Göçmenlerin topluma yük olduğunu savunanlara katılmıyorum', group: GoldGroup.baglam, note: 'A · savunanlara'),
    GoldCase.clean(text: 'Romanların hırsız olduğu dendiğinde herkes susuyor, bu yanlış', group: GoldGroup.baglam, note: 'A · dendiğinde'),
    GoldCase.clean(text: 'Engellilerin evde oturması gerektiğini söyleyen yönetici istifa etmeli', group: GoldGroup.baglam, note: 'A · söyleyen'),
    GoldCase.clean(text: 'Yahudilerin yok edilmesini isteyenler her çağda vardı, hep kaybettiler', group: GoldGroup.baglam, note: 'A · isteyenler'),
    GoldCase.clean(text: 'Mültecilerin gönderilmesini savunan pankartlar belediyece kaldırıldı', group: GoldGroup.baglam, note: 'A · savunan'),
    GoldCase.clean(text: 'Eşcinsellerin hastalıklı olduğunu söyleyen doktor uyarı aldı', group: GoldGroup.baglam, note: 'A · söyleyen'),
    GoldCase.clean(text: 'Kadınların çalışmaması gerektiğini savunanlar azınlıkta kaldı', group: GoldGroup.baglam, note: 'A · savunanlar'),
    GoldCase.clean(text: 'Suriyelilerin burada yaşanmaz dediği mahalleye taşındık, çok mutluyuz', group: GoldGroup.baglam, note: 'A · dediği'),
    GoldCase.clean(text: 'Kürtlerin defolsun diye bağırılması ırkçılıktır', group: GoldGroup.baglam, note: 'A · diye'),
    GoldCase.clean(text: 'Afganların asalak olduğunu yazan gazeteye dava açıldı', group: GoldGroup.baglam, note: 'A · yazan'),
    GoldCase.clean(text: 'Rumların bu ülkeden kovulmasını isteyenler tarihe geçti, utançla', group: GoldGroup.baglam, note: 'A · isteyenler'),
    GoldCase.clean(text: 'Göçmenlerin temizlenmesini savunan grup yasaklandı', group: GoldGroup.baglam, note: 'A · savunan'),
    GoldCase.clean(text: 'Çerkeslerin istenmediğini söyleyen tabela söküldü', group: GoldGroup.baglam, note: 'A · söyleyen'),
    GoldCase.clean(text: 'Arapların güvenilmez olduğunu iddia etmek düpedüz önyargı', group: GoldGroup.baglam, note: 'A · iddia etmek'),
    GoldCase.clean(text: 'Engellilerin topluma yük olduğunu savunan kitap toplatıldı', group: GoldGroup.baglam, note: 'A · savunan'),

    // ═══ B · Konuşanın kendi görüşü (saldırı, 10) ═══════════════════════════
    GoldCase.flag(text: 'Kürtler bu ülkeden gitsin', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'B · dışlama'),
    GoldCase.flag(text: 'Suriyeliler yok edilmeli', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'B · varlık reddi'),
    GoldCase.flag(text: 'Afganlar sınır dışı edilmeli', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'B · dışlama'),
    GoldCase.flag(text: 'Aleviler burada istenmiyor', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'B · dışlama'),
    GoldCase.flag(text: 'Ermeniler haindir', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'B · toplu suçlama'),
    GoldCase.flag(text: 'Göçmenler topluma yük oluyor artık', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'B · yük söylemi'),
    GoldCase.flag(text: 'Romanlar hırsızdır zaten', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'B · toplu suçlama'),
    GoldCase.flag(text: 'Eşcinseller hastalıklıdır', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'B · kimlik aşağılama'),
    GoldCase.flag(text: 'Mülteciler gönderilmeli hemen', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'B · dışlama'),
    GoldCase.flag(text: 'Afganlar asalaktır', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'B · insanlıktan çıkarma'),

    // ═══ C · Aktarıp ONAYLAYAN (saldırı, 10) — D8'in bedeli ═════════════════
    GoldCase.flag(text: 'Kürtlerin bu ülkeden gitmesini isteyenler sonuna kadar haklı', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'C · isteyenler + onay'),
    GoldCase.flag(text: 'Suriyelilerin yok edilmesini savunan arkadaşımı destekliyorum', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'C · savunan + onay'),
    GoldCase.flag(text: 'Afganların sınır dışı edilmesini isteyen herkese katılıyorum', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'C · isteyen + onay'),
    GoldCase.flag(text: 'Alevilerin burada istenmediğini söyleyenler doğruyu söylüyor', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'C · söyleyenler + onay'),
    GoldCase.flag(text: 'Göçmenlerin topluma yük olduğunu savunanlar çok haklı', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'C · savunanlar + onay'),
    GoldCase.flag(text: 'Romanların hırsız olduğunu söyleyen komşuma hak veriyorum', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'C · söyleyen + onay'),
    GoldCase.flag(text: 'Mültecilerin gönderilmesini isteyen pankartı ben de taşıdım', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'C · isteyen + onay'),
    GoldCase.flag(text: 'Ermenilerin hain olduğunu yazan yazara bayıldım', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'C · yazan + onay'),
    GoldCase.flag(text: 'Eşcinsellerin hastalıklı olduğunu söyleyen hocamız çok cesur', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'C · söyleyen + onay'),
    GoldCase.flag(text: 'Kürtlerin defolsun diye bağıran kalabalığa ben de katıldım', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'C · diye + onay'),
  ];
}
