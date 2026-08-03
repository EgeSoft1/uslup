// =============================================================================
// TurkiyeMesajlasma - Profil Oluşturma Ekranı (Mavi Vatan)
// Dosya: mobile/lib/presentation/auth/profile_creation_screen.dart
// =============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_shell.dart';

class ProfileCreationScreen extends StatefulWidget {
  const ProfileCreationScreen({super.key});

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController(text: 'Merhaba! Türkiye Mesajlaşma kullanıyorum.');
  bool _hasAvatar = false;

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  void _completeSetup() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lütfen adınızı girin.'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeShell()),
      (route) => false,
    );
  }

  void _pickAvatar() {
    setState(() => _hasAvatar = !_hasAvatar);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_hasAvatar ? 'Fotoğraf seçildi!' : 'Fotoğraf kaldırıldı.'),
        backgroundColor: _hasAvatar ? AppTheme.successGreen : AppTheme.surfaceLight,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profilini Oluştur',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 30),

              // --- Avatar Seçici ---
              GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _hasAvatar
                            ? const LinearGradient(
                                colors: [AppTheme.primaryRed, AppTheme.primaryRedDark],
                                begin: Alignment.topLeft, end: Alignment.bottomRight)
                            : null,
                        color: _hasAvatar ? null : AppTheme.surfaceLight,
                        border: Border.all(
                          color: _hasAvatar
                              ? AppTheme.primaryRed.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.1),
                          width: 3,
                        ),
                        boxShadow: _hasAvatar ? [
                          BoxShadow(color: AppTheme.primaryRed.withValues(alpha: 0.3), blurRadius: 25),
                        ] : [],
                      ),
                      child: Icon(
                        _hasAvatar ? Icons.person_rounded : Icons.camera_alt_rounded,
                        size: _hasAvatar ? 50 : 38,
                        color: _hasAvatar ? Colors.white : AppTheme.textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
                    // Düzenle rozeti - kırmızı
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.backgroundDark, width: 3),
                        boxShadow: [
                          BoxShadow(color: AppTheme.primaryRed.withValues(alpha: 0.3), blurRadius: 8),
                        ],
                      ),
                      child: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                    ),
                  ],
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 12),
              Text('Profil Fotoğrafı Ekle',
                style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.6), fontSize: 13))
                .animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 40),

              // --- Glassmorphism Form Kartı ---
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceMid.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ad Soyad
                        const Text('Adınız',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                          ),
                          child: TextField(
                            controller: _nameController,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'Ad Soyad',
                              hintStyle: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.35)),
                              prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTheme.primaryRed, size: 22),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Hakkımda
                        const Text('Hakkımda',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                          ),
                          child: TextField(
                            controller: _aboutController,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                            maxLines: 3,
                            maxLength: 140,
                            decoration: InputDecoration(
                              hintText: 'Kendiniz hakkında birşeyler yazın...',
                              hintStyle: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.35)),
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(bottom: 40),
                                child: Icon(Icons.info_outline_rounded, color: AppTheme.primaryRed, size: 22),
                              ),
                              counterStyle: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 350.ms, duration: 500.ms)
                .slideY(begin: 0.08, end: 0, delay: 350.ms, duration: 500.ms),

              const SizedBox(height: 36),

              // --- Cihaz Üstü İşleme Bilgi Kartı ---
              // Önceden "Uçtan Uca Şifreleme Aktif" yazıyordu; E2EE bu
              // prototipte YOK (bkz. docs/02_TEKNIK_BORC.md §1). Kart artık
              // kanıtlanabilir olanı söylüyor: nezaket motoru cihazda çalışır.
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.12)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.verified_user_rounded, color: AppTheme.primaryRed.withValues(alpha: 0.8), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Nezaket Motoru Cihazında Çalışır',
                            style: TextStyle(color: AppTheme.primaryRed, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('Yazdığın metin çözümlenirken telefondan çıkmaz.',
                            style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.5), fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 550.ms, duration: 500.ms),

              const SizedBox(height: 36),

              // --- Tamamla Butonu ---
              SizedBox(
                width: double.infinity, height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppTheme.primaryRed, AppTheme.primaryRedDark]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: AppTheme.primaryRed.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _completeSetup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 22),
                        SizedBox(width: 10),
                        Text('Kayıt Ol ve Başla',
                          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 700.ms, duration: 500.ms),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
