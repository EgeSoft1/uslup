// =============================================================================
// TÜRKİYE MESAJLAŞMA — Premium OTP Ekranı v3
// Dosya: mobile/lib/presentation/auth/otp_screen.dart
//
// Referans auth ekranına uyumlu: Krem arka plan, puslu alt siluet,
// Pinput (OTP girişi), Kırmızı onay butonu.
// =============================================================================

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_shell.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  bool _isVerifying = false;
  bool _isError = false;
  bool _isValid = false;
  late AnimationController _btnShimmer;

  // Renk sabitleri (Auth ekranı ile uyumlu)
  static const _redPrimary = Color(0xFFC8102E);
  static const _textDark = Color(0xFF1C1C1E);
  static const _textGray = Color(0xFF8E8E93);
  static const _cream = Color(0xFFFCF8F3);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _btnShimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _pinFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    _btnShimmer.dispose();
    super.dispose();
  }

  Future<void> _verifyCode(String code) async {
    setState(() {
      _isVerifying = true;
      _isError = false;
    });

    _pinFocusNode.unfocus();
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    if (code == "000000") {
      setState(() {
        _isVerifying = false;
        _isError = true;
        _isValid = false;
        _pinController.clear();
      });
      _pinFocusNode.requestFocus();
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeShell(),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: AppDurations.pageTransition,
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final defaultPinTheme = PinTheme(
      width: 50,
      height: 58,
      textStyle: const TextStyle(
        fontSize: 22,
        color: _textDark,
        fontWeight: FontWeight.w700,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0EAE1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: _redPrimary, width: 2),
        boxShadow: [
          BoxShadow(
            color: _redPrimary.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: _redPrimary.withValues(alpha: 0.3), width: 1.5),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: const Color(0xFFFFF0F0),
        border: Border.all(color: const Color(0xFFE30A17), width: 1.5),
      ),
      textStyle: defaultPinTheme.textStyle?.copyWith(color: const Color(0xFFE30A17)),
    );

    return Scaffold(
      backgroundColor: _cream,
      resizeToAvoidBottomInset: true,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Arka Plan Görseli ──
            Positioned.fill(
              child: Image.asset(
                'assets/images/auth_bg.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),

            // ── Alt Siluet ──
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: 0.15,
                child: CustomPaint(
                  size: Size(size.width, size.height * 0.15),
                  painter: _BottomSkylinePainter(),
                ),
              ),
            ),

            // ── Gradient Overlay ──
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFDFBF7).withValues(alpha: 0.0),
                      const Color(0xFFFDFBF7).withValues(alpha: 0.4),
                      const Color(0xFFF9F6F0).withValues(alpha: 0.85),
                      const Color(0xFFF9F6F0),
                    ],
                    stops: const [0.0, 0.45, 0.65, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // ── Ana İçerik ──
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 20),
                      child: Column(
                        children: [
                          SizedBox(height: size.height * 0.05),

                      // ── Geri Butonu ve Başlık ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFF0EAE1)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.arrow_back_ios_new_rounded,
                                    color: _textDark, size: 18),
                              ),
                            ),
                            const Text(
                              'Kodu Doğrula',
                              style: TextStyle(
                                color: _textDark,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(width: 40), // Dengelemek için
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms),

                      SizedBox(height: size.height * 0.06),

                      // ── Merkez İkon (Güvenlik Kalkanı) ──
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _redPrimary.withValues(alpha: 0.15),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.mark_email_read_rounded,
                              color: _redPrimary, size: 36),
                        ),
                      ).animate().scale(
                            begin: const Offset(0.5, 0.5),
                            end: const Offset(1, 1),
                            curve: Curves.easeOutBack,
                            duration: 600.ms,
                          ),

                      const SizedBox(height: 32),

                      // ── Açıklama Metni ──
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                            color: _textGray,
                            fontSize: 15,
                            height: 1.6,
                          ),
                          children: [
                            const TextSpan(text: 'Güvenlik kodunu\n'),
                            TextSpan(
                              text: widget.phoneNumber,
                              style: const TextStyle(
                                color: _textDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const TextSpan(text: '\nnumarasına SMS ile gönderdik.'),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                      const SizedBox(height: 32),

                      // ── OTP Pinput ──
                      Pinput(
                        length: 6,
                        controller: _pinController,
                        focusNode: _pinFocusNode,
                        defaultPinTheme: defaultPinTheme,
                        focusedPinTheme: focusedPinTheme,
                        submittedPinTheme: submittedPinTheme,
                        errorPinTheme: errorPinTheme,
                        forceErrorState: _isError,
                        pinputAutovalidateMode: PinputAutovalidateMode.disabled,
                        showCursor: true,
                        cursor: Container(
                          width: 2,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _redPrimary,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        onChanged: (val) {
                          if (_isError) setState(() => _isError = false);
                          setState(() => _isValid = val.length == 6);
                        },
                        onCompleted: (pin) {
                          if (!_isVerifying) _verifyCode(pin);
                        },
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0, delay: 300.ms),

                      const SizedBox(height: 28),

                      // ── Doğrulama Durumu (Yükleniyor / Hata) ──
                      AnimatedSwitcher(
                        duration: AppDurations.normal,
                        child: _isVerifying
                            ? const Column(
                                key: ValueKey('verifying'),
                                children: [
                                  SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      color: _redPrimary,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Doğrulanıyor...',
                                    style: TextStyle(
                                      color: _textGray,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                key: const ValueKey('idle'),
                                children: [
                                  if (_isError)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF0F0),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: const Color(0xFFE30A17).withValues(alpha: 0.2)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.error_outline_rounded,
                                              color: Color(0xFFE30A17), size: 18),
                                          SizedBox(width: 8),
                                          Text(
                                            'Hatalı kod girdiniz',
                                            style: TextStyle(
                                              color: Color(0xFFE30A17),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  // Yeniden Gönder butonu
                                  TextButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Yeni kod gönderildi'),
                                          backgroundColor: _textDark.withValues(alpha: 0.8),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Kodu Yeniden Gönder',
                                      style: TextStyle(
                                        color: _redPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ).animate().fadeIn(delay: 500.ms),

                      const Spacer(),

                      // ── Devam Et Butonu ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: GestureDetector(
                          onTap: () {
                            if (_isValid && !_isVerifying) {
                              _verifyCode(_pinController.text);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: _isValid
                                    ? [
                                        _redPrimary,
                                        const Color(0xFFA00D22),
                                      ]
                                    : [
                                        _redPrimary.withValues(alpha: 0.4),
                                        const Color(0xFFA00D22).withValues(alpha: 0.4),
                                      ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              boxShadow: _isValid
                                  ? [
                                      BoxShadow(
                                        color: _redPrimary.withValues(alpha: 0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Stack(
                              children: [
                                if (_isValid)
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: ShaderMask(
                                        shaderCallback: (bounds) {
                                          return LinearGradient(
                                            colors: [
                                              Colors.white.withValues(alpha: 0.0),
                                              Colors.white.withValues(alpha: 0.12),
                                              Colors.white.withValues(alpha: 0.0),
                                            ],
                                            stops: [
                                              (_btnShimmer.value - 0.3)
                                                  .clamp(0.0, 1.0),
                                              _btnShimmer.value,
                                              (_btnShimmer.value + 0.3)
                                                  .clamp(0.0, 1.0),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ).createShader(bounds);
                                        },
                                        blendMode: BlendMode.srcATop,
                                        child: Container(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle_outline_rounded,
                                          color: Colors.white.withValues(alpha: _isValid ? 1.0 : 0.7),
                                          size: 22),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Doğrula',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: _isValid ? 1.0 : 0.7),
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 600.ms, duration: 400.ms).slideY(
                            begin: 0.1,
                            end: 0,
                            delay: 600.ms,
                            duration: 400.ms,
                          ),

                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════════════════════════════

/// En alttaki siluet ve merkez hilal yıldız
class _BottomSkylinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    
    final paint = Paint()
      ..color = const Color(0xFFD4AF37) // Altın rengi
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Alt çizgi
    canvas.drawLine(Offset(0, h * 0.7), Offset(w, h * 0.7), paint);
    canvas.drawLine(Offset(0, h * 0.75), Offset(w, h * 0.75), paint..strokeWidth = 0.5);

    // Sol Köprü (sembolik)
    final path = Path();
    path.moveTo(w * 0.05, h * 0.7);
    path.lineTo(w * 0.05, h * 0.2);
    path.lineTo(w * 0.08, h * 0.2);
    path.lineTo(w * 0.08, h * 0.7); 
    path.moveTo(0, h * 0.5);
    path.quadraticBezierTo(w * 0.03, h * 0.6, w * 0.05, h * 0.2);
    path.moveTo(w * 0.08, h * 0.2);
    path.quadraticBezierTo(w * 0.15, h * 0.6, w * 0.25, h * 0.7);

    // Camiler ve Minareler
    path.moveTo(w * 0.35, h * 0.7);
    path.lineTo(w * 0.35, h * 0.4);
    path.moveTo(w * 0.38, h * 0.7);
    path.lineTo(w * 0.38, h * 0.55);
    path.quadraticBezierTo(w * 0.45, h * 0.4, w * 0.52, h * 0.55);
    path.lineTo(w * 0.52, h * 0.7);
    path.moveTo(w * 0.55, h * 0.7);
    path.lineTo(w * 0.55, h * 0.4);
    
    path.moveTo(w * 0.65, h * 0.7);
    path.lineTo(w * 0.65, h * 0.5);
    path.moveTo(w * 0.68, h * 0.7);
    path.quadraticBezierTo(w * 0.72, h * 0.55, w * 0.76, h * 0.7);

    path.moveTo(w * 0.85, h * 0.7);
    path.lineTo(w * 0.85, h * 0.4);
    path.lineTo(w * 0.83, h * 0.35);
    path.lineTo(w * 0.87, h * 0.35);
    path.lineTo(w * 0.89, h * 0.4);
    path.lineTo(w * 0.89, h * 0.7);

    canvas.drawPath(path, paint);

    // En alt orta Hilal Yıldız
    final cx = w / 2;
    final cy = h * 0.88;
    final r = h * 0.1;

    final fillPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.fill;

    // Hilal
    canvas.saveLayer(Rect.fromLTWH(0, 0, w, h), Paint());
    canvas.drawCircle(Offset(cx - r * 0.1, cy), r, fillPaint);
    canvas.drawCircle(
      Offset(cx + r * 0.2, cy - r * 0.05),
      r * 0.8,
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();

    // Yıldız
    final starPath = Path();
    final starCenter = Offset(cx + r * 0.7, cy);
    final starRadius = r * 0.35;
    for (int i = 0; i < 5; i++) {
      final angle = (i * 144 - 90) * pi / 180;
      final point = Offset(
        starCenter.dx + starRadius * cos(angle),
        starCenter.dy + starRadius * sin(angle),
      );
      if (i == 0) {
        starPath.moveTo(point.dx, point.dy);
      } else {
        starPath.lineTo(point.dx, point.dy);
      }
    }
    starPath.close();
    canvas.drawPath(starPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
