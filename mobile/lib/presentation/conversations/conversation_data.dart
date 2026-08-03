// =============================================================================
// Sohbet listesi veri modeli
// Dosya: mobile/lib/presentation/conversations/conversation_data.dart
//
// Önceden yedi sohbet, widget ağacının içine tek tek `ConversationTile(...)`
// olarak yazılmıştı. Arama yapılamıyor, sıralanamıyor, sayısı değiştirilemiyordu.
// Veriyi arayüzden ayırmak, aramanın ve sabitlemenin çalışmasını mümkün kılar.
// =============================================================================

import 'package:flutter/foundation.dart';

enum ConversationKind { direct, group }

@immutable
class Conversation {
  const Conversation({
    required this.id,
    required this.name,
    required this.preview,
    required this.time,
    this.unreadCount = 0,
    this.isOnline = false,
    this.avatarUrl,
    this.isPinned = false,
    this.isMuted = false,
    this.isDelivered = false,
    this.kind = ConversationKind.direct,
    required this.sortKey,
  });

  final String id;
  final String name;
  final String preview;

  /// Ekranda gösterilen kısa zaman etiketi ("14:30", "Dün", "Pzt").
  final String time;

  /// Sıralama için gerçek zaman. `time` metni sıralanamaz — "Dün" ile "14:30"
  /// alfabetik karşılaştırıldığında anlamsız sonuç verir.
  final DateTime sortKey;

  final int unreadCount;
  final bool isOnline;
  final String? avatarUrl;
  final bool isPinned;
  final bool isMuted;
  final bool isDelivered;
  final ConversationKind kind;

  bool get hasUnread => unreadCount > 0;

  /// Ada veya son mesaja göre eşleşme. Türkçe'ye duyarlı: "İ/ı" farkı
  /// yüzünden "isa" araması "İsa"yı bulamıyordu.
  bool matches(String query) {
    if (query.trim().isEmpty) return true;
    final q = _fold(query);
    return _fold(name).contains(q) || _fold(preview).contains(q);
  }

  static String _fold(String input) {
    const from = 'İIıŞşĞğÜüÖöÇç';
    const to = 'iiissgguuoocc';
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      final index = from.indexOf(ch);
      buffer.write(index >= 0 ? to[index] : ch.toLowerCase());
    }
    return buffer.toString();
  }
}

/// Demo verisi.
///
/// Backend bağlanana kadar tek kaynak burasıdır; ekranlar sabit liste
/// tutmaz. Gerçek depo geldiğinde yalnızca bu fonksiyon değişir.
List<Conversation> demoConversations() {
  final now = DateTime.now();
  DateTime ago(Duration d) => now.subtract(d);

  return <Conversation>[
    Conversation(
      id: '1',
      name: 'Ahmet Yılmaz',
      preview: 'Yarın buluşalım mı?',
      time: '14:30',
      sortKey: ago(const Duration(minutes: 12)),
      unreadCount: 2,
      isOnline: true,
      avatarUrl: 'https://i.pravatar.cc/150?img=11',
      isPinned: true,
    ),
    Conversation(
      id: '3',
      name: 'İş Grubu',
      preview: 'Zeynep: Sunumu paylaştım',
      time: '13:45',
      sortKey: ago(const Duration(hours: 1)),
      unreadCount: 3,
      isOnline: true,
      isMuted: true,
      isPinned: true,
      kind: ConversationKind.group,
    ),
    Conversation(
      id: '2',
      name: 'Ayşe Kaya',
      preview: 'Dosyayı gönderdim',
      time: 'Dün',
      sortKey: ago(const Duration(hours: 20)),
      isOnline: true,
      avatarUrl: 'https://i.pravatar.cc/150?img=5',
      isDelivered: true,
    ),
    Conversation(
      id: '7',
      name: 'Aile Grubu',
      preview: 'Annem: Akşam yemeği 20:00\'de 🍽️',
      time: 'Dün',
      sortKey: ago(const Duration(hours: 26)),
      unreadCount: 8,
      isMuted: true,
      kind: ConversationKind.group,
    ),
    Conversation(
      id: '4',
      name: 'Mehmet Demir',
      preview: 'Tamam, teşekkürler.',
      time: 'Pzt',
      sortKey: ago(const Duration(days: 2)),
      isOnline: true,
      avatarUrl: 'https://i.pravatar.cc/150?img=15',
      isDelivered: true,
    ),
    Conversation(
      id: '5',
      name: 'Fatma Şahin',
      preview: 'Toplantı saat kaçta?',
      time: 'Pzt',
      sortKey: ago(const Duration(days: 2, hours: 4)),
      avatarUrl: 'https://i.pravatar.cc/150?img=9',
      isDelivered: true,
    ),
    Conversation(
      id: '6',
      name: 'Ali Yıldırım',
      preview: 'Fotoğraf 📷',
      time: 'Paz',
      sortKey: ago(const Duration(days: 3)),
      avatarUrl: 'https://i.pravatar.cc/150?img=12',
    ),
  ];
}

@immutable
class StoryRing {
  const StoryRing({
    required this.name,
    required this.avatarUrl,
    this.isUnseen = false,
    this.isOnline = false,
  });

  final String name;
  final String avatarUrl;
  final bool isUnseen;
  final bool isOnline;
}

const List<StoryRing> demoStories = [
  StoryRing(
      name: 'Ayşe K.',
      avatarUrl: 'https://i.pravatar.cc/150?img=5',
      isUnseen: true,
      isOnline: true),
  StoryRing(
      name: 'Ali Y.',
      avatarUrl: 'https://i.pravatar.cc/150?img=12',
      isUnseen: true),
  StoryRing(
      name: 'Fatma D.',
      avatarUrl: 'https://i.pravatar.cc/150?img=9',
      isOnline: true),
  StoryRing(name: 'Mehmet', avatarUrl: 'https://i.pravatar.cc/150?img=11'),
  StoryRing(name: 'Zeynep', avatarUrl: 'https://i.pravatar.cc/150?img=45'),
];
