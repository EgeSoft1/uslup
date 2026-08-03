// =============================================================================
// TÜRKİYE MESAJLAŞMA — Premium Auth Ekranı v6
// Dosya: mobile/lib/presentation/auth/auth_screen.dart
//
// Referans görsele birebir uygun: Kullanıcının yüklediği yeni arka plan,
// üstte Telefon Numaranız ve (i) ikonu, ortada dairesel yörüngeler,
// kalkan ve Türk bayrağı, ülke seçici, +90 telefon girişi, kırmızı Devam Et butonu.
// =============================================================================

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'otp_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();
  Country _selectedCountry = CountryParser.parseCountryCode('TR');
  bool _isValid = false;

  // Renk sabitleri (Görselden referans alınmış)
  static const _redPrimary = Color(0xFFC8102E);
  static const _textDark = Color(0xFF1C1C1E);
  static const _textGray = Color(0xFF8E8E93);
  static const _dividerGray = Color(0xFFE5E5EA);
  static const _goldColor = Color(0xFFD4AF37); // Yörünge ve alt siluet için altın tonu

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _onPhoneChanged(String value) {
    setState(() {
      _isValid = value.replaceAll(RegExp(r'\D'), '').length >= 10;
    });
  }

  void _navigateToOtp() {
    if (!_isValid) return;
    _phoneFocus.unfocus();
    final fullNumber =
        '+${_selectedCountry.phoneCode} ${_phoneController.text.trim()}';

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => OtpScreen(phoneNumber: fullNumber),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      countryListTheme: CountryListThemeData(
        backgroundColor: Colors.white,
        textStyle: const TextStyle(color: _textDark, fontSize: 16),
        searchTextStyle: const TextStyle(color: _textDark, fontSize: 16),
        bottomSheetHeight: MediaQuery.of(context).size.height * 0.85,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        inputDecoration: InputDecoration(
          labelText: 'Ülke Ara',
          hintText: 'Ülke adı yazın...',
          prefixIcon: const Icon(Icons.search, color: _textGray),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _dividerGray),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _dividerGray),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _redPrimary, width: 1.5),
          ),
          filled: true,
          fillColor: const Color(0xFFF8F4EE),
        ),
      ),
      onSelect: (Country country) {
        setState(() => _selectedCountry = country);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── 1. Arka Plan Görseli ───────────────────────
            Positioned.fill(
              child: Image.asset(
                'assets/images/auth_bg.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),

            // ── 2. Alt kısımdaki siluet ve hilal yıldız ──
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

            // ── 3. Gradient Overlay (Alt kısımda form alanlarını belirginleştirmek için) ──
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFDFBF7).withValues(alpha: 0.0), // Üstte tam şeffaf
                      const Color(0xFFFDFBF7).withValues(alpha: 0.4), // Ortada hafif puslu
                      const Color(0xFFF9F6F0).withValues(alpha: 0.85), // Alt form alanında daha opak krem
                      const Color(0xFFF9F6F0), // En altta tam krem
                    ],
                    stops: const [0.0, 0.45, 0.65, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // ── 4. Ana İçerik ──────────────────────────────
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
                          
                          // ── Başlık Çubuğu ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 32), // Dengelemek için
                            const Text(
                              'Telefon Numaranız',
                              style: TextStyle(
                                color: _textDark,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                            // Kırmızı çemberli info ikonu
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _redPrimary,
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(Icons.info_outline_rounded,
                                  color: _redPrimary, size: 20),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms),

                      SizedBox(height: size.height * 0.03),

                      // ── Merkez Görsel Alanı (Kalkan, Bayrak, Yörüngeler) ──
                      SizedBox(
                        height: 240,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Arkadaki dairesel yörüngeler
                            CustomPaint(
                              size: const Size(220, 220),
                              painter: _OrbitRingsPainter(),
                            ),

                            // En üstte duran küçük hilal-yıldız
                            Positioned(
                              top: 0,
                              child: _buildSmallCrescentStar(),
                            ),

                            // Merkezdeki Kalkan (Beyaz çember içinde)
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                  color: _goldColor.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 5,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                // Solid Kırmızı Kalkan
                                child: CustomPaint(
                                  size: const Size(45, 55),
                                  painter: _SolidShieldPainter(),
                                ),
                              ),
                            ),

                            // Soldan çıkan dalgalanan bayrak
                            Positioned(
                              left: 20,
                              top: 70,
                              child: _buildWavingFlagWithPole(),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 600.ms).scale(
                            begin: const Offset(0.9, 0.9),
                            end: const Offset(1, 1),
                            curve: Curves.easeOutBack,
                            duration: 800.ms,
                          ),

                      const Spacer(),

                      // ── Ülke Seçici Kartı ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: GestureDetector(
                          onTap: _showCountryPicker,
                          child: Container(
                            height: 60,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFF0EAE1),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Bayrak dairesi
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey.shade100,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Center(
                                      child: _selectedCountry.countryCode == 'TR' 
                                          ? _buildRoundTurkishFlag() 
                                          : Text(
                                              _selectedCountry.flagEmoji,
                                              style: const TextStyle(fontSize: 22),
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    _selectedCountry.name,
                                    style: const TextStyle(
                                      color: _textDark,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down_rounded,
                                    color: _textGray, size: 24),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(
                            begin: 0.1,
                            end: 0,
                            delay: 200.ms,
                            duration: 400.ms,
                          ),

                      const SizedBox(height: 16),

                      // ── Telefon Numarası Giriş Kartı ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Container(
                          height: 60,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _phoneFocus.hasFocus
                                  ? _redPrimary.withValues(alpha: 0.5)
                                  : const Color(0xFFF0EAE1),
                              width: _phoneFocus.hasFocus ? 1.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Alan Kodu (+90)
                              SizedBox(
                                width: 50,
                                child: Text(
                                  '+${_selectedCountry.phoneCode}',
                                  style: const TextStyle(
                                    color: _redPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              // Dikey Ayırıcı Çizgi
                              Container(
                                width: 1,
                                height: 30,
                                color: const Color(0xFFE5E5EA),
                              ),
                              const SizedBox(width: 16),
                              // Input Alanı
                              Expanded(
                                child: TextField(
                                  controller: _phoneController,
                                  focusNode: _phoneFocus,
                                  keyboardType: TextInputType.phone,
                                  style: const TextStyle(
                                    color: _textDark,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Telefon Numaranız',
                                    hintStyle: TextStyle(
                                      color: _textGray,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 18), // Dikey hizalama için
                                  ),
                                  onChanged: _onPhoneChanged,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(
                            begin: 0.1,
                            end: 0,
                            delay: 300.ms,
                            duration: 400.ms,
                          ),

                      const SizedBox(height: 32),

                      // ── Devam Et Butonu ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: GestureDetector(
                          onTap: _navigateToOtp,
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Outlined kalkan ikonu
                                Icon(Icons.shield_outlined,
                                    color: Colors.white.withValues(alpha: _isValid ? 1.0 : 0.7),
                                    size: 22),
                                const SizedBox(width: 12),
                                Text(
                                  'Devam Et',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: _isValid ? 1.0 : 0.7),
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(Icons.arrow_forward_ios_rounded,
                                    color: Colors.white.withValues(alpha: _isValid ? 1.0 : 0.7),
                                    size: 14),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(
                            begin: 0.1,
                            end: 0,
                            delay: 400.ms,
                            duration: 400.ms,
                          ),

                      // Buton ile ekranın en altı arasındaki boşluk
                      SizedBox(height: size.height * 0.12),
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

  // Özel yuvarlak Türk bayrağı (Ülke seçicide kullanmak için)
  Widget _buildRoundTurkishFlag() {
    return Container(
      color: _redPrimary,
      child: Center(
        child: CustomPaint(
          size: const Size(20, 20),
          painter: _FlagCrescentStarPainter(color: Colors.white),
        ),
      ),
    );
  }

  // Dairesel yörüngelerin tepesindeki küçük kırmızı hilal-yıldız
  Widget _buildSmallCrescentStar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: Color(0xFFF9F6F0),
        shape: BoxShape.circle,
      ),
      child: CustomPaint(
        size: const Size(24, 24),
        painter: _CrescentStarPainter(color: _redPrimary),
      ),
    );
  }

  // Kalkanın yanındaki direkli bayrak
  Widget _buildWavingFlagWithPole() {
    return SizedBox(
      width: 70,
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Direk topuzu
          Positioned(
            left: -2,
            top: -2,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFC0A062),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Direk
          Positioned(
            left: 0,
            top: 2,
            bottom: -20, // Aşağı doğru uzasın
            child: Container(
              width: 2,
              decoration: BoxDecoration(
                color: const Color(0xFFC0A062), // Altın rengi direk
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          // Bayrak Kumaşı
          Positioned(
            left: 2,
            top: 5,
            child: CustomPaint(
              size: const Size(65, 40),
              painter: _WavingFlagPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════════════════════════════

/// Merkezdeki ince altın dairesel yörüngeler
class _OrbitRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    // İç yörünge
    canvas.drawCircle(Offset(cx, cy), size.width * 0.35, paint);
    
    // Orta yörünge
    canvas.drawCircle(Offset(cx, cy), size.width * 0.45, paint);
    
    // Dış yörünge
    canvas.drawCircle(Offset(cx, cy), size.width * 0.55, paint);

    // Yörüngeler üzerindeki minik noktalar
    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFC8102E); // Kırmızı nokta
    
    // Dış yörüngede kırmızı nokta (sağ taraf)
    canvas.drawCircle(Offset(cx + size.width * 0.55, cy), 2.5, dotPaint);
    
    // Orta yörüngede altın nokta (sağ alt)
    dotPaint.color = const Color(0xFFD4AF37);
    canvas.drawCircle(
      Offset(
        cx + size.width * 0.45 * cos(pi / 4),
        cy + size.width * 0.45 * sin(pi / 4),
      ),
      2.0,
      dotPaint,
    );

    // İç yörüngede kırmızı nokta (sol üst)
    dotPaint.color = const Color(0xFFC8102E);
    canvas.drawCircle(
      Offset(
        cx + size.width * 0.35 * cos(5 * pi / 4),
        cy + size.width * 0.35 * sin(5 * pi / 4),
      ),
      2.0,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Solid Kırmızı Kalkan
class _SolidShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC8102E) // Bayrak kırmızısı
      ..style = PaintingStyle.fill;
    
    // Gölge vermek için (hafif gradient gibi)
    paint.shader = const LinearGradient(
      colors: [Color(0xFFE30A17), Color(0xFFA00D22)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(size.width / 2, 0); // Üst orta
    path.lineTo(size.width, size.height * 0.15); // Sağ üst
    path.lineTo(size.width, size.height * 0.6); // Sağ orta
    
    // Alt eğri
    path.quadraticBezierTo(
      size.width / 2, size.height * 0.95,
      size.width / 2, size.height,
    );
    path.quadraticBezierTo(
      size.width / 2, size.height * 0.95,
      0, size.height * 0.6,
    );
    
    path.lineTo(0, size.height * 0.15); // Sol orta
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Dalgalanan Kırmızı Bayrak Kumaşı ve Hilal-Yıldız
class _WavingFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Kırmızı kumaş (gradient ile dalgalanma hissi)
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE30A17), Color(0xFFB30B17), Color(0xFFE30A17)],
        stops: [0.0, 0.5, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path = Path();
    path.moveTo(0, 0);
    // Üst kenar (dalgalı)
    path.quadraticBezierTo(w * 0.4, -h * 0.15, w, h * 0.1);
    // Sağ kenar
    path.lineTo(w, h * 0.9);
    // Alt kenar (dalgalı)
    path.quadraticBezierTo(w * 0.4, h * 0.75, 0, h * 0.9);
    path.close();

    // Gölge
    canvas.drawPath(
      path.shift(const Offset(2, 4)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Kumaşı çiz
    canvas.drawPath(path, paint);

    // Hilal ve Yıldız
    // Kumaşın şekline uyması için clip ve transform yapalım
    canvas.save();
    canvas.clipPath(path);
    // Hafif döndürerek bayrağın akışına uydur
    canvas.translate(w * 0.4, h * 0.45);
    canvas.rotate(-0.1);
    
    final elementPaint = Paint()..color = Colors.white;
    final r = h * 0.25;

    // Hilal
    canvas.saveLayer(Rect.fromCircle(center: Offset.zero, radius: r * 2), Paint());
    canvas.drawCircle(Offset(-r * 0.2, 0), r, elementPaint);
    canvas.drawCircle(
      Offset(r * 0.2, -r * 0.05),
      r * 0.8,
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();

    // Yıldız
    _drawStar(canvas, Offset(r * 0.8, 0), r * 0.35, elementPaint);
    
    canvas.restore();
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 144 - 90) * pi / 180;
      final point = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Standart Hilal Yıldız (Sade)
class _CrescentStarPainter extends CustomPainter {
  final Color color;
  _CrescentStarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.45;

    // Hilal
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawCircle(Offset(cx - r * 0.1, cy), r, paint);
    canvas.drawCircle(
      Offset(cx + r * 0.2, cy - r * 0.05),
      r * 0.8,
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();

    // Yıldız
    final path = Path();
    final starCenter = Offset(cx + r * 0.7, cy);
    final starRadius = r * 0.35;
    for (int i = 0; i < 5; i++) {
      final angle = (i * 144 - 90) * pi / 180;
      final point = Offset(
        starCenter.dx + starRadius * cos(angle),
        starCenter.dy + starRadius * sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Küçük Bayrak İçi Hilal Yıldız (Ülke seçici için)
class _FlagCrescentStarPainter extends CustomPainter {
  final Color color;
  _FlagCrescentStarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = size.width * 0.45;
    final cy = size.height * 0.5;
    final r = size.width * 0.35;

    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawCircle(Offset(cx - r * 0.1, cy), r, paint);
    canvas.drawCircle(
      Offset(cx + r * 0.2, cy - r * 0.05),
      r * 0.8,
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();

    // Yıldız
    final path = Path();
    final starCenter = Offset(cx + r * 0.8, cy);
    final starRadius = r * 0.3;
    for (int i = 0; i < 5; i++) {
      final angle = (i * 144 - 90) * pi / 180;
      final point = Offset(
        starCenter.dx + starRadius * cos(angle),
        starCenter.dy + starRadius * sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
    path.lineTo(w * 0.05, h * 0.2); // Kule
    path.lineTo(w * 0.08, h * 0.2); // Kule sağ
    path.lineTo(w * 0.08, h * 0.7); 
    // Halatlar
    path.moveTo(0, h * 0.5);
    path.quadraticBezierTo(w * 0.03, h * 0.6, w * 0.05, h * 0.2);
    path.moveTo(w * 0.08, h * 0.2);
    path.quadraticBezierTo(w * 0.15, h * 0.6, w * 0.25, h * 0.7);

    // Camiler ve Minareler
    // Cami 1
    path.moveTo(w * 0.35, h * 0.7);
    path.lineTo(w * 0.35, h * 0.4); // Minare sol
    path.moveTo(w * 0.38, h * 0.7);
    path.lineTo(w * 0.38, h * 0.55);
    path.quadraticBezierTo(w * 0.45, h * 0.4, w * 0.52, h * 0.55); // Kubbe
    path.lineTo(w * 0.52, h * 0.7);
    path.moveTo(w * 0.55, h * 0.7);
    path.lineTo(w * 0.55, h * 0.4); // Minare sağ
    
    // Cami 2 (Küçük)
    path.moveTo(w * 0.65, h * 0.7);
    path.lineTo(w * 0.65, h * 0.5); // Minare
    path.moveTo(w * 0.68, h * 0.7);
    path.quadraticBezierTo(w * 0.72, h * 0.55, w * 0.76, h * 0.7); // Kubbe

    // Galata kulesi (sembolik)
    path.moveTo(w * 0.85, h * 0.7);
    path.lineTo(w * 0.85, h * 0.4);
    path.lineTo(w * 0.83, h * 0.35); // Çatı
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
