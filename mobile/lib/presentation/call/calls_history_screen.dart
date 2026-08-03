// =============================================================================
// Aramalar Ekranı
// Dosya: mobile/lib/presentation/call/calls_history_screen.dart
//
// DÜZELTİLEN İŞLEV HATALARI
//   • Sağdaki geri arama düğmesi ve başlıktaki "yeni arama" düğmesi süslü
//     `Container`'dı — dokunma işleyicisi yoktu, hiçbiri çalışmıyordu.
//   • Arama kaydına dokunmak da bir şey yapmıyordu.
//   • `CallType` hem burada hem `call_screen.dart` içinde tanımlıydı; iki ayrı
//     tip aynı adı taşıyordu. Tek tanım `call_screen.dart`'a taşındı.
//   • Animasyon gecikmesi `groupIndex * 3 + i` ile hesaplanıyordu; "3" her
//     grupta 3 kayıt olduğunu varsayıyor, aksi hâlde sıralar üst üste biniyordu.
//   • Ekranın %35'ini kaplayan kırmızı manzara katmanı içeriği aşağı itiyordu
//     (120 px boşluk + 120 px alt boşluk). Kaldırıldı.
//   • Renkler paletten okunur — koyu tema çalışır.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_surfaces.dart';
import '../chat/chat_screen.dart';
import 'call_screen.dart';

enum CallDirection { incoming, outgoing, missed }

class CallEntry {
  const CallEntry({
    required this.name,
    required this.direction,
    required this.callType,
    required this.time,
    required this.dateGroup,
    this.avatarUrl,
    this.duration,
  });

  final String name;
  final String? avatarUrl;
  final CallDirection direction;
  final CallType callType;
  final String time;
  final String? duration;
  final String dateGroup;

  bool get isMissed => direction == CallDirection.missed;
}

class CallsHistoryScreen extends StatefulWidget {
  const CallsHistoryScreen({super.key});

  @override
  State<CallsHistoryScreen> createState() => _CallsHistoryScreenState();
}

class _CallsHistoryScreenState extends State<CallsHistoryScreen> {
  int _selectedTab = 0; // 0 = Tümü, 1 = Cevapsızlar

  static const List<CallEntry> _allCalls = [
    CallEntry(
      name: 'Ahmet Yılmaz',
      avatarUrl: 'https://i.pravatar.cc/150?img=11',
      direction: CallDirection.outgoing,
      callType: CallType.voice,
      time: '14:32',
      duration: '3 dk 42 sn',
      dateGroup: 'Bugün',
    ),
    CallEntry(
      name: 'Ayşe Kaya',
      avatarUrl: 'https://i.pravatar.cc/150?img=5',
      direction: CallDirection.missed,
      callType: CallType.voice,
      time: '12:15',
      dateGroup: 'Bugün',
    ),
    CallEntry(
      name: 'Mehmet Demir',
      avatarUrl: 'https://i.pravatar.cc/150?img=15',
      direction: CallDirection.incoming,
      callType: CallType.video,
      time: '10:08',
      duration: '12 dk 05 sn',
      dateGroup: 'Bugün',
    ),
    CallEntry(
      name: 'Fatma Çelik',
      avatarUrl: 'https://i.pravatar.cc/150?img=9',
      direction: CallDirection.outgoing,
      callType: CallType.video,
      time: '21:45',
      duration: '8 dk 30 sn',
      dateGroup: 'Dün',
    ),
    CallEntry(
      name: 'Ali Öztürk',
      avatarUrl: 'https://i.pravatar.cc/150?img=12',
      direction: CallDirection.missed,
      callType: CallType.voice,
      time: '18:22',
      dateGroup: 'Dün',
    ),
    CallEntry(
      name: 'Emre Arslan',
      direction: CallDirection.outgoing,
      callType: CallType.voice,
      time: '17:05',
      duration: '2 dk 18 sn',
      dateGroup: 'Dün',
    ),
  ];

  List<CallEntry> get _filteredCalls =>
      _selectedTab == 1 ? _allCalls.where((c) => c.isMissed).toList() : _allCalls;

  Map<String, List<CallEntry>> get _groupedCalls {
    final map = <String, List<CallEntry>>{};
    for (final call in _filteredCalls) {
      map.putIfAbsent(call.dateGroup, () => []).add(call);
    }
    return map;
  }

  int get _missedCount => _allCalls.where((c) => c.isMissed).length;

  void _placeCall(CallEntry call) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CallScreen(
          contactName: call.name,
          avatarUrl: call.avatarUrl ?? '',
          callType: call.callType,
        ),
      ),
    );
  }

  void _openChat(CallEntry call) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          contactName: call.name,
          avatarUrl: call.avatarUrl ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final groups = _groupedCalls;

    // Animasyon gecikmesi grup sınırlarını aşarak birikmeli sayılır;
    // böylece her satır bir öncekinden sonra belirir.
    var rowCounter = 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlayFor(p),
      child: Scaffold(
        backgroundColor: p.background,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                      AppSpacing.base, AppSpacing.lg, AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: p.brandGradient,
                          borderRadius: AppRadius.smAll,
                          boxShadow: p.brandShadow,
                        ),
                        child:
                            Icon(Icons.call_rounded, color: p.brandOn, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Aramalar',
                                style:
                                    Theme.of(context).textTheme.headlineMedium),
                            Text(
                              _missedCount == 0
                                  ? 'Cevapsız arama yok'
                                  : '$_missedCount cevapsız arama',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: _missedCount == 0
                                    ? p.textSecondary
                                    : p.brandInk,
                                fontWeight: _missedCount == 0
                                    ? FontWeight.w400
                                    : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _showDialpadHint,
                        tooltip: 'Yeni arama',
                        icon: const Icon(Icons.add_ic_call_rounded, size: 20),
                        color: p.brandInk,
                        style: IconButton.styleFrom(
                          backgroundColor: p.surface,
                          side: BorderSide(color: p.border),
                          minimumSize: const Size(42, 42),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 320.ms),
            ),

            // ── Sekmeler ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.base),
                child: _SegmentedTabs(
                  labels: ['Tümü', 'Cevapsızlar${_missedCount > 0 ? ' ($_missedCount)' : ''}'],
                  selected: _selectedTab,
                  onSelect: (index) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedTab = index);
                  },
                ),
              ).animate().fadeIn(delay: 60.ms, duration: 320.ms),
            ),

            if (groups.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: AppEmptyState(
                  icon: Icons.call_missed_rounded,
                  title: 'Cevapsız araman yok',
                  message: 'Kaçırdığın aramalar burada listelenir.',
                ),
              )
            else
              SliverList.builder(
                itemCount: groups.length,
                itemBuilder: (context, groupIndex) {
                  final entry = groups.entries.elementAt(groupIndex);
                  final calls = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSectionHeader(
                        title: entry.key,
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                            AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                      ),
                      for (final call in calls)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.base, 0,
                              AppSpacing.base, AppSpacing.sm + 2),
                          child: _CallTile(
                            call: call,
                            onTap: () => _openChat(call),
                            onCallBack: () => _placeCall(call),
                          ),
                        )
                            .animate()
                            .fadeIn(
                                delay: (28 * rowCounter++).clamp(0, 320).ms,
                                duration: 260.ms)
                            .slideY(begin: 0.05, end: 0),
                    ],
                  );
                },
              ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    );
  }

  void _showDialpadHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Numara çevirme yakında etkinleşecek.')),
    );
  }
}

// ─── Alt bileşenler ──────────────────────────────────────────────────────────

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.surfaceMuted,
        borderRadius: AppRadius.pill,
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: AppDurations.fast,
                  curve: AppCurves.standard,
                  decoration: BoxDecoration(
                    color: selected == i ? p.brand : Colors.transparent,
                    borderRadius: AppRadius.pill,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      color: selected == i ? p.brandOn : p.textSecondary,
                      fontWeight:
                          selected == i ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CallTile extends StatelessWidget {
  const _CallTile({
    required this.call,
    required this.onTap,
    required this.onCallBack,
  });

  final CallEntry call;
  final VoidCallback onTap;
  final VoidCallback onCallBack;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    final (IconData directionIcon, Color directionColor) = switch (call.direction) {
      CallDirection.outgoing => (Icons.call_made_rounded, p.info),
      CallDirection.incoming => (Icons.call_received_rounded, p.success),
      CallDirection.missed => (Icons.call_missed_rounded, p.danger),
    };

    return AppCard(
      onTap: onTap,
      radius: AppRadius.lg,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md + 2, vertical: AppSpacing.md),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AppAvatar(
                  imageUrl: call.avatarUrl,
                  name: call.name,
                  size: 46,
                  showOnlineDot: false,
                ),
                Positioned(
                  right: -3,
                  bottom: -3,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: p.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        color: directionColor
                            .withValues(alpha: p.isDark ? 0.28 : 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        call.callType == CallType.video
                            ? Icons.videocam_rounded
                            : directionIcon,
                        size: 11,
                        color: directionColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  call.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: call.isMissed ? p.danger : p.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(directionIcon, size: 13, color: directionColor),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        call.duration != null
                            ? '${call.time} · ${call.duration}'
                            : call.time,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(color: p.textSecondary, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCallBack,
            tooltip: call.callType == CallType.video
                ? 'Görüntülü ara'
                : 'Geri ara',
            icon: Icon(
              call.callType == CallType.video
                  ? Icons.videocam_rounded
                  : Icons.call_rounded,
              size: 19,
            ),
            color: p.brandInk,
            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(backgroundColor: p.brandSoft),
          ),
        ],
      ),
    );
  }
}
