import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class VaccinationScreen extends StatelessWidget {
  const VaccinationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.homeBackgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: Text(
              'Vaccination Screen - Coming Soon',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
        ),
      ),
    );
  }
}
