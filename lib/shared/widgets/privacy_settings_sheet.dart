import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../core/services/privacy_service.dart';

class PrivacySettingsSheet extends StatefulWidget {
  const PrivacySettingsSheet({super.key});

  @override
  State<PrivacySettingsSheet> createState() => _PrivacySettingsSheetState();
}

class _PrivacySettingsSheetState extends State<PrivacySettingsSheet> {
  bool _dataCollectionEnabled = true;
  bool _analyticsEnabled = true;
  bool _crashReportingEnabled = true;
  bool _personalizedAdsEnabled = false;
  bool _photoAccessEnabled = true;
  bool _notificationEnabled = true;
  bool _dataSharingEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dataCollectionEnabled = prefs.getBool('data_collection_enabled') ?? true;
      _analyticsEnabled = prefs.getBool('analytics_enabled') ?? true;
      _crashReportingEnabled = prefs.getBool('crash_reporting_enabled') ?? true;
      _personalizedAdsEnabled =
          prefs.getBool('personalized_ads_enabled') ?? false;
      _photoAccessEnabled = prefs.getBool('photo_access_enabled') ?? true;
      _notificationEnabled = prefs.getBool('notification_enabled') ?? true;
      _dataSharingEnabled = prefs.getBool('data_sharing_enabled') ?? false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    // Save to PrivacyService which handles both storage and functionality
    await PrivacyService().updateSetting(key, value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ayar kaydedildi ve uygulandı'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          decoration: BoxDecoration(
            color: themeProvider.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: themeProvider.mutedForegroundColor.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: themeProvider.primaryColor.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.privacy_tip_outlined,
                          color: themeProvider.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Gizlilik Ayarları',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: themeProvider.cardForeground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Veri gizliliği ve güvenlik tercihlerinizi yönetin',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: themeProvider.mutedForegroundColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Privacy Settings List
                  Column(
                    children: [
                      // Data Collection
                      _buildPrivacyOption(
                        icon: Icons.data_usage,
                        title: 'Veri Toplama',
                        subtitle:
                            'Uygulama performansını iyileştirmek için veri toplama',
                        value: _dataCollectionEnabled,
                        onChanged: (value) {
                          setState(() {
                            _dataCollectionEnabled = value;
                          });
                          _saveSetting('data_collection_enabled', value);
                        },
                        themeProvider: themeProvider,
                      ),
                      const SizedBox(height: 12),

                      // Analytics
                      _buildPrivacyOption(
                        icon: Icons.analytics_outlined,
                        title: 'Analitik',
                        subtitle:
                            'Kullanım istatistikleri ve performans analizi',
                        value: _analyticsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _analyticsEnabled = value;
                          });
                          _saveSetting('analytics_enabled', value);
                        },
                        themeProvider: themeProvider,
                      ),
                      const SizedBox(height: 12),

                      // Crash Reporting
                      _buildPrivacyOption(
                        icon: Icons.bug_report_outlined,
                        title: 'Hata Raporlama',
                        subtitle: 'Uygulama hatalarını otomatik raporlama',
                        value: _crashReportingEnabled,
                        onChanged: (value) {
                          setState(() {
                            _crashReportingEnabled = value;
                          });
                          _saveSetting('crash_reporting_enabled', value);
                        },
                        themeProvider: themeProvider,
                      ),
                      const SizedBox(height: 12),

                      // Personalized Ads
                      _buildPrivacyOption(
                        icon: Icons.ads_click,
                        title: 'Kişiselleştirilmiş Reklamlar',
                        subtitle: 'İlgi alanlarınıza göre reklam gösterimi',
                        value: _personalizedAdsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _personalizedAdsEnabled = value;
                          });
                          _saveSetting('personalized_ads_enabled', value);
                        },
                        themeProvider: themeProvider,
                      ),
                      const SizedBox(height: 12),

                      // Photo Access
                      _buildPrivacyOption(
                        icon: Icons.photo_library_outlined,
                        title: 'Fotoğraf Erişimi',
                        subtitle: 'Galeri ve kamera erişimi',
                        value: _photoAccessEnabled,
                        onChanged: (value) {
                          setState(() {
                            _photoAccessEnabled = value;
                          });
                          _saveSetting('photo_access_enabled', value);
                        },
                        themeProvider: themeProvider,
                      ),
                      const SizedBox(height: 12),

                      // Notifications
                      _buildPrivacyOption(
                        icon: Icons.notifications_outlined,
                        title: 'Bildirimler',
                        subtitle: 'Push bildirimleri ve hatırlatmalar',
                        value: _notificationEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationEnabled = value;
                          });
                          _saveSetting('notification_enabled', value);
                        },
                        themeProvider: themeProvider,
                      ),
                      const SizedBox(height: 12),

                      // Data Sharing
                      _buildPrivacyOption(
                        icon: Icons.share_outlined,
                        title: 'Veri Paylaşımı',
                        subtitle: 'Üçüncü taraf hizmetlerle veri paylaşımı',
                        value: _dataSharingEnabled,
                        onChanged: (value) {
                          setState(() {
                            _dataSharingEnabled = value;
                          });
                          _saveSetting('data_sharing_enabled', value);
                        },
                        themeProvider: themeProvider,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: themeProvider.primaryColor,
                            side: BorderSide(color: themeProvider.primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Kapat'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Reset all settings to default
                            _resetToDefaults();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('Varsayılana Sıfırla'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrivacyOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ThemeProvider themeProvider,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeProvider.borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: themeProvider.primaryColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: themeProvider.cardForeground,
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: themeProvider.primaryColor,
            inactiveThumbColor: themeProvider.mutedForegroundColor,
            inactiveTrackColor: themeProvider.borderColor,
          ),
        ],
      ),
    );
  }

  Future<void> _resetToDefaults() async {
    // Reset using PrivacyService
    await PrivacyService().resetToDefaults();

    // Reload settings
    await _loadSettings();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ayarlar varsayılan değerlere sıfırlandı ve uygulandı'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
