// =============================================================================
// Kişiler Ekranı
// Dosya: mobile/lib/presentation/contacts/contacts_screen.dart
//
// DÜZELTİLEN İŞLEV HATALARI
//   • Liste yalnızca 'A' ve 'B' harf gruplarını çiziyordu; başka harfle
//     başlayan hiçbir kişi GÖRÜNMÜYORDU. "Yeni kişi ekle" ile eklenen kişi
//     de çoğu zaman kayboluyordu. Artık gruplar veriden üretilir.
//   • Sağdaki A-Z kaydırıcısı, harfe dokununca listeyi kaydırmak yerine
//     arama kutusuna o harfi YAZIYORDU — yani filtreliyordu. Artık gerçekten
//     ilgili gruba kaydırıyor.
//   • A-Z şeridi 29 harfi sabit yükseklikte `spaceEvenly` diziyordu; küçük
//     ekranlarda taşıyordu. Artık yalnızca veride karşılığı olan harfler
//     gösteriliyor.
//   • Türkçe sıralama: `compareTo` bayt sırasına göre çalışır, "Çetin"
//     "Zeynep"ten sonra geliyordu. Türk alfabesi sırası uygulandı.
//   • Alt sayfadaki `TextEditingController`'lar hiç `dispose` edilmiyordu.
//   • Boş durum yoktu: arama sonuç vermeyince bomboş ekran kalıyordu.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_surfaces.dart';
import '../call/call_screen.dart';
import '../chat/chat_screen.dart';
import 'qr_scanner_screen.dart';

class Contact {
  const Contact(this.name, this.phone, {this.avatarUrl, this.isOnline = false});

  final String name;
  final String phone;
  final String? avatarUrl;
  final bool isOnline;

  /// Gruplama harfi. Türkçe'ye özgü harfler kendi grubuna düşer;
  /// harf olmayan başlangıçlar "#" altında toplanır.
  String get initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '#';
    final ch = _turkishUpper(trimmed[0]);
    return _turkishAlphabet.contains(ch) ? ch : '#';
  }
}

const List<String> _turkishAlphabet = [
  'A', 'B', 'C', 'Ç', 'D', 'E', 'F', 'G', 'Ğ', 'H', 'I', 'İ', 'J', 'K', 'L',
  'M', 'N', 'O', 'Ö', 'P', 'R', 'S', 'Ş', 'T', 'U', 'Ü', 'V', 'Y', 'Z',
];

/// Türkçe büyük harf: `toUpperCase()` "i" → "I" yapar, doğrusu "İ"dir.
String _turkishUpper(String s) =>
    s.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

/// Türk alfabesi sırasına göre karşılaştırma.
int _turkishCompare(String a, String b) {
  final ua = _turkishUpper(a);
  final ub = _turkishUpper(b);
  final len = ua.length < ub.length ? ua.length : ub.length;
  for (var i = 0; i < len; i++) {
    final ia = _turkishAlphabet.indexOf(ua[i]);
    final ib = _turkishAlphabet.indexOf(ub[i]);
    // Alfabede olmayan karakterler (boşluk, rakam) en sona.
    final ra = ia < 0 ? 1000 + ua.codeUnitAt(i) : ia;
    final rb = ib < 0 ? 1000 + ub.codeUnitAt(i) : ib;
    if (ra != rb) return ra.compareTo(rb);
  }
  return ua.length.compareTo(ub.length);
}

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// Harf başlıklarının konumunu ölçmek için — A-Z kaydırıcısı buraya bakar.
  final Map<String, GlobalKey> _letterKeys = {};

  final List<Contact> _contacts = [
    const Contact('Ahmet Yılmaz', '+90 532 XXX XX XX',
        avatarUrl: 'https://i.pravatar.cc/150?img=11', isOnline: true),
    const Contact('Ali Öztürk', '+90 555 XXX XX XX',
        avatarUrl: 'https://i.pravatar.cc/150?img=12', isOnline: true),
    const Contact('Ayşe Kaya', '+90 541 XXX XX XX',
        avatarUrl: 'https://i.pravatar.cc/150?img=5', isOnline: true),
    const Contact('Burcu Demir', '+90 542 XXX XX XX',
        avatarUrl: 'https://i.pravatar.cc/150?img=44'),
    const Contact('Çetin Aslan', '+90 533 XXX XX XX'),
    const Contact('Fatma Şahin', '+90 536 XXX XX XX',
        avatarUrl: 'https://i.pravatar.cc/150?img=9'),
    const Contact('İrem Doğan', '+90 505 XXX XX XX', isOnline: true),
    const Contact('Mehmet Demir', '+90 543 XXX XX XX',
        avatarUrl: 'https://i.pravatar.cc/150?img=15'),
    const Contact('Zeynep Arslan', '+90 507 XXX XX XX',
        avatarUrl: 'https://i.pravatar.cc/150?img=45'),
  ];

  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Veri ──────────────────────────────────────────────────────────────────

  List<Contact> get _filtered {
    final query = _searchController.text.trim();
    final normalizedQuery = _turkishUpper(query).replaceAll(' ', '');

    final result = _contacts.where((c) {
      if (query.isEmpty) return true;
      return _turkishUpper(c.name).contains(normalizedQuery) ||
          c.phone.replaceAll(' ', '').contains(query.replaceAll(' ', ''));
    }).toList();

    result.sort((a, b) => _sortAscending
        ? _turkishCompare(a.name, b.name)
        : _turkishCompare(b.name, a.name));
    return result;
  }

  /// Harf → o harfle başlayan kişiler. Sıra `_filtered` sırasını korur.
  Map<String, List<Contact>> get _grouped {
    final map = <String, List<Contact>>{};
    for (final contact in _filtered) {
      map.putIfAbsent(contact.initial, () => []).add(contact);
    }
    return map;
  }

  void _jumpToLetter(String letter) {
    final key = _letterKeys[letter];
    final ctx = key?.currentContext;
    if (ctx == null) return;
    HapticFeedback.selectionClick();
    Scrollable.ensureVisible(
      ctx,
      duration: AppDurations.normal,
      curve: AppCurves.standard,
      alignment: 0.08,
    );
  }

  // ─── Çizim ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final grouped = _grouped;
    final letters = grouped.keys.toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlayFor(p),
      child: Scaffold(
        backgroundColor: p.background,
        body: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                _buildHeader(p),
                _buildSearch(p),
                if (_searchController.text.isEmpty) _buildQuickActions(p),
                _buildListHeader(p, _filtered.length),
                if (grouped.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      icon: Icons.person_search_rounded,
                      title: 'Kişi bulunamadı',
                      message:
                          '"${_searchController.text.trim()}" için eşleşme yok.',
                      action: TextButton(
                        onPressed: _searchController.clear,
                        child: const Text('Aramayı temizle'),
                      ),
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: letters.length,
                    itemBuilder: (context, index) {
                      final letter = letters[index];
                      final key =
                          _letterKeys.putIfAbsent(letter, GlobalKey.new);
                      return _ContactGroup(
                        key: ValueKey('group-$letter'),
                        anchorKey: key,
                        letter: letter,
                        contacts: grouped[letter]!,
                        onCall: (c) => _startCall(c, false),
                        onVideo: (c) => _startCall(c, true),
                        onMessage: _openChat,
                      );
                    },
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
              ],
            ),
            if (letters.length > 1)
              Positioned(
                right: 2,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _AlphabetRail(
                    letters: letters,
                    onSelect: _jumpToLetter,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppPalette p) {
    return SliverToBoxAdapter(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.base, AppSpacing.lg, AppSpacing.md),
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
                child: Icon(Icons.people_rounded, color: p.brandOn, size: 21),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Kişiler',
                        style: Theme.of(context).textTheme.headlineMedium),
                    Text(
                      '${_contacts.length} kişi',
                      style: TextStyle(fontSize: 12.5, color: p.textSecondary),
                    ),
                  ],
                ),
              ),
              _CircleAction(
                icon: Icons.person_add_alt_1_rounded,
                tooltip: 'Kişi ekle',
                onTap: _showAddContactSheet,
              ),
              const SizedBox(width: AppSpacing.sm),
              _CircleAction(
                icon: _sortAscending
                    ? Icons.sort_by_alpha_rounded
                    : Icons.sort_rounded,
                tooltip: _sortAscending ? 'Z → A sırala' : 'A → Z sırala',
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _sortAscending = !_sortAscending);
                },
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 320.ms),
    );
  }

  Widget _buildSearch(AppPalette p) {
    final hasQuery = _searchController.text.isNotEmpty;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.base),
        child: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          style: TextStyle(fontSize: 15, color: p.textPrimary),
          decoration: InputDecoration(
            hintText: 'Kişi veya numara ara',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: hasQuery
                ? IconButton(
                    tooltip: 'Temizle',
                    onPressed: _searchController.clear,
                    icon: const Icon(Icons.close_rounded, size: 18),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base, vertical: 12),
            border: const OutlineInputBorder(
                borderRadius: AppRadius.pill, borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.pill,
                borderSide: BorderSide(color: p.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.pill,
                borderSide: BorderSide(color: p.brandInk, width: 1.5)),
          ),
        ),
      ).animate().fadeIn(delay: 60.ms, duration: 320.ms),
    );
  }

  Widget _buildQuickActions(AppPalette p) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.base, 0, AppSpacing.base, AppSpacing.lg),
        child: Column(
          children: [
            _QuickAction(
              icon: Icons.person_add_rounded,
              tint: p.brandInk,
              title: 'Yeni kişi ekle',
              subtitle: 'Rehberinden seç ya da bilgileri gir',
              onTap: _showAddContactSheet,
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            _QuickAction(
              icon: Icons.qr_code_2_rounded,
              tint: p.warning,
              title: 'QR kodum / kod tara',
              subtitle: 'Karşılıklı kod okutarak hızlı ekle',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute<void>(builder: (_) => const QrScannerScreen())),
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            _QuickAction(
              icon: Icons.group_add_rounded,
              tint: p.info,
              title: 'Yeni grup oluştur',
              subtitle: 'Grup kur ve arkadaşlarını ekle',
              onTap: _showCreateGroupSheet,
            ),
          ],
        ),
      ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.05, end: 0),
    );
  }

  Widget _buildListHeader(AppPalette p, int count) {
    return SliverToBoxAdapter(
      child: AppSectionHeader(
        title: 'Tüm kişiler',
        icon: Icons.contacts_rounded,
        trailing: AppBadge(label: '$count', dense: true),
      ),
    );
  }

  // ─── Eylemler ──────────────────────────────────────────────────────────────

  void _openChat(Contact contact) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          contactName: contact.name,
          avatarUrl: contact.avatarUrl ?? '',
        ),
      ),
    );
  }

  void _startCall(Contact contact, bool isVideo) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CallScreen(
          contactName: contact.name,
          avatarUrl: contact.avatarUrl ?? '',
          callType: isVideo ? CallType.video : CallType.voice,
        ),
      ),
    );
  }

  void _showAddContactSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _AddContactSheet(
        onSubmit: (name, phone) {
          setState(() => _contacts.add(Contact(name, phone)));
          Navigator.pop(sheetContext);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$name kişilere eklendi.')),
          );
        },
      ),
    );
  }

  void _showCreateGroupSheet() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _CreateGroupDialog(
        onSubmit: (name) {
          Navigator.pop(dialogContext);
          Navigator.push(
            context,
            MaterialPageRoute<void>(
                builder: (_) => ChatScreen(contactName: name)),
          );
        },
      ),
    );
  }
}

// ─── Alt bileşenler ──────────────────────────────────────────────────────────

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon, size: 20),
      color: p.brandInk,
      style: IconButton.styleFrom(
        backgroundColor: p.surface,
        side: BorderSide(color: p.border),
        minimumSize: const Size(42, 42),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      onTap: onTap,
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: p.isDark ? 0.20 : 0.11),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(icon, color: tint, size: 23),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: p.textSecondary),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: p.textTertiary),
        ],
      ),
    );
  }
}

class _ContactGroup extends StatelessWidget {
  const _ContactGroup({
    super.key,
    required this.anchorKey,
    required this.letter,
    required this.contacts,
    required this.onCall,
    required this.onVideo,
    required this.onMessage,
  });

  final GlobalKey anchorKey;
  final String letter;
  final List<Contact> contacts;
  final ValueChanged<Contact> onCall;
  final ValueChanged<Contact> onVideo;
  final ValueChanged<Contact> onMessage;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      // Sağda A-Z şeridi için pay bırakılır.
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.xxl, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            key: anchorKey,
            padding: const EdgeInsets.only(
                top: AppSpacing.sm, bottom: AppSpacing.md),
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: p.brandInk,
                letterSpacing: 0.5,
              ),
            ),
          ),
          for (var i = 0; i < contacts.length; i++) ...[
            _ContactRow(
              contact: contacts[i],
              onCall: () => onCall(contacts[i]),
              onVideo: () => onVideo(contacts[i]),
              onMessage: () => onMessage(contacts[i]),
            ),
            if (i < contacts.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 62),
                child: Divider(color: p.divider, height: 1),
              ),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.contact,
    required this.onCall,
    required this.onVideo,
    required this.onMessage,
  });

  final Contact contact;
  final VoidCallback onCall;
  final VoidCallback onVideo;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return InkWell(
      onTap: onMessage,
      borderRadius: AppRadius.mdAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            AppAvatar(
              imageUrl: contact.avatarUrl,
              name: contact.name,
              size: 46,
              isOnline: contact.isOnline,
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    contact.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contact.phone,
                    style: TextStyle(fontSize: 12.5, color: p.textSecondary),
                  ),
                ],
              ),
            ),
            _MiniAction(icon: Icons.call_rounded, tooltip: 'Ara', onTap: onCall),
            const SizedBox(width: 6),
            _MiniAction(
                icon: Icons.videocam_rounded,
                tooltip: 'Görüntülü ara',
                onTap: onVideo),
          ],
        ),
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon, size: 17),
      color: p.brandInk,
      // Dokunma hedefi 40 px — Material'ın asgarisine yakın, satırı şişirmiyor.
      constraints: const BoxConstraints.tightFor(width: 38, height: 38),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(backgroundColor: p.brandSoft),
    );
  }
}

/// Sağdaki harf şeridi. Yalnızca listede karşılığı olan harfleri gösterir.
class _AlphabetRail extends StatelessWidget {
  const _AlphabetRail({required this.letters, required this.onSelect});

  final List<String> letters;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: 3),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.9),
        borderRadius: AppRadius.pill,
        border: Border.all(color: p.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final letter in letters)
            GestureDetector(
              onTap: () => onSelect(letter),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 22,
                height: 22,
                child: Center(
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: p.textSecondary,
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

/// Kişi ekleme alt sayfası.
///
/// `StatefulWidget` çünkü kendi denetleyicilerini `dispose` etmesi gerekiyor;
/// önceki sürümde bunlar sayfa kapanınca sızıyordu.
class _AddContactSheet extends StatefulWidget {
  const _AddContactSheet({required this.onSubmit});

  final void Function(String name, String phone) onSubmit;

  @override
  State<_AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends State<_AddContactSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSubmit(_nameController.text.trim(), _phoneController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yeni kişi ekle',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.base),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Ad soyad',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ad gerekli' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefon numarası',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) => (v == null || v.trim().length < 7)
                  ? 'Geçerli bir numara gir'
                  : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Kişiyi ekle'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateGroupDialog extends StatefulWidget {
  const _CreateGroupDialog({required this.onSubmit});

  final ValueChanged<String> onSubmit;

  @override
  State<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<_CreateGroupDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    widget.onSubmit(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni grup oluştur'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(hintText: 'Grup adı'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Oluştur')),
      ],
    );
  }
}
