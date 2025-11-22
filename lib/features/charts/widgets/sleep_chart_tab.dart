import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../core/services/sleep_service.dart';
import '../../../shared/models/sleep_model.dart';
import 'time_range_selector.dart';
import 'package:intl/intl.dart';

class SleepChartTab extends StatefulWidget {
  final String babyId;
  final TimeRange timeRange;

  const SleepChartTab({
    super.key,
    required this.babyId,
    required this.timeRange,
  });

  @override
  State<SleepChartTab> createState() => _SleepChartTabState();
}

class _SleepChartTabState extends State<SleepChartTab> {
  List<Sleep> _sleeps = [];
  bool _isLoading = true;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    _loadSleeps();
  }

  @override
  void didUpdateWidget(SleepChartTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeRange != widget.timeRange ||
        oldWidget.babyId != widget.babyId) {
      _loadSleeps();
    }
  }

  Future<void> _loadSleeps() async {
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

      final sleeps = await SleepService.getSleepRecordsForDateRange(
        widget.babyId,
        startDate,
        now,
      );
      if (!mounted) return;
      setState(() {
        _sleeps = sleeps.where((s) => s.duration != null).toList()
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

  Map<String, double> _getDailySleepHours() {
    final start = _rangeStart!;
    final end = _rangeEnd!;
    final Map<String, double> dailyHours = {};

    // initialize all days in range to 0
    for (
      DateTime d = DateTime(start.year, start.month, start.day);
      !d.isAfter(end);
      d = d.add(const Duration(days: 1))
    ) {
      final key = DateFormat('yyyy-MM-dd').format(d);
      dailyHours[key] = 0.0;
    }

    for (final sleep in _sleeps) {
      if (sleep.endTime == null) continue; // aktif uykuları sayma

      DateTime s = sleep.startTime;
      DateTime e = sleep.endTime!;

      // clip to selected range
      if (e.isBefore(start) || s.isAfter(end)) continue;
      if (s.isBefore(start)) s = start;
      if (e.isAfter(end)) e = end;

      // distribute duration across days
      DateTime cursor = s;
      while (!cursor.isAfter(e)) {
        final dayStart = DateTime(cursor.year, cursor.month, cursor.day);
        final dayEnd = DateTime(
          cursor.year,
          cursor.month,
          cursor.day,
          23,
          59,
          59,
          999,
        );
        final segmentEnd = e.isBefore(dayEnd) ? e : dayEnd;
        final minutes = segmentEnd.difference(cursor).inMinutes;
        if (minutes > 0) {
          final key = DateFormat('yyyy-MM-dd').format(dayStart);
          dailyHours[key] = (dailyHours[key] ?? 0) + minutes / 60.0;
        }
        cursor = DateTime(
          dayStart.year,
          dayStart.month,
          dayStart.day,
        ).add(const Duration(days: 1));
      }
    }

    return dailyHours;
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

        if (_sleeps.isEmpty) {
          return Center(
            child: CustomCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bedtime_outlined,
                    size: 64,
                    color: themeProvider.mutedForegroundColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Uyku verisi bulunamadı',
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

        final dailyHours = _getDailySleepHours();
        final sortedDays = dailyHours.keys.toList()..sort();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.timeRange == TimeRange.daily)
                _buildHourlySleepChart(context, themeProvider)
              else
                _buildDailySleepChart(
                  context,
                  themeProvider,
                  sortedDays,
                  dailyHours,
                ),
              const SizedBox(height: 16),
              // Statistics
              _buildStatisticsCard(context, themeProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHourlySleepChart(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    // One bar per sleep session (max 4), labelled with start hour
    if (_rangeStart == null || _rangeEnd == null) {
      return const SizedBox.shrink();
    }

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

    // Clip sessions to the day and sort
    final sessions =
        _sleeps
            .where((s) => s.endTime != null)
            .map((s) {
              DateTime start = s.startTime.isBefore(dayStart)
                  ? dayStart
                  : s.startTime;
              DateTime end = s.endTime!.isAfter(dayEnd) ? dayEnd : s.endTime!;
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
      final h = end.difference(start).inMinutes / 60.0;
      maxVal = h > maxVal ? h : maxVal;
      labels.add(start.hour.toString().padLeft(2, '0'));
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: h,
              color: const Color(0xFF9FA8DA), // Soft indigo
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
              Icon(
                Icons.schedule,
                color: const Color(0xFF9FA8DA),
                size: 24,
              ), // Soft indigo
              const SizedBox(width: 8),
              Text(
                'Saatlik Uyku (Bugün)',
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

  Widget _buildDailySleepChart(
    BuildContext context,
    ThemeProvider themeProvider,
    List<String> days,
    Map<String, double> hours,
  ) {
    final spots = days.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final day = entry.value;
      return FlSpot(index, hours[day] ?? 0);
    }).toList();

    if (spots.isEmpty) return const SizedBox.shrink();

    final maxY = (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 1)
        .ceilToDouble();

    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bedtime,
                color: const Color(0xFF9FA8DA),
                size: 24,
              ), // Soft indigo
              const SizedBox(width: 8),
              Text(
                'Günlük Uyku Süresi',
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
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toStringAsFixed(1)}s',
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
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.indigo,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.indigo,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.indigo.withOpacity(0.1),
                    ),
                  ),
                ],
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
    final dailyHours = _getDailySleepHours();
    final totalHoursDouble = dailyHours.values.fold<double>(
      0.0,
      (a, b) => a + b,
    );
    final totalHours = totalHoursDouble.floor();
    final totalMinutes = ((totalHoursDouble - totalHours) * 60).round();

    // Calculate average based on time range
    double avgHours;
    String avgText;
    if (widget.timeRange == TimeRange.daily) {
      // For daily view: average per sleep session
      final sleepCount = _sleeps.length;
      avgHours = sleepCount > 0 ? totalHoursDouble / sleepCount : 0.0;
      // Format as hours and minutes
      final avgHoursInt = avgHours.floor();
      final avgMinutes = ((avgHours - avgHoursInt) * 60).round();
      avgText = avgHoursInt > 0
          ? (avgMinutes > 0
                ? '$avgHoursInt saat $avgMinutes dakika'
                : '$avgHoursInt saat')
          : '$avgMinutes dakika';
    } else {
      // For weekly/monthly view: average per day
      final dayCount = dailyHours.length == 0 ? 1 : dailyHours.length;
      avgHours = totalHoursDouble / dayCount;
      avgText = '${avgHours.toStringAsFixed(1)} saat';
    }

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
            'Toplam Uyku',
            '$totalHours saat $totalMinutes dakika',
            Icons.bedtime,
          ),
          const SizedBox(height: 12),
          _buildStatItem(
            context,
            themeProvider,
            'Ortalama Uyku Süresi',
            avgText,
            Icons.trending_up,
          ),
          const SizedBox(height: 12),
          _buildStatItem(
            context,
            themeProvider,
            'Toplam Uyku Sayısı',
            '${_sleeps.length}',
            Icons.nightlight_round,
          ),
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
        Icon(icon, color: Colors.indigo, size: 20),
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
            color: Colors.indigo,
          ),
        ),
      ],
    );
  }
}
