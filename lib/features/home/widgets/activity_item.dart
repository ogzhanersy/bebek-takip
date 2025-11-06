import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/providers/theme_provider.dart';

class ActivityItem extends StatelessWidget {
  final String time;
  final String title;
  final IconData icon;
  final Color iconColor;
  final DateTime actualTime; // Gerçek saat bilgisi için

  const ActivityItem({
    super.key,
    required this.time,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.actualTime,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return CustomCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: themeProvider.mutedColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: themeProvider.cardForeground),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        time,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: themeProvider.mutedForegroundColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Text(
                    _formatActualTime(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: themeProvider.cardForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatActualTime() {
    return '${actualTime.hour.toString().padLeft(2, '0')}:${actualTime.minute.toString().padLeft(2, '0')}';
  }
}
