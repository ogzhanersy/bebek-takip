import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/ad_service.dart';
import '../../shared/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class AdScreen extends StatefulWidget {
  const AdScreen({super.key});

  @override
  State<AdScreen> createState() => _AdScreenState();
}

class _AdScreenState extends State<AdScreen> {
  Timer? _countdownTimer;
  int _countdown = 5;
  bool _adLoaded = false;
  bool _adShown = false;
  bool _adDismissed = false;

  @override
  void initState() {
    super.initState();
    _loadAndShowAd();
  }

  Future<void> _loadAndShowAd() async {
    // Reklamları kontrol et
    if (!AdService.adsEnabled || AdService().isAdFree) {
      // Reklamlar devre dışıysa direkt geç
      _navigateToHome();
      return;
    }

    // Interstitial ad yükle
    await AdService().loadInterstitialAd();

    // Ad yüklenmesini bekle (maksimum 3 saniye)
    int attempts = 0;
    while (attempts < 30 && mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (AdService().isInterstitialAdLoaded) {
        if (mounted) {
          setState(() {
            _adLoaded = true;
          });
        }
        break;
      }
      attempts++;
    }

    // Ad yüklendiyse göster
    if (_adLoaded && mounted) {
      _showAd();
    } else {
      // Ad yüklenemediyse direkt geç
      _navigateToHome();
    }
  }

  void _showAd() {
    if (!AdService.adsEnabled || AdService().isAdFree || _adShown) return;

    try {
      // Interstitial ad'ı göster
      AdService().showInterstitialAd(
        onAdShowed: () {
          if (mounted) {
            setState(() {
              _adShown = true;
            });
            // Ad gösterildikten sonra 5 saniye geri sayım başlat
            _startCountdown();
          }
        },
        onAdDismissed: () {
          // Ad kapandığında ana ekrana geç
          _navigateToHome();
        },
      );
    } catch (e) {
      // Ad gösterilirken hata oluştu
      _navigateToHome();
    }
  }

  void _startCountdown() {
    // 5 saniye geri sayım başlat
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_adDismissed) {
        setState(() {
          _countdown--;
        });

        // Geri sayım bittiğinde ad'ı kapat (Interstitial ad otomatik kapanır)
        // Burada sadece UI güncellemesi yapıyoruz
        if (_countdown <= 0) {
          timer.cancel();
          // Ad zaten gösteriliyor, kullanıcı kapatabilir veya otomatik kapanır
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _navigateToHome() {
    if (!mounted) return;

    _countdownTimer?.cancel();

    // Kısa bir gecikme sonrası ana ekrana geç
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.go('/');
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        // Interstitial ad gösterildiğinde, ad tam ekran native view olarak gösterilir
        // Bu yüzden burada sadece loading ekranı gösteriyoruz
        // Ad gösterildikten sonra, ad'ın kendisi tam ekranı kaplar

        // Ad yüklenene kadar loading ekranı
        return Scaffold(
          backgroundColor: themeProvider.backgroundColor,
          body: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE1BEE7), Color(0xFFF8BBD9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.child_care,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Loading indicator
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
