import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/providers/theme_provider.dart';

enum TimeRange {
  daily,
  weekly,
  monthly,
}

class TimeRangeSelector extends StatelessWidget {
  final TimeRange selectedRange;
  final ValueChanged<TimeRange> onRangeChanged;

  const TimeRangeSelector({
    super.key,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: themeProvider.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: themeProvider.borderColor),
          ),
          child: Row(
            children: [
              _buildRangeButton(
                context,
                themeProvider,
                TimeRange.daily,
                'Günlük',
              ),
              _buildRangeButton(
                context,
                themeProvider,
                TimeRange.weekly,
                'Haftalık',
              ),
              _buildRangeButton(
                context,
                themeProvider,
                TimeRange.monthly,
                'Aylık',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRangeButton(
    BuildContext context,
    ThemeProvider themeProvider,
    TimeRange range,
    String label,
  ) {
    final isSelected = selectedRange == range;
    return Expanded(
      child: GestureDetector(
        onTap: () => onRangeChanged(range),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? themeProvider.primaryColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : themeProvider.cardForeground,
            ),
          ),
        ),
      ),
    );
  }
}

