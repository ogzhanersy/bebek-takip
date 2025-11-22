import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../core/services/physical_measurement_service.dart';
import '../../../shared/models/physical_measurement_model.dart';
import 'time_range_selector.dart';
import '../../../core/services/growth_target_service.dart';
import '../../../core/services/baby_service.dart';
import '../../../core/utils/who_growth_data.dart';

class DevelopmentChartTab extends StatefulWidget {
  final String babyId;
  final TimeRange timeRange;

  const DevelopmentChartTab({
    super.key,
    required this.babyId,
    required this.timeRange,
  });

  @override
  State<DevelopmentChartTab> createState() => _DevelopmentChartTabState();
}

class _DevelopmentChartTabState extends State<DevelopmentChartTab> {
  List<PhysicalMeasurement> _measurements = [];
  List<PhysicalMeasurement> _allMeasurements = [];
  bool _isLoading = true;
  GrowthTargets? _targets;
  Map<String, double>? _whoWeightTargets;
  Map<String, double>? _whoHeightTargets;

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
    _loadTargets();
  }

  @override
  void didUpdateWidget(DevelopmentChartTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeRange != widget.timeRange ||
        oldWidget.babyId != widget.babyId) {
      _loadMeasurements();
      _loadTargets();
    }
  }

  Future<void> _loadMeasurements() async {
    setState(() => _isLoading = true);
    try {
      final allMeasurements = await PhysicalMeasurementService.getMeasurements(
        widget.babyId,
      );

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
        _allMeasurements = [...allMeasurements]
          ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
        _measurements =
            allMeasurements
                .where((m) => m.measuredAt.isAfter(startDate))
                .toList()
              ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
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

  Future<void> _loadTargets() async {
    try {
      final t = await GrowthTargetService.getTargets(widget.babyId);
      // WHO hedeflerini de yükle
      final baby = await BabyService.getBabyById(widget.babyId);
      Map<String, double>? whoWeightTargets;
      Map<String, double>? whoHeightTargets;
      if (baby != null) {
        whoWeightTargets = WhoGrowthData.getWhoWeightTargets(baby);
        whoHeightTargets = WhoGrowthData.getWhoHeightTargets(baby);
      }
      if (!mounted) return;
      setState(() {
        _targets = t;
        _whoWeightTargets = whoWeightTargets;
        _whoHeightTargets = whoHeightTargets;
      });
    } catch (_) {}
  }

  List<FlSpot> _getWeightSpots() {
    return _measurements
        .where((m) => m.weight != null)
        .toList()
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key.toDouble();
          final measurement = entry.value;
          return FlSpot(index, measurement.weight!);
        })
        .toList();
  }

  List<FlSpot> _getHeightSpots() {
    return _measurements
        .where((m) => m.height != null)
        .toList()
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key.toDouble();
          final measurement = entry.value;
          return FlSpot(index, measurement.height!);
        })
        .toList();
  }

  List<FlSpot> _getHeadCircumferenceSpots() {
    return _measurements
        .where((m) => m.headCircumference != null)
        .toList()
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key.toDouble();
          final measurement = entry.value;
          return FlSpot(index, measurement.headCircumference!);
        })
        .toList();
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

        if (_measurements.isEmpty) {
          return Center(
            child: CustomCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 64,
                    color: themeProvider.mutedForegroundColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Gelişim verisi bulunamadı',
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

        final weightSpots = _getWeightSpots();
        final heightSpots = _getHeightSpots();
        final headSpots = _getHeadCircumferenceSpots();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.timeRange == TimeRange.daily) ...[
                _buildDailyValueCards(context, themeProvider),
              ] else ...[
                if (weightSpots.isNotEmpty) ...[
                  _buildChartCard(
                    context,
                    themeProvider,
                    'Kilo (kg)',
                    weightSpots,
                    const Color(0xFF90CAF9), // Soft blue
                    Icons.monitor_weight,
                    targetMin:
                        _targets?.weightMinKg ??
                        _whoWeightTargets?['min'] ??
                        6.0,
                    targetMax:
                        _targets?.weightMaxKg ??
                        _whoWeightTargets?['max'] ??
                        9.5,
                    currentValue: _measurements.isNotEmpty
                        ? (_measurements.last.weight ?? 0.0)
                        : 0.0,
                    showTargetBar: true,
                  ),
                  const SizedBox(height: 16),
                ],
                if (heightSpots.isNotEmpty) ...[
                  _buildChartCard(
                    context,
                    themeProvider,
                    'Boy (cm)',
                    heightSpots,
                    const Color(0xFF81C784), // Soft green
                    Icons.height,
                    targetMin:
                        _targets?.heightMinCm ??
                        _whoHeightTargets?['min'] ??
                        60.0,
                    targetMax:
                        _targets?.heightMaxCm ??
                        _whoHeightTargets?['max'] ??
                        80.0,
                    currentValue: _measurements.isNotEmpty
                        ? (_measurements.last.height ?? 0.0)
                        : 0.0,
                    showTargetBar: true,
                  ),
                  const SizedBox(height: 16),
                ],
                if (headSpots.isNotEmpty) ...[
                  _buildChartCard(
                    context,
                    themeProvider,
                    'Baş Çevresi (cm)',
                    headSpots,
                    const Color(0xFFFFB74D), // Soft orange
                    Icons.rounded_corner,
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDailyValueCards(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    // Latest and previous measurements (previous from overall history)
    final latest = _allMeasurements.isNotEmpty
        ? _allMeasurements.last
        : _measurements.last;
    final previous = _allMeasurements.length >= 2
        ? _allMeasurements[_allMeasurements.length - 2]
        : null;

    Widget buildCard({
      required String title,
      required double? value,
      required double? prev,
      required String unit,
      required double targetMin,
      required double targetMax,
      required Color color,
      required IconData icon,
      DateTime? valueDate,
      DateTime? prevDate,
      bool showProgress = true,
    }) {
      String deltaText = '-';
      if (value != null &&
          prev != null &&
          valueDate != null &&
          prevDate != null) {
        final delta = value - prev;
        final sign = delta >= 0 ? '+' : '';
        deltaText = '$sign${delta.toStringAsFixed(1)} $unit';
      }

      // Progress between target range
      double progress;
      if (value == null) {
        progress = 0;
      } else if (value <= targetMin) {
        progress = 0;
      } else if (value >= targetMax) {
        progress = 1;
      } else {
        progress = (value - targetMin) / (targetMax - targetMin);
      }

      return CustomCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        value != null ? value.toStringAsFixed(1) : '-',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        unit,
                        style: TextStyle(
                          fontSize: 14,
                          color: themeProvider.mutedForegroundColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '• önceki: $deltaText',
                        style: TextStyle(
                          fontSize: 12,
                          color: themeProvider.mutedForegroundColor,
                        ),
                      ),
                    ],
                  ),
                  if (showProgress) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        value: progress,
                        backgroundColor: themeProvider.borderColor,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hedef min: ${targetMin.toStringAsFixed(1)} $unit',
                          style: TextStyle(
                            fontSize: 11,
                            color: themeProvider.mutedForegroundColor,
                          ),
                        ),
                        Text(
                          'Hedef max: ${targetMax.toStringAsFixed(1)} $unit',
                          style: TextStyle(
                            fontSize: 11,
                            color: themeProvider.mutedForegroundColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    final cards = <Widget>[];
    cards.add(
      buildCard(
        title: 'Kilo',
        value: latest.weight,
        prev: previous?.weight,
        unit: 'kg',
        targetMin: _targets?.weightMinKg ?? _whoWeightTargets?['min'] ?? 6.0,
        targetMax: _targets?.weightMaxKg ?? _whoWeightTargets?['max'] ?? 9.5,
        color: Colors.blue,
        icon: Icons.monitor_weight,
        valueDate: latest.measuredAt,
        prevDate: previous?.measuredAt,
      ),
    );

    cards.add(const SizedBox(height: 12));

    cards.add(
      buildCard(
        title: 'Boy',
        value: latest.height,
        prev: previous?.height,
        unit: 'cm',
        targetMin: _targets?.heightMinCm ?? _whoHeightTargets?['min'] ?? 60.0,
        targetMax: _targets?.heightMaxCm ?? _whoHeightTargets?['max'] ?? 80.0,
        color: Colors.green,
        icon: Icons.height,
        valueDate: latest.measuredAt,
        prevDate: previous?.measuredAt,
      ),
    );

    cards.add(const SizedBox(height: 12));

    // Baş çevresi kartını ekle (hedefsiz progress)
    cards.add(const SizedBox(height: 12));
    cards.add(
      buildCard(
        title: 'Baş Çevresi',
        value: latest.headCircumference,
        prev: previous?.headCircumference,
        unit: 'cm',
        targetMin: 0,
        targetMax: 0,
        color: Colors.orange,
        icon: Icons.rounded_corner,
        valueDate: latest.measuredAt,
        prevDate: previous?.measuredAt,
        showProgress: false,
      ),
    );

    return Column(children: cards);
  }

  Widget _buildChartCard(
    BuildContext context,
    ThemeProvider themeProvider,
    String title,
    List<FlSpot> spots,
    Color color,
    IconData icon, {
    double? targetMin,
    double? targetMax,
    double? currentValue,
    bool showTargetBar = false,
  }) {
    if (spots.isEmpty) return const SizedBox.shrink();

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range * 0.1;

    // Latest value label
    final latestValue = spots.last.y;

    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.cardForeground,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  latestValue.toStringAsFixed(1),
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: range > 0 ? (range + padding * 2) / 4 : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: themeProvider.borderColor,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 11,
                            color: themeProvider.mutedForegroundColor,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
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
                minY: minY - padding,
                maxY: maxY + padding,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: color,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showTargetBar &&
              targetMin != null &&
              targetMax != null &&
              currentValue != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: () {
                  if (currentValue <= targetMin) return 0.0;
                  if (currentValue >= targetMax) return 1.0;
                  return (currentValue - targetMin) / (targetMax - targetMin);
                }(),
                backgroundColor: themeProvider.borderColor,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hedef min: ${targetMin.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: themeProvider.mutedForegroundColor,
                  ),
                ),
                Text(
                  'Değer: ${currentValue.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Hedef max: ${targetMax.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: themeProvider.mutedForegroundColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
