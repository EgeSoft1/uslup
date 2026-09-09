// =============================================================================
// Ev sahibi platform — gösterim verisi
// Dosya: mobile/lib/core/social/seed_data.dart
//
// ── BU VERİ NEDEN BÖYLE SEÇİLDİ ───────────────────────────────────────────
// Rastgele doldurulmuş bir akış, katmanın ne işe yaradığını göstermez.
// Buradaki içerik üç işi birden yapmak üzere yazıldı:
//
//   1. İNANDIRICILIK — akış gerçek bir platform gibi okunmalı, yoksa jüri
//      ürünü değil sahneyi değerlendirir.
//   2. KIŞKIRTMA     — en az bir başlık, okuyanı sert cevap yazmaya iten
//      türden olmalı. Katmanın vaadi "sinirlenen kullanıcı duraksar"dır;
//      sinirlenecek bir şey yoksa vaat sınanamaz.
//   3. SINIR VAKALARI — akış, katmanın SUSTURMADIĞI şeyleri de içermeli:
//      sert ama meşru eleştiri, tacize uğradığını anlatan kullanıcı, kendi
//      kimliğinden söz eden kullanıcı. Ürünün ayrıştığı yer burasıdır.
//
// ── SAHTELİK BEYANI ───────────────────────────────────────────────────────
// Buradaki hesaplar, sayılar ve gönderiler KURGUDUR. Gerçek kişi ya da
// kurumların hesapları taklit edilmemiştir; kurumsal adlar yerine kurgusal
// karşılıkları kullanılmıştır. Etkileşim sayıları elle yazılmıştır ve
// hiçbir ölçüm iddiası taşımaz — raporlanan tek sayı `civility_core`
// ölçümleridir.
// =============================================================================

import 'package:flutter/material.dart';

import 'social_models.dart';

abstract final class SeedData {
  // ─── Hesaplar ─────────────────────────────────────────────────────────────

  /// Cihazın sahibi. Prototip boyunca gönderiler bu hesaptan çıkar.
  static const SocialAuthor currentUser = SocialAuthor(
    id: 'u_ben',
    displayName: 'Deniz Yılmaz',
    handle: 'denizyilmaz',
    avatarColors: [Color(0xFF35C6EA), Color(0xFF4A6CF7)],
    bio: 'Yazılım geliştirici · Türkçe doğal dil işleme · Ankara',
    followers: 1284,
    following: 342,
    postCount: 96,
    isCurrentUser: true,
  );

  static const SocialAuthor _festival = SocialAuthor(
    id: 'u_festival',
    displayName: 'Teknoloji Festivali',
    handle: 'teknolojifest',
    avatarColors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
    verified: true,
    bio: 'Havacılık, uzay ve teknoloji festivali · Kurgusal hesap',
    followers: 2840000,
    following: 12,
    postCount: 18400,
  );

  static const SocialAuthor _vakif = SocialAuthor(
    id: 'u_vakif',
    displayName: 'Teknoloji Takımı Vakfı',
    handle: 'teknolojitakimi',
    avatarColors: [Color(0xFF065F46), Color(0xFF10B981)],
    verified: true,
    bio: 'Gençlik ve teknoloji eğitimleri · Kurgusal hesap',
    followers: 941000,
    following: 34,
    postCount: 7120,
  );

  static const SocialAuthor _aliz = SocialAuthor(
    id: 'u_aliz',
    displayName: 'Aliz AI',
    handle: 'alizai',
    avatarColors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
    verified: true,
    bio: 'Üslup — cihaz üstü Türkçe sosyal yapay zekâ katmanı. '
        'Metin cihazdan çıkmaz.',
    followers: 8420,
    following: 96,
    postCount: 214,
  );

  static const SocialAuthor _zeynep = SocialAuthor(
    id: 'u_zeynep',
    displayName: 'Zeynep Aydın',
    handle: 'zeynepaydin',
    avatarColors: [Color(0xFFDB2777), Color(0xFF9333EA)],
    bio: 'Dilbilimci · Türkçe biçimbilim · doktora öğrencisi',
    followers: 12400,
    following: 480,
    postCount: 3210,
  );

  static const SocialAuthor _mert = SocialAuthor(
    id: 'u_mert',
    displayName: 'Mert Kılıç',
    handle: 'mertklc',
    avatarColors: [Color(0xFFB45309), Color(0xFFF59E0B)],
    bio: 'Ürün yöneticisi. Sert eleştiri yaparım, hakaret etmem.',
    followers: 5620,
    following: 812,
    postCount: 9840,
  );

  static const SocialAuthor _elif = SocialAuthor(
    id: 'u_elif',
    displayName: 'Elif Şahin',
    handle: 'elifsahin',
    avatarColors: [Color(0xFF0891B2), Color(0xFF06B6D4)],
    bio: 'Arayüz tasarımcısı · erişilebilirlik · İzmir',
    followers: 22100,
    following: 390,
    postCount: 4680,
  );

  static const SocialAuthor _gundem = SocialAuthor(
    id: 'u_gundem',
    displayName: 'Gündem Notu',
    handle: 'gundemnotu',
    avatarColors: [Color(0xFF334155), Color(0xFF64748B)],
    verified: true,
    bio: 'Kurgusal haber hesabı · prototip verisi',
    followers: 640000,
    following: 8,
    postCount: 51200,
  );

  static const SocialAuthor _burak = SocialAuthor(
    id: 'u_burak',
    displayName: 'Burak Demir',
    handle: 'burakdmr',
    avatarColors: [Color(0xFF15803D), Color(0xFF4ADE80)],
    bio: 'Öğretmen · dijital okuryazarlık',
    followers: 3180,
    following: 640,
    postCount: 1420,
  );

  static const SocialAuthor _selin = SocialAuthor(
    id: 'u_selin',
    displayName: 'Selin Korkmaz',
    handle: 'selinkorkmaz',
    avatarColors: [Color(0xFFBE123C), Color(0xFFFB7185)],
    bio: 'Üniversite öğrencisi',
    followers: 840,
    following: 512,
    postCount: 620,
  );

  static const List<SocialAuthor> suggested = [
    _zeynep,
    _elif,
    _burak,
    _aliz,
    _mert,
  ];

  // ─── Akış ─────────────────────────────────────────────────────────────────

  /// Ana akış. [now] dışarıdan verilir ki zaman etiketleri ("3sa") her
  /// açılışta tutarlı olsun ve testler saate bağlı kalmasın.
  static List<SocialPost> posts(DateTime now) => [
        SocialPost(
          id: 'p1',
          author: _festival,
          body: 'Şanlıurfa\'da geri sayım başladı. 30 Eylül – 4 Ekim '
              'arasında yüz binlerce genç, kendi tasarladığı teknolojiyi '
              'sahaya çıkarıyor.\n\n'
              'Yarışma alanları, ulaşım ve konaklama bilgileri için '
              'takipte kalın. #Festival2026 #Şanlıurfa',
          createdAt: now.subtract(const Duration(minutes: 12)),
          likeCount: 4820,
          replyCount: 214,
          boostCount: 1960,
          viewCount: 184000,
          attachment: const PostAttachment.video(
            'Yarışma alanı · havadan görüntü',
            duration: '1:45',
            tint: [Color(0xFF0EA5E9), Color(0xFF1D4ED8)],
          ),
        ),
        SocialPost(
          id: 'p2',
          author: _aliz,
          body: 'Üslup artık akışın her metin kutusunda çalışıyor: gönderi, '
              'yorum, biyografi.\n\n'
              'Çözümleme cihazda yapılıyor — yazdığınız hiçbir cümle sunucuya '
              'gitmiyor. Ortalama 159 mikrosaniye; 60 FPS kare bütçesinin '
              'yüzde biri bile değil.\n\n'
              'Engellemiyoruz. Öneriyoruz, gerekçesini yazıyoruz, kararı '
              'size bırakıyoruz. #Üslup #SosyalYapayZekâ',
          createdAt: now.subtract(const Duration(minutes: 48)),
          likeCount: 1240,
          replyCount: 86,
          boostCount: 402,
          viewCount: 28400,
          attachment: const PostAttachment.gorsel(
            'Cihaz üstü çözümleme hattı · 5 katman',
            tint: [Color(0xFF35C6EA), Color(0xFF4A6CF7)],
          ),
        ),
        SocialPost(
          id: 'p3',
          author: _gundem,
          body: 'Dün akşamki maçın son dakikasında verilen penaltı kararı '
              'tartışma yarattı. Hakem yönetimi hakkında iki kulüpten de '
              'açıklama bekleniyor.\n\n'
              'Sizce karar doğru muydu?',
          createdAt: now.subtract(const Duration(hours: 2)),
          likeCount: 940,
          replyCount: 3820,
          boostCount: 210,
          viewCount: 412000,
        ),
        SocialPost(
          id: 'p4',
          author: _zeynep,
          body: 'Türkçe için hazır bir toksisite modeli kullanmaya '
              'çalışanlara: dikkat edin, çoğu İngilizce üzerine kurulu ve '
              'eklemeli yapıyı hiç görmüyor.\n\n'
              '"Katolikler bozuk" yakalanıyor ama "Katolikler bozuktur" '
              'kaçıyorsa, sorun eşikte değil — ek listesinde ünlü uyumu '
              'yok demektir.\n\n'
              'Türkçe\'de ek eklemek bir kaçış yolu olmamalı. #DoğalDilİşleme',
          createdAt: now.subtract(const Duration(hours: 4)),
          likeCount: 2140,
          replyCount: 128,
          boostCount: 690,
          viewCount: 64200,
        ),
        SocialPost(
          id: 'p5',
          author: _mert,
          body: 'Bu uygulamanın son güncellemesi bence tam bir felaket. '
              'Navigasyon mantığı bozulmuş, üç tıkla yaptığım işi şimdi '
              'yedi tıkla yapıyorum.\n\n'
              'Ekibe saygım sonsuz ama bu sürüm geri alınmalı.',
          createdAt: now.subtract(const Duration(hours: 5)),
          likeCount: 612,
          replyCount: 94,
          boostCount: 48,
          viewCount: 21800,
        ),
        SocialPost(
          id: 'p6',
          author: _elif,
          body: 'Erişilebilirlik "sonra eklenecek" bir katman değil.\n\n'
              'Kontrast oranını tasarımın sonunda ölçerseniz, düzeltmek için '
              'bütün paleti değiştirmeniz gerekir. Başında ölçerseniz bir '
              'onaltılık kod değiştirirsiniz.\n\n'
              'Bugün ekipte tek komutla çalışan bir kontrast denetimi kurduk. '
              'Tavsiye ederim. #Erişilebilirlik #Tasarım',
          createdAt: now.subtract(const Duration(hours: 7)),
          likeCount: 3420,
          replyCount: 156,
          boostCount: 1180,
          viewCount: 88400,
          attachment: const PostAttachment.gorsel(
            'WCAG 2.1 kontrast tablosu',
            tint: [Color(0xFF14B8A6), Color(0xFF0D9488)],
          ),
        ),
        SocialPost(
          id: 'p7',
          author: _vakif,
          body: 'Dijital okuryazarlık eğitimlerinin sonbahar dönemi '
              'başvuruları açıldı.\n\n'
              'Lise ve üniversite öğrencilerine ücretsiz. Kontenjan sınırlı.',
          createdAt: now.subtract(const Duration(hours: 9)),
          likeCount: 1820,
          replyCount: 62,
          boostCount: 940,
          viewCount: 47600,
        ),
        SocialPost(
          id: 'p8',
          author: _burak,
          body: 'Sınıfta bir anket yaptım: "İnternette birine söylediğin bir '
              'şeye sonradan pişman oldun mu?"\n\n'
              '28 öğrenciden 24\'ü evet dedi. Hepsi de "keşke göndermeden '
              'önce bir saniye düşünseydim" dedi.\n\n'
              'Sorun bilgi eksikliği değil, hız.',
          createdAt: now.subtract(const Duration(hours: 11)),
          likeCount: 5640,
          replyCount: 302,
          boostCount: 2240,
          viewCount: 156000,
          attachment: const PostAttachment.anket(
            ['Evet, birden fazla kez', 'Bir kez oldu', 'Hayır, hiç'],
            [1842, 640, 318],
          ),
        ),
        SocialPost(
          id: 'p_ben_1',
          author: currentUser,
          body: 'Bir cümlenin saldırgan olup olmadığını anlamak için '
              'kelimelere bakmak yetmiyor.\n\n'
              '"Sen hiç aptal değilsin" bir iltifat.\n'
              '"Bana aptal dedi, çok üzüldüm" bir şikâyet.\n'
              '"Kendimi aptal hissettim" bir itiraf.\n\n'
              'Üçünde de aynı kelime var. Kelime listesi üçünü de işaretler.',
          createdAt: now.subtract(const Duration(hours: 6)),
          likeCount: 342,
          replyCount: 28,
          boostCount: 96,
          viewCount: 8420,
        ),
        SocialPost(
          id: 'p_ben_2',
          author: currentUser,
          body: 'Sabah ölçüm aldım: taze bir ayrık kümede duyarlılık '
              'yüzde 100\'den yüzde 12\'ye düştü.\n\n'
              'Canım sıkıldı ama doğru olan bu sayıyı yazmak. '
              'Geliştirme kümesindeki başarı büyük ölçüde ezbermiş.',
          createdAt: now.subtract(const Duration(hours: 22)),
          likeCount: 128,
          replyCount: 14,
          boostCount: 31,
          viewCount: 3240,
        ),
        SocialPost(
          id: 'p9',
          author: _selin,
          body: 'Dün bir gönderimin altına gelen yorumlar yüzünden uygulamayı '
              'sildim, bugün geri yükledim.\n\n'
              'Şikâyet ettim ama "inceleniyor" yazısından öteye geçmedi. '
              'Yorum silinene kadar ben o cümleleri zaten okumuştum.',
          createdAt: now.subtract(const Duration(hours: 14)),
          likeCount: 8920,
          replyCount: 640,
          boostCount: 3120,
          viewCount: 284000,
        ),
      ];

  // ─── Yorumlar ─────────────────────────────────────────────────────────────

  /// Gönderi altındaki yanıtlar.
  ///
  /// `p3` (tartışmalı maç kararı) bilerek kalabalık ve gergindir: jüri
  /// demosunda "buraya bir cevap yaz" denildiğinde insanın sert yazma
  /// eğilimi gerçek olsun diye.
  static List<SocialPost> replies(DateTime now) => [
        // ── p3 · gergin başlık ────────────────────────────────────────────
        SocialPost(
          id: 'r1',
          parentId: 'p3',
          author: _mert,
          body: 'Karar yanlıştı ve bunu söylemek için taraftar olmaya gerek '
              'yok. Pozisyonun tekrarına bakın, temas top oynandıktan sonra.',
          createdAt: now.subtract(const Duration(hours: 1, minutes: 48)),
          likeCount: 1240,
          replyCount: 86,
          boostCount: 42,
          viewCount: 38200,
        ),
        SocialPost(
          id: 'r2',
          parentId: 'p3',
          author: _burak,
          body: 'İki gündür bu tartışmayı okuyorum. Kimse pozisyonu '
              'konuşmuyor, herkes birbirini konuşuyor.',
          createdAt: now.subtract(const Duration(hours: 1, minutes: 20)),
          likeCount: 2840,
          replyCount: 118,
          boostCount: 460,
          viewCount: 64800,
        ),
        SocialPost(
          id: 'r3',
          parentId: 'p3',
          author: _selin,
          body: 'Bana bu yorumun altında "salak" diyen oldu, sırf farklı '
              'düşündüğüm için. Çok üzüldüm açıkçası.\n\n'
              'Ben kimseye hakaret etmedim, sadece pozisyonu farklı gördüm.',
          createdAt: now.subtract(const Duration(minutes: 54)),
          likeCount: 4120,
          replyCount: 210,
          boostCount: 890,
          viewCount: 96400,
        ),
        SocialPost(
          id: 'r4',
          parentId: 'p3',
          author: _zeynep,
          body: 'Selin\'in yorumu, içerik denetiminin en klasik hatasını '
              'gösteriyor: hakaret sözcüğü geçtiği için MAĞDURUN mesajı '
              'işaretlenir, hakaret eden değil.\n\n'
              'Filtre, şikâyet edeni susturur.',
          createdAt: now.subtract(const Duration(minutes: 38)),
          likeCount: 6240,
          replyCount: 94,
          boostCount: 2140,
          viewCount: 128000,
        ),

        // ── p4 · Türkçe DDİ ───────────────────────────────────────────────
        SocialPost(
          id: 'r5',
          parentId: 'p4',
          author: _aliz,
          body: 'Aynı kusuru biz de ölçtük: bildirme eki listesinde yuvarlak '
              'ünlü yoktu ve "bozuk" yakalanırken "bozuktur" kaçıyordu.\n\n'
              'Yani ekin varlığı bir kaçış yoluna dönüşmüştü. Düzeltme '
              'sonrası dört ayrık kümede de gerileme olmadı.',
          createdAt: now.subtract(const Duration(hours: 3, minutes: 10)),
          likeCount: 940,
          replyCount: 28,
          boostCount: 310,
          viewCount: 22400,
        ),
        SocialPost(
          id: 'r6',
          parentId: 'p4',
          author: _elif,
          body: 'Bu konu tasarımı da doğrudan ilgilendiriyor. Kullanıcı '
              'neden uyarıldığını göremiyorsa, uyarı bir hata mesajıdır — '
              'geri bildirim değil.',
          createdAt: now.subtract(const Duration(hours: 2, minutes: 40)),
          likeCount: 1620,
          replyCount: 34,
          boostCount: 520,
          viewCount: 31200,
        ),

        // ── p9 · mağdur anlatısı ──────────────────────────────────────────
        SocialPost(
          id: 'r7',
          parentId: 'p9',
          author: _burak,
          body: 'Bu tam olarak sorunun kendisi. İçerik kaldırılıyor ama '
              'okunmuş olması geri alınmıyor.',
          createdAt: now.subtract(const Duration(hours: 13)),
          likeCount: 3240,
          replyCount: 62,
          boostCount: 1180,
          viewCount: 74600,
        ),
        SocialPost(
          id: 'r8',
          parentId: 'p9',
          author: _zeynep,
          body: 'Yayın sonrası denetim, zararı ölçen bir sistemdir; '
              'önleyen değil. Müdahale noktasını yazma anına taşımadan '
              'bu döngü kırılmıyor.',
          createdAt: now.subtract(const Duration(hours: 12, minutes: 20)),
          likeCount: 5120,
          replyCount: 140,
          boostCount: 1940,
          viewCount: 112000,
        ),

        // ── p5 · sert ama meşru eleştiri ──────────────────────────────────
        SocialPost(
          id: 'r9',
          parentId: 'p5',
          author: _elif,
          body: 'Katılıyorum, yeni akış gerçekten daha uzun. Ama "felaket" '
              'demek yerine hangi adımın eklendiğini yazsak ekip daha hızlı '
              'düzeltir.',
          createdAt: now.subtract(const Duration(hours: 4, minutes: 30)),
          likeCount: 420,
          replyCount: 18,
          boostCount: 36,
          viewCount: 9800,
        ),
      ];

  // ─── Bildirimler ──────────────────────────────────────────────────────────

  static List<SocialNotification> notifications(DateTime now) => [
        SocialNotification(
          id: 'n1',
          kind: NotificationKind.uslup,
          author: null,
          text: 'Bu hafta 3 gönderiyi göndermeden önce düzelttin. '
              'Bu sayı yalnızca sende görünür.',
          createdAt: now.subtract(const Duration(minutes: 6)),
          unread: true,
        ),
        SocialNotification(
          id: 'n2',
          kind: NotificationKind.yanit,
          author: _zeynep,
          text: 'gönderine yanıt verdi: "Aynı ölçümü biz de aldık, '
              'ayrık kümede sonuç çok farklı çıkıyor."',
          createdAt: now.subtract(const Duration(minutes: 24)),
          postId: 'p4',
          unread: true,
        ),
        SocialNotification(
          id: 'n3',
          kind: NotificationKind.begeni,
          author: _elif,
          text: 've 128 kişi gönderini beğendi.',
          createdAt: now.subtract(const Duration(hours: 1, minutes: 5)),
          unread: true,
        ),
        SocialNotification(
          id: 'n4',
          kind: NotificationKind.yukseltme,
          author: _aliz,
          text: 'gönderini yükseltti.',
          createdAt: now.subtract(const Duration(hours: 2, minutes: 30)),
          unread: true,
        ),
        SocialNotification(
          id: 'n5',
          kind: NotificationKind.takip,
          author: _burak,
          text: 'seni takip etmeye başladı.',
          createdAt: now.subtract(const Duration(hours: 5)),
          unread: false,
        ),
        SocialNotification(
          id: 'n6',
          kind: NotificationKind.bahsetme,
          author: _mert,
          text: 'bir gönderide senden bahsetti.',
          createdAt: now.subtract(const Duration(hours: 8)),
          postId: 'p5',
          unread: false,
        ),
        SocialNotification(
          id: 'n7',
          kind: NotificationKind.begeni,
          author: _selin,
          text: 've 42 kişi yorumunu beğendi.',
          createdAt: now.subtract(const Duration(hours: 20)),
          unread: false,
        ),
      ];

  // ─── Gündem ───────────────────────────────────────────────────────────────

  static const List<TrendTopic> trends = [
    TrendTopic(
      tag: 'Şanlıurfa',
      postCount: 48200,
      category: 'Teknoloji · Gündemde',
      risingBy: 240,
    ),
    TrendTopic(
      tag: 'SosyalYapayZekâ',
      postCount: 12400,
      category: 'Teknoloji',
      risingBy: 86,
    ),
    TrendTopic(
      tag: 'DoğalDilİşleme',
      postCount: 6180,
      category: 'Bilim',
    ),
    TrendTopic(
      tag: 'Erişilebilirlik',
      postCount: 4920,
      category: 'Tasarım',
      risingBy: 34,
    ),
    TrendTopic(
      tag: 'DijitalOkuryazarlık',
      postCount: 3240,
      category: 'Eğitim',
    ),
    TrendTopic(
      tag: 'Üslup',
      postCount: 1840,
      category: 'Teknoloji · Yeni',
      risingBy: 412,
    ),
  ];
}
