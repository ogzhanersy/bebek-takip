import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/baby_model.dart';
import '../../core/services/baby_service.dart';
import 'tracking_provider.dart';

class BabyProvider extends ChangeNotifier {
  List<Baby> _babies = [];
  String? _selectedBabyId;
  TrackingProvider? _trackingProvider;
  bool _isLoading = true; // Loading state eklendi

  List<Baby> get babies => _babies;
  String? get selectedBabyId => _selectedBabyId;
  bool get isLoading => _isLoading; // Loading getter eklendi

  // Set tracking provider reference
  void setTrackingProvider(TrackingProvider trackingProvider) {
    _trackingProvider = trackingProvider;
  }

  Baby? get selectedBaby {
    if (_selectedBabyId == null) return null;
    try {
      return _babies.firstWhere((baby) => baby.id == _selectedBabyId);
    } catch (e) {
      return _babies.isNotEmpty ? _babies.first : null;
    }
  }

  BabyProvider() {
    _loadBabies();
  }

  Future<void> _loadBabies() async {
    try {
      _isLoading = true;
      notifyListeners(); // Loading başladığını bildir

      // Try to load from Supabase first
      _babies = await BabyService.getBabies();

      // Get selected baby from local storage
      final prefs = await SharedPreferences.getInstance();
      final selectedId = prefs.getString('selected_baby_id');

      // If no babies exist, don't create a default baby
      if (_babies.isEmpty) {
        _selectedBabyId = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Set selected baby - prioritize last selected baby
      if (selectedId != null && _babies.any((baby) => baby.id == selectedId)) {
        // Last selected baby still exists, use it
        _selectedBabyId = selectedId;
      } else if (_babies.isNotEmpty) {
        // No valid selected baby, choose the first one
        _selectedBabyId = _babies.first.id;
        await _saveSelectedBaby();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading babies: $e');
      // Fallback to local storage if Supabase fails
      await _loadBabiesFromLocal();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addBaby(Baby baby) async {
    try {
      final createdBaby = await BabyService.createBaby(baby);
      _babies.add(createdBaby);

      // If this is the first baby, set it as selected
      if (_babies.length == 1) {
        _selectedBabyId = createdBaby.id;
        await _saveSelectedBaby();
      }

      await _saveBabiesLocal(); // Cache locally
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding baby: $e');
      rethrow;
    }
  }

  Future<void> updateBaby(Baby updatedBaby) async {
    try {
      final updated = await BabyService.updateBaby(updatedBaby);
      final index = _babies.indexWhere((baby) => baby.id == updated.id);
      if (index != -1) {
        _babies[index] = updated;
        await _saveBabiesLocal();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating baby: $e');
      rethrow;
    }
  }

  Future<void> deleteBaby(String babyId) async {
    try {
      final babyToDelete = _babies.firstWhere((baby) => baby.id == babyId);

      // Don't allow deleting the primary baby if there are other babies
      if (babyToDelete.isPrimary && _babies.length > 1) {
        throw Exception(
          'Ana bebek silinmeden önce başka bir bebeği ana bebek yapın.',
        );
      }

      await BabyService.deleteBaby(babyId);
      _babies.removeWhere((baby) => baby.id == babyId);

      // If we deleted the selected baby, select another one
      if (_selectedBabyId == babyId) {
        _selectedBabyId = _babies.isNotEmpty ? _babies.first.id : null;
        await _saveSelectedBaby();
      }

      await _saveBabiesLocal();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting baby: $e');
      rethrow;
    }
  }

  Future<void> setPrimaryBaby(String babyId) async {
    try {
      await BabyService.setPrimaryBaby(babyId);

      // Update local state
      _babies = _babies.map((baby) => baby.copyWith(isPrimary: false)).toList();
      final index = _babies.indexWhere((baby) => baby.id == babyId);
      if (index != -1) {
        _babies[index] = _babies[index].copyWith(isPrimary: true);
        _selectedBabyId = babyId;
        await _saveSelectedBaby();
      }

      await _saveBabiesLocal();
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting primary baby: $e');
      rethrow;
    }
  }

  void selectBaby(String babyId) {
    if (_babies.any((baby) => baby.id == babyId)) {
      _selectedBabyId = babyId;
      _saveSelectedBaby();
      notifyListeners();
    }
  }

  // Helper methods
  Future<void> _loadBabiesFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final babiesJson = prefs.getString('babies');
      final selectedId = prefs.getString('selected_baby_id');

      if (babiesJson != null) {
        final List<dynamic> babyList = json.decode(babiesJson);
        _babies = babyList.map((json) => Baby.fromJson(json)).toList();
      }

      _selectedBabyId =
          selectedId ?? (_babies.isNotEmpty ? _babies.first.id : null);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading babies from local: $e');
    }
  }

  Future<void> _saveBabiesLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final babiesJson = json.encode(
        _babies.map((baby) => baby.toJson()).toList(),
      );
      await prefs.setString('babies', babiesJson);
    } catch (e) {
      debugPrint('Error saving babies locally: $e');
    }
  }

  Future<void> _saveSelectedBaby() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_selectedBabyId != null) {
        await prefs.setString('selected_baby_id', _selectedBabyId!);
      }
    } catch (e) {
      debugPrint('Error saving selected baby: $e');
    }
  }

  Future<void> refreshBabies() async {
    await _loadBabies();
  }

  Future<void> setSelectedBaby(Baby baby) async {
    // Save current baby's sleep state before switching
    if (_selectedBabyId != null && _trackingProvider != null) {
      await _trackingProvider!.saveAppCloseTime();
    }

    _selectedBabyId = baby.id;
    await _saveSelectedBaby();

    // Update current baby in tracking provider (don't reload all states)
    if (_trackingProvider != null) {
      _trackingProvider!.currentBabyId = baby.id;
    }

    notifyListeners();
  }

  String calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    final difference = now.difference(birthDate);
    final days = difference.inDays;

    if (days < 30) {
      return '$days günlük';
    } else {
      final months = (days / 30).floor();
      return '$months aylık';
    }
  }
}
