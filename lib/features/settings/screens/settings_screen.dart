import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/supabase_service.dart';
// import '../../../core/services/firebase_service.dart';
// import '../../../core/services/notification_service.dart';
// import '../../../core/services/onesignal_service.dart';  // Temporarily disabled
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/bottom_navigation.dart';
import '../../../shared/providers/theme_provider.dart';
// Removed duplicate language selector that used a separate provider/sheet
import 'profile_edit_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _showLogoutDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red, size: 24),
              const SizedBox(width: 12),
              const Text('Çıkış Yap'),
            ],
          ),
          content: const Text(
            'Hesabınızdan çıkış yapmak istediğinizden emin misiniz?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'İptal',
                style: TextStyle(
                  color: AppColors.mutedForeground,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleLogout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Çıkış Yap',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Sign out from Supabase
      await SupabaseService.signOut();

      // Wait a bit for auth state to update
      await Future.delayed(const Duration(milliseconds: 1000));

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Başarıyla çıkış yapıldı'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Force navigation to auth screen
      if (context.mounted) {
        // Use GoRouter to navigate to root (which will show AuthWrapper)
        context.go('/');
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çıkış yapılırken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToProfileEdit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProfileEditScreen(fromPage: 'settings'),
      ),
    );
  }

  // _showHelpSupportDialog kaldırıldı

  // _buildHelpSection kaldırıldı

  // İkinci Hakkında diyaloğu kaldırıldı

  void _showThemeSelector(BuildContext context, ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: themeProvider.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: themeProvider.mutedForegroundColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Tema Seçimi',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: themeProvider.cardForeground,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildThemeOption(
              context,
              themeProvider,
              AppThemeMode.light,
              Icons.light_mode,
              'Açık Tema',
              'Beyaz arka plan ve koyu metin',
            ),
            _buildThemeOption(
              context,
              themeProvider,
              AppThemeMode.dark,
              Icons.dark_mode,
              'Koyu Tema',
              'Koyu arka plan ve açık metin',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeProvider themeProvider,
    AppThemeMode theme,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final isSelected = themeProvider.currentTheme == theme;

    return GestureDetector(
      onTap: () {
        themeProvider.setTheme(theme);
        Navigator.of(context).pop();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? themeProvider.primaryColor.withValues(alpha: 0.1)
              : themeProvider.cardBackground,
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
            Icon(
              icon,
              color: isSelected
                  ? themeProvider.primaryColor
                  : themeProvider.mutedForegroundColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? themeProvider.primaryColor
                          : themeProvider.cardForeground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: themeProvider.mutedForegroundColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: themeProvider.primaryColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  // Dil seçimi iptal edildi

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.currentUser;

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: themeProvider.settingsBackgroundGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Back Button Header
                  Padding(
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
                          'Ayarlar',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // User Info Card
                          CustomCard(
                            padding: const EdgeInsets.all(16), // 16px iç boşluk
                            onTap: () {
                              _navigateToProfileEdit(context);
                            },
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: themeProvider.primaryColor
                                      .withValues(alpha: 0.2),
                                  backgroundImage: _getUserAvatarImage(user),
                                  child: _getUserAvatarImage(user) == null
                                      ? Icon(
                                          Icons.person,
                                          size: 40,
                                          color: themeProvider.primaryColor,
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  user?.userMetadata?['name'] ??
                                      user?.userMetadata?['full_name'] ??
                                      user?.email ??
                                      'Misafir Kullanıcı',
                                  style: Theme.of(context).textTheme.titleLarge,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Bebek Takip Uygulaması',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.mutedForeground,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16), // Alt boşluk
                          // Settings Options
                          CustomCard(
                            child: Column(
                              children: [
                                // Language Selection (single source of truth)

                                // OneSignal Test (Temporarily disabled)
                                /*
                                _buildSettingItem(
                                  context,
                                  icon: Icons.notifications_active_outlined,
                                  title: 'OneSignal Test',
                                  subtitle:
                                      'Push notification sistemini test et',
                                  onTap: () async {
                                    try {
                                      final currentUser =
                                          SupabaseService.currentUser;
                                      if (currentUser == null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Kullanıcı oturumu açmamış',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }

                                      // Send OneSignal test notification
                                      final success =
                                          await OneSignalService.sendTestNotification();

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            success
                                                ? 'OneSignal test bildirimi gönderildi!'
                                                : 'OneSignal test bildirimi gönderilemedi',
                                          ),
                                          backgroundColor: success
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('OneSignal hatası: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                ),

                                _buildSettingItem(
                                  context,
                                  icon: Icons.campaign_outlined,
                                  title: 'Kampanya Testi',
                                  subtitle:
                                      'Toplu bildirim testi (%50 indirim)',
                                  onTap: () async {
                                    try {
                                      final currentUser =
                                          SupabaseService.currentUser;
                                      if (currentUser == null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Kullanıcı oturumu açmamış',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }

                                      // Send campaign notification
                                      final success =
                                          await OneSignalService.sendCampaignNotification(
                                            title: '🎉 %50 İndirim!',
                                            message:
                                                'Bebek ürünlerinde büyük fırsat! Sadece bugün geçerli.',
                                            imageUrl:
                                                'https://via.placeholder.com/500x300/FF6B6B/FFFFFF?text=%50+İndirim',
                                            actionUrl:
                                                'https://example.com/campaign',
                                          );

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            success
                                                ? 'Kampanya bildirimi gönderildi!'
                                                : 'Kampanya bildirimi gönderilemedi',
                                          ),
                                          backgroundColor: success
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Kampanya hatası: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                ),
                                */
                                // Dil seçimi iptal edildi
                                _buildSettingItem(
                                  context,
                                  icon: Icons.color_lens_outlined,
                                  title: 'Tema',
                                  subtitle: themeProvider.getThemeDisplayName(),
                                  onTap: () => _showThemeSelector(
                                    context,
                                    themeProvider,
                                  ),
                                ),

                                const Divider(),

                                // Yedekleme özelliği iptal edildi
                                _buildSettingItem(
                                  context,
                                  icon: Icons.info_outline,
                                  title: 'Hakkında',
                                  subtitle: 'Uygulama bilgileri ve özellikler',
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AboutScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Support & About
                          CustomCard(
                            child: Column(
                              children: [
                                _buildSettingItem(
                                  context,
                                  icon: Icons.help_outline,
                                  title: 'Yardım & Destek',
                                  subtitle: 'SSS ve destek',
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const HelpSupportScreen(),
                                      ),
                                    );
                                  },
                                ),

                                // Alttaki ikinci Hakkında kaldırıldı
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Logout Button
                          if (user != null)
                            CustomCard(
                              child: Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.red.withValues(
                                          alpha: 0.3,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.logout,
                                          color: Colors.red,
                                          size: 32,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Çıkış Yap',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                color: Colors.red,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Hesabınızdan güvenli bir şekilde çıkış yapın',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color:
                                                    AppColors.mutedForeground,
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () =>
                                                _showLogoutDialog(context),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: const Text(
                                              'Çıkış Yap',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: const BottomNavigation(currentIndex: 4),
        );
      },
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        margin: const EdgeInsets.only(left: 8), // Sol boşluk
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(
        subtitle,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.mutedForeground),
      ),
      trailing: Container(
        margin: const EdgeInsets.only(right: 8), // Sağ boşluk
        child: Icon(Icons.chevron_right, color: AppColors.mutedForeground),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  // Kullanıcı avatar resmini düzeltilmiş URL ile al
  NetworkImage? _getUserAvatarImage(dynamic user) {
    final avatarUrl = user?.userMetadata?['avatar_url'];
    if (avatarUrl != null) {
      final fixedUrl = _fixAvatarUrl(avatarUrl);
      return NetworkImage(fixedUrl);
    }
    return null;
  }

  // Eski URL formatını yeni formata çevir
  String _fixAvatarUrl(String url) {
    // Eski format: .../avatars/user_id/profile/filename
    // Yeni format: .../avatars/profile/filename

    if (url.contains('/avatars/') && url.contains('/profile/')) {
      // URL'yi parçalara ayır
      final parts = url.split('/avatars/');
      if (parts.length == 2) {
        final afterAvatars = parts[1];
        final pathParts = afterAvatars.split('/');

        // Eğer user_id/profile/filename formatındaysa
        if (pathParts.length >= 3 && pathParts[1] == 'profile') {
          // user_id kısmını atla, sadece profile/filename al
          final newPath = 'profile/${pathParts.sublist(2).join('/')}';
          final newUrl = '${parts[0]}/avatars/$newPath';
          return newUrl;
        }
      }
    }

    return url; // Değişiklik gerekmiyorsa aynen döndür
  }
}
