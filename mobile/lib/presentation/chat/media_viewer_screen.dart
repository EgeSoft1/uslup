// Not: Medya görüntüleyici KASITLI olarak her iki temada da koyudur.
// Fotoğrafın etrafındaki zemin açık olduğunda göz görsele değil çerçeveye
// gidiyor; bu yüzden burada palet yerine sabit koyu değerler kullanılır.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_palette.dart';

/// Görüntüleyici zemini — her iki temada da sabit koyu.
const Color _scrim = Color(0xFF0D0B0A);
const Color _onScrim = Color(0xFFF6F1EB);
const Color _onScrimMuted = Color(0xFFA8A19B);

class MediaViewerScreen extends StatefulWidget {
  final String heroTag;
  final String title;
  final String time;

  const MediaViewerScreen({
    super.key,
    required this.heroTag,
    required this.title,
    required this.time,
  });

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  
  double _dragOffsetY = 0;
  double _bgOpacity = 1.0;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        _transformationController.value = _animation!.value;
      });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onDoubleTap(TapDownDetails details) {
    if (_animationController.isAnimating) return;
    
    if (_transformationController.value != Matrix4.identity()) {
      // Zoom out
      _animation = Matrix4Tween(
        begin: _transformationController.value,
        end: Matrix4.identity(),
      ).animate(CurveTween(curve: Curves.easeInOut).animate(_animationController));
      _animationController.forward(from: 0);
      setState(() => _isZoomed = false);
    } else {
      // Zoom in
      final position = details.localPosition;
      _animation = Matrix4Tween(
        begin: _transformationController.value,
        end: Matrix4.identity()
          ..translateByDouble(-position.dx * 2, -position.dy * 2, 0, 1)
          ..scaleByDouble(3.0, 3.0, 3.0, 1),
      ).animate(CurveTween(curve: Curves.easeInOut).animate(_animationController));
      _animationController.forward(from: 0);
      setState(() => _isZoomed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kaydırma sırasında arkaplan rengini ve resmin boyutunu ayarla
    final scale = 1.0 - (_dragOffsetY.abs() / 1000).clamp(0.0, 0.4);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Arkaplan
          AnimatedOpacity(
            duration: const Duration(milliseconds: 0),
            opacity: _bgOpacity,
            child: const ColoredBox(color: _scrim),
          ),

          // Medya
          GestureDetector(
            onVerticalDragUpdate: _isZoomed ? null : (details) {
              setState(() {
                _dragOffsetY += details.delta.dy;
                _bgOpacity = (1.0 - (_dragOffsetY.abs() / 400)).clamp(0.0, 1.0);
              });
            },
            onVerticalDragEnd: _isZoomed ? null : (details) {
              if (_dragOffsetY.abs() > 100) {
                Navigator.of(context).pop();
              } else {
                setState(() {
                  _dragOffsetY = 0;
                  _bgOpacity = 1.0;
                });
              }
            },
            child: Transform.translate(
              offset: Offset(0, _dragOffsetY),
              child: Transform.scale(
                scale: scale,
                child: Center(
                  child: Hero(
                    tag: widget.heroTag,
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 1.0,
                      maxScale: 4.0,
                      onInteractionUpdate: (details) {
                        if (details.scale != 1.0) {
                          setState(() => _isZoomed = true);
                        }
                      },
                      onInteractionEnd: (details) {
                        if (_transformationController.value == Matrix4.identity()) {
                          setState(() => _isZoomed = false);
                        }
                      },
                      child: GestureDetector(
                        onDoubleTapDown: _onDoubleTap,
                        child: AspectRatio(
                          aspectRatio: 1, // Kare mock görsel
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: context.palette.brandGradient,
                            ),
                            child: const Center(
                              child: Icon(Icons.image_rounded,
                                  size: 80, color: Colors.white54),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Üst Bar (Sadece resim kaydırılmıyorken göster)
          if (_dragOffsetY == 0 && !_isZoomed)
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  bottom: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_scrim.withValues(alpha: 0.85), Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: _onScrim),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.title, style: const TextStyle(color: _onScrim, fontSize: 16, fontWeight: FontWeight.w600)),
                          Text(widget.time, style: const TextStyle(color: _onScrimMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.star_border_rounded, color: _onScrim),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded, color: _onScrim),
                      onPressed: () {},
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),
            ),

          // Alt Action Bar
          if (_dragOffsetY == 0 && !_isZoomed)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                  top: 24,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [_scrim.withValues(alpha: 0.9), Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(Icons.reply_rounded, 'Yanıtla'),
                    _buildActionButton(Icons.forward_to_inbox_rounded, 'İlet'),
                    _buildActionButton(Icons.share_rounded, 'Paylaş'),
                    _buildActionButton(Icons.delete_outline_rounded, 'Sil'),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _onScrim, size: 24),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: _onScrim.withValues(alpha: 0.8), fontSize: 12)),
      ],
    );
  }
}
