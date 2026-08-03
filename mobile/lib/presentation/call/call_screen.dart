// =============================================================================
// TÜRKİYE MESAJLAŞMA — Premium Arama Ekranı v4
// Dosya: mobile/lib/presentation/call/call_screen.dart
//
// Aktif sesli/görüntülü arama ekranı. Dalga animasyonu, kontrol butonları,
// geri sayım ve koyu/kırmızı premium tasarım.
// =============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/widgets/app_avatar.dart';

enum CallState { ringing, connecting, connected, ended }

/// Arama türünün TEK tanımı. Önceden `calls_history_screen.dart` içinde de
/// aynı adla ikinci bir enum vardı; iki dosya birbirini import ettiğinde
/// çakışıyordu.
enum CallType { voice, video }

class CallScreen extends StatefulWidget {
  final String contactName;
  final String avatarUrl;
  final CallType callType;

  const CallScreen({
    super.key,
    this.contactName = 'Ahmet Yılmaz',
    this.avatarUrl = 'https://i.pravatar.cc/150?img=11',
    this.callType = CallType.voice,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  CallState _callState = CallState.ringing;
  bool _isMuted = false;
  bool _isSpeaker = false;
  bool _isCameraOn = false;

  int _callDurationSeconds = 0;
  Timer? _callTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _isCameraOn = widget.callType == CallType.video;
    
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _callState = CallState.connecting);
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _callState = CallState.connected);
        _startCallTimer();
      }
    });
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _callDurationSeconds++);
    });
  }

  String get _formattedDuration {
    final minutes = (_callDurationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_callDurationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _statusText {
    switch (_callState) {
      case CallState.ringing: return 'Aranıyor...';
      case CallState.connecting: return 'Bağlanıyor...';
      case CallState.connected: return _formattedDuration;
      case CallState.ended: return 'Arama sonlandı';
    }
  }

  void _endCall() {
    HapticFeedback.mediumImpact();
    _callTimer?.cancel();
    setState(() => _callState = CallState.ended);
    // `mounted` denetimi zorunlu: kullanıcı bu 600 ms içinde geri
    // tuşuna basarsa ekran çoktan kapanmış olur.
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _pulseController.dispose();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.dark,
    ));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1C1C2E),
              Color(0xFF2D1B3D),
              Color(0xFF1A0F24),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded, color: Color(0xFF10B981), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Uçtan uca şifreli',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ).animate().fadeIn(duration: 600.ms),

              const Spacer(flex: 2),

              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_callState == CallState.ringing || _callState == CallState.connecting)
                      ...List.generate(3, (i) {
                        return AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final progress = (_pulseController.value + (i * 0.33)) % 1.0;
                            return Opacity(
                              opacity: (1 - progress) * 0.4,
                              child: Container(
                                width: 120 + (progress * 80),
                                height: 120 + (progress * 80),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFC8102E),
                                    width: 2 - (progress * 1.5),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    Container(
                      width: 120,
                      height: 120,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFC8102E), width: 2.5),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFC8102E).withValues(alpha: 0.3), blurRadius: 30),
                        ],
                      ),
                      child: AppAvatar(
                        imageUrl: widget.avatarUrl,
                        name: widget.contactName,
                        size: 114,
                        showOnlineDot: false,
                      ),
                    ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Text(
                widget.contactName,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 8),

              Text(
                _statusText,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _callState == CallState.connected
                      ? const Color(0xFF10B981)
                      : Colors.white.withValues(alpha: 0.6),
                ),
              ).animate().fadeIn(delay: 300.ms),

              const Spacer(flex: 3),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      label: _isMuted ? 'Kapalı' : 'Mikrofon',
                      isActive: _isMuted,
                      onTap: () => setState(() => _isMuted = !_isMuted),
                    ),
                    _buildControlButton(
                      icon: _isSpeaker ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                      label: 'Hoparlör',
                      isActive: _isSpeaker,
                      onTap: () => setState(() => _isSpeaker = !_isSpeaker),
                    ),
                    _buildControlButton(
                      icon: _isCameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                      label: 'Kamera',
                      isActive: _isCameraOn,
                      onTap: () => setState(() => _isCameraOn = !_isCameraOn),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 40),

              GestureDetector(
                onTap: _endCall,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8102E),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFC8102E).withValues(alpha: 0.5), blurRadius: 25, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 32),
                ),
              ).animate().scale(delay: 500.ms, curve: Curves.elasticOut, duration: 600.ms),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isActive ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
