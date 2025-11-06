import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/privacy_service.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/providers/baby_provider.dart';
import '../../../shared/models/baby_model.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../core/services/growth_target_service.dart';

class EditBabyScreen extends StatefulWidget {
  final Baby baby;

  const EditBabyScreen({super.key, required this.baby});

  @override
  State<EditBabyScreen> createState() => _EditBabyScreenState();
}

class _EditBabyScreenState extends State<EditBabyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightMinCtrl = TextEditingController();
  final _weightMaxCtrl = TextEditingController();
  final _heightMinCtrl = TextEditingController();
  final _heightMaxCtrl = TextEditingController();

  late DateTime _birthDate;
  late Gender _selectedGender;
  bool _isLoading = false;
  File? _babyPhoto;
  String? _currentBabyAvatarUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _nameController.text = widget.baby.name;
    _weightController.text = widget.baby.weight != '0'
        ? widget.baby.weight
        : '';
    _heightController.text = widget.baby.height != '0'
        ? widget.baby.height
        : '';
    _birthDate = widget.baby.birthDate;
    _selectedGender = widget.baby.gender;
    _currentBabyAvatarUrl = widget.baby.avatar;
    _loadGrowthTargets();
  }

  Future<void> _loadGrowthTargets() async {
    try {
      final t = await GrowthTargetService.getTargets(widget.baby.id);
      if (t != null && mounted) {
        setState(() {
          _weightMinCtrl.text = t.weightMinKg?.toStringAsFixed(1) ?? '';
          _weightMaxCtrl.text = t.weightMaxKg?.toStringAsFixed(1) ?? '';
          _heightMinCtrl.text = t.heightMinCm?.toStringAsFixed(1) ?? '';
          _heightMaxCtrl.text = t.heightMaxCm?.toStringAsFixed(1) ?? '';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _pickBabyPhoto() async {
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

  Future<void> _updateBaby() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Capture provider before async gaps to avoid using BuildContext across awaits
      final babyProvider = context.read<BabyProvider>();
      String? avatarUrl = widget.baby.avatar; // Mevcut avatar'ı koru

      // Upload new photo if selected
      if (_babyPhoto != null) {
        avatarUrl = await _uploadBabyPhoto();
      }

      final updatedBaby = Baby(
        id: widget.baby.id, // Mevcut ID'yi koru
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
        createdAt: widget.baby.createdAt, // Mevcut oluşturma tarihini koru
      );

      await babyProvider.updateBaby(updatedBaby);

      // Upsert growth targets
      final g = GrowthTargets(
        babyId: widget.baby.id,
        weightMinKg: _weightMinCtrl.text.isEmpty ? null : double.tryParse(_weightMinCtrl.text),
        weightMaxKg: _weightMaxCtrl.text.isEmpty ? null : double.tryParse(_weightMaxCtrl.text),
        heightMinCm: _heightMinCtrl.text.isEmpty ? null : double.tryParse(_heightMinCtrl.text),
        heightMaxCm: _heightMaxCtrl.text.isEmpty ? null : double.tryParse(_heightMaxCtrl.text),
      );
      await GrowthTargetService.upsertTargets(g);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bebek bilgileri başarıyla güncellendi!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/babies');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bebek güncellenirken hata oluştu: $e'),
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

      final fileName =
          'baby_${widget.baby.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      // Bebek fotoğrafları için ayrı klasör
      final filePath = 'babies/$fileName';

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
                          onTap: () => context.go('/babies'),
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
                          'Bebek Düzenle',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
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
                                        : _currentBabyAvatarUrl != null
                                        ? ClipOval(
                                            child: Image.network(
                                              _currentBabyAvatarUrl!,
                                              fit: BoxFit.cover,
                                              width: 80,
                                              height: 80,
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) {
                                                  return child;
                                                }
                                                return SizedBox(
                                                  width: 80,
                                                  height: 80,
                                                  child: Center(
                                                    child: CircularProgressIndicator(
                                                      value:
                                                          loadingProgress
                                                                  .expectedTotalBytes !=
                                                              null
                                                          ? loadingProgress
                                                                    .cumulativeBytesLoaded /
                                                                loadingProgress
                                                                    .expectedTotalBytes!
                                                          : null,
                                                    ),
                                                  ),
                                                );
                                              },
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Icon(
                                                      _selectedGender ==
                                                              Gender.male
                                                          ? Icons.male
                                                          : Icons.female,
                                                      size: 40,
                                                      color: Colors.white,
                                                    );
                                                  },
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
                                  'Bebek Bilgilerini Düzenle',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Bebeğinizin bilgilerini güncelleyin',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.mutedForeground,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Değiştirmek isterseniz fotoğrafa dokunun',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.mutedForeground,
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
                                              color: Colors.black,
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
                                                : AppColors.primary,
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
                                              color: AppColors.border,
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
                                                  ? const Color(0xFFE91E63)
                                                  : AppColors.primary,
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
                                              color: Colors.black,
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
                                              color: AppColors.border,
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
                                                    : AppColors.primary,
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
                                                color:
                                                    AppColors.mutedForeground,
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
                                          color: Colors.black,
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
                                                  ? AppColors.primary
                                                        .withValues(alpha: 0.1)
                                                  : Colors.transparent,
                                              border: Border.all(
                                                color:
                                                    _selectedGender ==
                                                        Gender.male
                                                    ? AppColors.primary
                                                    : AppColors.border,
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
                                                      ? AppColors.primary
                                                      : AppColors
                                                            .mutedForeground,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Erkek',
                                                  style: TextStyle(
                                                    color:
                                                        _selectedGender ==
                                                            Gender.male
                                                        ? AppColors.primary
                                                        : AppColors
                                                              .mutedForeground,
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
                                                    : AppColors.border,
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
                                                    color: Colors.black,
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
                                                      : AppColors.primary,
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
                                                        color: AppColors.border,
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
                                                            : AppColors.primary,
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
                                                    color: Colors.black,
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
                                                      : AppColors.primary,
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
                                                        color: AppColors.border,
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
                                                            : AppColors.primary,
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

                                  // Growth Targets
                                  Text(
                                    'Gelişim Hedefleri',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _weightMinCtrl,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Kilo min (kg)',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _weightMaxCtrl,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Kilo max (kg)',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _heightMinCtrl,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Boy min (cm)',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _heightMaxCtrl,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Boy max (cm)',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 24),

                                  // Update Button
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
                                                      : AppColors.primary)
                                                  .withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : _updateBaby,
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
                                                  ? 'Güncelleniyor...'
                                                  : 'Değişiklikleri Kaydet',
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
