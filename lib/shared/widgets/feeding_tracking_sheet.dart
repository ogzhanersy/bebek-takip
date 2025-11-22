import 'dart:async';
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

  // Timer for breastfeeding
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isTimerRunning = false;
  bool _isTimerPaused = false;
  DateTime? _timerStartTime;
  DateTime? _pausedTime;
  int _pausedElapsedSeconds = 0;

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
    _timer?.cancel();
    _notesController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_isTimerRunning) return;

    setState(() {
      _isTimerRunning = true;
      _isTimerPaused = false;
      _timerStartTime = DateTime.now();
      if (_pausedTime != null) {
        // Resume from pause
        final pauseDuration = DateTime.now().difference(_pausedTime!);
        _pausedElapsedSeconds += pauseDuration.inSeconds;
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds = _pausedElapsedSeconds +
              DateTime.now().difference(_timerStartTime!).inSeconds;
        });
      }
    });
  }

  void _pauseTimer() {
    if (!_isTimerRunning) return;

    setState(() {
      _isTimerRunning = false;
      _isTimerPaused = true;
      _pausedTime = DateTime.now();
      _pausedElapsedSeconds = _elapsedSeconds;
    });

    _timer?.cancel();
  }

  void _stopTimer() {
    setState(() {
      _isTimerRunning = false;
      _isTimerPaused = false;
      _elapsedSeconds = 0;
      _pausedElapsedSeconds = 0;
      _timerStartTime = null;
      _pausedTime = null;
    });

    _timer?.cancel();
  }

  Future<void> _stopTimerAndSave() async {
    // Stop timer first but keep the data for saving
    final wasRunning = _isTimerRunning;
    final wasPaused = _isTimerPaused;
    final elapsed = _elapsedSeconds;
    final startTime = _timerStartTime;
    
    _timer?.cancel();
    
    // Auto-save if it's breastfeeding, timer was running or paused, and we have valid data
    if (_selectedType == FeedingType.breastfeeding &&
        (wasRunning || wasPaused) &&
        elapsed > 0 &&
        startTime != null &&
        _selectedSide != null) {
      // Save the feeding automatically
      await _saveFeedingWithTimerData(startTime, elapsed);
    } else {
      // Just stop the timer without saving
      _stopTimer();
    }
  }

  Future<void> _saveFeedingWithTimerData(DateTime startTime, int elapsedSeconds) async {
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
        _stopTimer();
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
        _stopTimer();
        return;
      }

      // Calculate end time from timer data
      final endTime = startTime.add(Duration(seconds: elapsedSeconds));

      final feeding = Feeding(
        babyId: currentBaby.id,
        type: _selectedType,
        side: _selectedSide,
        notes: _showNotes && _notesController.text.isNotEmpty
            ? _notesController.text.trim()
            : null,
        startTime: startTime,
        endTime: endTime,
      );

      // Save the feeding
      if (await SyncService.isOnline()) {
        await FeedingService.createFeeding(feeding);
      } else {
        await SyncService.enqueue({
          'type': 'create',
          'table': 'feeding_records',
          'payload': feeding.toJson(),
        });
      }

      // Stop timer after saving
      _stopTimer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Beslenme kaydedildi'),
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
      _stopTimer();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatTimer(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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

      // Calculate end time for breastfeeding with timer
      DateTime? endTime;
      if (_selectedType == FeedingType.breastfeeding &&
          _isTimerRunning &&
          _timerStartTime != null) {
        endTime = DateTime.now();
      } else if (_selectedType == FeedingType.breastfeeding &&
          _elapsedSeconds > 0 &&
          _timerStartTime != null) {
        // Timer was stopped, calculate end time
        endTime = _timerStartTime!.add(Duration(seconds: _elapsedSeconds));
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
        startTime: _hasSelectedDateTime ? _selectedDateTime : (_timerStartTime ?? DateTime.now()),
        endTime: endTime,
      );

      // Stop timer after saving
      if (_selectedType == FeedingType.breastfeeding) {
        _stopTimer();
      }

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
                      '🍼',
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

                // Timer Display and Controls
                if (_selectedSide != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: themeProvider.primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Timer Display
                        Text(
                          _formatTimer(_elapsedSeconds),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: themeProvider.primaryColor,
                            fontFeatures: [const FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Control Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!_isTimerRunning && !_isTimerPaused) ...[
                              // Start button
                              ElevatedButton.icon(
                                onPressed: () {
                                  _startTimer();
                                },
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Başlat'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeProvider.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ] else if (_isTimerRunning) ...[
                              // Pause button
                              ElevatedButton.icon(
                                onPressed: () {
                                  _pauseTimer();
                                },
                                icon: const Icon(Icons.pause),
                                label: const Text('Duraklat'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Stop button
                              ElevatedButton.icon(
                                onPressed: _isLoading ? null : () {
                                  _stopTimerAndSave();
                                },
                                icon: const Icon(Icons.stop),
                                label: const Text('Durdur'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ] else if (_isTimerPaused) ...[
                              // Resume button
                              ElevatedButton.icon(
                                onPressed: () {
                                  _startTimer();
                                },
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Devam Et'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeProvider.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Stop button
                              ElevatedButton.icon(
                                onPressed: _isLoading ? null : () {
                                  _stopTimerAndSave();
                                },
                                icon: const Icon(Icons.stop),
                                label: const Text('Durdur'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
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
                            _hasSelectedDateTime
                                ? Icon(Icons.save, size: 20)
                                : Text('🍼', style: TextStyle(fontSize: 20)),
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

  Widget _buildTypeButton(String label, dynamic icon, FeedingType type) { // IconData or String (emoji)
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
                icon is IconData
                    ? Icon(
                        icon,
                        color: isSelected
                            ? themeProvider.primaryColor
                            : themeProvider.mutedForegroundColor,
                        size: 24,
                      )
                    : Text(
                        icon as String,
                        style: TextStyle(fontSize: 24),
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
          onTap: () {
            // If switching sides while timer is running, stop timer
            if (_isTimerRunning && _selectedSide != null && _selectedSide != side) {
              _stopTimer();
            }
            setState(() {
              _selectedSide = side;
              // Don't auto-start timer, just select the side
            });
          },
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
