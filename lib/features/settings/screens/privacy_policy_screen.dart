import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/providers/theme_provider.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
              'Gizlilik Politikası',
              style: TextStyle(
                color: themeProvider.cardForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeaderSection(themeProvider),
                const SizedBox(height: 32),

                // Last Updated
                _buildLastUpdatedSection(themeProvider),
                const SizedBox(height: 32),

                // Table of Contents
                _buildTableOfContents(themeProvider),
                const SizedBox(height: 32),

                // Privacy Policy Content
                _buildPolicyContent(themeProvider),
                const SizedBox(height: 32),

                // Contact Information
                _buildContactSection(themeProvider),
                const SizedBox(height: 32),

                // Footer
                _buildFooter(themeProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(ThemeProvider themeProvider) {
    return Container(
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
          Icon(
            Icons.privacy_tip_outlined,
            size: 48,
            color: themeProvider.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Bebek Takip Gizlilik Politikası',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: themeProvider.cardForeground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Verilerinizin güvenliği bizim için önemlidir',
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

  Widget _buildLastUpdatedSection(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeProvider.borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.update, color: themeProvider.primaryColor, size: 20),
          const SizedBox(width: 12),
          Text(
            'Son Güncelleme: 1 Ocak 2025',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: themeProvider.cardForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableOfContents(ThemeProvider themeProvider) {
    final sections = [
      '1. Toplanan Veriler',
      '2. Veri Kullanımı',
      '3. Veri Paylaşımı',
      '4. Veri Güvenliği',
      '5. Çocuk Gizliliği',
      '6. Kullanıcı Hakları',
      '7. Çerezler',
      '8. Değişiklikler',
      '9. İletişim',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'İçindekiler',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: themeProvider.cardForeground,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeProvider.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: themeProvider.borderColor),
          ),
          child: Column(
            children: sections
                .map(
                  (section) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: themeProvider.mutedForegroundColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          section,
                          style: TextStyle(color: themeProvider.cardForeground),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyContent(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPolicySection(
          title: '1. Toplanan Veriler',
          content: '''
Bebek Takip uygulaması, bebeğinizin gelişimini takip etmek ve size en iyi hizmeti sunmak için aşağıdaki verileri toplar:

• **Kişisel Bilgiler:** Ad, e-posta adresi, telefon numarası
• **Bebek Bilgileri:** İsim, doğum tarihi, cinsiyet, boy, kilo
• **Gelişim Verileri:** Beslenme, uyku, alt değişimi, ölçümler
• **Anılar:** Fotoğraflar, videolar, notlar
• **Cihaz Bilgileri:** Cihaz türü, işletim sistemi, uygulama versiyonu
• **Kullanım Verileri:** Uygulama içi etkileşimler, hata raporları

Bu veriler sadece uygulamanın temel işlevlerini yerine getirmek için gereklidir.
          ''',
          themeProvider: themeProvider,
        ),
        const SizedBox(height: 24),

        _buildPolicySection(
          title: '2. Veri Kullanımı',
          content: '''
Toplanan veriler aşağıdaki amaçlarla kullanılır:

• **Hizmet Sağlama:** Bebek takibi ve gelişim analizi
• **Kişiselleştirme:** Size özel öneriler ve hatırlatmalar
• **İyileştirme:** Uygulama performansı ve kullanıcı deneyimi
• **Güvenlik:** Hesap güvenliği ve dolandırıcılık önleme
• **Destek:** Teknik destek ve müşteri hizmetleri

Verileriniz hiçbir zaman üçüncü taraflarla satılmaz veya pazarlama amaçlı kullanılmaz.
          ''',
          themeProvider: themeProvider,
        ),
        const SizedBox(height: 24),

        _buildPolicySection(
          title: '3. Veri Paylaşımı',
          content: '''
Verileriniz aşağıdaki durumlar dışında üçüncü taraflarla paylaşılmaz:

• **Yasal Zorunluluk:** Mahkeme kararı veya yasal gereklilik
• **Güvenlik:** Güvenlik tehditlerinin önlenmesi
• **Hizmet Sağlayıcıları:** Supabase gibi güvenilir teknoloji ortakları
• **Kullanıcı Onayı:** Açık rızanızla belirtilen durumlar

Tüm veri paylaşımları GDPR ve KVKK uyumludur.
          ''',
          themeProvider: themeProvider,
        ),
        const SizedBox(height: 24),

        _buildPolicySection(
          title: '4. Veri Güvenliği',
          content: '''
Verilerinizin güvenliği için aşağıdaki önlemleri alıyoruz:

• **Şifreleme:** Tüm veriler end-to-end şifreleme ile korunur
• **Güvenli Sunucular:** Supabase'in güvenli altyapısı kullanılır
• **Erişim Kontrolü:** Sadece yetkili personel verilere erişebilir
• **Düzenli Güvenlik:** Güvenlik açıkları düzenli olarak kontrol edilir
• **Yedekleme:** Veriler güvenli şekilde yedeklenir

Veri ihlali durumunda 72 saat içinde kullanıcılar bilgilendirilir.
          ''',
          themeProvider: themeProvider,
        ),
        const SizedBox(height: 24),

        _buildPolicySection(
          title: '5. Çocuk Gizliliği',
          content: '''
13 yaş altı çocukların verileri özel koruma altındadır:

• **Ebeveyn Onayı:** Çocuk verileri için ebeveyn onayı gerekir
• **Sınırlı Toplama:** Sadece gerekli minimum veri toplanır
• **Güvenli Saklama:** Çocuk verileri özel güvenlik önlemleri ile korunur
• **Erişim Hakları:** Ebeveynler çocuk verilerine erişim talep edebilir
• **Silme Hakkı:** Çocuk verileri istendiğinde tamamen silinebilir

COPPA ve GDPR-K uyumlu çocuk koruma politikaları uygulanır.
          ''',
          themeProvider: themeProvider,
        ),
        const SizedBox(height: 24),

        _buildPolicySection(
          title: '6. Kullanıcı Hakları',
          content: '''
KVKK ve GDPR kapsamında aşağıdaki haklara sahipsiniz:

• **Bilgi Alma:** Hangi verilerinizin toplandığını öğrenme
• **Erişim:** Verilerinize erişim talep etme
• **Düzeltme:** Yanlış verilerin düzeltilmesini isteme
• **Silme:** Verilerinizin silinmesini talep etme
• **Taşınabilirlik:** Verilerinizi başka platforma aktarma
• **İtiraz:** Veri işlemeye itiraz etme
• **Şikayet:** Veri koruma otoritelerine şikayet etme

Bu haklarınızı kullanmak için bizimle iletişime geçebilirsiniz.
          ''',
          themeProvider: themeProvider,
        ),
        const SizedBox(height: 24),

        _buildPolicySection(
          title: '7. Çerezler',
          content: '''
Uygulamamız aşağıdaki çerez türlerini kullanır:

• **Zorunlu Çerezler:** Uygulamanın temel işlevleri için gerekli
• **Performans Çerezleri:** Uygulama performansını analiz etme
• **Fonksiyonel Çerezler:** Kullanıcı tercihlerini hatırlama
• **Analitik Çerezler:** Kullanım istatistikleri toplama

Çerez ayarlarınızı istediğiniz zaman değiştirebilirsiniz.
          ''',
          themeProvider: themeProvider,
        ),
        const SizedBox(height: 24),

        _buildPolicySection(
          title: '8. Değişiklikler',
          content: '''
Bu gizlilik politikası aşağıdaki durumlarda güncellenebilir:

• **Yasal Değişiklikler:** Yeni yasa ve düzenlemeler
• **Teknoloji Güncellemeleri:** Yeni özellik ve hizmetler
• **Güvenlik İyileştirmeleri:** Güvenlik önlemlerinin artırılması
• **Kullanıcı Geri Bildirimleri:** Kullanıcı talepleri ve önerileri

Önemli değişiklikler e-posta ve uygulama içi bildirim ile duyurulur.
          ''',
          themeProvider: themeProvider,
        ),
      ],
    );
  }

  Widget _buildPolicySection({
    required String title,
    required String content,
    required ThemeProvider themeProvider,
  }) {
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
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeProvider.cardForeground,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
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
                '9. İletişim',
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
            'Gizlilik politikası ile ilgili sorularınız için:',
            style: TextStyle(
              fontSize: 14,
              color: themeProvider.mutedForegroundColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.email,
            label: 'E-posta',
            value: 'privacy@babytracker.com',
            onTap: () => _launchEmail('privacy@babytracker.com'),
            themeProvider: themeProvider,
          ),
          const SizedBox(height: 8),
          _buildContactItem(
            icon: Icons.phone,
            label: 'Telefon',
            value: '+90 (212) 555-0123',
            onTap: () => _launchPhone('+902125550123'),
            themeProvider: themeProvider,
          ),
          const SizedBox(height: 8),
          _buildContactItem(
            icon: Icons.web,
            label: 'Web Sitesi',
            value: 'www.babytracker.com',
            onTap: () => _launchUrl('https://www.babytracker.com'),
            themeProvider: themeProvider,
          ),
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
            'Bebeğinizin güvenliği bizim için önemlidir',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeProvider.cardForeground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Bu gizlilik politikası, bebeğinizin ve ailenizin verilerinin güvenliğini sağlamak için tasarlanmıştır.',
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

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
