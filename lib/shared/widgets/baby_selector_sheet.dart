import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/baby_model.dart';
import '../../shared/providers/baby_provider.dart';
import '../../shared/providers/theme_provider.dart';
import '../../features/babies/screens/add_baby_screen.dart';

class BabySelectorSheet extends StatelessWidget {
  const BabySelectorSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          decoration: BoxDecoration(
            color: themeProvider.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Consumer<BabyProvider>(
            builder: (context, babyProvider, _) {
              final babies = babyProvider.babies;
              final selectedBaby = babyProvider.selectedBaby;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: themeProvider.mutedForegroundColor.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title
                  Text(
                    'Bebek Seç',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: themeProvider.cardForeground,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Babies List
                  if (babies.isEmpty)
                    _buildEmptyState(context, themeProvider)
                  else
                    _buildBabiesList(
                      context,
                      babies,
                      selectedBaby,
                      babyProvider,
                      themeProvider,
                    ),

                  const SizedBox(height: 16),

                  // Add Baby Button
                  _buildAddBabyButton(context, themeProvider),

                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.babyBlueGradient,
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.child_care_outlined,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz bebek eklenmemiş',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: themeProvider.cardForeground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'İlk bebeğinizi ekleyerek takibe başlayın',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: themeProvider.mutedForegroundColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBabiesList(
    BuildContext context,
    List<Baby> babies,
    Baby? selectedBaby,
    BabyProvider babyProvider,
    ThemeProvider themeProvider,
  ) {
    return Column(
      children: babies
          .map(
            (baby) => _buildBabyItem(
              context,
              baby,
              selectedBaby,
              babyProvider,
              themeProvider,
            ),
          )
          .toList(),
    );
  }

  Widget _buildBabyItem(
    BuildContext context,
    Baby baby,
    Baby? selectedBaby,
    BabyProvider babyProvider,
    ThemeProvider themeProvider,
  ) {
    final isSelected = selectedBaby?.id == baby.id;
    final age = _calculateAge(baby.birthDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            babyProvider.setSelectedBaby(baby);
            Navigator.of(context).pop();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? themeProvider.primaryColor.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? themeProvider.primaryColor
                    : themeProvider.borderColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Baby Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: baby.gender == Gender.male
                          ? themeProvider.primaryColor.withValues(alpha: 0.3)
                          : Colors.pink.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(23),
                    child: baby.avatar != null && baby.avatar!.isNotEmpty
                        ? Image.network(
                            baby.avatar!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: baby.gender == Gender.male
                                      ? AppColors.babyBlueGradient
                                      : AppColors.babyPinkGradient,
                                ),
                                child: Icon(
                                  baby.gender == Gender.male
                                      ? Icons.male
                                      : Icons.female,
                                  color: Colors.white,
                                  size: 25,
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: baby.gender == Gender.male
                                      ? AppColors.babyBlueGradient
                                      : AppColors.babyPinkGradient,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: baby.gender == Gender.male
                                  ? AppColors.babyBlueGradient
                                  : AppColors.babyPinkGradient,
                            ),
                            child: Icon(
                              baby.gender == Gender.male
                                  ? Icons.male
                                  : Icons.female,
                              color: Colors.white,
                              size: 25,
                            ),
                          ),
                  ),
                ),

                const SizedBox(width: 16),

                // Baby Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        baby.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: themeProvider.cardForeground,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${baby.gender == Gender.male ? 'Erkek' : 'Kız'} • $age',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: themeProvider.mutedForegroundColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Selection Indicator
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: themeProvider.primaryColor,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddBabyButton(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddBabyScreen()),
          );
        },
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Yeni Bebek Ekle'),
        style: ElevatedButton.styleFrom(
          backgroundColor: themeProvider.primaryColor,
          foregroundColor: themeProvider.primaryForegroundColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  String _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    final difference = now.difference(birthDate);

    if (difference.inDays < 30) {
      return '${difference.inDays} günlük';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months aylık';
    } else {
      final years = (difference.inDays / 365).floor();
      final months = ((difference.inDays % 365) / 30).floor();
      if (months > 0) {
        return '$years yaş $months aylık';
      } else {
        return '$years yaşında';
      }
    }
  }
}
