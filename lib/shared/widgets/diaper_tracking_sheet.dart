import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/providers/baby_provider.dart';
import '../../shared/providers/theme_provider.dart';
import '../../core/services/diaper_service.dart';
import '../../shared/models/diaper_model.dart';
import '../../core/services/sync_service.dart';

class DiaperTrackingSheet extends StatefulWidget {
  final VoidCallback? onDiaperSaved;
  final Diaper? diaperToEdit; // Edit modu için

  const DiaperTrackingSheet({super.key, this.onDiaperSaved, this.diaperToEdit});

  @override
  State<DiaperTrackingSheet> createState() => _DiaperTrackingSheetState();
}

class _DiaperTrackingSheetState extends State<DiaperTrackingSheet> {
  final _notesController = TextEditingController();

  DiaperType _selectedType = DiaperType.wet;
  bool _isLoading = false;
  bool _showNotes = false;
  DateTime _selectedDateTime = DateTime.now();
  bool _hasSelectedDateTime = false;

  @override
  void initState() {
    super.initState();

    // Edit modunda mevcut veriyi yükle
    if (widget.diaperToEdit != null) {
      final diaper = widget.diaperToEdit!;
      _selectedType = diaper.type;
      _selectedDateTime = diaper.time;
      _hasSelectedDateTime = true;

      if (diaper.notes != null) {
        _notesController.text = diaper.notes!;
        _showNotes = true;
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
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

  Future<void> _saveDiaper() async {
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

      final diaper = Diaper(
        id: widget
            .diaperToEdit
            ?.id, // Remove ?? '' to let UUID generate automatically
        babyId: currentBaby.id,
        type: _selectedType,
        notes: _showNotes && _notesController.text.isNotEmpty
            ? _notesController.text.trim()
            : null,
        time: _hasSelectedDateTime ? _selectedDateTime : DateTime.now(),
      );

      if (widget.diaperToEdit != null) {
        // Edit modunda - mevcut kaydı güncelle
        await DiaperService.updateDiaper(diaper);
      } else {
        // Yeni kayıt - çevrimiçi/çevrimdışı oluştur
        if (await SyncService.isOnline()) {
          await DiaperService.createDiaper(diaper);
        } else {
          await SyncService.enqueue({
            'type': 'create',
            'table': 'diaper_records',
            'payload': diaper.toJson(),
          });
          // Diaper queued for sync
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.diaperToEdit != null
                  ? 'Alt değişimi kaydı güncellendi'
                  : 'Alt değişimi kaydedildi',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Call callback to refresh parent screen
        widget.onDiaperSaved?.call();
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
                      gradient: AppColors.babyGreenGradient,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.baby_changing_station,
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
                          'Alt Değişimi Kaydet',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: themeProvider.cardForeground,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bebeğinizin alt değişimi bilgilerini kaydedin',
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

              // Diaper Type Selection
              Text(
                'Alt Değişimi Türü',
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
                      'Islak',
                      Icons.water_drop,
                      DiaperType.wet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeButton(
                      'Kirli',
                      Icons.warning,
                      DiaperType.dirty,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _buildTypeButton(
                  'Hem Islak Hem Kirli',
                  Icons.warning,
                  DiaperType.mixed,
                ),
              ),

              const SizedBox(height: 20),

              // Notes Field
              if (_showNotes) ...[
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Notlar',
                    hintText:
                        'Alt değişimi ile ilgili notlarınızı buraya yazabilirsiniz...',
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
                  onPressed: _isLoading ? null : _saveDiaper,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeProvider.isDarkMode
                        ? AppColors.darkBabyGreen
                        : const Color.fromARGB(255, 161, 216, 161),
                    foregroundColor: Colors.white,
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
                                  : Icons.baby_changing_station,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Alt Değişimini Kaydet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
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

  Widget _buildTypeButton(String label, IconData icon, DiaperType type) {
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
}
