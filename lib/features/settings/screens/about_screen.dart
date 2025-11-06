import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/widgets/custom_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Scaffold(
          backgroundColor: themeProvider.backgroundColor,
          appBar: AppBar(
            title: const Text('Hakkında'),
            backgroundColor: themeProvider.backgroundColor,
            foregroundColor: themeProvider.cardForeground,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Info Card
                CustomCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // App Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE1BEE7), Color(0xFFF8BBD9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.child_care,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bebek Takip',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: themeProvider.cardForeground,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Versiyon 1.0.2',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: themeProvider.mutedForegroundColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bebeğinizin gelişimini takip etmek ve önemli anları kaydetmek için tasarlanmış kapsamlı bir uygulama.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: themeProvider.cardForeground,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Features Card
                CustomCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.star_outline,
                            color: themeProvider.primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Özellikler',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: themeProvider.cardForeground,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureItem(
                        context,
                        themeProvider,
                        Icons.bedtime,
                        'Uyku Takibi',
                        'Bebeğinizin uyku düzenini takip edin',
                      ),
                      _buildFeatureItem(
                        context,
                        themeProvider,
                        Icons.restaurant,
                        'Beslenme Kayıtları',
                        'Emzirme ve mama kayıtlarını tutun',
                      ),
                      _buildFeatureItem(
                        context,
                        themeProvider,
                        Icons.child_care,
                        'Alt Değişimi',
                        'Alt değişimi zamanlarını kaydedin',
                      ),
                      _buildFeatureItem(
                        context,
                        themeProvider,
                        Icons.straighten,
                        'Gelişim Takibi',
                        'Kilo, boy ve baş çevresi ölçümleri',
                      ),
                      _buildFeatureItem(
                        context,
                        themeProvider,
                        Icons.photo_camera,
                        'Anılar',
                        'Özel anları fotoğraf ve notlarla kaydedin',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Contact Card
                CustomCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.contact_support_outlined,
                            color: themeProvider.primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'İletişim',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: themeProvider.cardForeground,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildContactItem(
                        context,
                        themeProvider,
                        Icons.email_outlined,
                        'E-posta',
                        'destek@bebektakip.com',
                        'mailto:destek@bebektakip.com',
                      ),
                      // Web sitesi kaldırıldı
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Legal Card
                CustomCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.gavel_outlined,
                            color: themeProvider.primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Yasal Bilgiler',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: themeProvider.cardForeground,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.privacy_tip_outlined,
                          color: themeProvider.mutedForegroundColor,
                        ),
                        title: Text(
                          'Gizlilik Politikası',
                          style: TextStyle(color: themeProvider.cardForeground),
                        ),
                        onTap: () {
                          // Navigate to privacy policy
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.description_outlined,
                          color: themeProvider.mutedForegroundColor,
                        ),
                        title: Text(
                          'Kullanım Koşulları',
                          style: TextStyle(color: themeProvider.cardForeground),
                        ),
                        onTap: () {
                          // Navigate to terms of service
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Copyright
                Center(
                  child: Text(
                    '© 2024 Bebek Takip. Tüm hakları saklıdır.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: themeProvider.mutedForegroundColor,
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

  Widget _buildFeatureItem(
    BuildContext context,
    ThemeProvider themeProvider,
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: themeProvider.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: themeProvider.cardForeground,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: themeProvider.mutedForegroundColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context,
    ThemeProvider themeProvider,
    IconData icon,
    String title,
    String value,
    String url,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final uri = Uri.parse(url);
          final launched = await canLaunchUrl(uri) && await launchUrl(uri);
          if (!launched) {
            await Clipboard.setData(ClipboardData(text: value));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Adres panoya kopyalandı')),
              );
            }
          }
        },
        onLongPress: () async {
          await Clipboard.setData(ClipboardData(text: value));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Adres panoya kopyalandı')),
            );
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Icon(icon, color: themeProvider.primaryColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: themeProvider.cardForeground,
                      ),
                    ),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: themeProvider.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.open_in_new,
                  color: themeProvider.mutedForegroundColor,
                  size: 16,
                ),
                tooltip: 'Uygulamada aç',
                onPressed: () async {
                  final uri = Uri.parse(url);
                  final launched =
                      await canLaunchUrl(uri) &&
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                  if (!launched) {
                    await Clipboard.setData(ClipboardData(text: value));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Adres panoya kopyalandı'),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
