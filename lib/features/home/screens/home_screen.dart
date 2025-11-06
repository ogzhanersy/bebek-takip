import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
// import 'package:haptic_feedback/haptic_feedback.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/providers/baby_provider.dart';
import '../../../shared/providers/tracking_provider.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/widgets/bottom_navigation.dart';
import '../../../shared/widgets/baby_selector_sheet.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/sleep_tracking_sheet.dart';
import '../../../shared/widgets/feeding_tracking_sheet.dart';
import '../../../shared/widgets/diaper_tracking_sheet.dart';
import '../../../shared/widgets/development_tracking_sheet.dart';
import '../../../shared/widgets/no_baby_warning.dart';
import '../../../shared/widgets/notification_display_widget.dart';
import '../../../core/services/sleep_service.dart';
import '../../../core/services/feeding_service.dart';
import '../../../core/services/diaper_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/services/ad_service.dart';
import '../../../shared/models/sleep_model.dart';
import '../../../shared/models/feeding_model.dart';
import '../../../shared/models/diaper_model.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/summary_item.dart';
import '../widgets/activity_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Today's data
  List<Sleep> _todaySleeps = [];
  List<Feeding> _todayFeedings = [];
  List<Diaper> _todayDiapers = [];
  bool _isLoadingSummary = true;
  Timer? _relativeTimeTicker;

  @override
  void initState() {
    super.initState();
    // Don't load data immediately - wait for BabyProvider to be ready
    // Periodically rebuild to update relative time labels
    _relativeTimeTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Data loading is now handled in Consumer
  }

  Future<void> _loadTodayData() async {
    // When offline: try displaying cached data
    if (!(await SyncService.isOnline())) {
      final babyProvider = context.read<BabyProvider>();
      final currentBaby = babyProvider.selectedBaby;
      if (currentBaby != null) {
        final now = DateTime.now();
        final cache = await CacheService.loadTodayData(
          babyId: currentBaby.id,
          date: now,
        );
        if (cache != null) {
          final sleeps = (cache['sleeps'] as List?) ?? [];
          final feedings = (cache['feedings'] as List?) ?? [];
          final diapers = (cache['diapers'] as List?) ?? [];
          setState(() {
            _todaySleeps = sleeps
                .map((e) => Sleep.fromJson(Map<String, dynamic>.from(e)))
                .toList();
            _todayFeedings = feedings
                .map((e) => Feeding.fromJson(Map<String, dynamic>.from(e)))
                .toList();
            _todayDiapers = diapers
                .map((e) => Diaper.fromJson(Map<String, dynamic>.from(e)))
                .toList();
            _isLoadingSummary = false;
          });
          return;
        }
      }
      if (mounted) setState(() => _isLoadingSummary = false);
      return;
    }
    final babyProvider = context.read<BabyProvider>();
    final currentBaby = babyProvider.selectedBaby;

    if (currentBaby == null) {
      setState(() => _isLoadingSummary = false);
      return;
    }

    try {
      // Get current device date (user's phone date)
      final now = DateTime.now();
      final deviceDate = DateTime(now.year, now.month, now.day);

      // Load all data first, then filter by device date

      // Load all data first, then filter by device date
      final results = await Future.wait([
        SleepService.getSleepRecords(currentBaby.id),
        FeedingService.getFeedingRecords(currentBaby.id),
        DiaperService.getDiapers(currentBaby.id),
      ]);

      setState(() {
        // Filter sleep records by device date (00:00-23:59)
        _todaySleeps = (results[0] as List<Sleep>).where((sleep) {
          final sleepDate = DateTime(
            sleep.startTime.year,
            sleep.startTime.month,
            sleep.startTime.day,
          );
          return sleepDate.isAtSameMomentAs(deviceDate);
        }).toList();

        // Filter feeding records by device date (00:00-23:59)
        _todayFeedings = (results[1] as List<Feeding>).where((feeding) {
          final feedingDate = DateTime(
            feeding.startTime.year,
            feeding.startTime.month,
            feeding.startTime.day,
          );
          return feedingDate.isAtSameMomentAs(deviceDate);
        }).toList();

        // Filter diaper records by device date (00:00-23:59)
        _todayDiapers = (results[2] as List<Diaper>).where((diaper) {
          final diaperDate = DateTime(
            diaper.time.year,
            diaper.time.month,
            diaper.time.day,
          );
          return diaperDate.isAtSameMomentAs(deviceDate);
        }).toList();

        _isLoadingSummary = false;
      });

      // Save cache for offline read
      await CacheService.saveTodayData(
        babyId: currentBaby.id,
        date: DateTime.now(),
        sleeps: _todaySleeps.map((e) => e.toJson()).toList(),
        feedings: _todayFeedings.map((e) => e.toJson()).toList(),
        diapers: _todayDiapers.map((e) => e.toJson()).toList(),
      );
    } catch (e) {
      debugPrint('Error loading today data: $e');
      setState(() => _isLoadingSummary = false);
    }
  }

  @override
  void dispose() {
    _relativeTimeTicker?.cancel();
    super.dispose();
  }

  String _getSummaryTitle() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));

    // Check if it's today, yesterday, or tomorrow
    if (now.day == today.day &&
        now.month == today.month &&
        now.year == today.year) {
      return 'Bugünün Özeti';
    } else if (now.day == yesterday.day &&
        now.month == yesterday.month &&
        now.year == yesterday.year) {
      return 'Dünün Özeti';
    } else if (now.day == tomorrow.day &&
        now.month == tomorrow.month &&
        now.year == tomorrow.year) {
      return 'Yarının Özeti';
    } else {
      // Format the date for display
      final months = [
        'Ocak',
        'Şubat',
        'Mart',
        'Nisan',
        'Mayıs',
        'Haziran',
        'Temmuz',
        'Ağustos',
        'Eylül',
        'Ekim',
        'Kasım',
        'Aralık',
      ];
      return '${now.day} ${months[now.month - 1]} ${now.year} Özeti';
    }
  }

  String _formatTrackingTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _calculateTotalSleepDuration() {
    if (_todaySleeps.isEmpty) return '0s 0dk';

    int totalMinutes = 0;
    for (final sleep in _todaySleeps) {
      if (sleep.endTime != null) {
        totalMinutes += sleep.endTime!.difference(sleep.startTime).inMinutes;
      }
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours}s ${minutes}dk';
  }

  List<Map<String, dynamic>> _getRecentActivities() {
    final activities = <Map<String, dynamic>>[];

    // Add sleep activities
    for (final sleep in _todaySleeps) {
      if (sleep.endTime != null) {
        activities.add({
          'type': 'sleep',
          'title': 'Uyku bitti',
          'time': sleep.endTime!.toLocal(),
          'icon': Icons.bedtime_outlined,
          'iconColor': AppColors.primary,
        });
      }
    }

    // Add feeding activities
    for (final feeding in _todayFeedings) {
      activities.add({
        'type': 'feeding',
        'title': 'Beslenme',
        'time': feeding.startTime.toLocal(),
        'icon': Icons.restaurant_outlined,
        'iconColor': AppColors.babyPink,
      });
    }

    // Add diaper activities
    for (final diaper in _todayDiapers) {
      activities.add({
        'type': 'diaper',
        'title': 'Alt değişimi',
        'time': diaper.time.toLocal(),
        'icon': Icons.child_care_outlined,
        'iconColor': AppColors.babyGreen,
      });
    }

    // Sort by time (most recent first) and take last 3
    activities.sort(
      (a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime),
    );
    return activities.take(3).toList();
  }

  String _formatTime(DateTime dateTime) {
    final localTime = dateTime.toLocal();
    final now = DateTime.now();
    Duration difference = now.difference(localTime);
    if (difference.isNegative) {
      difference = Duration.zero;
    }

    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  // Kullanıcı avatar resmini düzeltilmiş URL ile al
  NetworkImage? _getUserAvatarImage() {
    final avatarUrl = SupabaseService.currentUser?.userMetadata?['avatar_url'];
    if (avatarUrl != null) {
      final fixedUrl = _fixAvatarUrl(avatarUrl);
      return NetworkImage(fixedUrl);
    }
    return null;
  }

  // Eski URL formatını yeni formata çevir
  String _fixAvatarUrl(String url) {
    // Eski format: .../avatars/user_id/profile/filename
    // Yeni format: .../avatars/profile/filename

    if (url.contains('/avatars/') && url.contains('/profile/')) {
      // URL'yi parçalara ayır
      final parts = url.split('/avatars/');
      if (parts.length == 2) {
        final afterAvatars = parts[1];
        final pathParts = afterAvatars.split('/');

        // Eğer user_id/profile/filename formatındaysa
        if (pathParts.length >= 3 && pathParts[1] == 'profile') {
          // user_id kısmını atla, sadece profile/filename al
          final newPath = 'profile/${pathParts.sublist(2).join('/')}';
          final newUrl = '${parts[0]}/avatars/$newPath';
          return newUrl;
        }
      }
    }

    return url; // Değişiklik gerekmiyorsa aynen döndür
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            // Ana sayfada geri tuşuna basıldığında uygulamayı kapatma
            // Bunun yerine uygulamayı minimize et veya ana sayfada kal
          },
          child: Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: themeProvider.homeBackgroundGradient,
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Header - Transparent
                    Consumer<BabyProvider>(
                      builder: (context, babyProvider, _) {
                        final currentBaby = babyProvider.selectedBaby;
                        return Container(
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // User Profile Avatar
                              GestureDetector(
                                onTap: () {
                                  context.go('/profile/edit');
                                },
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: themeProvider.primaryColor
                                      .withValues(alpha: 0.1),
                                  backgroundImage: _getUserAvatarImage(),
                                  child: _getUserAvatarImage() == null
                                      ? Icon(
                                          Icons.person,
                                          color: themeProvider.primaryColor,
                                          size: 24,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Merhaba Anne!',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: themeProvider.cardForeground,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: () => _showBabySelector(context),
                                      child: Row(
                                        children: [
                                          Text(
                                            currentBaby != null
                                                ? 'Bebek ${currentBaby.name}'
                                                : 'Bebek seçin',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: themeProvider
                                                      .mutedForegroundColor,
                                                ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.keyboard_arrow_down,
                                            color: themeProvider
                                                .mutedForegroundColor,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.notifications_outlined,
                                  color: themeProvider.cardForeground,
                                ),
                                onPressed: () {
                                  // Haptics.vibrate(HapticsType.light);
                                  _showNotificationSheet(context);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Main Content - Check if baby exists
                    Consumer<BabyProvider>(
                      builder: (context, babyProvider, _) {
                        // Load data when BabyProvider finishes loading
                        if (!babyProvider.isLoading && _isLoadingSummary) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _loadTodayData();
                          });
                        }

                        // Show loading state while babies are being loaded
                        if (babyProvider.isLoading) {
                          return Expanded(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Bebekler yükleniyor...',
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: AppColors.mutedForeground,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // If no babies exist, show only warning
                        if (babyProvider.babies.isEmpty) {
                          return Expanded(
                            child: Center(
                              child: SingleChildScrollView(
                                child: NoBabyWarning(
                                  title: 'Henüz Kayıtlı Bebek Yok',
                                  message:
                                      'Bebek takibine başlamak için önce bir bebek eklemeniz gerekiyor.',
                                  buttonText: 'Bebek Ekle',
                                  onPressed: () => context.go('/add-baby'),
                                ),
                              ),
                            ),
                          );
                        }

                        // If babies exist but none selected, show warning
                        if (babyProvider.selectedBaby == null) {
                          return Expanded(
                            child: Center(
                              child: SingleChildScrollView(
                                child: NoBabyWarning(
                                  title: 'Bebek Seçin',
                                  message:
                                      'Takip yapmak için bir bebek seçmeniz gerekiyor.',
                                  buttonText: 'Bebek Seç',
                                  onPressed: () => _showBabySelector(context),
                                ),
                              ),
                            ),
                          );
                        }

                        // If baby exists and selected, show all content
                        return Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Active Tracking Card
                                Consumer<TrackingProvider>(
                                  builder: (context, trackingProvider, _) {
                                    final currentBaby =
                                        babyProvider.selectedBaby;
                                    final isTracking = currentBaby != null
                                        ? trackingProvider.isBabyTracking(
                                            currentBaby.id,
                                          )
                                        : false;

                                    if (!isTracking) {
                                      return const SizedBox.shrink();
                                    }

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      child: CustomCard(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFE3F2FD),
                                            Color(0xFFF3E5F5),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 48,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                ),
                                                child: const Icon(
                                                  Icons.bedtime_outlined,
                                                  color: AppColors.primary,
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Uyku Takibi',
                                                      style: Theme.of(
                                                        context,
                                                      ).textTheme.titleLarge,
                                                    ),
                                                    Text(
                                                      _formatTrackingTime(
                                                        trackingProvider
                                                            .getBabySeconds(
                                                              currentBaby.id,
                                                            ),
                                                      ),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .headlineMedium
                                                          ?.copyWith(
                                                            color: AppColors
                                                                .primary,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              CustomButton(
                                                text: 'Durdur',
                                                onPressed: () {
                                                  // Haptics.vibrate(HapticsType.medium);
                                                  trackingProvider
                                                      .stopSleepTracking();
                                                },
                                                variant: ButtonVariant.outline,
                                                icon: Icons.pause,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                // Quick Actions Section
                                Text(
                                  'Hızlı İşlemler',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 16),

                                GridView.count(
                                  crossAxisCount: 2,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 1.2,
                                  children: [
                                    QuickActionCard(
                                      title: 'Uyku',
                                      subtitle: 'Başlat',
                                      iconPath: 'assets/images/sleep-icon.jpg',
                                      gradient: AppColors.babyBlueGradient,
                                      onTap: () =>
                                          _showTrackingSheet(context, 'sleep'),
                                    ),
                                    QuickActionCard(
                                      title: 'Beslenme',
                                      subtitle: 'Kaydet',
                                      iconPath:
                                          'assets/images/feeding-icon.jpg',
                                      gradient: AppColors.babyPinkGradient,
                                      onTap: () => _showTrackingSheet(
                                        context,
                                        'feeding',
                                      ),
                                    ),
                                    QuickActionCard(
                                      title: 'Alt Değişimi',
                                      subtitle: 'Kaydet',
                                      iconPath: 'assets/images/diaper-icon.jpg',
                                      gradient: AppColors.babyGreenGradient,
                                      onTap: () =>
                                          _showTrackingSheet(context, 'diaper'),
                                    ),
                                    QuickActionCard(
                                      title: 'Ölçümler',
                                      subtitle: 'Kilo, boy, baş çevresi',
                                      icon: Icons.straighten_outlined,
                                      gradient: AppColors.babyPurpleGradient,
                                      onTap: () =>
                                          _showDevelopmentSheet(context),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 32),

                                // Banner Ad
                                const Center(child: BannerAdWidget()),
                                const SizedBox(height: 24),

                                // Today's Summary Section - Header Outside Card
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _getSummaryTitle(),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineSmall,
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        context.go('/daily-summary');
                                      },
                                      child: Text(
                                        'Tümünü Gör',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Summary Cards in Single Row
                                CustomCard(
                                  padding: const EdgeInsets.all(20),
                                  child: _isLoadingSummary
                                      ? const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(20),
                                            child: CircularProgressIndicator(),
                                          ),
                                        )
                                      : Row(
                                          children: [
                                            Expanded(
                                              child: SummaryItem(
                                                label: 'Uyku',
                                                value:
                                                    _calculateTotalSleepDuration(),
                                                icon: Icons.bedtime_outlined,
                                                iconColor: AppColors.primary,
                                                subtext: 'Bugün',
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: SummaryItem(
                                                label: 'Beslenme',
                                                value:
                                                    '${_todayFeedings.length} kez',
                                                icon: Icons.restaurant_outlined,
                                                iconColor: AppColors.babyPink,
                                                subtext: 'Bugün',
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: SummaryItem(
                                                label: 'Alt Değişimi',
                                                value:
                                                    '${_todayDiapers.length} kez',
                                                icon: Icons.child_care_outlined,
                                                iconColor: AppColors.babyGreen,
                                                subtext: 'Bugün',
                                              ),
                                            ),
                                          ],
                                        ),
                                ),

                                const SizedBox(height: 32),

                                // Recent Activities
                                Text(
                                  'Son Aktiviteler',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 16),

                                // Activity List
                                _isLoadingSummary
                                    ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(20),
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                    : _getRecentActivities().isEmpty
                                    ? Column(
                                        children: [
                                          CustomCard(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 20,
                                            ),
                                            child: Column(
                                              children: [
                                                Icon(
                                                  Icons.history_outlined,
                                                  size: 48,
                                                  color:
                                                      AppColors.mutedForeground,
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  'Henüz aktivite yok',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        color: AppColors
                                                            .mutedForeground,
                                                      ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Bugün yapılan aktiviteler burada görünecek',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color: AppColors
                                                            .mutedForeground,
                                                      ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                        ],
                                      )
                                    : Column(
                                        children: _getRecentActivities()
                                            .map(
                                              (activity) => Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 12,
                                                ),
                                                child: ActivityItem(
                                                  icon:
                                                      activity['icon']
                                                          as IconData,
                                                  title:
                                                      activity['title']
                                                          as String,
                                                  time: _formatTime(
                                                    activity['time']
                                                        as DateTime,
                                                  ),
                                                  iconColor:
                                                      activity['iconColor']
                                                          as Color,
                                                  actualTime:
                                                      activity['time']
                                                          as DateTime,
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: const BottomNavigation(currentIndex: 0),
          ),
        );
      },
    );
  }

  void _showBabySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BabySelectorSheet(),
    );
  }

  void _showTrackingSheet(BuildContext context, String type) {
    // Haptics.vibrate(HapticsType.light);

    switch (type) {
      case 'sleep':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => SleepTrackingSheet(
            onSleepSaved: () {
              _loadTodayData();
            },
          ),
        ).then((_) {
          // Refresh data after sheet is closed
          _loadTodayData();
        });
        break;
      case 'feeding':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => FeedingTrackingSheet(
            onFeedingSaved: () {
              _loadTodayData();
            },
          ),
        ).then((_) {
          // Refresh data after sheet is closed
          _loadTodayData();
        });
        break;
      case 'diaper':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => DiaperTrackingSheet(
            onDiaperSaved: () {
              _loadTodayData();
            },
          ),
        ).then((_) {
          // Refresh data after sheet is closed
          _loadTodayData();
        });
        break;
    }
  }

  void _showDevelopmentSheet(BuildContext context) {
    // Haptics.vibrate(HapticsType.light);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DevelopmentTrackingSheet(
        onMeasurementSaved: () {
          _loadTodayData();
        },
      ),
    ).then((_) {
      // Refresh data after sheet is closed
      _loadTodayData();
    });
  }

  void _showNotificationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.mutedForeground,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Bildirimler',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Expanded(child: NotificationDisplayWidget()),
          ],
        ),
      ),
    );
  }
}
