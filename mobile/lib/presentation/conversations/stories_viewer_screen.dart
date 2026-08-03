// =============================================================================
// TÜRKİYE MESAJLAŞMA — Premium Hikaye Görüntüleyici v4
// Dosya: mobile/lib/presentation/conversations/stories_viewer_screen.dart
//
// Tam ekran hikaye görüntüleme. İlerleme çubuğu, kaydırarak kapatma
// ve yanıt gönderme özelliği.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/widgets/app_avatar.dart';

class StoriesViewerScreen extends StatefulWidget {
  final String userName;
  final String avatarUrl;

  const StoriesViewerScreen({
    super.key,
    this.userName = 'Ayşe K.',
    this.avatarUrl = 'https://i.pravatar.cc/150?img=5',
  });

  @override
  State<StoriesViewerScreen> createState() => _StoriesViewerScreenState();
}

class _StoriesViewerScreenState extends State<StoriesViewerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  final int _totalStories = 3;
  int _currentStoryIndex = 0;
  final TextEditingController _replyController = TextEditingController();

  // Mock hikaye renkleri (gerçek uygulamada resimler olacak)
  final List<List<Color>> _storyGradients = [
    [const Color(0xFFC8102E), const Color(0xFF8B0000)],
    [const Color(0xFF0284C7), const Color(0xFF1E40AF)],
    [const Color(0xFF10B981), const Color(0xFF047857)],
  ];

  final List<String> _storyTexts = [
    'İstanbul boğazından muhteşem bir gün batımı 🌅',
    'Yeni projem üzerinde çalışıyorum 💻',
    'Hafta sonu kahve keyfi ☕',
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });
    _progressController.forward();
  }

  void _nextStory() {
    if (_currentStoryIndex < _totalStories - 1) {
      setState(() => _currentStoryIndex++);
      _progressController.reset();
      _progressController.forward();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      setState(() => _currentStoryIndex--);
      _progressController.reset();
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _replyController.dispose();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.dark,
    ));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.localPosition.dx < screenWidth / 3) {
            _previousStory();
          } else {
            _nextStory();
          }
        },
        onLongPressStart: (_) => _progressController.stop(),
        onLongPressEnd: (_) => _progressController.forward(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Hikaye Arka Planı ──
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _storyGradients[_currentStoryIndex],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.image_rounded, color: Colors.white24, size: 64),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Text(
                        _storyTexts[_currentStoryIndex],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── İlerleme Çubukları ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: List.generate(_totalStories, (index) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 3,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(1.5),
                            child: index < _currentStoryIndex
                                ? Container(color: Colors.white) // Tamamlanmış
                                : index == _currentStoryIndex
                                    ? AnimatedBuilder(
                                        animation: _progressController,
                                        builder: (context, child) {
                                          return LinearProgressIndicator(
                                            value: _progressController.value,
                                            backgroundColor: Colors.white.withValues(alpha: 0.3),
                                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                                            minHeight: 3,
                                          );
                                        },
                                      )
                                    : Container(color: Colors.white.withValues(alpha: 0.3)), // Gelecek
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),

            // ── Üst Kullanıcı Bilgisi ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Row(
                    children: [
                      AppAvatar(
                        imageUrl: widget.avatarUrl,
                        name: widget.userName,
                        size: 36,
                        showOnlineDot: false,
                        ringColor: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.userName,
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '2 saat önce',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms),
            ),

            // ── Alt Yanıt Çubuğu ──
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: TextField(
                              controller: _replyController,
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                              decoration: InputDecoration(
                                hintText: 'Yanıt gönder...',
                                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFC8102E),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: const Color(0xFFC8102E).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
            ),
          ],
        ),
      ),
    );
  }
}
