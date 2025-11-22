import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/providers/theme_provider.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Scaffold(
          backgroundColor: themeProvider.backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: themeProvider.cardForeground,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Yardım ve Destek',
              style: TextStyle(
                color: themeProvider.cardForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeaderSection(themeProvider),
                const SizedBox(height: 32),

                // FAQ Section
                _buildFAQSection(themeProvider),
                const SizedBox(height: 32),

                // Contact Section
                _buildContactSection(themeProvider),
                const SizedBox(height: 32),

                // Footer
                _buildFooter(themeProvider),
              ],
            ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(ThemeProvider themeProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeProvider.primaryColor.withValues(alpha: 0.1),
            themeProvider.primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeProvider.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.help_outline, size: 48, color: themeProvider.primaryColor),
          const SizedBox(height: 16),
          Text(
            'Yardım ve Destek',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: themeProvider.cardForeground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Size nasıl yardımcı olabiliriz?',
            style: TextStyle(
              fontSize: 16,
              color: themeProvider.mutedForegroundColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection(ThemeProvider themeProvider) {
    final faqs = [
      {
        'question': 'Bebek bilgilerini nasıl ekleyebilirim?',
        'answer':
            'Ana sayfada "Bebeklerim" bölümüne gidin ve "Yeni Bebek Ekle" butonuna tıklayın. Bebeğinizin adı, doğum tarihi, cinsiyet, boy ve kilo bilgilerini girebilirsiniz.',
      },
      {
        'question': 'Beslenme kayıtlarını nasıl tutabilirim?',
        'answer':
            'Ana sayfada "Beslenme" kartına tıklayın ve beslenme türünü (emzirme/biberon), miktarını ve süresini kaydedin. Geçmiş tarihli kayıtlar da ekleyebilirsiniz.',
      },
      {
        'question': 'Anıları nasıl ekleyebilirim?',
        'answer':
            'Memories sayfasında "Anı Ekle" butonuna tıklayın. Fotoğraf, video veya not ekleyerek bebeğinizin özel anlarını kaydedebilirsiniz.',
      },
      {
        'question': 'Şifremi nasıl değiştirebilirim?',
        'answer':
            'Ayarlar > Profil Düzenle > Şifre Değiştir bölümünden mevcut şifrenizi girerek yeni şifrenizi belirleyebilirsiniz.',
      },
      {
        'question': 'Verilerim güvende mi?',
        'answer':
            'Evet, tüm verileriniz Supabase\'in güvenli altyapısında şifrelenmiş olarak saklanır. Gizlilik ayarlarınızdan veri toplama tercihlerinizi yönetebilirsiniz.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sık Sorulan Sorular',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: themeProvider.cardForeground,
          ),
        ),
        const SizedBox(height: 16),
        ...faqs.map(
          (faq) => _buildFAQItem(
            question: faq['question']!,
            answer: faq['answer']!,
            themeProvider: themeProvider,
          ),
        ),
      ],
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
    required ThemeProvider themeProvider,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeProvider.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: themeProvider.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.cardForeground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: themeProvider.mutedForegroundColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeProvider.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.contact_support,
                color: themeProvider.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'İletişim',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.cardForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Sorularınız için bizimle iletişime geçin:',
            style: TextStyle(
              fontSize: 14,
              color: themeProvider.mutedForegroundColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.email,
            label: 'E-posta',
            value: 'destek@bebektakip.com',
            onTap: () => _launchEmail('destek@bebektakip.com'),
            themeProvider: themeProvider,
          ),
          // Telefon ve Web Sitesi kaldırıldı
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    required ThemeProvider themeProvider,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: themeProvider.primaryColor),
            const SizedBox(width: 12),
            Text(
              '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: themeProvider.cardForeground,
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: themeProvider.primaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeProvider.borderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.favorite, color: Colors.red, size: 24),
          const SizedBox(height: 12),
          Text(
            'Bebeğinizin mutluluğu bizim için önemlidir',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeProvider.cardForeground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Herhangi bir sorunuz varsa, bizimle iletişime geçmekten çekinmeyin.',
            style: TextStyle(
              fontSize: 14,
              color: themeProvider.mutedForegroundColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  // Telefon ve web yönlendirmeleri kaldırıldı
}
