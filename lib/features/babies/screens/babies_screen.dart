import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/bottom_navigation.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/no_baby_warning.dart';
import '../../../shared/providers/baby_provider.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/models/baby_model.dart';
import '../../../core/services/ad_service.dart';
import 'add_baby_screen.dart';

class BabiesScreen extends StatelessWidget {
  const BabiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: themeProvider.homeBackgroundGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Back Button Header - Transparent
                  Container(
                    decoration: const BoxDecoration(color: Colors.transparent),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.go('/'),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Bebeklerim',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: themeProvider.cardForeground,
                              ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Consumer<BabyProvider>(
                      builder: (context, babyProvider, _) {
                        final babies = babyProvider.babies;

                        if (babies.isEmpty) {
                          return Center(
                            child: SingleChildScrollView(
                              child: NoBabyWarning(
                                title: 'Henüz Kayıtlı Bebek Yok',
                                message:
                                    'Bebek takibine başlamak için önce bir bebek eklemeniz gerekiyor.',
                                buttonText: 'Bebek Ekle',
                                onPressed: () => context.go('/add-baby'),
                              ),
                            ),
                          );
                        }

                        return _buildBabiesList(context, babies);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: const BottomNavigation(currentIndex: 1),
        );
      },
    );
  }

  Widget _buildBabiesList(BuildContext context, List<Baby> babies) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add Baby Button
          CustomCard(
            padding: const EdgeInsets.all(20),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AddBabyScreen()),
              );
            },
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppColors.babyBlueGradient,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, _) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Yeni Bebek Ekle',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: themeProvider.cardForeground,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Bebeğinizi ekleyerek takibe başlayın',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: themeProvider.mutedForegroundColor,
                                    ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    return Icon(
                      Icons.arrow_forward_ios,
                      color: themeProvider.mutedForegroundColor,
                      size: 16,
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Babies List
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return Text(
                'Bebeklerim (${babies.length})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: themeProvider.cardForeground,
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          ...babies.map((baby) => _buildBabyCard(context, baby)),

          const SizedBox(height: 24),

          // Banner Ad
          const Center(child: BannerAdWidget()),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBabyCard(BuildContext context, Baby baby) {
    final age = _calculateAge(baby.birthDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: CustomCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Baby Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: baby.gender == Gender.male
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : Colors.pink.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: baby.avatar != null && baby.avatar!.isNotEmpty
                    ? Image.network(
                        baby.avatar!,
                        width: 60,
                        height: 60,
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
                              size: 30,
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
                          size: 30,
                        ),
                      ),
              ),
            ),

            const SizedBox(width: 16),

            // Baby Info
            Expanded(
              child: Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return Column(
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
                      if (baby.weight != '0' || baby.height != '0') ...[
                        const SizedBox(height: 4),
                        Text(
                          '${baby.weight != '0' ? '${baby.weight} kg' : ''}${baby.weight != '0' && baby.height != '0' ? ' • ' : ''}${baby.height != '0' ? '${baby.height} cm' : ''}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: themeProvider.mutedForegroundColor,
                              ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),

            // Menu Button
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: themeProvider.mutedForegroundColor,
                    size: 24,
                  ),
                  onSelected: (value) =>
                      _handleMenuAction(context, value, baby),
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: themeProvider.primaryColor),
                          const SizedBox(width: 8),
                          Text('Düzenle'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Sil'),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action, Baby baby) {
    switch (action) {
      case 'edit':
        _editBaby(context, baby);
        break;
      case 'delete':
        _deleteBaby(context, baby);
        break;
    }
  }

  void _editBaby(BuildContext context, Baby baby) {
    context.go('/edit-baby/${baby.id}');
  }

  void _deleteBaby(BuildContext context, Baby baby) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bebeği Sil'),
          content: Text(
            '${baby.name} adlı bebeği silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _confirmDeleteBaby(context, baby);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteBaby(BuildContext context, Baby baby) async {
    try {
      final babyProvider = Provider.of<BabyProvider>(context, listen: false);
      await babyProvider.deleteBaby(baby.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${baby.name} başarıyla silindi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bebek silinirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
