import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/providers/baby_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSignUp = false;
  String? _errorMessage;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool _showPassword = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resim seçilirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadProfilePhoto() async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu açmamış');
      }

      final fileName =
          'profile_${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'profile/$fileName';

      await SupabaseService.storage
          .from('avatars')
          .upload(filePath, _profileImage!);

      final publicUrl = SupabaseService.storage
          .from('avatars')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Fotoğraf yüklenirken hata oluştu: $e');
    }
  }

  String _getUserFriendlyErrorMessage(dynamic error) {
    // Convert to string first to check all possible formats
    final errorString = error.toString().toLowerCase();

    // Check for invalid credentials FIRST (most common login error)
    // This catches: "AuthApiException (message: Invalid login credentials, ... code: invalid_credentials)"
    if (errorString.contains('invalid login credentials') ||
        errorString.contains('invalid_credentials') ||
        errorString.contains('code: invalid_credentials') ||
        (errorString.contains('authapiexception') &&
            (errorString.contains('invalid') ||
                errorString.contains('credentials'))) ||
        errorString.contains('wrong password') ||
        errorString.contains('incorrect password')) {
      return 'E-posta adresi veya şifre hatalı. Lütfen kontrol edin.';
    }

    // Check if it's a Supabase AuthException with message property
    if (error is AuthException) {
      final message = error.message.toLowerCase();

      if (message.contains('invalid login credentials') ||
          message.contains('invalid_credentials')) {
        return 'E-posta adresi veya şifre hatalı. Lütfen kontrol edin.';
      }

      if (message.contains('email not confirmed') ||
          message.contains('email_not_confirmed')) {
        return 'E-posta adresinizi doğrulamamışsınız. Lütfen e-postanızı kontrol edin.';
      }

      if (message.contains('user not found') ||
          message.contains('email not found')) {
        return 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı.';
      }

      if (message.contains('email already registered') ||
          message.contains('user already registered') ||
          message.contains('already registered')) {
        return 'Bu e-posta adresi ile zaten bir hesap var. Giriş yapmayı deneyin.';
      }

      if (message.contains('password') && message.contains('weak')) {
        return 'Şifre çok zayıf. Daha güçlü bir şifre seçin.';
      }

      if (message.contains('email') &&
          (message.contains('invalid') || message.contains('format'))) {
        return 'Geçerli bir e-posta adresi girin.';
      }
    }

    // Network/Connection Errors
    if (errorString.contains('socketfailed') ||
        errorString.contains('host lookup') ||
        errorString.contains('no address associated') ||
        errorString.contains('network is unreachable') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('authretryablefetchexception')) {
      return 'İnternet bağlantınızı kontrol edin. Sunucuya bağlanılamıyor.';
    }

    // Other Auth Errors
    if (errorString.contains('user not found') ||
        errorString.contains('email not found')) {
      return 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı.';
    }

    if (errorString.contains('email already registered') ||
        errorString.contains('user already registered') ||
        errorString.contains('already registered')) {
      return 'Bu e-posta adresi ile zaten bir hesap var. Giriş yapmayı deneyin.';
    }

    // Generic error - try to extract useful info
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return 'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.';
    }

    if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return 'Yetkiniz yok. Lütfen giriş bilgilerinizi kontrol edin.';
    }

    // Default user-friendly message - hide all technical details
    return 'Bir hata oluştu. Lütfen bilgilerinizi kontrol edip tekrar deneyin.';
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        await SupabaseService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Update user metadata with name and profile image
        Map<String, dynamic> userData = {
          'name': _nameController.text.trim(),
          'full_name': _nameController.text.trim(),
        };

        // Upload profile image if selected
        if (_profileImage != null) {
          try {
            final avatarUrl = await _uploadProfilePhoto();
            if (avatarUrl != null) {
              userData['avatar_url'] = avatarUrl;
            }
          } catch (e) {
            debugPrint('Profile image upload failed: $e');
            // Continue without profile image
          }
        }

        await SupabaseService.client.auth.updateUser(
          UserAttributes(data: userData),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kayıt başarılı! E-postanızı kontrol edin.'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() => _isSignUp = false);
        }
      } else {
        await SupabaseService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Refresh babies after login
        if (mounted) {
          await context.read<BabyProvider>().refreshBabies();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getUserFriendlyErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: themeProvider.settingsBackgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 100),
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 8,
                    shadowColor: themeProvider.isDarkMode
                        ? Colors.black.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: themeProvider.cardBackground,
                        border: Border.all(color: themeProvider.borderColor),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Header Icon
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFE1BEE7), // Soft mor
                                      Color(0xFFF8BBD9), // Soft pembe
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.favorite,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Title
                              Text(
                                _isSignUp
                                    ? 'Hesap Oluştur'
                                    : 'Tekrar Hoş Geldiniz',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: themeProvider.cardForeground,
                                    ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 8),

                              // Subtitle
                              Text(
                                _isSignUp
                                    ? 'Bebeğinizin gelişimini takip edin'
                                    : 'Bebek takip hesabınıza giriş yapın',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: themeProvider.mutedForegroundColor,
                                    ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 32),

                              // Profile Image (only for sign up)
                              if (_isSignUp) ...[
                                Center(
                                  child: GestureDetector(
                                    onTap: _pickProfileImage,
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                        border: Border.all(
                                          color: AppColors.primary,
                                          width: 2,
                                        ),
                                      ),
                                      child: _profileImage != null
                                          ? ClipOval(
                                              child: Image.file(
                                                _profileImage!,
                                                fit: BoxFit.cover,
                                                width: 100,
                                                height: 100,
                                              ),
                                            )
                                          : Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.camera_alt_outlined,
                                                  color: AppColors.primary,
                                                  size: 32,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Profil Resmi',
                                                  style: TextStyle(
                                                    color: AppColors.primary,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Name Field (only for sign up)
                              if (_isSignUp) ...[
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'İsim Soyisim',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: themeProvider.cardForeground,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _nameController,
                                      decoration: InputDecoration(
                                        hintText: 'Adınızı ve soyadınızı girin',
                                        prefixIcon: const Icon(
                                          Icons.person_outlined,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                        border: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(12),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: const BorderRadius.all(
                                            Radius.circular(12),
                                          ),
                                          borderSide: BorderSide(
                                            color: themeProvider.borderColor,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: const BorderRadius.all(
                                            Radius.circular(12),
                                          ),
                                          borderSide: BorderSide(
                                            color: themeProvider.primaryColor,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'İsim soyisim gerekli';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Email Field
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'E-posta',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: themeProvider.cardForeground,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _emailController,
                                    decoration: InputDecoration(
                                      hintText: 'ornek@email.com',
                                      prefixIcon: const Icon(
                                        Icons.email_outlined,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                      border: const OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(12),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                          Radius.circular(12),
                                        ),
                                        borderSide: BorderSide(
                                          color: themeProvider.borderColor,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                          Radius.circular(12),
                                        ),
                                        borderSide: BorderSide(
                                          color: themeProvider.primaryColor,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'E-posta adresi gerekli';
                                      }
                                      if (!value.contains('@')) {
                                        return 'Geçerli bir e-posta adresi girin';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Password Field
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Şifre',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: themeProvider.cardForeground,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _passwordController,
                                    decoration: InputDecoration(
                                      hintText: 'Şifreniz',
                                      prefixIcon: const Icon(
                                        Icons.lock_outlined,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _showPassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _showPassword = !_showPassword;
                                          });
                                        },
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                      border: const OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(12),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(12),
                                        ),
                                        borderSide: BorderSide(
                                          color: themeProvider.borderColor,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(12),
                                        ),
                                        borderSide: BorderSide(
                                          color: themeProvider.primaryColor,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    obscureText: !_showPassword,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Şifre gerekli';
                                      }
                                      if (value.length < 6) {
                                        return 'Şifre en az 6 karakter olmalı';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),

                              if (_errorMessage != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.red),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 8),

                              // Şifremi Unuttum Link
                              if (!_isSignUp)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      context.go('/forgot-password');
                                    },
                                    child: Text(
                                      'Şifremi unuttum',
                                      style: TextStyle(
                                        color: themeProvider.primaryColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 8),

                              // Submit Button
                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(
                                        0xFFC8D8EA,
                                      ), // rgb(200, 216, 234) - Soft mavi
                                      Color(
                                        0xFFE9C7D4,
                                      ), // rgb(233, 199, 212) - Soft pembe
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFC8D8EA,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleAuth,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : Text(
                                          _isSignUp
                                              ? 'Hesap Oluştur'
                                              : 'Giriş Yap',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Divider
                              Divider(
                                color: themeProvider.borderColor,
                                thickness: 1,
                              ),

                              const SizedBox(height: 16),

                              // Toggle Auth Mode
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isSignUp = !_isSignUp;
                                    _errorMessage = null;
                                  });
                                },
                                child: Text(
                                  _isSignUp
                                      ? 'Zaten hesabınız var mı? Giriş yapın'
                                      : 'Hesabınız yok mu? Kayıt olun',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
