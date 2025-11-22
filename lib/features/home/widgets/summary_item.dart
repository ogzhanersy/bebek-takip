import 'package:flutter/material.dart';

class SummaryItem extends StatelessWidget {
  final dynamic icon; // IconData or String (emoji)
  final Color iconColor;
  final String label;
  final String value;
  final String subtext;

  const SummaryItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        icon is IconData
            ? Icon(icon, color: iconColor, size: 24)
            : Text(
                icon as String,
                style: TextStyle(fontSize: 24),
              ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        Text(
          subtext,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
