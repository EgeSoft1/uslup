// =============================================================================
// TÜRKİYE MESAJLAŞMA — Premium Splash Ekranı v5
// Dosya: mobile/lib/presentation/splash/splash_screen.dart
//
// Fotogerçekçi arka plan görseli + üzerine altın animasyonlu overlay.
// =============================================================================

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../auth/auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _navigationTimer = Timer(
      const Duration(milliseconds: 3500),
      _navigateToAuth,
    );
  }

  void _navigateToAuth() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AuthScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF2A0406),
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Arka Plan Görseli ───────────────────────
            Image.asset(
              'assets/images/splash_bg.jpg',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),

            // ── Üst gradient overlay (yazı okunurluğu) ──
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                  ],
                  stops: const [0.0, 0.3, 0.6, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // ── Ana İçerik ──────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.50),

                  // ── "TÜRKİYE" başlığı ──
                  Text(
                    'TÜRKİYE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 10,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 25,
                          offset: const Offset(0, 4),
                        ),
                        Shadow(
                          color: const Color(0xFFD4920A).withValues(alpha: 0.35),
                          blurRadius: 50,
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 800.ms)
                      .slideY(begin: 0.5, end: 0, delay: 400.ms, duration: 800.ms, curve: Curves.easeOutCubic),

                  const SizedBox(height: 6),

                  // ── "MESAJLAŞMA" ──
                  Text(
                    'MESAJLAŞMA',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 19,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 14,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 15,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 800.ms, duration: 600.ms),

                  const SizedBox(height: 30),

                  // ── "Güvenli • Yerli • Milli" ──
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _tagText('Güvenli'),
                      _goldDot(),
                      _tagText('Yerli'),
                      _goldDot(),
                      _tagText('Milli'),
                    ],
                  ).animate().fadeIn(delay: 1100.ms, duration: 500.ms),

                  const Spacer(),

                  // ── "Uçtan Uca Şifrelenmiş" rozeti ──
                  AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (_, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 13),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Color.lerp(
                              const Color(0xFFD4920A).withValues(alpha: 0.3),
                              const Color(0xFFD4920A).withValues(alpha: 0.6),
                              (sin(_shimmerController.value * 2 * pi) + 1) / 2,
                            )!,
                            width: 1,
                          ),
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFD4920A).withValues(alpha: 0.12),
                              const Color(0xFFD4920A).withValues(alpha: 0.05),
                            ],
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Kilit ikonu, olmayan bir şifreleme katmanını
                            // ima ediyordu. Telefon ikonu, gerçekten doğru
                            // olan şeyi anlatıyor: işlem cihazın kendisinde.
                            Icon(Icons.phone_iphone_rounded,
                                color: const Color(0xFFD4920A).withValues(alpha: 0.85),
                                size: 16),
                            const SizedBox(width: 10),
                            Text(
                              'Cihazda Çalışır · Metin Çıkmaz',
                              style: TextStyle(
                                color: const Color(0xFFD4920A).withValues(alpha: 0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ).animate().fadeIn(delay: 1500.ms, duration: 500.ms),

                  const SizedBox(height: 16),

                  Text(
                    'v1.0.0',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.25),
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tagText(String text) {
    return Text(
      text,
      style: TextStyle(
        color: const Color(0xFFD4920A).withValues(alpha: 0.95),
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }

  Widget _goldDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(
          color: const Color(0xFFD4920A).withValues(alpha: 0.8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4920A).withValues(alpha: 0.4),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}
