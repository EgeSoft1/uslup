// =============================================================================
// Ev sahibi platform — veri modelleri
// Dosya: mobile/lib/core/social/social_models.dart
//
// ── BU KATMAN NEDEN VAR ───────────────────────────────────────────────────
// Üslup bir uygulama değil, bir sosyal platformun metin giriş noktalarına
// düşen bir KATMANDIR. Katmanı boş bir ekranda göstermek, onu bir yazım
// denetleyicisine indirger. Ürünün iddiası ise şudur: akışta bir gönderiyi
// okuyup sinirlenen kullanıcı, cevabını yazarken duraksar.
//
// Bu yüzden prototip gerçek bir akış, gerçek yorum başlıkları ve gerçek
// gönderim akışı taşır. Buradaki modeller o kabuğun verisidir.
//
// ── SINIR ─────────────────────────────────────────────────────────────────
// Bu katman ÜRÜNÜN KENDİSİ DEĞİLDİR ve öyle sunulmamalıdır. Ağ yoktur,
// sunucu yoktur, kalıcılık yoktur; veri bellekte durur ve uygulama kapanınca
// kaybolur. Ölçülen, test edilen ve raporlanan şey `civility_core`tur.
// Kabuk, o çekirdeğin nereye takıldığını gösterir.
//
// ── MAHREMİYET ────────────────────────────────────────────────────────────
// Gönderi metinleri burada tutulur çünkü kullanıcının kendi cihazındaki
// kendi akışıdır — tıpkı gerçek bir istemcinin belleğindeki gibi. Üslup
// katmanı bu metinleri OKUR ama hiçbir yere GÖNDERMEZ; topluluk sağlığına
// giden sinyal sınıfının tek bir metin alanı yoktur ve bu, çekirdek pakette
// bir testle korunur (`community_health_test.dart`).
// =============================================================================

import 'package:flutter/material.dart';

// ─── Yazar ───────────────────────────────────────────────────────────────────

/// Akıştaki bir hesap.
///
/// Avatar görselleri ağdan indirilmez — ürünün "çalışma zamanında tek bir ağ
/// çağrısı yapılmaz" iddiası bir görsel için delinemez. Her hesap kendi
/// gradyanını ve baş harflerini taşır, avatar çizilir.
@immutable
class SocialAuthor {
  const SocialAuthor({
    required this.id,
    required this.displayName,
    required this.handle,
    required this.avatarColors,
    this.verified = false,
    this.bio = '',
    this.followers = 0,
    this.following = 0,
    this.postCount = 0,
    this.isCurrentUser = false,
  });

  final String id;
  final String displayName;

  /// `@` işareti olmadan saklanır; arayüz kendisi ekler.
  final String handle;

  final bool verified;

  /// Avatar gradyanının iki ucu.
  final List<Color> avatarColors;

  final String bio;
  final int followers;
  final int following;
  final int postCount;

  /// Cihazın sahibi mi? Kendi gönderilerinde farklı eylemler gösterilir.
  final bool isCurrentUser;

  /// Avatarda yazılan baş harfler.
  ///
  /// Türkçe'ye özgü tuzak: Dart'ın `toUpperCase()` işlevi 'i' harfini 'I'
  /// yapar, oysa Türkçe'de 'İ' olmalıdır. "İbrahim" → "IB" yanlış, "İB"
  /// doğrudur. Aynı sorun çekirdek motorda küçük harfe çevirirken de vardı
  /// ve orada da elle çözülmüştü (`turkish_normalizer.dart`).
  String get initials {
    final words = displayName
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    final first = _trUpperFirst(words.first);
    if (words.length == 1) return first;
    return '$first${_trUpperFirst(words[1])}';
  }

  /// `substring(0, 1)` kasıtlıdır: `characters` paketi Flutter'ın genel
  /// API yüzeyinden gelmez, ayrıca import ister. Görünen adların ilk
  /// karakteri Türkçe bir harftir; birleşik grafem riski yoktur.
  static String _trUpperFirst(String word) {
    final ch = word.substring(0, 1);
    return switch (ch) {
      'i' => 'İ',
      'ı' => 'I',
      _ => ch.toUpperCase(),
    };
  }

  SocialAuthor copyWith({int? followers, int? postCount}) => SocialAuthor(
        id: id,
        displayName: displayName,
        handle: handle,
        avatarColors: avatarColors,
        verified: verified,
        bio: bio,
        followers: followers ?? this.followers,
        following: following,
        postCount: postCount ?? this.postCount,
        isCurrentUser: isCurrentUser,
      );
}

// ─── Gönderi eki ─────────────────────────────────────────────────────────────

/// Gönderiye iliştirilen medya türü.
///
/// Görseller ağdan gelmez; gradyan + etiket olarak çizilir. Bir prototipte
/// sahte fotoğraf indirmek, gösterilen şeyin ne kadarının gerçek olduğunu
/// bulanıklaştırır.
enum PostAttachmentKind { yok, gorsel, video, anket }

@immutable
class PostAttachment {
  const PostAttachment.yok()
      : kind = PostAttachmentKind.yok,
        label = '',
        duration = null,
        pollOptions = const [],
        pollVotes = const [],
        tint = const [Color(0xFF9CA3AF), Color(0xFF6B7280)];

  const PostAttachment.gorsel(this.label, {required this.tint})
      : kind = PostAttachmentKind.gorsel,
        duration = null,
        pollOptions = const [],
        pollVotes = const [];

  const PostAttachment.video(this.label,
      {required this.duration, required this.tint})
      : kind = PostAttachmentKind.video,
        pollOptions = const [],
        pollVotes = const [];

  const PostAttachment.anket(this.pollOptions, this.pollVotes)
      : kind = PostAttachmentKind.anket,
        label = '',
        duration = null,
        tint = const [Color(0xFF35C6EA), Color(0xFF4A6CF7)];

  final PostAttachmentKind kind;
  final String label;
  final String? duration;
  final List<String> pollOptions;
  final List<int> pollVotes;
  final List<Color> tint;

  bool get isEmpty => kind == PostAttachmentKind.yok;

  int get totalVotes => pollVotes.fold(0, (a, b) => a + b);
}

// ─── Gönderi ─────────────────────────────────────────────────────────────────

/// Akıştaki bir gönderi ya da yorum.
///
/// Yorum ayrı bir tür değildir; yalnızca [parentId] taşıyan bir gönderidir.
/// Ayrı tür yapmak, Üslup katmanının yorum kutusunda da çalıştığını
/// göstermek için ikinci bir kod yolu gerektirirdi — ve o yol test
/// edilmediği için sessizce eskirdi.
@immutable
class SocialPost {
  const SocialPost({
    required this.id,
    required this.author,
    required this.body,
    required this.createdAt,
    this.parentId,
    this.likeCount = 0,
    this.replyCount = 0,
    this.boostCount = 0,
    this.viewCount = 0,
    this.liked = false,
    this.boosted = false,
    this.bookmarked = false,
    this.attachment = const PostAttachment.yok(),
    this.revisedBeforeSending = false,
    this.sentDespiteWarning = false,
  });

  final String id;
  final SocialAuthor author;
  final String body;
  final DateTime createdAt;

  /// Doluysa bu bir yorumdur ve bu kimlikli gönderinin altındadır.
  final String? parentId;

  final int likeCount;
  final int replyCount;
  final int boostCount;
  final int viewCount;

  final bool liked;
  final bool boosted;
  final bool bookmarked;

  final PostAttachment attachment;

  /// Kullanıcı bu gönderiyi göndermeden ÖNCE Üslup uyarısı alıp düzeltti mi?
  ///
  /// ── NEDEN GÖNDERİDE VE NEDEN GİZLİ ───────────────────────────────────
  /// Bu alan yalnızca gönderinin sahibine gösterilir ve yalnızca kendi
  /// profilinde toplu olarak sayılır. Akışta herkese "bu kişi düzeltildi"
  /// rozeti basmak, ürünün bütün etik duruşunu tersine çevirirdi: müdahale
  /// bir ceza değil, bir duraksamadır. Rozet, duraksamayı bir damgaya
  /// dönüştürür ve kullanıcıyı özelliği kapatmaya iter.
  final bool revisedBeforeSending;

  /// Uyarıyı görüp yine de gönderdi mi? Aynı gizlilik kuralına tabidir.
  /// Ölçüm için tutulur; sistem hiçbir gönderimi engellemez.
  final bool sentDespiteWarning;

  bool get isReply => parentId != null;

  /// Gönderi metnindeki etiketler (#) — Keşfet gündemini besler.
  List<String> get hashtags => RegExp(r'#([\wçğıöşüÇĞİÖŞÜ]+)')
      .allMatches(body)
      .map((m) => m.group(1)!)
      .toList(growable: false);

  SocialPost copyWith({
    int? likeCount,
    int? replyCount,
    int? boostCount,
    int? viewCount,
    bool? liked,
    bool? boosted,
    bool? bookmarked,
  }) {
    return SocialPost(
      id: id,
      author: author,
      body: body,
      createdAt: createdAt,
      parentId: parentId,
      likeCount: likeCount ?? this.likeCount,
      replyCount: replyCount ?? this.replyCount,
      boostCount: boostCount ?? this.boostCount,
      viewCount: viewCount ?? this.viewCount,
      liked: liked ?? this.liked,
      boosted: boosted ?? this.boosted,
      bookmarked: bookmarked ?? this.bookmarked,
      attachment: attachment,
      revisedBeforeSending: revisedBeforeSending,
      sentDespiteWarning: sentDespiteWarning,
    );
  }
}

// ─── Bildirim ────────────────────────────────────────────────────────────────

enum NotificationKind { begeni, yanit, yukseltme, takip, bahsetme, uslup }

extension NotificationKindInfo on NotificationKind {
  IconData get icon => switch (this) {
        NotificationKind.begeni => Icons.favorite_rounded,
        NotificationKind.yanit => Icons.mode_comment_rounded,
        NotificationKind.yukseltme => Icons.rocket_launch_rounded,
        NotificationKind.takip => Icons.person_add_alt_1_rounded,
        NotificationKind.bahsetme => Icons.alternate_email_rounded,
        NotificationKind.uslup => Icons.shield_moon_rounded,
      };

  String get label => switch (this) {
        NotificationKind.begeni => 'Beğeni',
        NotificationKind.yanit => 'Yanıt',
        NotificationKind.yukseltme => 'Yükseltme',
        NotificationKind.takip => 'Takip',
        NotificationKind.bahsetme => 'Bahsetme',
        NotificationKind.uslup => 'Üslup',
      };
}

@immutable
class SocialNotification {
  const SocialNotification({
    required this.id,
    required this.kind,
    required this.author,
    required this.text,
    required this.createdAt,
    this.unread = true,
    this.postId,
  });

  final String id;
  final NotificationKind kind;

  /// Üslup bildirimlerinde yazar yoktur — bildirim sistemin kendisindendir.
  final SocialAuthor? author;

  final String text;
  final DateTime createdAt;
  final bool unread;
  final String? postId;

  SocialNotification markRead() => SocialNotification(
        id: id,
        kind: kind,
        author: author,
        text: text,
        createdAt: createdAt,
        unread: false,
        postId: postId,
      );
}

// ─── Gündem ──────────────────────────────────────────────────────────────────

@immutable
class TrendTopic {
  const TrendTopic({
    required this.tag,
    required this.postCount,
    required this.category,
    this.risingBy,
  });

  final String tag;
  final int postCount;
  final String category;

  /// Yükseliş yüzdesi; null ise gösterilmez.
  final int? risingBy;
}

// ─── Biçimlendirme yardımcıları ──────────────────────────────────────────────

/// NSosyal'in akışında kullanılan kısa süre biçimi: `10dk`, `3sa`, `2g`.
String kisaSure(DateTime moment, {DateTime? now}) {
  final delta = (now ?? DateTime.now()).difference(moment);
  if (delta.isNegative || delta.inSeconds < 45) return 'şimdi';
  if (delta.inMinutes < 60) return '${delta.inMinutes}dk';
  if (delta.inHours < 24) return '${delta.inHours}sa';
  if (delta.inDays < 7) return '${delta.inDays}g';
  return '${moment.day}.${moment.month}';
}

/// Türkçe kısa sayı biçimi: `842`, `12,4B`, `1,2Mn`.
///
/// Ondalık ayırıcı virgüldür. İngilizce biçim (`12.4K`) Türkçe bir arayüzde
/// hem yanlış hem de "yerli çözüm" iddiasıyla çelişir.
String kisaSayi(int value) {
  if (value < 1000) return '$value';
  if (value < 1000000) {
    final thousands = value / 1000;
    if (thousands >= 100) return '${thousands.round()}B';
    return '${thousands.toStringAsFixed(1).replaceAll('.', ',')}B';
  }
  final millions = value / 1000000;
  return '${millions.toStringAsFixed(1).replaceAll('.', ',')}Mn';
}
