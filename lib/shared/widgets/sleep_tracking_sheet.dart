import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/providers/tracking_provider.dart';
import '../../shared/providers/baby_provider.dart';
import '../../shared/providers/theme_provider.dart';
import '../../core/services/sleep_service.dart';
import '../../shared/models/sleep_model.dart';
import '../../core/services/sync_service.dart';

class SleepTrackingSheet extends StatefulWidget {
  final VoidCallback? onSleepSaved;
  final Sleep? sleepToEdit; // Edit modu için

  const SleepTrackingSheet({super.key, this.onSleepSaved, this.sleepToEdit});

  @override
  State<SleepTrackingSheet> createState() => _SleepTrackingSheetState();
}

class _SleepTrackingSheetState extends State<SleepTrackingSheet> {
  final _notesController = TextEditingController();
  bool _isLoading = false;
  bool _showNotes = false;
  DateTime _selectedStartTime = DateTime.now();
  DateTime? _selectedEndTime;
  bool _hasSelectedStartTime = false;

  @override
  void initState() {
    super.initState();
    if (widget.sleepToEdit != null) {
      final sleep = widget.sleepToEdit!;
      _selectedStartTime = sleep.startTime;
      _hasSelectedStartTime = true;

      if (sleep.endTime != null) {
        _selectedEndTime = sleep.endTime;
      }

      if (sleep.notes != null) {
        _notesController.text = sleep.notes!;
        _showNotes = true;
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectStartTime() async {
    final firstDate = DateTime.now().subtract(const Duration(days: 30));
    final lastDate = DateTime.now();

    // initialDate firstDate'den önce olamaz
    final initialDate = _selectedStartTime.isBefore(firstDate)
        ? firstDate
        : _selectedStartTime;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedStartTime),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Theme.of(context).colorScheme.primary,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                alwaysUse24HourFormat: true, // 24 saatlik format
              ),
              child: child!,
            ),
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _selectedStartTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _hasSelectedStartTime = true;
        });
      }
    }
  }

  Future<void> _selectEndTime() async {
    final firstDate = DateTime.now().subtract(const Duration(days: 30));
    final lastDate = DateTime.now();

    // initialDate firstDate'den önce olamaz
    final initialDate = _selectedEndTime?.isBefore(firstDate) == true
        ? firstDate
        : (_selectedEndTime ?? DateTime.now());

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedEndTime ?? DateTime.now()),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Theme.of(context).colorScheme.primary,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                alwaysUse24HourFormat: true, // 24 saatlik format
              ),
              child: child!,
            ),
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _selectedEndTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _startSleep() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final trackingProvider = context.read<TrackingProvider>();
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

      // Check if it's a past sleep record (has start/end times) or edit mode
      if (widget.sleepToEdit != null ||
          _hasSelectedStartTime ||
          _selectedEndTime != null) {
        await _savePastSleep(currentBaby.id);
      } else {
        // Start real-time sleep tracking
        await trackingProvider.startSleepTracking(
          currentBaby.id,
          customStartTime: _selectedStartTime,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.sleepToEdit != null
                  ? 'Uyku kaydı güncellendi'
                  : (_hasSelectedStartTime || _selectedEndTime != null
                        ? 'Uyku kaydedildi'
                        : 'Uyku takibi başlatıldı'),
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Call callback to refresh parent screen
        widget.onSleepSaved?.call();
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

  Future<void> _savePastSleep(String babyId) async {
    try {
      final endTime = _selectedEndTime ?? DateTime.now();

      if (widget.sleepToEdit != null) {
        // Edit modunda - mevcut kaydı güncelle
        final sleep = Sleep(
          id: widget.sleepToEdit!.id, // Mevcut ID'yi koru
          babyId: babyId,
          startTime: _selectedStartTime,
          endTime: endTime,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

        await SleepService.updateSleep(sleep);
      } else {
        // Yeni kayıt - çevrimiçi/çevrimdışı oluştur
        final notes = _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim();
        if (await SyncService.isOnline()) {
          await SleepService.savePastSleep(
            babyId,
            _selectedStartTime,
            endTime,
            notes: notes,
          );
          debugPrint(
            'Past sleep saved to Supabase: $_selectedStartTime to $endTime',
          );
        } else {
          final sleep = Sleep(
            babyId: babyId,
            startTime: _selectedStartTime,
            endTime: endTime,
            notes: notes,
          );
          await SyncService.enqueue({
            'type': 'create',
            'table': 'sleep_records',
            'payload': sleep.toJson(),
          });
          debugPrint('Past sleep queued for sync');
        }
      }
    } catch (e) {
      debugPrint('Error saving past sleep: $e');
      rethrow;
    }
  }

  Future<void> _stopSleep() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final trackingProvider = context.read<TrackingProvider>();

      // Stop sleep tracking
      await trackingProvider.stopSleepTracking();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uyku takibi durduruldu'),
            backgroundColor: Colors.green,
          ),
        );
        // Call callback to refresh parent screen
        widget.onSleepSaved?.call();
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
          child: Consumer2<TrackingProvider, BabyProvider>(
            builder: (context, trackingProvider, babyProvider, _) {
              final currentBaby = babyProvider.selectedBaby;
              final isTracking = currentBaby != null
                  ? trackingProvider.isBabyTracking(currentBaby.id)
                  : false;
              final sleepStartTime = currentBaby != null
                  ? trackingProvider.babySleepStates[currentBaby.id]?.startTime
                  : null;

              return Column(
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
                          gradient: AppColors.babyBlueGradient,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Icon(
                          Icons.bedtime,
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
                              isTracking
                                  ? 'Uyku Takibi Devam Ediyor'
                                  : 'Uyku Takibi',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: themeProvider.cardForeground,
                                  ),
                            ),
                            if (isTracking && sleepStartTime != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Başlangıç: ${_formatTime(sleepStartTime)}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: themeProvider.mutedForegroundColor,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Selected Times Info
                  if (!isTracking &&
                      (_hasSelectedStartTime || _selectedEndTime != null)) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: themeProvider.primaryColor.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: themeProvider.primaryColor.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.bedtime,
                                color: themeProvider.primaryColor,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Uyku Zamanları',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: themeProvider.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.play_arrow,
                                color: themeProvider.primaryColor,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Başlangıç: ${_formatDateTime(_selectedStartTime)}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: themeProvider.primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                          if (_selectedEndTime != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.stop,
                                  color: themeProvider.primaryColor,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Bitiş: ${_formatDateTime(_selectedEndTime!)}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: themeProvider.primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Time Selection Buttons
                  if (!isTracking) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectStartTime,
                            icon: const Icon(Icons.play_arrow, size: 20),
                            label: const Text('Başlangıç'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: themeProvider.primaryColor,
                              side: BorderSide(
                                color: themeProvider.primaryColor,
                              ),
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
                            onPressed: _selectEndTime,
                            icon: const Icon(Icons.stop, size: 20),
                            label: const Text('Bitiş'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: themeProvider.primaryColor,
                              side: BorderSide(
                                color: themeProvider.primaryColor,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Notes Field
                  if (_showNotes) ...[
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Notlar',
                        hintText:
                            'Uyku ile ilgili notlarınızı buraya yazabilirsiniz...',
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
                    const SizedBox(height: 16),
                  ],

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
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : (isTracking ? _stopSleep : _startSleep),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isTracking
                            ? AppColors.babyOrangeGradient.colors.first
                            : themeProvider.primaryColor,
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
                                  isTracking ? Icons.stop : Icons.play_arrow,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isTracking
                                      ? 'Uyku Takibini Durdur'
                                      : (widget.sleepToEdit != null
                                            ? 'Uyku Kaydını Güncelle'
                                            : (_hasSelectedStartTime ||
                                                      _selectedEndTime != null
                                                  ? 'Uyku Kaydını Kaydet'
                                                  : 'Uyku Takibini Başlat')),
                                  style: const TextStyle(
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
              );
            },
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (selectedDate == today) {
      return 'Bugün ${_formatTime(dateTime)}';
    } else if (selectedDate == today.subtract(const Duration(days: 1))) {
      return 'Dün ${_formatTime(dateTime)}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${_formatTime(dateTime)}';
    }
  }
}
