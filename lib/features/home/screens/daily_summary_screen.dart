import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/providers/baby_provider.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/models/sleep_model.dart';
import '../../../shared/models/feeding_model.dart';
import '../../../shared/models/diaper_model.dart';
import '../../../core/services/sleep_service.dart';
import '../../../core/services/feeding_service.dart';
import '../../../core/services/diaper_service.dart';
import '../../../core/services/ad_service.dart';
import '../widgets/sleep_records_bottom_sheet.dart';
import '../widgets/feeding_records_bottom_sheet.dart';
import '../widgets/diaper_records_bottom_sheet.dart';

class DailySummaryScreen extends StatefulWidget {
  const DailySummaryScreen({super.key});

  @override
  State<DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends State<DailySummaryScreen> {
  List<Sleep> _allSleeps = [];
  List<Feeding> _allFeedings = [];
  List<Diaper> _allDiapers = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final babyProvider = context.read<BabyProvider>();
    final currentBaby = babyProvider.selectedBaby;

    if (currentBaby == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      setState(() => _isLoading = true);

      final sleepResults = await SleepService.getSleepRecords(currentBaby.id);

      final feedingResults = await FeedingService.getFeedingRecords(
        currentBaby.id,
      );
      final diaperResults = await DiaperService.getDiapers(currentBaby.id);

      setState(() {
        _allSleeps = sleepResults;
        _allFeedings = feedingResults;
        _allDiapers = diaperResults;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veriler yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Tekrar Dene',
              textColor: Colors.white,
              onPressed: _loadAllData,
            ),
          ),
        );
      }
    }
  }

  List<Sleep> _getSleepsForDate(DateTime date) {
    // date is already in local timezone
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final filteredSleeps = _allSleeps.where((sleep) {
      // sleep.startTime is already in local timezone from fromJson()
      return sleep.startTime.isAfter(
            dayStart.subtract(const Duration(milliseconds: 1)),
          ) &&
          sleep.startTime.isBefore(dayEnd);
    }).toList();

    return filteredSleeps;
  }

  List<Feeding> _getFeedingsForDate(DateTime date) {
    // date is already in local timezone
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final filteredFeedings = _allFeedings.where((feeding) {
      // feeding.startTime is already in local timezone from fromJson()
      return feeding.startTime.isAfter(
            dayStart.subtract(const Duration(milliseconds: 1)),
          ) &&
          feeding.startTime.isBefore(dayEnd);
    }).toList();

    return filteredFeedings;
  }

  List<Diaper> _getDiapersForDate(DateTime date) {
    // date is already in local timezone
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final filteredDiapers = _allDiapers.where((diaper) {
      // diaper.time is already in local timezone from fromJson()
      return diaper.time.isAfter(
            dayStart.subtract(const Duration(milliseconds: 1)),
          ) &&
          diaper.time.isBefore(dayEnd);
    }).toList();

    return filteredDiapers;
  }

  String _calculateTotalSleepDuration(List<Sleep> sleeps) {
    if (sleeps.isEmpty) return '0s 0dk';

    int totalMinutes = 0;
    for (final sleep in sleeps) {
      if (sleep.endTime != null) {
        totalMinutes += sleep.endTime!.difference(sleep.startTime).inMinutes;
      }
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours}s ${minutes}dk';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final selectedDate = DateTime(date.year, date.month, date.day);

    if (selectedDate.isAtSameMomentAs(today)) {
      return 'Bugün';
    } else if (selectedDate.isAtSameMomentAs(yesterday)) {
      return 'Dün';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  bool _isAtMaxDate() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final selectedDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    return selectedDate.isAtSameMomentAs(todayDate);
  }

  bool _isAtMinDate() {
    final babyProvider = context.read<BabyProvider>();
    final currentBaby = babyProvider.selectedBaby;

    if (currentBaby == null) return false;

    final birthDate = DateTime(
      currentBaby.birthDate.year,
      currentBaby.birthDate.month,
      currentBaby.birthDate.day,
    );
    final selectedDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    return selectedDate.isAtSameMomentAs(birthDate);
  }

  void _showSleepRecords() {
    final sleeps = _getSleepsForDate(_selectedDate);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          SleepRecordsBottomSheet(sleeps: sleeps, selectedDate: _selectedDate),
    ).then((shouldRefresh) {
      if (shouldRefresh == true) {
        _loadAllData();
      }
    });
  }

  void _showFeedingRecords() {
    final feedings = _getFeedingsForDate(_selectedDate);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FeedingRecordsBottomSheet(
        feedings: feedings,
        selectedDate: _selectedDate,
      ),
    ).then((shouldRefresh) {
      if (shouldRefresh == true) {
        _loadAllData();
      }
    });
  }

  void _showDiaperRecords() {
    final diapers = _getDiapersForDate(_selectedDate);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DiaperRecordsBottomSheet(
        diapers: diapers,
        selectedDate: _selectedDate,
      ),
    ).then((shouldRefresh) {
      if (shouldRefresh == true) {
        _loadAllData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;

            // Daily summary ekranında geri tuşuna basıldığında ana sayfaya git
            context.go('/');
          },
          child: Scaffold(
            appBar: AppBar(
              title: Consumer<BabyProvider>(
                builder: (context, babyProvider, _) {
                  final currentBaby = babyProvider.selectedBaby;
                  return Text(
                    currentBaby != null
                        ? '${currentBaby.name} - Günlük Özet'
                        : 'Günlük Özet',
                  );
                },
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: themeProvider.cardForeground,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/'),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime.now();
                    });
                  },
                  tooltip: 'Bugün',
                ),
              ],
            ),
            body: Container(
              decoration: BoxDecoration(
                gradient: themeProvider.homeBackgroundGradient,
              ),
              child: SafeArea(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          // Date Selector
                          Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: themeProvider.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    // Don't allow going before birth date
                                    if (!_isAtMinDate()) {
                                      setState(() {
                                        _selectedDate = _selectedDate.subtract(
                                          const Duration(days: 1),
                                        );
                                      });
                                    }
                                  },
                                  icon: Icon(
                                    Icons.chevron_left,
                                    color: _isAtMinDate()
                                        ? Colors.grey
                                        : themeProvider.cardForeground,
                                  ),
                                ),
                                Text(
                                  _formatDate(_selectedDate),
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: themeProvider.cardForeground,
                                      ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    // Don't allow going beyond today
                                    if (!_isAtMaxDate()) {
                                      setState(() {
                                        _selectedDate = _selectedDate.add(
                                          const Duration(days: 1),
                                        );
                                      });
                                    }
                                  },
                                  icon: Icon(
                                    Icons.chevron_right,
                                    color: _isAtMaxDate()
                                        ? Colors.grey
                                        : themeProvider.cardForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Summary Cards
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              children: [
                                // Sleep Summary
                                GestureDetector(
                                  onTap: _showSleepRecords,
                                  child: CustomCard(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.bedtime_outlined,
                                              color: AppColors.primary,
                                              size: 24,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Uyku',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        _buildSummaryRow(
                                          'Toplam Süre',
                                          _calculateTotalSleepDuration(
                                            _getSleepsForDate(_selectedDate),
                                          ),
                                        ),
                                        _buildSummaryRow(
                                          'Kayıt Sayısı',
                                          '${_getSleepsForDate(_selectedDate).length} kez',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Feeding Summary
                                GestureDetector(
                                  onTap: _showFeedingRecords,
                                  child: CustomCard(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '🍼',
                                              style: TextStyle(fontSize: 24),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Beslenme',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        _buildSummaryRow(
                                          'Toplam Kayıt',
                                          '${_getFeedingsForDate(_selectedDate).length} kez',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Diaper Summary
                                GestureDetector(
                                  onTap: _showDiaperRecords,
                                  child: CustomCard(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.child_care_outlined,
                                              color: AppColors.babyGreen,
                                              size: 24,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Alt Değişimi',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        _buildSummaryRow(
                                          'Kayıt Sayısı',
                                          '${_getDiapersForDate(_selectedDate).length} kez',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 32),
                              ],
                            ),
                          ),

                          // Banner Ad at the bottom
                          Container(
                            width: double.infinity,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: const BannerAdWidget(),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
