import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/providers/baby_provider.dart';
import '../../shared/providers/theme_provider.dart';
import '../../core/services/physical_measurement_service.dart';
import '../../shared/models/physical_measurement_model.dart';
import '../../core/utils/who_growth_data.dart';
import '../../shared/widgets/custom_card.dart';

class DevelopmentTrackingSheet extends StatefulWidget {
  final VoidCallback? onMeasurementSaved;

  const DevelopmentTrackingSheet({super.key, this.onMeasurementSaved});

  @override
  State<DevelopmentTrackingSheet> createState() =>
      _DevelopmentTrackingSheetState();
}

class _DevelopmentTrackingSheetState extends State<DevelopmentTrackingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _headCircumferenceController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _showNotes = false;
  bool _showDatePicker = false;

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _headCircumferenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveDevelopment() async {
    if (!_formKey.currentState!.validate()) return;

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

      // Create physical measurement record
      final measurement = PhysicalMeasurement(
        id: null, // Let UUID generate automatically
        babyId: currentBaby.id,
        weight: _weightController.text.isNotEmpty
            ? double.tryParse(_weightController.text)
            : null,
        height: _heightController.text.isNotEmpty
            ? double.tryParse(_heightController.text)
            : null,
        headCircumference: _headCircumferenceController.text.isNotEmpty
            ? double.tryParse(_headCircumferenceController.text)
            : null,
        notes: _showNotes && _notesController.text.isNotEmpty
            ? _notesController.text.trim()
            : null,
        measuredAt: _showDatePicker ? _selectedDate : DateTime.now(),
      );

      await PhysicalMeasurementService.createMeasurement(measurement);

      // Update baby's current weight and height if provided
      if (_weightController.text.isNotEmpty ||
          _heightController.text.isNotEmpty) {
        final updatedBaby = currentBaby.copyWith(
          weight: _weightController.text.isNotEmpty
              ? _weightController.text
              : currentBaby.weight,
          height: _heightController.text.isNotEmpty
              ? _heightController.text
              : currentBaby.height,
        );
        await babyProvider.updateBaby(updatedBaby);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ölçüm kaydedildi'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onMeasurementSaved?.call();
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
          child: Form(
            key: _formKey,
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

                // Title
                Text(
                  'Fiziksel Ölçümler',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: themeProvider.cardForeground,
                  ),
                ),

                const SizedBox(height: 20),

                // WHO Bilgilendirme
                Consumer<BabyProvider>(
                  builder: (context, babyProvider, _) {
                    final currentBaby = babyProvider.selectedBaby;
                    if (currentBaby != null) {
                      final whoInfo = WhoGrowthData.getWhoWeightInfo(
                        currentBaby,
                      );
                      if (whoInfo != null) {
                        return Column(
                          children: [
                            CustomCard(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: themeProvider.primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      whoInfo,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color:
                                            themeProvider.mutedForegroundColor,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        );
                      }
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Weight Input
                TextFormField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Kilo (kg)',
                    hintText: 'Örn: 7.5',
                    prefixIcon: Icon(
                      Icons.monitor_weight,
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
                      final weight = double.tryParse(value);
                      if (weight == null || weight <= 0) {
                        return 'Geçerli bir kilo girin';
                      }
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Height Input
                TextFormField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Boy (cm)',
                    hintText: 'Örn: 65',
                    prefixIcon: Icon(
                      Icons.height,
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
                      final height = double.tryParse(value);
                      if (height == null || height <= 0) {
                        return 'Geçerli bir boy girin';
                      }
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Head Circumference Input
                TextFormField(
                  controller: _headCircumferenceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Baş Çevresi (cm)',
                    hintText: 'Örn: 42',
                    prefixIcon: Icon(
                      Icons.circle_outlined,
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
                      final circumference = double.tryParse(value);
                      if (circumference == null || circumference <= 0) {
                        return 'Geçerli bir baş çevresi girin';
                      }
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Optional Fields Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            setState(() => _showNotes = !_showNotes),
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
                        onPressed: () =>
                            setState(() => _showDatePicker = !_showDatePicker),
                        icon: Icon(
                          _showDatePicker ? Icons.save : Icons.access_time,
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

                // Notes Field (if enabled)
                if (_showNotes) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Notlar',
                      hintText: 'Ek notlarınızı buraya yazabilirsiniz...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: themeProvider.borderColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: themeProvider.primaryColor,
                        ),
                      ),
                      labelStyle: TextStyle(
                        color: themeProvider.mutedForegroundColor,
                      ),
                      hintStyle: TextStyle(
                        color: themeProvider.mutedForegroundColor,
                      ),
                    ),
                  ),
                ],

                // Date Picker (if enabled)
                if (_showDatePicker) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: Icon(
                      Icons.calendar_today,
                      color: themeProvider.primaryColor,
                    ),
                    label: Text(
                      'Tarih: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
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
                ],

                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveDevelopment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeProvider.primaryColor,
                      foregroundColor: themeProvider.primaryForegroundColor,
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
                              Icon(Icons.add, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Ölçüm Kaydını Ekle',
                                style: TextStyle(
                                  color: themeProvider.primaryForegroundColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
