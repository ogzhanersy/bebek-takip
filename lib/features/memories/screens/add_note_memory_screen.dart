import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/memory_model.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/providers/baby_provider.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../core/services/memory_service.dart';

class AddNoteMemoryScreen extends StatefulWidget {
  const AddNoteMemoryScreen({super.key});

  @override
  State<AddNoteMemoryScreen> createState() => _AddNoteMemoryScreenState();
}

class _AddNoteMemoryScreenState extends State<AddNoteMemoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

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
                          'Not Anısı Ekle',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: themeProvider.cardForeground,
                              ),
                        ),
                        const Spacer(),
                        Icon(Icons.note, color: AppColors.primary, size: 24),
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormSection(ThemeProvider themeProvider) {
    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Not Bilgileri',
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
              hintText: 'Bu not anısı için bir başlık yazın',
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
            maxLines: 6,
            decoration: InputDecoration(
              labelText: 'Not İçeriği *',
              hintText: 'Bu not anısının içeriğini yazın...',
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
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Not içeriği gereklidir';
              }
              return null;
            },
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
        type: MemoryType.note,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        memoryDate: _selectedDate,
        metadata: {
          'word_count': _descriptionController.text.trim().split(' ').length,
          'character_count': _descriptionController.text.trim().length,
        },
      );

      // Save memory
      await MemoryService.createMemory(memory);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not anısı başarıyla kaydedildi!'),
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
