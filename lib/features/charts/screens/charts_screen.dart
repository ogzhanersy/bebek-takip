import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/providers/baby_provider.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/bottom_navigation.dart';
import '../../../core/services/ad_service.dart';
import '../widgets/development_chart_tab.dart';
import '../widgets/feeding_chart_tab.dart';
import '../widgets/sleep_chart_tab.dart';
import '../widgets/overview_chart_tab.dart';
import '../widgets/time_range_selector.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TimeRange _selectedTimeRange = TimeRange.daily;
  int _weeklyClickCount = 0;
  int _monthlyClickCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadClickCounters();
  }

  Future<void> _loadClickCounters() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _weeklyClickCount = prefs.getInt('charts_weekly_click_count') ?? 0;
      _monthlyClickCount = prefs.getInt('charts_monthly_click_count') ?? 0;
    });
  }

  Future<void> _saveClickCounter(TimeRange range, int count) async {
    final prefs = await SharedPreferences.getInstance();
    if (range == TimeRange.weekly) {
      await prefs.setInt('charts_weekly_click_count', count);
    } else if (range == TimeRange.monthly) {
      await prefs.setInt('charts_monthly_click_count', count);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleTimeRangeChange(TimeRange range) async {
    // Günlük seçeneğine tıklandığında reklam gösterme
    if (range == TimeRange.daily) {
      setState(() {
        _selectedTimeRange = range;
      });
      return;
    }

    // Haftalık veya aylık seçildiğinde sayaç kontrolü yap
    if (range == TimeRange.weekly || range == TimeRange.monthly) {
      // İlgili seçenek için sayaç değerini al
      int clickCount = range == TimeRange.weekly
          ? _weeklyClickCount
          : _monthlyClickCount;

      // Sayaç artır (1, 2, 3, 4...)
      clickCount++;

      // Her 3 tıklamada bir reklam göster (1, 4, 7, 10...)
      // Yani: 1. tıklamada reklam, 2-3. tıklamada yok, 4. tıklamada tekrar reklam
      bool shouldShowAd = (clickCount % 3 == 1);

      // Sayaç değerini kaydet
      await _saveClickCounter(range, clickCount);

      // State'i güncelle
      if (mounted) {
        setState(() {
          if (range == TimeRange.weekly) {
            _weeklyClickCount = clickCount;
          } else {
            _monthlyClickCount = clickCount;
          }
        });
      }

      // Reklam gösterilmeyecekse direkt geç
      if (!shouldShowAd) {
        if (mounted) {
          setState(() {
            _selectedTimeRange = range;
          });
        }
        return;
      }

      // Reklamları kontrol et
      if (!AdService.adsEnabled || AdService().isAdFree) {
        // Reklamlar devre dışıysa direkt geç
        if (mounted) {
          setState(() {
            _selectedTimeRange = range;
          });
        }
        return;
      }

      // Interstitial ad yükle
      await AdService().loadInterstitialAd();

      // Ad yüklenmesini bekle (maksimum 2 saniye)
      int attempts = 0;
      bool adLoaded = false;
      while (attempts < 20 && !adLoaded) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (AdService().isInterstitialAdLoaded) {
          adLoaded = true;
          break;
        }
        attempts++;
      }

      // Ad yüklendiyse göster, sonra timeRange'i güncelle
      if (adLoaded) {
        AdService().showInterstitialAd(
          onAdShowed: () {
            // Ad gösterildi
          },
          onAdDismissed: () {
            // Ad kapandığında timeRange'i güncelle
            if (mounted) {
              setState(() {
                _selectedTimeRange = range;
              });
            }
          },
        );
      } else {
        // Ad yüklenemediyse direkt geç
        if (mounted) {
          setState(() {
            _selectedTimeRange = range;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<BabyProvider, ThemeProvider>(
      builder: (context, babyProvider, themeProvider, _) {
        final currentBaby = babyProvider.selectedBaby;

        return Scaffold(
          backgroundColor: themeProvider.backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Grafikler & Analiz',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(110),
              child: Column(
                children: [
                  // Time Range Selector
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TimeRangeSelector(
                      selectedRange: _selectedTimeRange,
                      onRangeChanged: (range) {
                        _handleTimeRangeChange(range);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Tab Bar
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(icon: Icon(Icons.dashboard), text: 'Genel'),
                      Tab(icon: Icon(Icons.bedtime), text: 'Uyku'),
                      Tab(
                        icon: Text('🍼', style: TextStyle(fontSize: 20)),
                        text: 'Beslenme',
                      ),
                      Tab(icon: Icon(Icons.trending_up), text: 'Gelişim'),
                    ],
                    labelColor: themeProvider.primaryColor,
                    unselectedLabelColor: themeProvider.mutedForegroundColor,
                    indicatorColor: themeProvider.primaryColor,
                  ),
                ],
              ),
            ),
          ),
          body: SafeArea(
            child: currentBaby == null
                ? Center(
                    child: CustomCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.child_care_outlined,
                            size: 64,
                            color: themeProvider.mutedForegroundColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Grafikleri görmek için bir bebek seçin',
                            style: TextStyle(
                              fontSize: 16,
                              color: themeProvider.mutedForegroundColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      OverviewChartTab(
                        babyId: currentBaby.id,
                        timeRange: _selectedTimeRange,
                      ),
                      SleepChartTab(
                        babyId: currentBaby.id,
                        timeRange: _selectedTimeRange,
                      ),
                      FeedingChartTab(
                        babyId: currentBaby.id,
                        timeRange: _selectedTimeRange,
                      ),
                      DevelopmentChartTab(
                        babyId: currentBaby.id,
                        timeRange: _selectedTimeRange,
                      ),
                    ],
                  ),
          ),
          bottomNavigationBar: const BottomNavigation(currentIndex: 2),
        );
      },
    );
  }
}
