import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../core/services/sleep_service.dart';
import '../../../core/services/feeding_service.dart';
import '../../../core/services/physical_measurement_service.dart';
import '../../../shared/models/sleep_model.dart';
import '../../../shared/models/feeding_model.dart';
import '../../../shared/models/physical_measurement_model.dart';
import 'time_range_selector.dart';

class OverviewChartTab extends StatefulWidget {
  final String babyId;
  final TimeRange timeRange;

  const OverviewChartTab({
    super.key,
    required this.babyId,
    required this.timeRange,
  });

  @override
  State<OverviewChartTab> createState() => _OverviewChartTabState();
}

class _OverviewChartTabState extends State<OverviewChartTab> {
  bool _isLoading = true;
  List<Sleep> _sleeps = [];
  List<Feeding> _feedings = [];
  List<PhysicalMeasurement> _measurements = [];
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(OverviewChartTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeRange != widget.timeRange ||
        oldWidget.babyId != widget.babyId) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      DateTime startDate;
      switch (widget.timeRange) {
        case TimeRange.daily:
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case TimeRange.weekly:
          startDate = now.subtract(const Duration(days: 6));
          break;
        case TimeRange.monthly:
          startDate = now.subtract(const Duration(days: 29));
          break;
      }

      final results = await Future.wait([
        SleepService.getSleepRecordsForDateRange(widget.babyId, startDate, now),
        FeedingService.getFeedingRecordsForDateRange(
          widget.babyId,
          startDate,
          now,
        ),
        PhysicalMeasurementService.getMeasurements(widget.babyId),
      ]);
      if (!mounted) return;
      setState(() {
        _sleeps = (results[0] as List<Sleep>)
            .where((s) => s.duration != null)
            .toList();
        _feedings = results[1] as List<Feeding>;
        _measurements = (results[2] as List<PhysicalMeasurement>)
            .where((m) => m.measuredAt.isAfter(startDate))
            .toList();
        _rangeStart = DateTime(startDate.year, startDate.month, startDate.day);
        _rangeEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Veri yüklenirken hata: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        if (_isLoading) {
          return Center(
            child: CircularProgressIndicator(color: themeProvider.primaryColor),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              _buildSummaryCard(
                context,
                themeProvider,
                'Uyku',
                '${_sleeps.length} kayıt',
                _totalSleepHoursString(),
                'saat',
                Icons.bedtime,
                Colors.indigo,
              ),
              const SizedBox(height: 16),
              _buildSummaryCard(
                context,
                themeProvider,
                'Beslenme',
                '${_feedings.length} kayıt',
                _feedings
                    .where(
                      (f) => f.type == FeedingType.bottle && f.amount != null,
                    )
                    .fold<int>(0, (sum, f) => sum + (f.amount ?? 0))
                    .toString(),
                'ml süt',
                Icons.restaurant,
                Colors.purple,
              ),
              const SizedBox(height: 16),
              _buildSummaryCard(
                context,
                themeProvider,
                'Gelişim',
                '${_measurements.length} ölçüm',
                _measurements.where((m) => m.weight != null).isNotEmpty
                    ? '${_measurements.where((m) => m.weight != null).last.weight}'
                    : '-',
                'kg',
                Icons.trending_up,
                Colors.blue,
              ),
              const SizedBox(height: 16),
              // Quick Stats
              _buildQuickStatsCard(context, themeProvider),
            ],
          ),
        );
      },
    );
  }

  String _totalSleepHoursString() {
    final dailyHours = _getDailySleepHours();
    final total = dailyHours.values.fold<double>(0.0, (a, b) => a + b);
    // show without truncating minutes (e.g., 6.5 -> 6.5)
    return total.toStringAsFixed(total.truncateToDouble() == total ? 0 : 1);
  }

  Map<String, double> _getDailySleepHours() {
    if (_rangeStart == null || _rangeEnd == null) return {};
    final start = _rangeStart!;
    final end = _rangeEnd!;
    final Map<String, double> dailyHours = {};

    for (DateTime d = DateTime(start.year, start.month, start.day);
        !d.isAfter(end);
        d = d.add(const Duration(days: 1))) {
      final key = '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      dailyHours[key] = 0.0;
    }

    for (final sleep in _sleeps) {
      if (sleep.endTime == null) continue;
      DateTime s = sleep.startTime;
      DateTime e = sleep.endTime!;

      if (e.isBefore(start) || s.isAfter(end)) continue;
      if (s.isBefore(start)) s = start;
      if (e.isAfter(end)) e = end;

      DateTime cursor = s;
      while (!cursor.isAfter(e)) {
        final dayStart = DateTime(cursor.year, cursor.month, cursor.day);
        final dayEnd = DateTime(cursor.year, cursor.month, cursor.day, 23, 59, 59, 999);
        final segmentEnd = e.isBefore(dayEnd) ? e : dayEnd;
        final minutes = segmentEnd.difference(cursor).inMinutes;
        if (minutes > 0) {
          final key = '${dayStart.year.toString().padLeft(4, '0')}-${dayStart.month.toString().padLeft(2, '0')}-${dayStart.day.toString().padLeft(2, '0')}';
          dailyHours[key] = (dailyHours[key] ?? 0) + minutes / 60.0;
        }
        cursor = DateTime(dayStart.year, dayStart.month, dayStart.day)
            .add(const Duration(days: 1));
      }
    }

    return dailyHours;
  }

  Widget _buildSummaryCard(
    BuildContext context,
    ThemeProvider themeProvider,
    String title,
    String subtitle,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.cardForeground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: themeProvider.mutedForegroundColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  color: themeProvider.mutedForegroundColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsCard(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    final dailyHours = _getDailySleepHours();
    final totalHours = dailyHours.values.fold<double>(0.0, (a, b) => a + b);
    final dayCount = dailyHours.isEmpty ? 1 : dailyHours.length;
    final avgSleepPerDay = totalHours / dayCount;

    final start = _rangeStart;
    final end = _rangeEnd;
    int feedingDayCount = 1;
    if (start != null && end != null) {
      feedingDayCount = end.difference(start).inDays + 1;
    }
    final avgFeedingPerDay = feedingDayCount > 0
        ? _feedings.length / feedingDayCount
        : 0.0;

    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Özet İstatistikler',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: themeProvider.cardForeground,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            context,
            themeProvider,
            'Ortalama Uyku (Günlük)',
          '${avgSleepPerDay.toStringAsFixed(1)} saat',
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            context,
            themeProvider,
            'Ortalama Beslenme (Günlük)',
            '${avgFeedingPerDay.toStringAsFixed(1)}',
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            context,
            themeProvider,
            'Toplam Ölçüm',
            '${_measurements.length}',
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    ThemeProvider themeProvider,
    String label,
    String value,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: themeProvider.cardForeground),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: themeProvider.primaryColor,
          ),
        ),
      ],
    );
  }
}
