import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class TrackingSheet extends StatelessWidget {
  final String type;

  const TrackingSheet({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${type.toUpperCase()} Takibi',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          Text('$type tracking will be implemented here'),
        ],
      ),
    );
  }
}
