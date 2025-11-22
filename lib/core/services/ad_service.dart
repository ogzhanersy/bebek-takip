import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Reklamlar aktif
  static const bool _adsEnabled = true;

  // Production Ad Unit IDs
  static String get _bannerAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-6831342609343630/6178076325' // Production Banner Android
      : 'ca-app-pub-3940256099942544/2934735716'; // Test Banner iOS (henüz oluşturulmadı)

  static String get _interstitialAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-6831342609343630/9704126478' // Production Interstitial Android
      : 'ca-app-pub-3940256099942544/4411468910'; // Test Interstitial iOS

  static String get _rewardedAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917' // Test Rewarded Android
      : 'ca-app-pub-3940256099942544/1712485313'; // Test Rewarded iOS

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _isInitialized = false;
  bool _isAdFree = false;

  // AdMob'u başlat
  static Future<void> initialize() async {
    if (!_adsEnabled) {
      return;
    }
    await MobileAds.instance.initialize();
    await AdService()._loadUserPreferences();
    AdService()._isInitialized = true;
  }

  // Kullanıcı tercihlerini yükle
  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isAdFree = prefs.getBool('is_ad_free') ?? false;
  }

  // Banner reklam oluştur
  BannerAd createBannerAd() {
    if (!_adsEnabled) {
      throw Exception('Reklamlar devre dışı');
    }
    return BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          // Ad loaded successfully
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
        },
        onAdOpened: (ad) {
          // Ad opened
        },
        onAdClosed: (ad) {
          // Ad closed
        },
      ),
    );
  }

  // Interstitial reklam yükle
  Future<void> loadInterstitialAd() async {
    if (!_adsEnabled || _isAdFree) return;

    await InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  // Interstitial ad yüklendi mi?
  bool get isInterstitialAdLoaded => _interstitialAd != null;

  // Interstitial reklam göster
  Future<void> showInterstitialAd({
    VoidCallback? onAdDismissed,
    VoidCallback? onAdShowed,
  }) async {
    if (!_adsEnabled || _isAdFree || _interstitialAd == null) {
      onAdDismissed?.call();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        onAdShowed?.call();
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        // Yeni interstitial reklam yükle
        loadInterstitialAd();
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Interstitial ad failed to show: $error');
        ad.dispose();
        _interstitialAd = null;
        onAdDismissed?.call();
      },
    );

    await _interstitialAd!.show();
  }

  // Rewarded reklam yükle
  Future<void> loadRewardedAd() async {
    if (!_adsEnabled || _isAdFree) return;

    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  // Rewarded reklam göster
  Future<bool> showRewardedAd() async {
    if (!_adsEnabled || _isAdFree || _rewardedAd == null) return false;

    bool rewardEarned = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        // Ad showed
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        // Yeni rewarded reklam yükle
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded ad failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        rewardEarned = true;
      },
    );

    return rewardEarned;
  }

  // Reklamları temizle
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }

  // Reklamsız deneyim aktif mi?
  bool get isAdFree => _isAdFree;

  // Reklam servisi hazır mı?
  bool get isInitialized => _isInitialized;

  // Reklamlar aktif mi?
  static bool get adsEnabled => _adsEnabled;

  // Reklamsız deneyimi aktif et
  Future<void> enableAdFree() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_ad_free', true);
    _isAdFree = true;

    // Mevcut reklamları temizle
    dispose();
  }

  // Reklamsız deneyimi kapat
  Future<void> disableAdFree() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_ad_free', false);
    _isAdFree = false;

    // Reklamları yeniden yükle
    loadInterstitialAd();
    loadRewardedAd();
  }
}

// Banner reklam widget'ı
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    // Reklamlar devre dışı bırakıldı
    if (!AdService.adsEnabled || AdService().isAdFree) return;

    try {
      _bannerAd = AdService().createBannerAd();
    } catch (e) {
      // Reklamlar devre dışıysa sessizce geç
      return;
    }
    _bannerAd!.load().then((_) {
      if (mounted) {
        setState(() {
          _isAdLoaded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reklamlar devre dışı bırakıldı - her zaman boş widget döndür
    if (!AdService.adsEnabled ||
        AdService().isAdFree ||
        !_isAdLoaded ||
        _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
