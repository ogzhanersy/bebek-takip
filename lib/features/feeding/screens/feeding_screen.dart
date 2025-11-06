import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/providers/theme_provider.dart';

class FeedingScreen extends StatelessWidget {
  const FeedingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: themeProvider.feedingBackgroundGradient,
            ),
            child: SafeArea(
              child: Center(
                child: Text(
                  'Feeding Screen - Coming Soon',
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
