import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../core/services/feeding_service.dart';
import '../../../shared/models/feeding_model.dart';
import 'time_range_selector.dart';
import 'package:intl/intl.dart';

class FeedingChartTab extends StatefulWidget {
  final String babyId;
  final TimeRange timeRange;

  const FeedingChartTab({
    super.key,
    required this.babyId,
    required this.timeRange,
  });

  @override
  State<FeedingChartTab> createState() => _FeedingChartTabState();
}

class _FeedingChartTabState extends State<FeedingChartTab> {
  List<Feeding> _feedings = [];
  bool _isLoading = true;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    _loadFeedings();
  }

  @override
  void didUpdateWidget(FeedingChartTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeRange != widget.timeRange ||
        oldWidget.babyId != widget.babyId) {
      _loadFeedings();
    }
  }

  Future<void> _loadFeedings() async {
    setState(() => _isLoading = true);
    try {
      final allFeedings = await FeedingService.getFeedingRecords(widget.babyId);

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

      if (!mounted) return;
      setState(() {
        _feedings =
            allFeedings.where((f) => f.startTime.isAfter(startDate)).toList()
              ..sort((a, b) => a.startTime.compareTo(b.startTime));
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

  Map<String, double> _getDailyFeedingCounts() {
    if (_rangeStart == null || _rangeEnd == null) return {};
    final start = _rangeStart!;
    final end = _rangeEnd!;
    final Map<String, double> dailyCounts = {};

    // initialize all days to 0
    for (
      DateTime d = DateTime(start.year, start.month, start.day);
      !d.isAfter(end);
      d = d.add(const Duration(days: 1))
    ) {
      final key = DateFormat('yyyy-MM-dd').format(d);
      dailyCounts[key] = 0.0;
    }

    for (final feeding in _feedings) {
      final dateKey = DateFormat('yyyy-MM-dd').format(feeding.startTime);
      if (dailyCounts.containsKey(dateKey)) {
        dailyCounts[dateKey] = (dailyCounts[dateKey] ?? 0) + 1;
      }
    }

    return dailyCounts;
  }

  // Build 5-day buckets for Monthly view to improve readability
  ({List<String> labels, List<double> values}) _getFiveDayBuckets() {
    final start = _rangeStart!; // earliest allowed day in range
    final end = _rangeEnd!; // today end
    final labels = <String>[];
    final values = <double>[];

    // Start from today and go backwards in 5-day windows
    DateTime bucketEnd = DateTime(
      end.year,
      end.month,
      end.day,
      23,
      59,
      59,
      999,
    );
    while (!bucketEnd.isBefore(start)) {
      final bucketStart = DateTime(
        bucketEnd.year,
        bucketEnd.month,
        bucketEnd.day,
      ).subtract(const Duration(days: 4));
      final effectiveStart = bucketStart.isBefore(start)
          ? DateTime(start.year, start.month, start.day)
          : bucketStart;

      // label with bucketStart day (dd/MM)
      final dd = effectiveStart.day.toString().padLeft(2, '0');
      final mm = effectiveStart.month.toString().padLeft(2, '0');
      labels.add('$dd/$mm');

      final count = _feedings
          .where(
            (f) =>
                !f.startTime.isBefore(effectiveStart) &&
                !f.startTime.isAfter(bucketEnd),
          )
          .length
          .toDouble();
      values.add(count);

      // Move to previous window
      bucketEnd = effectiveStart.subtract(const Duration(days: 1));
    }
    // Reverse so that oldest is on the left, newest (today) on the right
    final revLabels = labels.reversed.toList();
    final revValues = values.reversed.toList();
    return (labels: revLabels, values: revValues);
  }

  Map<FeedingType, int> _getFeedingTypeCounts() {
    final counts = <FeedingType, int>{
      FeedingType.breastfeeding: 0,
      FeedingType.bottle: 0,
      FeedingType.solid: 0,
    };
    for (final feeding in _feedings) {
      counts[feeding.type] = (counts[feeding.type] ?? 0) + 1;
    }
    return counts;
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

        if (_feedings.isEmpty) {
          return Center(
            child: CustomCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.restaurant_outlined,
                    size: 64,
                    color: themeProvider.mutedForegroundColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Beslenme verisi bulunamadı',
                    style: TextStyle(
                      fontSize: 16,
                      color: themeProvider.mutedForegroundColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final dailyCounts = _getDailyFeedingCounts();
        final typeCounts = _getFeedingTypeCounts();
        final sortedDays = dailyCounts.keys.toList()..sort();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Daily sessions (duration) if Daily, else counts per day
              if (widget.timeRange == TimeRange.daily)
                _buildDailySessionChart(context, themeProvider)
              else
                (widget.timeRange == TimeRange.monthly
                    ? _buildFiveDayBucketChart(context, themeProvider)
                    : _buildDailyCountChart(
                        context,
                        themeProvider,
                        sortedDays,
                        dailyCounts,
                      )),
              const SizedBox(height: 16),
              // Feeding Type Distribution
              _buildTypeDistributionChart(context, themeProvider, typeCounts),
              const SizedBox(height: 16),
              // Statistics
              _buildStatisticsCard(context, themeProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDailySessionChart(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    if (_rangeStart == null || _rangeEnd == null)
      return const SizedBox.shrink();

    final DateTime dayStart = DateTime(
      _rangeStart!.year,
      _rangeStart!.month,
      _rangeStart!.day,
    );
    final DateTime dayEnd = DateTime(
      _rangeStart!.year,
      _rangeStart!.month,
      _rangeStart!.day,
      23,
      59,
      59,
      999,
    );

    final sessions =
        _feedings
            .where((f) => f.endTime != null)
            .map((f) {
              DateTime start = f.startTime.isBefore(dayStart)
                  ? dayStart
                  : f.startTime;
              DateTime end = f.endTime!.isAfter(dayEnd) ? dayEnd : f.endTime!;
              return {'start': start, 'end': end};
            })
            .where(
              (m) => (m['end'] as DateTime).isAfter(m['start'] as DateTime),
            )
            .toList()
          ..sort(
            (a, b) =>
                (a['start'] as DateTime).compareTo(b['start'] as DateTime),
          );

    final limited = sessions.take(4).toList();

    final List<String> labels = [];
    final List<BarChartGroupData> bars = [];
    double maxVal = 0.0;
    for (int i = 0; i < limited.length; i++) {
      final start = limited[i]['start'] as DateTime;
      final end = limited[i]['end'] as DateTime;
      final hours = end.difference(start).inMinutes / 60.0;
      maxVal = hours > maxVal ? hours : maxVal;
      labels.add(start.hour.toString().padLeft(2, '0'));
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: hours,
              color: Colors.purple,
              width: 22,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
            ),
          ],
        ),
      );
    }

    final maxY = (maxVal == 0 ? 1.0 : (maxVal + 0.5)).ceilToDouble();

    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.purple, size: 24),
              const SizedBox(width: 8),
              Text(
                'Günlük Beslenme (Süre)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.cardForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.5,
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) => Text(
                        _formatHours(value),
                        style: TextStyle(
                          fontSize: 11,
                          color: themeProvider.mutedForegroundColor,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          labels[idx],
                          style: TextStyle(
                            fontSize: 11,
                            color: themeProvider.mutedForegroundColor,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: themeProvider.borderColor),
                    left: BorderSide(color: themeProvider.borderColor),
                  ),
                ),
                minY: 0,
                maxY: maxY,
                barGroups: bars,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        _formatHours(rod.toY),
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatHours(num value) {
    final totalMinutes = (value * 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h == 0) return '${m}dk';
    if (m == 0) return '${h}s';
    return '${h}s ${m}dk';
  }

  Widget _buildDailyCountChart(
    BuildContext context,
    ThemeProvider themeProvider,
    List<String> days,
    Map<String, double> counts,
  ) {
    final spots = days.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final day = entry.value;
      return FlSpot(index, counts[day] ?? 0);
    }).toList();

    if (spots.isEmpty) return const SizedBox.shrink();

    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: Colors.purple, size: 24),
              const SizedBox(width: 8),
              Text(
                'Günlük Beslenme Sayısı',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.cardForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 11,
                            color: themeProvider.mutedForegroundColor,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= days.length) return const Text('');
                        final day = days[value.toInt()];
                        final date = DateTime.parse(day);
                        return Text(
                          '${date.day}/${date.month}',
                          style: TextStyle(
                            fontSize: 10,
                            color: themeProvider.mutedForegroundColor,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: themeProvider.borderColor),
                    left: BorderSide(color: themeProvider.borderColor),
                  ),
                ),
                maxY:
                    (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 1)
                        .ceilToDouble(),
                barGroups: spots.asMap().entries.map((entry) {
                  final index = entry.key;
                  final spot = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: spot.y,
                        color: Colors.purple,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiveDayBucketChart(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    final buckets = _getFiveDayBuckets();
    if (buckets.values.isEmpty) return const SizedBox.shrink();

    final spots = buckets.values.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      return BarChartGroupData(
        x: index.toInt(),
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: Colors.purple,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    final maxY = (buckets.values.fold<double>(0.0, (a, b) => a > b ? a : b) + 1)
        .ceilToDouble();

    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: Colors.purple, size: 24),
              const SizedBox(width: 8),
              Text(
                '5 Günlük Beslenme Sayısı',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.cardForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 11,
                          color: themeProvider.mutedForegroundColor,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= buckets.labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          buckets.labels[idx],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: themeProvider.mutedForegroundColor,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: themeProvider.borderColor),
                    left: BorderSide(color: themeProvider.borderColor),
                  ),
                ),
                maxY: maxY,
                barGroups: spots,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeDistributionChart(
    BuildContext context,
    ThemeProvider themeProvider,
    Map<FeedingType, int> typeCounts,
  ) {
    final total = typeCounts.values.reduce((a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final sections = [
      PieChartSectionData(
        value: typeCounts[FeedingType.breastfeeding]?.toDouble() ?? 0,
        title:
            'Emzirme\n${((typeCounts[FeedingType.breastfeeding] ?? 0) / total * 100).toStringAsFixed(0)}%',
        color: Colors.pink,
        radius: 80,
      ),
      PieChartSectionData(
        value: typeCounts[FeedingType.bottle]?.toDouble() ?? 0,
        title:
            'Biberon\n${((typeCounts[FeedingType.bottle] ?? 0) / total * 100).toStringAsFixed(0)}%',
        color: Colors.blue,
        radius: 80,
      ),
      PieChartSectionData(
        value: typeCounts[FeedingType.solid]?.toDouble() ?? 0,
        title:
            'Katı Gıda\n${((typeCounts[FeedingType.solid] ?? 0) / total * 100).toStringAsFixed(0)}%',
        color: Colors.orange,
        radius: 80,
      ),
    ].where((s) => s.value > 0).toList();

    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: Colors.pink, size: 24),
              const SizedBox(width: 8),
              Text(
                'Beslenme Tipi Dağılımı',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.cardForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    final totalFeedings = _feedings.length;
    // Gün sayısı: seçilen aralık için
    final now = DateTime.now();
    final startDate = () {
      switch (widget.timeRange) {
        case TimeRange.daily:
          return DateTime(now.year, now.month, now.day);
        case TimeRange.weekly:
          return now.subtract(const Duration(days: 6));
        case TimeRange.monthly:
          return now.subtract(const Duration(days: 29));
      }
    }();
    final dayCount = now.difference(startDate).inDays + 1;
    final avgPerDay = dayCount > 0 ? totalFeedings / dayCount : 0.0;
    final bottleFeedings = _feedings
        .where((f) => f.type == FeedingType.bottle)
        .toList();
    final totalMilk = bottleFeedings
        .where((f) => f.amount != null)
        .fold<int>(0, (sum, f) => sum + (f.amount ?? 0));

    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'İstatistikler',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: themeProvider.cardForeground,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatItem(
            context,
            themeProvider,
            'Toplam Beslenme',
            '$totalFeedings',
            Icons.restaurant,
          ),
          const SizedBox(height: 12),
          _buildStatItem(
            context,
            themeProvider,
            'Ortalama (Günlük)',
            avgPerDay.toStringAsFixed(1),
            Icons.trending_up,
          ),
          if (totalMilk > 0) ...[
            const SizedBox(height: 12),
            _buildStatItem(
              context,
              themeProvider,
              'Toplam Süt Miktarı',
              '$totalMilk ml',
              Icons.local_drink,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    ThemeProvider themeProvider,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: themeProvider.primaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: themeProvider.cardForeground),
          ),
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
