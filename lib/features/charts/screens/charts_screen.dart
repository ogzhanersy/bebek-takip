import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/providers/baby_provider.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/bottom_navigation.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                        setState(() {
                          _selectedTimeRange = range;
                        });
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
                      Tab(icon: Icon(Icons.restaurant), text: 'Beslenme'),
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
          body: currentBaby == null
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
          bottomNavigationBar: const BottomNavigation(currentIndex: 2),
        );
      },
    );
  }
}
