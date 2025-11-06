import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/services/sleep_service.dart';

// Sleep state model for each baby
class SleepState {
  final bool isTracking;
  final DateTime? startTime;
  final int totalDuration;
  final DateTime? lastAppCloseTime;
  final String babyId;

  SleepState({
    required this.isTracking,
    this.startTime,
    required this.totalDuration,
    this.lastAppCloseTime,
    required this.babyId,
  });

  Map<String, dynamic> toJson() {
    return {
      'isTracking': isTracking,
      'startTime': startTime?.toIso8601String(),
      'totalDuration': totalDuration,
      'lastAppCloseTime': lastAppCloseTime?.toIso8601String(),
      'babyId': babyId,
    };
  }

  factory SleepState.fromJson(Map<String, dynamic> json) {
    return SleepState(
      isTracking: json['isTracking'] ?? false,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'])
          : null,
      totalDuration: json['totalDuration'] ?? 0,
      lastAppCloseTime: json['lastAppCloseTime'] != null
          ? DateTime.parse(json['lastAppCloseTime'])
          : null,
      babyId: json['babyId'] ?? '',
    );
  }

  SleepState copyWith({
    bool? isTracking,
    DateTime? startTime,
    int? totalDuration,
    DateTime? lastAppCloseTime,
    String? babyId,
  }) {
    return SleepState(
      isTracking: isTracking ?? this.isTracking,
      startTime: startTime ?? this.startTime,
      totalDuration: totalDuration ?? this.totalDuration,
      lastAppCloseTime: lastAppCloseTime ?? this.lastAppCloseTime,
      babyId: babyId ?? this.babyId,
    );
  }
}

class TrackingProvider extends ChangeNotifier {
  // Multi-baby sleep tracking
  Map<String, SleepState> _babySleepStates = {};
  String? _currentBabyId;
  Set<String> _activeTrackingBabies = {}; // Birden fazla aktif bebek
  Timer? _timer;

  // Public getter for current baby ID
  String? get currentBabyId => _currentBabyId;
  set currentBabyId(String? value) => _currentBabyId = value;

  // Persistence keys
  static const String _babyStatesKey = 'baby_sleep_states';
  static const String _currentBabyKey = 'current_sleep_baby';
  static const String _activeBabiesKey = 'active_tracking_babies';

  // Manual entry
  bool _isManualEntry = false;
  String _manualHours = '';
  String _manualMinutes = '';

  // Getters
  bool get isTracking =>
      _currentBabyId != null &&
      _babySleepStates[_currentBabyId]?.isTracking == true;
  int get seconds => _currentBabyId != null
      ? _babySleepStates[_currentBabyId]?.totalDuration ?? 0
      : 0;
  bool get isManualEntry => _isManualEntry;
  String get manualHours => _manualHours;
  String get manualMinutes => _manualMinutes;
  DateTime? get sleepStartTime => _currentBabyId != null
      ? _babySleepStates[_currentBabyId]?.startTime
      : null;
  String? get babyId => _currentBabyId;

  // Multi-tracking getters
  Set<String> get activeTrackingBabies => _activeTrackingBabies;
  bool isBabyTracking(String babyId) =>
      _babySleepStates[babyId]?.isTracking == true;
  int getBabySeconds(String babyId) =>
      _babySleepStates[babyId]?.totalDuration ?? 0;
  Map<String, SleepState> get babySleepStates => _babySleepStates;

  String get trackingTime {
    final currentSeconds = seconds;
    final hours = currentSeconds ~/ 3600;
    final minutes = (currentSeconds % 3600) ~/ 60;
    final secs = currentSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // Sleep tracking methods
  Future<void> startSleepTracking(
    String babyId, {
    DateTime? customStartTime,
  }) async {
    _currentBabyId = babyId;
    final startTime = customStartTime ?? DateTime.now();

    try {
      // Start sleep session in Supabase
      await SleepService.startSleep(babyId);
    } catch (e) {
      debugPrint('Error starting sleep session in Supabase: $e');
      // Continue with local tracking even if Supabase fails
    }

    // Create or update sleep state for this baby
    _babySleepStates[babyId] = SleepState(
      isTracking: true,
      startTime: startTime,
      totalDuration:
          _babySleepStates[babyId]?.totalDuration ?? 0, // Mevcut süreyi koru
      lastAppCloseTime: DateTime.now(),
      babyId: babyId,
    );

    // Add to active tracking babies
    _activeTrackingBabies.add(babyId);

    _startTimer();
    await _saveAllSleepStates();
    notifyListeners();
  }

  Future<void> stopSleepTracking() async {
    if (_currentBabyId != null) {
      try {
        // Get active sleep record from Supabase
        final activeSleep = await SleepService.getActiveSleep(_currentBabyId!);

        if (activeSleep != null) {
          // End the sleep session in Supabase
          await SleepService.endSleep(activeSleep.id);
        }
      } catch (e) {
        debugPrint('Error ending sleep session in Supabase: $e');
        // Continue with local cleanup even if Supabase fails
      }

      // Clean up local state
      _babySleepStates[_currentBabyId!] = SleepState(
        isTracking: false,
        startTime: null,
        totalDuration: 0,
        lastAppCloseTime: null,
        babyId: _currentBabyId!,
      );

      // Remove from active tracking babies
      _activeTrackingBabies.remove(_currentBabyId!);
    }

    _currentBabyId = null;

    // Stop timer only if no active babies
    if (_activeTrackingBabies.isEmpty) {
      _stopTimer();
    }

    await _saveAllSleepStates();
    notifyListeners();
  }

  void _startTimer() {
    if (_timer != null) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Update all active tracking babies
      for (final babyId in _activeTrackingBabies) {
        if (_babySleepStates[babyId]?.isTracking == true) {
          final currentState = _babySleepStates[babyId]!;
          _babySleepStates[babyId] = currentState.copyWith(
            totalDuration: currentState.totalDuration + 1,
          );
        }
      }
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void startTracking() {
    if (isTracking) return;

    if (_currentBabyId != null) {
      _babySleepStates[_currentBabyId!] = SleepState(
        isTracking: true,
        startTime: DateTime.now(),
        totalDuration: 0,
        lastAppCloseTime: DateTime.now(),
        babyId: _currentBabyId!,
      );
      _startTimer();
      notifyListeners();
    }
  }

  void stopTracking() {
    if (!isTracking) return;

    if (_currentBabyId != null) {
      _babySleepStates[_currentBabyId!] = SleepState(
        isTracking: false,
        startTime: null,
        totalDuration: 0,
        lastAppCloseTime: null,
        babyId: _currentBabyId!,
      );
      _stopTimer();
      notifyListeners();
    }
  }

  void resetTimer() {
    if (_currentBabyId != null) {
      _babySleepStates[_currentBabyId!] = SleepState(
        isTracking: false,
        startTime: null,
        totalDuration: 0,
        lastAppCloseTime: null,
        babyId: _currentBabyId!,
      );
    }
    _stopTimer();
    notifyListeners();
  }

  void toggleTracking() {
    if (isTracking) {
      stopTracking();
    } else {
      startTracking();
    }
  }

  // Manual entry methods
  void setIsManualEntry(bool value) {
    _isManualEntry = value;
    notifyListeners();
  }

  void setManualHours(String hours) {
    _manualHours = hours;
    notifyListeners();
  }

  void setManualMinutes(String minutes) {
    _manualMinutes = minutes;
    notifyListeners();
  }

  void clearManualEntry() {
    _manualHours = '';
    _manualMinutes = '';
    notifyListeners();
  }

  // Save tracking data
  Future<void> saveTrackingSession({
    required String babyId,
    required Duration duration,
    String? notes,
    DateTime? startTime,
  }) async {
    try {
      final actualStartTime = startTime ?? DateTime.now().subtract(duration);
      final endTime = DateTime.now();

      // Save to Supabase using SleepService
      await SleepService.savePastSleep(
        babyId,
        actualStartTime,
        endTime,
        notes: notes,
      );

      // Reset the timer after successful save
      resetTimer();
    } catch (e) {
      // If Supabase save fails, still reset timer to prevent data loss
      resetTimer();
      rethrow;
    }
  }

  // Save manual entry
  Future<void> saveManualEntry({
    required String babyId,
    required int hours,
    required int minutes,
    String? notes,
    DateTime? date,
  }) async {
    try {
      final actualDate = date ?? DateTime.now();
      final startTime = actualDate.subtract(
        Duration(hours: hours, minutes: minutes),
      );
      final endTime = actualDate;

      // Save to Supabase using SleepService
      await SleepService.savePastSleep(
        babyId,
        startTime,
        endTime,
        notes: notes,
      );

      // Clear manual entry after successful save
      clearManualEntry();
      notifyListeners();
    } catch (e) {
      // Clear manual entry even if save fails to prevent UI issues
      clearManualEntry();
      notifyListeners();
      rethrow;
    }
  }

  // Persistence methods
  Future<void> _saveAllSleepStates() async {
    final prefs = await SharedPreferences.getInstance();

    // Save all baby sleep states
    final statesJson = _babySleepStates.map(
      (key, value) => MapEntry(key, value.toJson()),
    );
    await prefs.setString(_babyStatesKey, jsonEncode(statesJson));

    // Save current baby
    if (_currentBabyId != null) {
      await prefs.setString(_currentBabyKey, _currentBabyId!);
    } else {
      await prefs.remove(_currentBabyKey);
    }

    // Save active tracking babies
    await prefs.setStringList(_activeBabiesKey, _activeTrackingBabies.toList());
  }

  Future<void> saveAppCloseTime() async {
    // Update last app close time for all tracking babies
    final now = DateTime.now();
    for (final entry in _babySleepStates.entries) {
      if (entry.value.isTracking) {
        _babySleepStates[entry.key] = entry.value.copyWith(
          lastAppCloseTime: now,
        );
      }
    }
    await _saveAllSleepStates();
  }

  Future<void> loadSleepState() async {
    final prefs = await SharedPreferences.getInstance();

    // Load all baby sleep states
    final statesJson = prefs.getString(_babyStatesKey);
    if (statesJson != null) {
      final statesMap = jsonDecode(statesJson) as Map<String, dynamic>;
      _babySleepStates = statesMap.map(
        (key, value) =>
            MapEntry(key, SleepState.fromJson(value as Map<String, dynamic>)),
      );
    }

    // Load current baby
    _currentBabyId = prefs.getString(_currentBabyKey);

    // Load active tracking babies
    final activeBabiesList = prefs.getStringList(_activeBabiesKey) ?? [];
    _activeTrackingBabies = activeBabiesList.toSet();

    // Calculate elapsed time for tracking babies
    final now = DateTime.now();
    for (final entry in _babySleepStates.entries) {
      if (entry.value.isTracking && entry.value.lastAppCloseTime != null) {
        final elapsedSinceClose = now
            .difference(entry.value.lastAppCloseTime!)
            .inSeconds;
        final totalElapsed = entry.value.totalDuration + elapsedSinceClose;

        _babySleepStates[entry.key] = entry.value.copyWith(
          totalDuration: totalElapsed,
          lastAppCloseTime: now,
        );
      }
    }

    // Start timer if any baby is tracking
    if (_activeTrackingBabies.isNotEmpty) {
      _startTimer();
    }

    await _saveAllSleepStates();
    notifyListeners();
  }

  @override
  void dispose() {
    saveAppCloseTime();
    _timer?.cancel();
    super.dispose();
  }
}
