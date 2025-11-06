import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../shared/models/memory_model.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/providers/baby_provider.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../core/services/memory_service.dart';

class AddPhotoMemoryScreen extends StatefulWidget {
  const AddPhotoMemoryScreen({super.key});

  @override
  State<AddPhotoMemoryScreen> createState() => _AddPhotoMemoryScreenState();
}

class _AddPhotoMemoryScreenState extends State<AddPhotoMemoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _selectedImage;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, BabyProvider>(
      builder: (context, themeProvider, babyProvider, _) {
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
                  _buildHeader(themeProvider),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Photo Section
                            _buildPhotoSection(themeProvider),

                            const SizedBox(height: 24),

                            // Form Section
                            _buildFormSection(themeProvider),

                            const SizedBox(height: 24),

                            // Date Section
                            _buildDateSection(themeProvider),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Action Buttons
                  _buildActionButtons(themeProvider, babyProvider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeProvider themeProvider) {
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
              'Fotoğraf Anısı Ekle',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: themeProvider.cardForeground,
              ),
            ),
          ),
          Icon(Icons.photo_camera, color: themeProvider.primaryColor, size: 24),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(ThemeProvider themeProvider) {
    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_camera,
                color: themeProvider.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Fotoğraf',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.cardForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_selectedImage != null)
            _buildImagePreview(themeProvider)
          else
            _buildImagePlaceholder(themeProvider),
        ],
      ),
    );
  }

  Widget _buildImagePreview(ThemeProvider themeProvider) {
    return Column(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: themeProvider.borderColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(_selectedImage!, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Değiştir',
                variant: ButtonVariant.outline,
                icon: Icons.edit,
                onPressed: _selectImage,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'Kaldır',
                variant: ButtonVariant.destructive,
                icon: Icons.delete,
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder(ThemeProvider themeProvider) {
    return GestureDetector(
      onTap: _selectImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: themeProvider.inputColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: themeProvider.borderColor,
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 48,
              color: themeProvider.mutedForegroundColor,
            ),
            const SizedBox(height: 12),
            Text(
              'Fotoğraf Seç',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: themeProvider.mutedForegroundColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Galeri veya kamera ile fotoğraf ekle',
              style: TextStyle(
                fontSize: 12,
                color: themeProvider.mutedForegroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection(ThemeProvider themeProvider) {
    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Anı Bilgileri',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeProvider.cardForeground,
            ),
          ),
          const SizedBox(height: 20),

          // Title Field
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Başlık *',
              hintText: 'Bu anı için bir başlık yazın',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: themeProvider.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: themeProvider.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: themeProvider.primaryColor),
              ),
              prefixIcon: Icon(Icons.title, color: themeProvider.primaryColor),
            ),
            style: TextStyle(color: themeProvider.cardForeground),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Başlık gereklidir';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Description Field
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Açıklama',
              hintText: 'Bu anı hakkında detaylar yazın (isteğe bağlı)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: themeProvider.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: themeProvider.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: themeProvider.primaryColor),
              ),
              prefixIcon: Icon(
                Icons.description,
                color: themeProvider.primaryColor,
              ),
            ),
            style: TextStyle(color: themeProvider.cardForeground),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection(ThemeProvider themeProvider) {
    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tarih',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeProvider.cardForeground,
            ),
          ),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeProvider.inputColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: themeProvider.borderColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: themeProvider.primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: TextStyle(
                      fontSize: 16,
                      color: themeProvider.cardForeground,
                    ),
                  ),
                  const Spacer(),
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

  Widget _buildActionButtons(
    ThemeProvider themeProvider,
    BabyProvider babyProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.cardBackground,
        border: Border(top: BorderSide(color: themeProvider.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'İptal',
              variant: ButtonVariant.outline,
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CustomButton(
              text: 'Kaydet',
              isLoading: _isLoading,
              onPressed: _isLoading ? null : () => _saveMemory(babyProvider),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectImage() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Provider.of<ThemeProvider>(
            context,
            listen: false,
          ).cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Provider.of<ThemeProvider>(
                  context,
                  listen: false,
                ).mutedForegroundColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(
                Icons.photo_library,
                color: Provider.of<ThemeProvider>(
                  context,
                  listen: false,
                ).primaryColor,
              ),
              title: const Text('Galeriden Seç'),
              onTap: () async {
                Navigator.pop(context);
                final image = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (image != null) {
                  setState(() {
                    _selectedImage = File(image.path);
                  });
                }
              },
            ),
            ListTile(
              leading: Icon(
                Icons.camera_alt,
                color: Provider.of<ThemeProvider>(
                  context,
                  listen: false,
                ).primaryColor,
              ),
              title: const Text('Kamera ile Çek'),
              onTap: () async {
                Navigator.pop(context);
                final image = await picker.pickImage(
                  source: ImageSource.camera,
                );
                if (image != null) {
                  setState(() {
                    _selectedImage = File(image.path);
                  });
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                ? const ColorScheme.dark()
                : const ColorScheme.light(),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _saveMemory(BabyProvider babyProvider) async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir fotoğraf seçin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentBaby = babyProvider.selectedBaby;
      if (currentBaby == null) {
        throw Exception('Aktif bebek bulunamadı');
      }

      // Create memory
      final memory = Memory(
        babyId: currentBaby.id,
        type: MemoryType.photo,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        memoryDate: _selectedDate,
        metadata: {
          'file_size': await _selectedImage!.length(),
          'file_name': _selectedImage!.path.split('/').last,
        },
      );

      // Save memory with media
      await MemoryService.createMemoryWithMedia(memory, _selectedImage);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fotoğraf anısı başarıyla kaydedildi!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // true değeri ile geri dön
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
