import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/services/supabase_service.dart';
import '../../../core/services/privacy_service.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/widgets/change_password_sheet.dart';
import '../../../shared/widgets/privacy_settings_sheet.dart';
import '../../../core/config/supabase_config.dart';
// import 'help_support_screen.dart'; // moved to Settings

class ProfileEditScreen extends StatefulWidget {
  final String? fromPage;

  const ProfileEditScreen({super.key, this.fromPage});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();

  bool _isLoading = false;
  File? _profilePhoto;
  String? _currentAvatarUrl;
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupAnimations();
    _setupPhoneFormatting();
  }

  void _setupPhoneFormatting() {
    _phoneController.addListener(() {
      final text = _phoneController.text;
      final cleanText = text.replaceAll(RegExp(r'[^\d]'), '');

      // Only allow up to 11 digits
      if (cleanText.length <= 11) {
        String formattedText = '';
        if (cleanText.isNotEmpty) {
          if (cleanText.startsWith('0')) {
            formattedText = cleanText;
            if (cleanText.length > 4) {
              formattedText =
                  '${cleanText.substring(0, 4)} ${cleanText.substring(4)}';
            }
            if (cleanText.length > 7) {
              formattedText =
                  '${cleanText.substring(0, 4)} ${cleanText.substring(4, 7)} ${cleanText.substring(7)}';
            }
            if (cleanText.length > 9) {
              formattedText =
                  '${cleanText.substring(0, 4)} ${cleanText.substring(4, 7)} ${cleanText.substring(7, 9)} ${cleanText.substring(9)}';
            }
          } else {
            formattedText = cleanText;
          }
        }

        if (formattedText != text) {
          _phoneController.value = _phoneController.value.copyWith(
            text: formattedText,
            selection: TextSelection.collapsed(offset: formattedText.length),
          );
        }
      } else {
        // If more than 11 digits, truncate to 11 digits and reformat
        final truncatedCleanText = cleanText.substring(0, 11);
        String formattedText = '';
        if (truncatedCleanText.isNotEmpty) {
          if (truncatedCleanText.startsWith('0')) {
            formattedText = truncatedCleanText;
            if (truncatedCleanText.length > 4) {
              formattedText =
                  '${truncatedCleanText.substring(0, 4)} ${truncatedCleanText.substring(4)}';
            }
            if (truncatedCleanText.length > 7) {
              formattedText =
                  '${truncatedCleanText.substring(0, 4)} ${truncatedCleanText.substring(4, 7)} ${truncatedCleanText.substring(7)}';
            }
            if (truncatedCleanText.length > 9) {
              formattedText =
                  '${truncatedCleanText.substring(0, 4)} ${truncatedCleanText.substring(4, 7)} ${truncatedCleanText.substring(7, 9)} ${truncatedCleanText.substring(9)}';
            }
          } else {
            formattedText = truncatedCleanText;
          }
        }

        _phoneController.value = _phoneController.value.copyWith(
          text: formattedText,
          selection: TextSelection.collapsed(offset: formattedText.length),
        );
      }
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  void _initializeData() async {
    final user = SupabaseService.currentUser;
    if (user != null) {
      _nameController.text = user.userMetadata?['name'] ?? '';
      _emailController.text = user.email ?? '';
      _phoneController.text = user.userMetadata?['phone'] ?? '';
      _birthDateController.text = user.userMetadata?['birth_date'] ?? '';

      // Avatar URL'sini düzelt
      String? avatarUrl = user.userMetadata?['avatar_url'];
      if (avatarUrl != null) {
        _currentAvatarUrl = _fixAvatarUrl(avatarUrl);
      }

      // Debug: Avatar URL'sini konsola yazdır

      // Test için hardcoded URL (Supabase'de gördüğünüz URL'yi buraya yapıştırın)
      // _currentAvatarUrl =
      //     'https://cnhtcvwseywsirxzgdht.supabase.co/storage/v1/object/public/avatars/profile/profile_2ffc32f8-367d-405c-8f0e-3a91ad1c9c91_1759086453725.jpg';

      // Kullanıcı verilerini yeniden yükle
      final updatedUser = await SupabaseService.client.auth.getUser();
      if (updatedUser.user != null) {
        String? updatedAvatarUrl =
            updatedUser.user!.userMetadata?['avatar_url'];
        if (updatedAvatarUrl != null) {
          _currentAvatarUrl = _fixAvatarUrl(updatedAvatarUrl);
        }
        setState(() {}); // UI'yi güncelle
      }
    }
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    try {
      // Check if photo access is enabled
      if (!PrivacyService().isFeatureEnabled('photo_access')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Fotoğraf erişimi gizlilik ayarlarında devre dışı bırakılmış',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profilePhoto = File(image.path);
        });

        // Haptic feedback
        // Haptics.vibrate(HapticsType.light);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil fotoğrafı seçildi'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fotoğraf seçilirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _uploadProfilePhoto() async {
    try {
      // Check if photo access is enabled
      if (!PrivacyService().isFeatureEnabled('photo_access')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Fotoğraf erişimi gizlilik ayarlarında devre dışı bırakılmış',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return null;
      }

      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu açmamış');
      }

      final fileName =
          'profile_${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      // Supabase'deki gerçek dosya yapısına uygun: profile/ klasörüne direkt yükle
      final filePath = 'profile/$fileName';

      await SupabaseService.storage
          .from('avatars')
          .upload(filePath, _profilePhoto!);

      final publicUrl = SupabaseService.storage
          .from('avatars')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Fotoğraf yüklenirken hata oluştu: $e');
    }
  }

  Future<void> _selectBirthDate() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 365 * 25),
      ), // 25 yaş
      firstDate: DateTime.now().subtract(
        const Duration(days: 365 * 100),
      ), // 100 yaş
      lastDate: DateTime.now().subtract(
        const Duration(days: 365 * 13),
      ), // 13 yaş
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: themeProvider.isDarkMode
                ? ColorScheme.dark(
                    primary: themeProvider.primaryColor,
                    onPrimary: Colors.white,
                    surface: themeProvider.cardBackground,
                    onSurface: themeProvider.cardForeground,
                    background: themeProvider.backgroundColor,
                    onBackground: themeProvider.cardForeground,
                  )
                : ColorScheme.light(
                    primary: themeProvider.primaryColor,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: themeProvider.cardForeground,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _birthDateController.text =
            '${pickedDate.day.toString().padLeft(2, '0')}/'
            '${pickedDate.month.toString().padLeft(2, '0')}/'
            '${pickedDate.year}';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu açmamış');
      }

      // Supabase'de kullanıcı profil bilgilerini güncelle
      await SupabaseService.client.auth.updateUser(
        UserAttributes(
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : null,
          data: {
            'name': _nameController.text.trim(),
            'full_name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'birth_date': _birthDateController.text.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Profil fotoğrafını yükle (eğer seçildiyse)
      String? avatarUrl;
      if (_profilePhoto != null) {
        try {
          avatarUrl = await _uploadProfilePhoto();

          // Profil fotoğrafı URL'sini kullanıcı metadata'sına ekle
          await SupabaseService.client.auth.updateUser(
            UserAttributes(
              data: {
                'avatar_url': avatarUrl,
                'updated_at': DateTime.now().toIso8601String(),
              },
            ),
          );
        } catch (photoError) {
          // Fotoğraf yükleme hatası - sadece uyarı ver, profil güncellemesini durdurma
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Profil fotoğrafı yüklenemedi: $photoError'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil başarıyla güncellendi'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Animasyonlu geri dönüş
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          // Hangi sayfadan geldiğine göre yönlendirme yap
          if (widget.fromPage == 'settings') {
            Navigator.of(context).pop(); // Ayarlar sayfasına geri dön
          } else {
            context.go('/'); // Ana sayfaya git
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil güncellenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
                  // Header - Ana sayfa ile aynı stil
                  Container(
                    decoration: const BoxDecoration(color: Colors.transparent),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            // Hangi sayfadan geldiğine göre geri dön
                            if (widget.fromPage == 'settings') {
                              Navigator.of(context).pop();
                            } else {
                              context.go('/');
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios,
                              color: themeProvider.primaryColor,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Profil Düzenle',
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
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 16),

                              // Profile Picture Section
                              _buildHeroProfileSection(themeProvider),

                              const SizedBox(height: 24),

                              // Personal Information Section
                              _buildPersonalInfoSection(themeProvider),

                              const SizedBox(height: 16),

                              // Additional Information Section
                              _buildAdditionalInfoSection(themeProvider),

                              const SizedBox(height: 16),

                              // Security Section
                              _buildSecuritySection(themeProvider),

                              const SizedBox(height: 24),

                              // Save Button
                              _buildSaveButton(themeProvider),

                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
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

  Widget _buildHeroProfileSection(ThemeProvider themeProvider) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickProfilePhoto,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: themeProvider.primaryColor.withValues(
                alpha: 0.1,
              ),
              child: _profilePhoto != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.file(
                        _profilePhoto!,
                        fit: BoxFit.cover,
                        width: 100,
                        height: 100,
                      ),
                    )
                  : _currentAvatarUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.network(
                        _currentAvatarUrl!,
                        fit: BoxFit.cover,
                        width: 100,
                        height: 100,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 100,
                            height: 100,
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            size: 50,
                            color: themeProvider.primaryColor,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 50,
                      color: themeProvider.primaryColor,
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Profil Fotoğrafı',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: themeProvider.cardForeground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fotoğraf eklemek için dokunun',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: themeProvider.mutedForegroundColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection(ThemeProvider themeProvider) {
    return CustomCard(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: themeProvider.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Kişisel Bilgiler',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: themeProvider.cardForeground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Name Field
            _buildTextField(
              controller: _nameController,
              label: 'Ad Soyad',
              hint: 'Adınızı ve soyadınızı girin',
              icon: Icons.person_outline,
              themeProvider: themeProvider,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ad soyad gereklidir';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Email Field
            _buildTextField(
              controller: _emailController,
              label: 'E-posta',
              hint: 'E-posta adresinizi girin',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              themeProvider: themeProvider,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'E-posta gereklidir';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return 'Geçerli bir e-posta adresi girin';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoSection(ThemeProvider themeProvider) {
    return CustomCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeProvider.secondaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: themeProvider.secondaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Ek Bilgiler',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: themeProvider.cardForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Phone Field
          _buildTextField(
            controller: _phoneController,
            label: 'Telefon',
            hint: '05XX XXX XX XX',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            themeProvider: themeProvider,
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                // Remove all non-digit characters for validation
                final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');

                // Check if it starts with 0
                if (!cleanValue.startsWith('0')) {
                  return 'Telefon numarası 0 ile başlamalıdır';
                }

                // Check if it's exactly 11 digits
                if (cleanValue.length != 11) {
                  return 'Telefon numarası 11 haneli olmalıdır';
                }

                // Check if it's a valid Turkish mobile number format
                if (!RegExp(r'^05[0-9]{9}$').hasMatch(cleanValue)) {
                  return 'Geçerli bir Türkiye cep telefonu numarası girin (05XX XXX XX XX)';
                }
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Birth Date Field
          GestureDetector(
            onTap: _selectBirthDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: themeProvider.borderColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: themeProvider.mutedForegroundColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Doğum Tarihi',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: themeProvider.mutedForegroundColor,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _birthDateController.text.isEmpty
                              ? 'Doğum tarihinizi seçin'
                              : _birthDateController.text,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: _birthDateController.text.isEmpty
                                    ? themeProvider.mutedForegroundColor
                                    : themeProvider.cardForeground,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: themeProvider.mutedForegroundColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(ThemeProvider themeProvider) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ayarlar',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: themeProvider.cardForeground,
            ),
          ),
          const SizedBox(height: 20),

          // Change Password Option
          _buildSecurityOption(
            icon: Icons.lock_outline,
            title: 'Şifre Değiştir',
            subtitle: 'Hesap güvenliğinizi artırın',
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const ChangePasswordSheet(),
              );
            },
            themeProvider: themeProvider,
          ),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.go('/forgot-password'),
              child: Text(
                'Şifremi unuttum',
                style: TextStyle(
                  color: themeProvider.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Privacy Settings Option
          _buildSecurityOption(
            icon: Icons.privacy_tip_outlined,
            title: 'Gizlilik Ayarları',
            subtitle: 'Fotoğraf erişimi ve veri gizliliği ayarları',
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const PrivacySettingsSheet(),
              );
            },
            themeProvider: themeProvider,
          ),

          const SizedBox(height: 12),

          // Yardım ve Destek profil sayfasından kaldırıldı (Ayarlar'a taşındı)
          const SizedBox(height: 24),

          // Danger Zone
          Text(
            'Hesap İşlemleri',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _confirmAndDeleteAccount,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.delete_forever, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Hesabı Sil',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeProvider themeProvider,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: themeProvider.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: themeProvider.borderColor),
        ),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: themeProvider.mutedForegroundColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: themeProvider.mutedForegroundColor,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndDeleteAccount() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: themeProvider.cardBackground,
        title: Row(
          children: const [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('Hesabı Sil'),
          ],
        ),
        content: const Text(
          'Bu işlem geri alınamaz. Hesabınız ve ona bağlı tüm bebek/veriler silinecek. Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Vazgeç',
              style: TextStyle(color: themeProvider.primaryColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Evet, Sil',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Get the access token for the Edge Function call
      final session = SupabaseService.client.auth.currentSession;
      if (session == null) {
        throw Exception('Oturum bilgisi bulunamadı');
      }

      // Call the Edge Function to delete user and all data
      final supabaseUrl = SupabaseConfig.supabaseUrl;
      final functionUrl = '$supabaseUrl/functions/v1/delete-user';

      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
          'apikey': SupabaseConfig.supabaseAnonKey,
        },
        body: jsonEncode({}),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Hesap silme başarısız');
      }

      // Sign out user after successful deletion
      await SupabaseService.client.auth.signOut();

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hesap ve tüm veriler tamamen silindi.'),
          backgroundColor: Colors.red,
        ),
      );
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hesap silme hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ThemeProvider themeProvider,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: themeProvider.cardForeground,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: themeProvider.primaryColor),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: themeProvider.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: themeProvider.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildSaveButton(ThemeProvider themeProvider) {
    return CustomButton(
      onPressed: _isLoading ? null : _saveProfile,
      text: _isLoading ? 'Kaydediliyor...' : 'Değişiklikleri Kaydet',
      isLoading: _isLoading,
    );
  }
}
