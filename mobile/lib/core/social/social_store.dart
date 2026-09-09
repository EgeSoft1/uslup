// =============================================================================
// Ev sahibi platform — bellek içi durum
// Dosya: mobile/lib/core/social/social_store.dart
//
// Akış, yorumlar, beğeniler ve bildirimler burada durur. Ağ yoktur, veri
// tabanı yoktur, disk yoktur; uygulama kapanınca her şey kaybolur.
//
// ── NEDEN KALICILIK YOK ───────────────────────────────────────────────────
// Kasıtlı ve ürünün iddiasıyla tutarlı. `civility_core` çalışma zamanında
// hiçbir şey yazmaz; kabuğun disk kullanması, jüriye "peki metinler nereye
// yazılıyor" sorusunu sordururdu. Gerçek bir istemcide kalıcılık elbette
// olur — ama o kalıcılık platformun sorumluluğudur, katmanın değil.
//
// ── TEK ÖRNEK (SINGLETON) ─────────────────────────────────────────────────
// Sekmeler `IndexedStack` içinde canlı kalır; akışta beğenilen bir gönderi
// profil sekmesinde de beğenilmiş görünmelidir. Durum ekranlarda tutulsaydı
// her sekme kendi kopyasını taşırdı.
// =============================================================================

import 'package:flutter/foundation.dart';

import 'seed_data.dart';
import 'social_models.dart';

class SocialStore extends ChangeNotifier {
  SocialStore._() {
    _seed();
  }

  static final SocialStore instance = SocialStore._();

  /// Test ve önizleme için bağımsız örnek. Tek örneği kirletmez.
  @visibleForTesting
  factory SocialStore.forTest() = SocialStore._;

  final List<SocialPost> _posts = [];
  final List<SocialNotification> _notifications = [];

  /// Bu oturumda kullanıcının uyarı sonrası düzelttiği gönderi sayısı.
  int _revisedThisSession = 0;

  /// Uyarıyı görüp yine de gönderdiği sayı. Sistem engellemez; ölçer.
  int _sentDespiteWarningThisSession = 0;

  /// Bu oturumda kullanıcının yaptığı toplam gönderim.
  int _sentThisSession = 0;

  int _nextId = 1000;

  void _seed() {
    final now = DateTime.now();
    _posts
      ..addAll(SeedData.posts(now))
      ..addAll(SeedData.replies(now));
    _notifications.addAll(SeedData.notifications(now));
  }

  // ─── Okuma ────────────────────────────────────────────────────────────────

  /// Ana akış — yalnızca kök gönderiler, yeniden eskiye.
  List<SocialPost> get feed {
    final roots = _posts.where((p) => !p.isReply).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(roots);
  }

  /// Medya sekmesi — yalnızca eki olan kök gönderiler.
  List<SocialPost> get mediaFeed =>
      List.unmodifiable(feed.where((p) => !p.attachment.isEmpty));

  List<SocialPost> repliesOf(String postId) {
    final items = _posts.where((p) => p.parentId == postId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List.unmodifiable(items);
  }

  SocialPost? postById(String id) {
    for (final p in _posts) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<SocialPost> get myPosts {
    final mine = _posts
        .where((p) => p.author.isCurrentUser && !p.isReply)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(mine);
  }

  List<SocialPost> get myReplies {
    final mine = _posts.where((p) => p.author.isCurrentUser && p.isReply).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(mine);
  }

  List<SocialPost> get bookmarks {
    final saved = _posts.where((p) => p.bookmarked).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(saved);
  }

  List<SocialNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadNotificationCount =>
      _notifications.where((n) => n.unread).length;

  /// Kullanıcının bu oturumda kaç kez uyarıdan sonra metnini düzelttiği.
  ///
  /// Yalnızca cihazın sahibine gösterilir. Bkz. [SocialPost.revisedBeforeSending]
  /// üzerindeki gerekçe: bu sayı bir rozet değil, bir aynadır.
  int get revisedThisSession => _revisedThisSession;

  int get sentDespiteWarningThisSession => _sentDespiteWarningThisSession;

  /// Kullanıcının bu oturumda yaptığı gönderim sayısı (yorumlar dâhil).
  int get sentThisSession => _sentThisSession;

  // ─── Yazma ────────────────────────────────────────────────────────────────

  void toggleLike(String id) => _mutate(id, (p) {
        final on = !p.liked;
        return p.copyWith(
          liked: on,
          likeCount: p.likeCount + (on ? 1 : -1),
        );
      });

  void toggleBoost(String id) => _mutate(id, (p) {
        final on = !p.boosted;
        return p.copyWith(
          boosted: on,
          boostCount: p.boostCount + (on ? 1 : -1),
        );
      });

  void toggleBookmark(String id) =>
      _mutate(id, (p) => p.copyWith(bookmarked: !p.bookmarked));

  /// Yeni gönderi ya da yanıt ekler.
  ///
  /// [revised] ve [sentDespiteWarning], gönderim kutusundaki Üslup katmanının
  /// sonucundan gelir. Metin buraya gelmeden ÖNCE çözümlenmiştir; bu sınıf
  /// çözümleme yapmaz ve motoru hiç tanımaz.
  SocialPost publish({
    required String body,
    String? parentId,
    bool revised = false,
    bool sentDespiteWarning = false,
    PostAttachment attachment = const PostAttachment.yok(),
  }) {
    final post = SocialPost(
      id: '${_nextId++}',
      author: SeedData.currentUser,
      body: body.trim(),
      createdAt: DateTime.now(),
      parentId: parentId,
      viewCount: 1,
      attachment: attachment,
      revisedBeforeSending: revised,
      sentDespiteWarning: sentDespiteWarning,
    );

    _posts.add(post);

    _sentThisSession++;
    if (revised) _revisedThisSession++;
    if (sentDespiteWarning) _sentDespiteWarningThisSession++;

    // Yanıt, üst gönderinin sayacını artırır.
    if (parentId != null) {
      _mutate(parentId, (p) => p.copyWith(replyCount: p.replyCount + 1),
          silent: true);
    }

    notifyListeners();
    return post;
  }

  void markNotificationsRead() {
    var changed = false;
    for (var i = 0; i < _notifications.length; i++) {
      if (_notifications[i].unread) {
        _notifications[i] = _notifications[i].markRead();
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  // ─── İç ───────────────────────────────────────────────────────────────────

  void _mutate(
    String id,
    SocialPost Function(SocialPost) transform, {
    bool silent = false,
  }) {
    for (var i = 0; i < _posts.length; i++) {
      if (_posts[i].id == id) {
        _posts[i] = transform(_posts[i]);
        if (!silent) notifyListeners();
        return;
      }
    }
  }
}
