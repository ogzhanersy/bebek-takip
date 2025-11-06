import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/providers/theme_provider.dart';

class SleepScreen extends StatelessWidget {
  const SleepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: themeProvider.sleepBackgroundGradient,
            ),
            child: SafeArea(
              child: Center(
                child: Text(
                  'Sleep Screen - Coming Soon',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
