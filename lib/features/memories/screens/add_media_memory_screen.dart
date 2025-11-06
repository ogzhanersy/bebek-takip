import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/memory_model.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/providers/baby_provider.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../core/services/memory_service.dart';
import '../../../core/services/privacy_service.dart';

class AddMediaMemoryScreen extends StatefulWidget {
  const AddMediaMemoryScreen({super.key});

  @override
  State<AddMediaMemoryScreen> createState() => _AddMediaMemoryScreenState();
}

class _AddMediaMemoryScreenState extends State<AddMediaMemoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _selectedMedia;
  DateTime _selectedDate = DateTime.now();
  String _selectedMilestoneType = 'other';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _milestoneTypes = [
    {'id': 'first_step', 'name': 'İlk Adım', 'icon': Icons.directions_walk},
    {'id': 'first_word', 'name': 'İlk Kelime', 'icon': Icons.record_voice_over},
    {
      'id': 'first_tooth',
      'name': 'İlk Diş',
      'icon': Icons.sentiment_very_satisfied,
    },
    {
      'id': 'first_smile',
      'name': 'İlk Gülümseme',
      'icon': Icons.sentiment_satisfied,
    },
    {'id': 'first_crawl', 'name': 'İlk Emekleme', 'icon': Icons.pets},
    {'id': 'first_sit', 'name': 'İlk Oturma', 'icon': Icons.accessibility},
    {'id': 'first_clap', 'name': 'İlk Alkış', 'icon': Icons.pan_tool},
    {'id': 'first_wave', 'name': 'İlk El Sallama', 'icon': Icons.waving_hand},
    {
      'id': 'first_solid_food',
      'name': 'İlk Katı Gıda',
      'icon': Icons.restaurant,
    },
    {'id': 'first_bath', 'name': 'İlk Banyo', 'icon': Icons.bathtub},
    {
      'id': 'first_sleep_through',
      'name': 'Gece Boyunca Uyuma',
      'icon': Icons.bedtime,
    },
    {'id': 'other', 'name': 'Diğer', 'icon': Icons.star},
  ];

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
          body: Container(
            decoration: BoxDecoration(
              gradient: themeProvider.homeBackgroundGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Back Button Header - Transparent
                  Container(
                    decoration: const BoxDecoration(color: Colors.transparent),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
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
                          'Fotoğraf Anısı Ekle',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: themeProvider.cardForeground,
                              ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.photo_camera,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Column(
                      children: [
                        // Form Content
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Media Section
                                  _buildMediaSection(themeProvider),

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
                        _buildActionButtons(themeProvider),
                      ],
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

  Widget _buildMediaSection(ThemeProvider themeProvider) {
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
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Medya Seçimi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.cardForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_selectedMedia != null)
            _buildMediaPreview(themeProvider)
          else
            _buildMediaPlaceholder(themeProvider),
        ],
      ),
    );
  }

  Widget _buildMediaPreview(ThemeProvider themeProvider) {
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
            child: Image.file(_selectedMedia!, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectMedia,
                icon: Icon(Icons.edit, color: themeProvider.primaryColor),
                label: Text(
                  'Değiştir',
                  style: TextStyle(color: themeProvider.primaryColor),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: themeProvider.primaryColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedMedia = null;
                  });
                },
                icon: Icon(Icons.delete, color: Colors.red),
                label: Text('Kaldır', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMediaPlaceholder(ThemeProvider themeProvider) {
    return GestureDetector(
      onTap: _selectMedia,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: themeProvider.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: themeProvider.borderColor,
            style: BorderStyle.solid,
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
            const SizedBox(height: 16),
            Text(
              'Fotoğraf veya Video Seç',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: themeProvider.cardForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Galeri veya kamera ile medya ekleyin',
              style: TextStyle(
                fontSize: 14,
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

          // Milestone Type Dropdown
          DropdownButtonFormField<String>(
            value: _selectedMilestoneType,
            decoration: InputDecoration(
              labelText: 'Kilometre Taşı Türü',
              hintText: 'Bir kilometre taşı seçin (isteğe bağlı)',
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
            ),
            style: TextStyle(color: themeProvider.cardForeground),
            dropdownColor: themeProvider.cardBackground,
            items: _milestoneTypes.map((milestone) {
              return DropdownMenuItem<String>(
                value: milestone['id'],
                child: Row(
                  children: [
                    Icon(
                      milestone['icon'],
                      size: 20,
                      color: themeProvider.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      milestone['name'],
                      style: TextStyle(
                        fontSize: 14,
                        color: themeProvider.cardForeground,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedMilestoneType = value;
                });
              }
            },
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
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Açıklama',
              hintText: 'Bu anı hakkında detaylar yazın',
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
                border: Border.all(color: themeProvider.borderColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: themeProvider.primaryColor,
                    size: 20,
                  ),
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
                    color: themeProvider.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.cardBackground,
        border: Border(top: BorderSide(color: themeProvider.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: themeProvider.mutedForegroundColor,
                side: BorderSide(color: themeProvider.borderColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('İptal'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: CustomButton(
              text: _isLoading ? 'Kaydediliyor...' : 'Kaydet',
              onPressed: _isLoading ? null : _saveMemory,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectMedia() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickMedia(picker, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickMedia(picker, ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMedia(ImagePicker picker, ImageSource source) async {
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

      final XFile? media = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (media != null) {
        setState(() {
          _selectedMedia = File(media.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Medya seçilirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _saveMemory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir fotoğraf veya video seçin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final babyProvider = Provider.of<BabyProvider>(context, listen: false);
      final currentBaby = babyProvider.selectedBaby;
      if (currentBaby == null) {
        throw Exception('Aktif bebek bulunamadı');
      }

      // Always use photo type (no video support)
      final memoryType = MemoryType.photo;

      // Create memory
      final memory = Memory(
        babyId: currentBaby.id,
        type: memoryType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        memoryDate: _selectedDate,
        metadata: {
          'file_size': await _selectedMedia!.length(),
          'file_name': _selectedMedia!.path.split('/').last,
          'milestone_type': _selectedMilestoneType,
        },
      );

      // Save memory with media
      await MemoryService.createMemoryWithMedia(memory, _selectedMedia);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medya anısı başarıyla kaydedildi!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
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
