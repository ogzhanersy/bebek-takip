import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/widgets/custom_card.dart';
import 'add_media_memory_screen.dart';
import 'add_note_memory_screen.dart';

class AddMemoryMainScreen extends StatelessWidget {
  const AddMemoryMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              gradient: themeProvider.homeBackgroundGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(context, themeProvider),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Welcome Section
                          _buildWelcomeSection(themeProvider),

                          const SizedBox(height: 24),

                          // Memory Types Section
                          _buildMemoryTypesSection(context, themeProvider),

                          const SizedBox(height: 24),

                          // Quick Tips Section
                          _buildQuickTipsSection(themeProvider),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: themeProvider.primaryColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              'Anı Ekle',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: themeProvider.cardForeground,
              ),
            ),
          ),
          Icon(Icons.add_circle, color: themeProvider.primaryColor, size: 24),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(ThemeProvider themeProvider) {
    return CustomCard(
      child: Column(
        children: [
          Icon(
            Icons.photo_library,
            size: 48,
            color: themeProvider.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Anılarınızı Kaydedin',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: themeProvider.cardForeground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bebeğinizin özel anlarını fotoğraf, video, not veya kilometre taşı olarak kaydedin',
            style: TextStyle(
              fontSize: 14,
              color: themeProvider.mutedForegroundColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryTypesSection(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Anı Türleri',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: themeProvider.cardForeground,
          ),
        ),
        const SizedBox(height: 16),

        // Photo/Video Memory
        _buildMemoryTypeCard(
          themeProvider,
          title: 'Fotoğraf veya Video Anısı',
          subtitle: 'Galeri veya kamera ile fotoğraf/video ekleyin',
          icon: Icons.photo_camera,
          color: Colors.blue,
          onTap: () => _navigateToScreen(context, const AddMediaMemoryScreen()),
        ),

        const SizedBox(height: 12),

        // Note Memory
        _buildMemoryTypeCard(
          themeProvider,
          title: 'Not Anısı',
          subtitle: 'Sadece metin ile anı oluşturun',
          icon: Icons.note,
          color: Colors.green,
          onTap: () => _navigateToScreen(context, const AddNoteMemoryScreen()),
        ),
      ],
    );
  }

  Widget _buildMemoryTypeCard(
    ThemeProvider themeProvider, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: CustomCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: themeProvider.cardForeground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: themeProvider.mutedForegroundColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: themeProvider.mutedForegroundColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTipsSection(ThemeProvider themeProvider) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                'Hızlı İpuçları',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.cardForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildTipItem(
            themeProvider,
            icon: Icons.photo_camera,
            text: 'Fotoğraflar otomatik olarak sıkıştırılır',
          ),
          _buildTipItem(
            themeProvider,
            icon: Icons.videocam,
            text: 'Videolar için yüksek kalite önerilir',
          ),
          _buildTipItem(
            themeProvider,
            icon: Icons.note,
            text: 'Notlar arama yapılabilir',
          ),
          _buildTipItem(
            themeProvider,
            icon: Icons.emoji_events,
            text: 'Kilometre taşları yaş hesaplaması yapar',
          ),
          _buildTipItem(
            themeProvider,
            icon: Icons.trending_up,
            text: 'Gelişim verileri grafiklerde görünür',
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(
    ThemeProvider themeProvider, {
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: themeProvider.mutedForegroundColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: themeProvider.mutedForegroundColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => screen));
  }
}
