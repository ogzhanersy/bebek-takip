import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/providers/baby_provider.dart';
import '../../../shared/models/baby_model.dart';
import '../../../shared/providers/theme_provider.dart';

class AddBabyScreen extends StatefulWidget {
  const AddBabyScreen({super.key});

  @override
  State<AddBabyScreen> createState() => _AddBabyScreenState();
}

class _AddBabyScreenState extends State<AddBabyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  DateTime _birthDate = DateTime.now();
  Gender _selectedGender = Gender.male;
  bool _isLoading = false;
  File? _babyPhoto;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _pickBabyPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _babyPhoto = File(image.path);
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

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime.now().subtract(
        const Duration(days: 365 * 5),
      ), // 5 yıl öncesi
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.foreground,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _saveBaby() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Capture provider before async gaps to avoid using BuildContext synchronously warning
      final babyProvider = context.read<BabyProvider>();
      String? avatarUrl;

      // Upload photo if selected
      if (_babyPhoto != null) {
        avatarUrl = await _uploadBabyPhoto();
      }

      final baby = Baby(
        name: _nameController.text.trim(),
        birthDate: _birthDate,
        gender: _selectedGender,
        weight: _weightController.text.trim().isEmpty
            ? '0'
            : _weightController.text.trim(),
        height: _heightController.text.trim().isEmpty
            ? '0'
            : _heightController.text.trim(),
        avatar: avatarUrl,
      );

      await babyProvider.addBaby(baby);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bebek başarıyla eklendi!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bebek eklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String> _uploadBabyPhoto() async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu açmamış');
      }

      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '${currentUser.id}/$fileName';

      await SupabaseService.storage
          .from('avatars')
          .upload(filePath, _babyPhoto!);

      final publicUrl = SupabaseService.storage
          .from('avatars')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Fotoğraf yüklenirken hata oluştu: $e');
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
                  // Header - Transparent
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
                              color: themeProvider.primaryColor,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Bebek Ekle',
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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),

                          // Header Card
                          CustomCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: _pickBabyPhoto,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      gradient: _selectedGender == Gender.male
                                          ? AppColors.babyBlueGradient
                                          : AppColors.babyPinkGradient,
                                      borderRadius: BorderRadius.circular(40),
                                    ),
                                    child: _babyPhoto != null
                                        ? ClipOval(
                                            child: Image.file(
                                              _babyPhoto!,
                                              fit: BoxFit.cover,
                                              width: 80,
                                              height: 80,
                                            ),
                                          )
                                        : Icon(
                                            _selectedGender == Gender.male
                                                ? Icons.male
                                                : Icons.female,
                                            size: 40,
                                            color: Colors.white,
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Yeni Bebek Ekle',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: themeProvider.cardForeground,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Bebeğinizin bilgilerini girin',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color:
                                            themeProvider.mutedForegroundColor,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Değiştirmek isterseniz fotoğrafa dokunun',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color:
                                            themeProvider.mutedForegroundColor,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Form
                          CustomCard(
                            padding: const EdgeInsets.all(20),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Name Field
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Bebek Adı',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color:
                                                  themeProvider.cardForeground,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _nameController,
                                        decoration: InputDecoration(
                                          hintText: 'Bebeğinizin adını girin',
                                          prefixIcon: Icon(
                                            Icons.child_care_outlined,
                                            color:
                                                _selectedGender == Gender.female
                                                ? Colors.pink
                                                : themeProvider.primaryColor,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 16,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: themeProvider.borderColor,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color:
                                                  _selectedGender ==
                                                      Gender.female
                                                  ? Colors.pink
                                                  : themeProvider.primaryColor,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Bebek adı gereklidir';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 20),

                                  // Birth Date Field
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Doğum Tarihi',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color:
                                                  themeProvider.cardForeground,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: _selectBirthDate,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: themeProvider.borderColor,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today,
                                                color:
                                                    _selectedGender ==
                                                        Gender.female
                                                    ? Colors.pink
                                                    : themeProvider
                                                          .primaryColor,
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                '${_birthDate.day}/${_birthDate.month}/${_birthDate.year}',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodyLarge,
                                              ),
                                              const Spacer(),
                                              Icon(
                                                Icons.arrow_drop_down,
                                                color: themeProvider
                                                    .mutedForegroundColor,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 20),

                                  // Gender Selection
                                  Text(
                                    'Cinsiyet',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: themeProvider.cardForeground,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(
                                            () => _selectedGender = Gender.male,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  _selectedGender == Gender.male
                                                  ? themeProvider.primaryColor
                                                        .withValues(alpha: 0.1)
                                                  : Colors.transparent,
                                              border: Border.all(
                                                color:
                                                    _selectedGender ==
                                                        Gender.male
                                                    ? themeProvider.primaryColor
                                                    : themeProvider.borderColor,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.male,
                                                  color:
                                                      _selectedGender ==
                                                          Gender.male
                                                      ? themeProvider
                                                            .primaryColor
                                                      : themeProvider
                                                            .mutedForegroundColor,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Erkek',
                                                  style: TextStyle(
                                                    color:
                                                        _selectedGender ==
                                                            Gender.male
                                                        ? themeProvider
                                                              .primaryColor
                                                        : themeProvider
                                                              .mutedForegroundColor,
                                                    fontWeight:
                                                        _selectedGender ==
                                                            Gender.male
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(
                                            () =>
                                                _selectedGender = Gender.female,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  _selectedGender ==
                                                      Gender.female
                                                  ? Colors.pink.withValues(
                                                      alpha: 0.1,
                                                    )
                                                  : Colors.transparent,
                                              border: Border.all(
                                                color:
                                                    _selectedGender ==
                                                        Gender.female
                                                    ? Colors.pink
                                                    : themeProvider.borderColor,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.female,
                                                  color:
                                                      _selectedGender ==
                                                          Gender.female
                                                      ? Colors.pink
                                                      : AppColors
                                                            .mutedForeground,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Kız',
                                                  style: TextStyle(
                                                    color:
                                                        _selectedGender ==
                                                            Gender.female
                                                        ? Colors.pink
                                                        : AppColors
                                                              .mutedForeground,
                                                    fontWeight:
                                                        _selectedGender ==
                                                            Gender.female
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 20),

                                  // Weight and Height Fields
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Güncel Ağırlık (kg)',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: themeProvider
                                                        .cardForeground,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                            const SizedBox(height: 8),
                                            TextFormField(
                                              controller: _weightController,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                hintText: '3.2',
                                                prefixIcon: Icon(
                                                  Icons.monitor_weight_outlined,
                                                  color:
                                                      _selectedGender ==
                                                          Gender.female
                                                      ? Colors.pink
                                                      : themeProvider
                                                            .primaryColor,
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 16,
                                                    ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color: themeProvider
                                                            .borderColor,
                                                      ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color:
                                                            _selectedGender ==
                                                                Gender.female
                                                            ? Colors.pink
                                                            : themeProvider
                                                                  .primaryColor,
                                                        width: 2,
                                                      ),
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Güncel Boy (cm)',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: themeProvider
                                                        .cardForeground,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                            const SizedBox(height: 8),
                                            TextFormField(
                                              controller: _heightController,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                hintText: '50',
                                                prefixIcon: Icon(
                                                  Icons.height,
                                                  color:
                                                      _selectedGender ==
                                                          Gender.female
                                                      ? Colors.pink
                                                      : themeProvider
                                                            .primaryColor,
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 16,
                                                    ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color: themeProvider
                                                            .borderColor,
                                                      ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color:
                                                            _selectedGender ==
                                                                Gender.female
                                                            ? Colors.pink
                                                            : themeProvider
                                                                  .primaryColor,
                                                        width: 2,
                                                      ),
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 24),

                                  // Save Button
                                  Container(
                                    width: double.infinity,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: _selectedGender == Gender.female
                                          ? const LinearGradient(
                                              colors: [
                                                Color(0xFFF29DC1), // #f29dc1
                                                Color(0xFFFCE1F9), // #fce1f9
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : const LinearGradient(
                                              colors: [
                                                Color(0xFF1976D2), // Blue 700
                                                Color(0xFF42A5F5), // Blue 400
                                                Color(0xFF90CAF9), // Blue 200
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              (_selectedGender == Gender.female
                                                      ? Colors.pink
                                                      : themeProvider
                                                            .primaryColor)
                                                  .withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _saveBaby,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            )
                                          : Text(
                                              _isLoading
                                                  ? 'Kaydediliyor...'
                                                  : 'Bebeği Kaydet',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
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
        );
      },
    );
  }
}
