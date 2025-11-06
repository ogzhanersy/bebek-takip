import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import '../../../shared/models/memory_model.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../core/services/memory_service.dart';

class MemoryEditScreen extends StatefulWidget {
  final Memory memory;
  final VoidCallback? onMemoryUpdated;

  const MemoryEditScreen({
    super.key,
    required this.memory,
    this.onMemoryUpdated,
  });

  @override
  State<MemoryEditScreen> createState() => _MemoryEditScreenState();
}

class _MemoryEditScreenState extends State<MemoryEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late MemoryType _selectedType;
  File? _selectedMedia;
  bool _isLoading = false;
  bool _hasChanges = false;
  Timer? _autosaveTimer;
  bool _isAutosaving = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _titleController = TextEditingController(text: widget.memory.title);
    _descriptionController = TextEditingController(
      text: widget.memory.description ?? '',
    );
    _selectedDate = widget.memory.memoryDate;
    _selectedType = widget.memory.type;

    // Listen to text changes to track modifications
    _titleController.addListener(_onTextChanged);
    _descriptionController.addListener(_onTextChanged);

    // Load draft data if available
    _loadDraftData();
  }

  Future<void> _loadDraftData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftKey = 'memory_draft_${widget.memory.id}';
      final draftJson = prefs.getString(draftKey);

      if (draftJson != null) {
        final draftData = jsonDecode(draftJson) as Map<String, dynamic>;

        // Only load draft if it's newer than the current memory
        final draftUpdatedAt = DateTime.parse(draftData['updated_at']);
        if (draftUpdatedAt.isAfter(widget.memory.updatedAt)) {
          _titleController.text = draftData['title'] ?? widget.memory.title;
          _descriptionController.text =
              draftData['description'] ?? widget.memory.description ?? '';
          _selectedDate = DateTime.parse(draftData['memory_date']);
          _selectedType = MemoryType.values.firstWhere(
            (e) => e.toString().split('.').last == draftData['type'],
            orElse: () => widget.memory.type,
          );

          setState(() {
            _hasChanges = true;
          });
        }
      }
    } catch (e) {
      // If draft loading fails, continue with original data
    }
  }

  void _onTextChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
    _scheduleAutosave();
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(seconds: 3), () {
      if (_hasChanges && !_isLoading) {
        _performAutosave();
      }
    });
  }

  Future<void> _performAutosave() async {
    if (_isAutosaving || _isLoading) return;

    setState(() {
      _isAutosaving = true;
    });

    try {
      // Save draft to local storage
      final prefs = await SharedPreferences.getInstance();
      final draftData = {
        'memory_id': widget.memory.id,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'memory_date': _selectedDate.toIso8601String(),
        'type': _selectedType.toString().split('.').last,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await prefs.setString(
        'memory_draft_${widget.memory.id}',
        jsonEncode(draftData),
      );

      if (mounted) {
        setState(() {
          _hasChanges = false;
        });

        // Show subtle autosave indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                const Text('Otomatik kaydedildi'),
              ],
            ),
            backgroundColor: Colors.green.withValues(alpha: 0.1),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      // Autosave failed, but don't show error to user
      // Just keep the changes indicator
    } finally {
      if (mounted) {
        setState(() {
          _isAutosaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
                  // Header
                  _buildHeader(themeProvider),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Media Section
                          _buildMediaSection(themeProvider),

                          const SizedBox(height: 24),

                          // Form Section
                          _buildFormSection(themeProvider),

                          const SizedBox(height: 24),

                          // Type Selection
                          _buildTypeSection(themeProvider),

                          const SizedBox(height: 24),

                          // Date Selection
                          _buildDateSection(themeProvider),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  // Action Buttons
                  _buildActionButtons(themeProvider),
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
      decoration: const BoxDecoration(color: Colors.transparent),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _handleBack(),
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
          Expanded(
            child: Text(
              'Anı Düzenle',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: themeProvider.cardForeground,
              ),
            ),
          ),
          if (_hasChanges)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Değişiklikler',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (_isAutosaving)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Kaydediliyor...',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaSection(ThemeProvider themeProvider) {
    // Don't show media section for note type
    if (_selectedType == MemoryType.note) {
      return const SizedBox.shrink();
    }

    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Medya',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: themeProvider.cardForeground,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _selectMedia,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: themeProvider.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit,
                        size: 14,
                        color: themeProvider.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Değiştir',
                        style: TextStyle(
                          color: themeProvider.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Media Preview
          _buildMediaPreview(themeProvider),
        ],
      ),
    );
  }

  Widget _buildMediaPreview(ThemeProvider themeProvider) {
    if (_selectedMedia != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.file(_selectedMedia!, fit: BoxFit.cover),
        ),
      );
    } else if (widget.memory.mediaUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            widget.memory.mediaUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: themeProvider.cardBackground,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: themeProvider.cardBackground,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: 48,
                        color: themeProvider.mutedForegroundColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Medya yüklenemedi',
                        style: TextStyle(
                          color: themeProvider.mutedForegroundColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: themeProvider.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: themeProvider.borderColor,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getTypeIcon(_selectedType),
                size: 48,
                color: themeProvider.mutedForegroundColor,
              ),
              const SizedBox(height: 8),
              Text(
                'Medya Yok',
                style: TextStyle(color: themeProvider.mutedForegroundColor),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildFormSection(ThemeProvider themeProvider) {
    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Anı Bilgileri',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: themeProvider.cardForeground,
            ),
          ),
          const SizedBox(height: 16),

          // Title Field
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Başlık',
              labelStyle: TextStyle(color: themeProvider.mutedForegroundColor),
              hintText: 'Anı başlığını girin',
              hintStyle: TextStyle(color: themeProvider.mutedForegroundColor),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: themeProvider.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
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

          const SizedBox(height: 16),

          // Description Field
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Açıklama',
              labelStyle: TextStyle(color: themeProvider.mutedForegroundColor),
              hintText: 'Anı açıklamasını girin (isteğe bağlı)',
              hintStyle: TextStyle(color: themeProvider.mutedForegroundColor),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: themeProvider.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
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

  Widget _buildTypeSection(ThemeProvider themeProvider) {
    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Anı Türü',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: themeProvider.cardForeground,
            ),
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: MemoryType.values.map((type) {
              final isSelected = _selectedType == type;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedType = type;
                    _hasChanges = true;
                  });
                  _scheduleAutosave();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? themeProvider.primaryColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? themeProvider.primaryColor
                          : themeProvider.borderColor,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getTypeIcon(type),
                        size: 20,
                        color: isSelected
                            ? themeProvider.primaryColor
                            : themeProvider.mutedForegroundColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getTypeName(type),
                        style: TextStyle(
                          color: isSelected
                              ? themeProvider.primaryColor
                              : themeProvider.cardForeground,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: themeProvider.cardForeground,
            ),
          ),
          const SizedBox(height: 16),

          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: themeProvider.borderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: themeProvider.primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: TextStyle(
                      color: themeProvider.cardForeground,
                      fontSize: 16,
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
              onPressed: _isLoading ? null : _handleBack,
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

  IconData _getTypeIcon(MemoryType type) {
    switch (type) {
      case MemoryType.photo:
        return Icons.photo;
      case MemoryType.note:
        return Icons.note_alt;
      case MemoryType.milestone:
        return Icons.emoji_events;
      case MemoryType.development:
        return Icons.trending_up;
    }
  }

  String _getTypeName(MemoryType type) {
    switch (type) {
      case MemoryType.photo:
        return 'Fotoğraf';
      case MemoryType.note:
        return 'Not';
      case MemoryType.milestone:
        return 'Kilometre Taşı';
      case MemoryType.development:
        return 'Gelişim';
    }
  }

  Future<void> _selectMedia() async {
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
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 1920,
                  maxHeight: 1080,
                  imageQuality: 85,
                );
                if (image != null) {
                  setState(() {
                    _selectedMedia = File(image.path);
                    _hasChanges = true;
                  });
                  _scheduleAutosave();
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
                final XFile? image = await picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 1920,
                  maxHeight: 1080,
                  imageQuality: 85,
                );
                if (image != null) {
                  setState(() {
                    _selectedMedia = File(image.path);
                    _hasChanges = true;
                  });
                  _scheduleAutosave();
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
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: themeProvider.isDarkMode
                ? ColorScheme.dark(primary: themeProvider.primaryColor)
                : ColorScheme.light(primary: themeProvider.primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _hasChanges = true;
      });
      _scheduleAutosave();
    }
  }

  void _handleBack() {
    if (_hasChanges) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Değişiklikleri Kaydet'),
          content: const Text(
            'Yapılan değişiklikler kaydedilmedi. Çıkmak istediğinizden emin misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).pop();
              },
              child: const Text('Çık', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _saveMemory() async {
    // Validate form
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Başlık gereklidir'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update memory with new data
      final updatedMemory = widget.memory.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        memoryDate: _selectedDate,
        type: _selectedType,
        updatedAt: DateTime.now(),
      );

      // Save to Supabase
      await MemoryService.updateMemory(updatedMemory);

      // Clear draft after successful save
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('memory_draft_${widget.memory.id}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anı başarıyla güncellendi'),
            backgroundColor: Colors.green,
          ),
        );

        // Call callback to refresh memories list
        if (widget.onMemoryUpdated != null) {
          widget.onMemoryUpdated!();
        }

        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Anı güncellenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
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
