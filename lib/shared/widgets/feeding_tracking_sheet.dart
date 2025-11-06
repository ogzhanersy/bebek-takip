import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/providers/baby_provider.dart';
import '../../shared/providers/theme_provider.dart';
import '../../core/services/feeding_service.dart';
import '../../shared/models/feeding_model.dart';
import '../../core/services/sync_service.dart';

class FeedingTrackingSheet extends StatefulWidget {
  final VoidCallback? onFeedingSaved;
  final Feeding? feedingToEdit; // Edit modu için

  const FeedingTrackingSheet({
    super.key,
    this.onFeedingSaved,
    this.feedingToEdit,
  });

  @override
  State<FeedingTrackingSheet> createState() => _FeedingTrackingSheetState();
}

class _FeedingTrackingSheetState extends State<FeedingTrackingSheet> {
  final _notesController = TextEditingController();
  final _amountController = TextEditingController();

  FeedingType _selectedType = FeedingType.bottle;
  String? _selectedSide; // left/right for breastfeeding
  bool _isLoading = false;
  bool _showNotes = false;
  DateTime _selectedDateTime = DateTime.now();
  bool _hasSelectedDateTime = false;

  @override
  void initState() {
    super.initState();

    // Edit modunda mevcut veriyi yükle
    if (widget.feedingToEdit != null) {
      final feeding = widget.feedingToEdit!;
      _selectedType = feeding.type;
      _selectedSide = feeding.side;
      _selectedDateTime = feeding.startTime;
      _hasSelectedDateTime = true;

      if (feeding.amount != null) {
        _amountController.text = feeding.amount.toString();
      }
      if (feeding.notes != null) {
        _notesController.text = feeding.notes!;
        _showNotes = true;
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final firstDate = DateTime.now().subtract(const Duration(days: 30));
    final lastDate = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _hasSelectedDateTime = true;
        });
      }
    }
  }

  Future<void> _saveFeeding() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final babyProvider = context.read<BabyProvider>();
      final currentBaby = babyProvider.selectedBaby;

      if (currentBaby == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lütfen önce bir bebek seçin'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (currentBaby.id.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Bebek ID\'si geçersiz. Lütfen bebek seçimini kontrol edin.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final feeding = Feeding(
        id: widget
            .feedingToEdit
            ?.id, // Remove ?? '' to let UUID generate automatically
        babyId: currentBaby.id,
        type: _selectedType,
        amount: _amountController.text.isNotEmpty
            ? int.tryParse(_amountController.text)
            : null,
        side: _selectedSide,
        notes: _showNotes && _notesController.text.isNotEmpty
            ? _notesController.text.trim()
            : null,
        startTime: _hasSelectedDateTime ? _selectedDateTime : DateTime.now(),
      );

      if (widget.feedingToEdit != null) {
        // Edit modunda - mevcut kaydı güncelle
        await FeedingService.updateFeeding(feeding);
      } else {
        // Yeni kayıt - çevrimiçi/çevrimdışı oluştur
        if (await SyncService.isOnline()) {
          await FeedingService.createFeeding(feeding);
        } else {
          await SyncService.enqueue({
            'type': 'create',
            'table': 'feeding_records',
            'payload': feeding.toJson(),
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.feedingToEdit != null
                  ? 'Beslenme kaydı güncellendi'
                  : 'Beslenme kaydedildi',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Call callback to refresh parent screen
        widget.onFeedingSaved?.call();
        // Close bottom sheet
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İşlem sırasında hata oluştu: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          decoration: BoxDecoration(
            color: themeProvider.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: themeProvider.mutedForegroundColor.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: AppColors.babyPinkGradient,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.child_care,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Beslenme Kaydet',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: themeProvider.cardForeground,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bebeğinizin beslenme bilgilerini kaydedin',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: themeProvider.mutedForegroundColor,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Feeding Type Selection
              Text(
                'Beslenme Türü',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: themeProvider.cardForeground,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeButton(
                      'Biberon',
                      Icons.local_drink,
                      FeedingType.bottle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeButton(
                      'Emzirme',
                      Icons.favorite,
                      FeedingType.breastfeeding,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Amount Input (for bottle feeding)
              if (_selectedType == FeedingType.bottle) ...[
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Miktar (ml)',
                    hintText: 'Örn: 120',
                    prefixIcon: Icon(
                      Icons.straighten,
                      color: themeProvider.primaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: themeProvider.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: themeProvider.primaryColor),
                    ),
                    labelStyle: TextStyle(
                      color: themeProvider.mutedForegroundColor,
                    ),
                    hintStyle: TextStyle(
                      color: themeProvider.mutedForegroundColor,
                    ),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final amount = int.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Geçerli bir miktar girin';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Breastfeeding Side Selection
              if (_selectedType == FeedingType.breastfeeding) ...[
                Text(
                  'Hangi Taraf?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: themeProvider.cardForeground,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSideButton(
                        'Sol',
                        Icons.arrow_back_ios,
                        'left',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSideButton(
                        'Sağ',
                        Icons.arrow_forward_ios,
                        'right',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Notes Field
              if (_showNotes) ...[
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Notlar',
                    hintText:
                        'Beslenme ile ilgili notlarınızı buraya yazabilirsiniz...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: themeProvider.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: themeProvider.primaryColor),
                    ),
                    labelStyle: TextStyle(
                      color: themeProvider.mutedForegroundColor,
                    ),
                    hintStyle: TextStyle(
                      color: themeProvider.mutedForegroundColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Optional Fields Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _showNotes = !_showNotes),
                      icon: Icon(
                        _showNotes
                            ? Icons.remove_circle_outline
                            : Icons.add_circle_outline,
                        color: themeProvider.primaryColor,
                      ),
                      label: Text(
                        'Not Ekle',
                        style: TextStyle(color: themeProvider.primaryColor),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: themeProvider.primaryColor,
                        side: BorderSide(color: themeProvider.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectDateTime,
                      icon: Icon(
                        _hasSelectedDateTime ? Icons.save : Icons.access_time,
                        color: themeProvider.primaryColor,
                      ),
                      label: Text(
                        'Geçmiş Tarihli',
                        style: TextStyle(color: themeProvider.primaryColor),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: themeProvider.primaryColor,
                        side: BorderSide(color: themeProvider.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveFeeding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeProvider.isDarkMode
                        ? AppColors.darkAccent
                        : AppColors.accent,
                    foregroundColor: themeProvider.isDarkMode
                        ? AppColors.darkAccentForeground
                        : AppColors.accentForeground,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _hasSelectedDateTime
                                  ? Icons.save
                                  : Icons.restaurant,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _hasSelectedDateTime
                                  ? 'Beslenmeyi Kaydet'
                                  : 'Beslenmeyi Kaydet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: themeProvider.isDarkMode
                                    ? AppColors.darkAccentForeground
                                    : AppColors.accentForeground,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypeButton(String label, IconData icon, FeedingType type) {
    final isSelected = _selectedType == type;

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return GestureDetector(
          onTap: () => setState(() => _selectedType = type),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? themeProvider.primaryColor.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? themeProvider.primaryColor
                    : themeProvider.borderColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? themeProvider.primaryColor
                      : themeProvider.mutedForegroundColor,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? themeProvider.primaryColor
                        : themeProvider.mutedForegroundColor,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSideButton(String label, IconData icon, String side) {
    final isSelected = _selectedSide == side;

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return GestureDetector(
          onTap: () => setState(() => _selectedSide = side),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? themeProvider.primaryColor.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? themeProvider.primaryColor
                    : themeProvider.borderColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? themeProvider.primaryColor
                      : themeProvider.mutedForegroundColor,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? themeProvider.primaryColor
                        : themeProvider.mutedForegroundColor,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
