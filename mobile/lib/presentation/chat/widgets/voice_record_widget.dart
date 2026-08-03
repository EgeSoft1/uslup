import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import 'dart:math' as math;

class VoiceRecordWidget extends StatefulWidget {
  final VoidCallback onCancel;
  final Function(String path, int duration) onSend;

  const VoiceRecordWidget({
    super.key,
    required this.onCancel,
    required this.onSend,
  });

  @override
  State<VoiceRecordWidget> createState() => _VoiceRecordWidgetState();
}

class _VoiceRecordWidgetState extends State<VoiceRecordWidget> with TickerProviderStateMixin {
  int _seconds = 0;
  Timer? _timer;
  final List<double> _waveformData = [];
  final _random = math.Random();
  
  // İptal kaydırması için
  double _dragOffset = 0.0;
  
  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  void _startRecording() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        if (timer.tick % 10 == 0) _seconds++; // Her 1 saniyede
        
        // Rastgele ses dalgası verisi üret (Prototip)
        if (_waveformData.length > 30) _waveformData.removeAt(0);
        // Gerçekçi olması için önceki değere yakın bir değer üret
        final last = _waveformData.isNotEmpty ? _waveformData.last : 10.0;
        var next = last + (_random.nextDouble() * 20 - 10);
        next = next.clamp(5.0, 35.0);
        _waveformData.add(next);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime() {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dx;
      if (_dragOffset < -120) {
        // İptal edildi
        widget.onCancel();
      }
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragOffset > -120) {
      // Geri yaylanma
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(_dragOffset < 0 ? _dragOffset : 0, 0),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: AppTheme.primaryRed.withValues(alpha: 0.1), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            // Yanıp sönen kırmızı nokta
            Container(
              width: 10, height: 10,
              decoration: const BoxDecoration(color: AppTheme.primaryRed, shape: BoxShape.circle),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(duration: 500.ms),
            
            const SizedBox(width: 8),
            
            // Süre
            Text(_formatTime(), 
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600, fontFeatures: [FontFeature.tabularFigures()])),
            
            const SizedBox(width: 12),
            
            // Ses Dalgaları (Waveform)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: _waveformData.map((height) {
                  return Container(
                    margin: const EdgeInsets.only(left: 3),
                    width: 3,
                    height: height,
                    decoration: BoxDecoration(
                      color: AppTheme.accentTurquoise.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Sola kaydır uyarısı
            GestureDetector(
              onHorizontalDragUpdate: _handleDragUpdate,
              onHorizontalDragEnd: _handleDragEnd,
              child: Row(
                children: [
                  const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textSecondary, size: 14)
                      .animate(onPlay: (c) => c.repeat()).slideX(begin: 0.2, end: -0.2, duration: 1.seconds),
                  const SizedBox(width: 4),
                  Text('İptal', style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.8), fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().slideX(begin: 0.2, end: 0, duration: 250.ms, curve: Curves.easeOutBack);
  }
}
