// =============================================================================
// Sohbet Ekranı
// Dosya: mobile/lib/presentation/chat/chat_screen.dart
//
// DÜZELTİLEN İŞLEV HATASI — mesaj sırası
// --------------------------------------
// Liste `reverse: true` ile çiziliyor ve `itemBuilder` `_messages[len-1-i]`
// okuyordu; yani listenin SON elemanı en altta görünür. `_sendMessage` ise
// yeni mesajı `insert(0, ...)` ile listenin BAŞINA koyuyordu.
// Sonuç: gönderilen her mesaj konuşmanın en üstünde, en eski mesajmış gibi
// beliriyordu. Artık `add(...)` ile sona ekleniyor.
//
// YENİ — Nezaket Koçu mesaj kutusunda
// -----------------------------------
// Ürünün tezi "gönderilmeden önce müdahale". Motor şimdiye dek yalnızca ayrı
// bir sekmede çalışıyordu; asıl saldırganlık ise sohbette yazılır. Artık
// aynı `LexicalTurkishClassifier` her tuş vuruşunda mesaj kutusunu da ölçer.
// Düşük riskte hiçbir kesinti yok — yalnızca kenarlık rengi değişir.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_avatar.dart';
import '../call/call_screen.dart';
import 'chat_detail_screen.dart';
import 'widgets/emoji_sticker_picker.dart';

class ChatMessage {
  ChatMessage({
    required this.text,
    required this.isMine,
    required this.sentAt,
    this.isRead = false,
  });

  final String text;
  final bool isMine;
  final DateTime sentAt;
  final bool isRead;

  String get timeLabel => '${sentAt.hour.toString().padLeft(2, '0')}:'
      '${sentAt.minute.toString().padLeft(2, '0')}';
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    this.conversationId = '1',
    required this.contactName,
    this.avatarUrl = 'https://i.pravatar.cc/150?img=11',
  });

  final String conversationId;
  final String contactName;
  final String avatarUrl;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  late final LexicalTurkishClassifier _civility = LexicalTurkishClassifier();
  late final LocalRewriteSuggester _suggester = LocalRewriteSuggester(_civility);

  CivilityAnalysis? _analysis;
  RewriteSuggestion? _suggestion;
  bool _isComposing = false;

  /// Kullanıcı "yine de gönder" dediyse aynı metin için bir daha sorulmaz.
  String? _overriddenText;

  late final List<ChatMessage> _messages = _seedMessages();

  static List<ChatMessage> _seedMessages() {
    final now = DateTime.now();
    DateTime at(int minutesAgo) => now.subtract(Duration(minutes: minutesAgo));
    // En eski başta, en yeni sonda — liste sırası kronolojiktir.
    return [
      ChatMessage(text: 'Selam, nasılsın?', isMine: false, sentAt: at(48)),
      ChatMessage(
          text: 'İyiyim teşekkürler, sen nasılsın? Görüşmeyeli uzun zaman oldu.',
          isMine: true,
          sentAt: at(46),
          isRead: true),
      ChatMessage(
          text: 'Evet baya oldu. Yarın akşam müsait misin? Bir kahve içelim.',
          isMine: false,
          sentAt: at(23)),
      ChatMessage(
          text: 'Harika olur! Kadıköy sahil tarafında buluşalım mı?',
          isMine: true,
          sentAt: at(18),
          isRead: true),
      ChatMessage(
          text: 'Tamamdır, saat 19:00 uygun mudur?',
          isMine: false,
          sentAt: at(6)),
    ];
  }

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  // ─── Nezaket ölçümü ────────────────────────────────────────────────────────

  /// Her tuş vuruşunda çalışır. Ölçülen süre ~280 µs; 16 ms'lik kare
  /// bütçesinin %1,7'si olduğu için gecikmeli tetikleme (debounce) yok.
  void _onTextChanged() {
    final text = _textController.text;
    final analysis = _civility.analyze(text);

    setState(() {
      _analysis = analysis;
      _isComposing = text.trim().isNotEmpty;
      if (text != _overriddenText) _overriddenText = null;
      _suggestion = null;
    });

    if (analysis.risk == RiskLevel.riskli || analysis.risk == RiskLevel.yuksek) {
      _suggester.suggest(analysis).then((suggestion) {
        // Kullanıcı bu arada yazmaya devam etmiş olabilir.
        if (!mounted || _textController.text != analysis.text) return;
        setState(() => _suggestion = suggestion);
      });
    }
  }

  RiskLevel get _risk => _analysis?.risk ?? RiskLevel.temiz;

  bool get _needsConfirmation =>
      _risk == RiskLevel.yuksek && _textController.text != _overriddenText;

  Color _riskColor(AppPalette p) => switch (_risk) {
        RiskLevel.temiz => p.success,
        RiskLevel.dikkat => p.warning,
        RiskLevel.riskli => p.warning,
        RiskLevel.yuksek => p.danger,
      };

  // ─── Gönderme ──────────────────────────────────────────────────────────────

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Yüksek riskte sistem engellemez — sorar. Karar kullanıcınındır.
    if (_needsConfirmation) {
      _confirmRiskySend(text);
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      // DÜZELTME: `insert(0, …)` yeni mesajı en eski konuma koyuyordu.
      _messages
          .add(ChatMessage(text: text, isMine: true, sentAt: DateTime.now()));
      _isComposing = false;
      _analysis = null;
      _suggestion = null;
      _overriddenText = null;
    });
    _textController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    // Liste ters çizildiği için "en alt" 0 ofsetidir.
    _scrollController.animateTo(
      0,
      duration: AppDurations.normal,
      curve: AppCurves.standard,
    );
  }

  Future<void> _confirmRiskySend(String text) async {
    HapticFeedback.heavyImpact();
    final p = context.palette;
    final analysis = _analysis;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.shield_outlined, color: p.danger, size: 28),
        title: const Text('Bunu göndermek istediğine emin misin?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mesajın karşı tarafta ağır bir saldırı olarak okunabilir. '
              'Karar senin — istersen olduğu gibi gönder.',
            ),
            if (analysis != null && analysis.hasFindings) ...[
              const SizedBox(height: AppSpacing.base),
              for (final finding in analysis.findings.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Icon(Icons.circle, size: 5, color: p.danger),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '"${finding.matchedText}" — ${finding.category.label}',
                          style:
                              TextStyle(fontSize: 13, color: p.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Düzenleyeyim'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: p.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Yine de gönder'),
          ),
        ],
      ),
    );

    if (proceed == true && mounted) {
      setState(() => _overriddenText = text);
      _sendMessage();
    }
  }

  void _applySuggestion(RewriteSuggestion suggestion) {
    HapticFeedback.selectionClick();
    _textController.value = TextEditingValue(
      text: suggestion.text,
      selection: TextSelection.collapsed(offset: suggestion.text.length),
    );
  }

  // ─── Ekler ve emoji ────────────────────────────────────────────────────────

  void _showAttachmentMenu() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            alignment: WrapAlignment.center,
            children: [
              _attachmentAction(
                  sheetContext, Icons.photo_library_rounded, 'Galeri'),
              _attachmentAction(sheetContext, Icons.camera_alt_rounded, 'Kamera'),
              _attachmentAction(
                  sheetContext, Icons.insert_drive_file_rounded, 'Dosya'),
              _attachmentAction(
                  sheetContext, Icons.location_on_rounded, 'Konum'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachmentAction(
      BuildContext sheetContext, IconData icon, String label) {
    final p = context.palette;
    return InkWell(
      borderRadius: AppRadius.mdAll,
      onTap: () {
        Navigator.pop(sheetContext);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label yakında etkinleşecek.')),
        );
      },
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: p.brandSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: p.brandInk, size: 23),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(label, style: TextStyle(fontSize: 12, color: p.textSecondary)),
          ],
        ),
      ),
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => EmojiStickerPicker(
        onEmojiSelected: (emoji) {
          final text = _textController.text;
          _textController.value = TextEditingValue(
            text: '$text$emoji',
            selection:
                TextSelection.collapsed(offset: text.length + emoji.length),
          );
          Navigator.pop(sheetContext);
        },
        onStickerSelected: (_) => Navigator.pop(sheetContext),
        onGifSelected: (_) => Navigator.pop(sheetContext),
      ),
    );
  }

  // ─── Çizim ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlayFor(p),
      child: Scaffold(
        backgroundColor: p.background,
        appBar: _buildAppBar(p),
        body: Column(
          children: [
            Expanded(child: _buildMessageList()),
            if (_suggestion != null) _buildSuggestionBar(p, _suggestion!),
            _buildInputBar(p),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppPalette p) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(66),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.surface,
          border: Border(bottom: BorderSide(color: p.divider)),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 66,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, size: 22),
                  color: p.textPrimary,
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Geri',
                ),
                Expanded(
                  child: InkWell(
                    borderRadius: AppRadius.smAll,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                          builder: (_) => const ChatDetailScreen()),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          AppAvatar(
                            imageUrl: widget.avatarUrl,
                            name: widget.contactName,
                            size: 40,
                            isOnline: true,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.contactName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    color: p.textPrimary,
                                  ),
                                ),
                                Text(
                                  'çevrimiçi',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: p.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _AppBarAction(
                  icon: Icons.call_rounded,
                  tooltip: 'Sesli ara',
                  onTap: _startCall,
                ),
                const SizedBox(width: 4),
                _AppBarAction(
                  icon: Icons.videocam_rounded,
                  tooltip: 'Görüntülü ara',
                  onTap: _startCall,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startCall() {
    Navigator.push(
        context, MaterialPageRoute<void>(builder: (_) => const CallScreen()));
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.base, AppSpacing.lg, AppSpacing.base, AppSpacing.lg),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        // `reverse: true` → index 0 en altta. Kronolojik listenin sonundan
        // geriye doğru okunur.
        final position = _messages.length - 1 - index;
        final message = _messages[position];
        final previous = position > 0 ? _messages[position - 1] : null;
        // Avatar yalnızca konuşma sırası değiştiğinde; art arda gelen
        // mesajlarda aynı yüzü tekrarlamak gürültü yapıyordu.
        final showAvatar =
            !message.isMine && (previous == null || previous.isMine);

        return _MessageBubble(
          message: message,
          showAvatar: showAvatar,
          avatarUrl: widget.avatarUrl,
          contactName: widget.contactName,
        );
      },
    );
  }

  // ─── Öneri şeridi ──────────────────────────────────────────────────────────

  Widget _buildSuggestionBar(AppPalette p, RewriteSuggestion suggestion) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.base, 0, AppSpacing.base, AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: p.successSoft,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: p.success.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.auto_fix_high_rounded, size: 15, color: p.success),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Böyle mi demek istedin?',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
              ),
              Text(
                '${suggestion.projectedCivilityScore} puan',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: p.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            suggestion.text,
            style: TextStyle(fontSize: 14, height: 1.35, color: p.textPrimary),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              TextButton(
                onPressed: () => _applySuggestion(suggestion),
                style: TextButton.styleFrom(
                  foregroundColor: p.success,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  minimumSize: const Size(0, 34),
                ),
                child: const Text('Bunu kullan'),
              ),
              TextButton(
                onPressed: () => setState(() => _suggestion = null),
                style: TextButton.styleFrom(
                  foregroundColor: p.textTertiary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  minimumSize: const Size(0, 34),
                ),
                child: const Text('Kendim yazarım'),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.15, end: 0);
  }

  // ─── Mesaj kutusu ──────────────────────────────────────────────────────────

  Widget _buildInputBar(AppPalette p) {
    final riskColor = _riskColor(p);
    final showRisk = _isComposing && _risk != RiskLevel.temiz;

    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.md,
          MediaQuery.viewPaddingOf(context).bottom + AppSpacing.sm),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showRisk) _buildRiskStrip(p, riskColor),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: _showAttachmentMenu,
                icon: const Icon(Icons.add_circle_outline_rounded),
                color: p.textSecondary,
                tooltip: 'Ekle',
              ),
              Expanded(
                child: AnimatedContainer(
                  duration: AppDurations.fast,
                  padding: const EdgeInsets.only(left: AppSpacing.base),
                  decoration: BoxDecoration(
                    color: p.surfaceMuted,
                    borderRadius: AppRadius.xlAll,
                    border: Border.all(
                      color:
                          showRisk ? riskColor.withValues(alpha: 0.7) : p.border,
                      width: showRisk ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          focusNode: _inputFocus,
                          textInputAction: TextInputAction.newline,
                          keyboardType: TextInputType.multiline,
                          maxLines: 5,
                          minLines: 1,
                          style: TextStyle(fontSize: 15, color: p.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Mesaj yaz',
                            hintStyle:
                                TextStyle(color: p.textTertiary, fontSize: 15),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _showEmojiPicker,
                        icon:
                            const Icon(Icons.emoji_emotions_outlined, size: 21),
                        color: p.textTertiary,
                        tooltip: 'Emoji',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _SendButton(
                isComposing: _isComposing,
                needsConfirmation: _needsConfirmation,
                onTap: _isComposing ? _sendMessage : _recordVoiceHint,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _recordVoiceHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesli mesaj yakında etkinleşecek.')),
    );
  }

  /// Mesaj kutusunun üstünde beliren ince nezaket şeridi.
  ///
  /// Kesintisizlik ilkesi: metin engellenmez, yalnızca ne görüldüğü söylenir.
  Widget _buildRiskStrip(AppPalette p, Color riskColor) {
    final analysis = _analysis;
    final finding =
        (analysis != null && analysis.hasFindings) ? analysis.findings.first : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, 0, AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: riskColor.withValues(alpha: p.isDark ? 0.16 : 0.09),
          borderRadius: AppRadius.smAll,
        ),
        child: Row(
          children: [
            Icon(Icons.shield_outlined, size: 15, color: riskColor),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                finding == null
                    ? _risk.intervention
                    : '"${finding.matchedText}" — ${finding.category.label}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: p.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${analysis?.civilityScore ?? 100}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: riskColor,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 180.ms),
    );
  }
}

// ─── Alt bileşenler ──────────────────────────────────────────────────────────

class _AppBarAction extends StatelessWidget {
  const _AppBarAction({
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
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(backgroundColor: p.brandSoft),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.showAvatar,
    required this.avatarUrl,
    required this.contactName,
  });

  final ChatMessage message;
  final bool showAvatar;
  final String avatarUrl;
  final String contactName;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isMine = message.isMine;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine)
            SizedBox(
              width: 34,
              child: showAvatar
                  ? AppAvatar(
                      imageUrl: avatarUrl,
                      name: contactName,
                      size: 26,
                      showOnlineDot: false,
                    )
                  : null,
            ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.74,
              ),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              decoration: BoxDecoration(
                color: isMine ? p.bubbleOutgoing : p.bubbleIncoming,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMine ? 18 : 5),
                  bottomRight: Radius.circular(isMine ? 5 : 18),
                ),
                border: isMine ? null : Border.all(color: p.border),
                boxShadow: isMine ? null : p.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color:
                          isMine ? p.bubbleOutgoingText : p.bubbleIncomingText,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        message.timeLabel,
                        style: TextStyle(
                          color: isMine
                              ? p.bubbleOutgoingText.withValues(alpha: 0.75)
                              : p.textTertiary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead
                              ? Icons.done_all_rounded
                              : Icons.check_rounded,
                          size: 14,
                          color: p.bubbleOutgoingText
                              .withValues(alpha: message.isRead ? 1 : 0.75),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMine) const SizedBox(width: 4),
        ],
      ),
    ).animate().fadeIn(duration: 180.ms).slideY(begin: 0.08, end: 0);
  }
}

/// Gönder düğmesi.
///
/// Yüksek riskte kalkan simgesine döner — kullanıcı basmadan önce sistemin
/// bir şey gördüğünü anlar. Yine de basabilir; engel değil, uyarıdır.
class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.isComposing,
    required this.needsConfirmation,
    required this.onTap,
  });

  final bool isComposing;
  final bool needsConfirmation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = needsConfirmation ? p.danger : p.brand;

    return Semantics(
      button: true,
      label: isComposing ? 'Gönder' : 'Sesli mesaj',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: AppCurves.standard,
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: isComposing ? color : p.surfaceMuted,
            shape: BoxShape.circle,
            boxShadow: isComposing
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.32),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            !isComposing
                ? Icons.mic_rounded
                : needsConfirmation
                    ? Icons.shield_rounded
                    : Icons.send_rounded,
            color: isComposing ? p.brandOn : p.textTertiary,
            size: 21,
          ),
        ),
      ),
    );
  }
}
