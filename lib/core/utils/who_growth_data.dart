import '../../../shared/models/baby_model.dart';

class WhoGrowthData {
  // Erkek için WHO kilo verileri (Medyan değerler)
  static const Map<String, double> _maleWeightMedian = {
    '0': 3.3, // Doğum
    '1': 4.5, // 1 ay
    '2': 5.6, // 2 ay
    '3': 6.4, // 3 ay
    '4': 7.0, // 4 ay
    '5': 7.5, // 5 ay
    '6': 7.9, // 6 ay
    '7': 8.3, // 7 ay
    '8': 8.6, // 8 ay
    '9': 8.9, // 9 ay
    '10': 9.2, // 10 ay
    '11': 9.4, // 11 ay
    '12': 9.9, // 12 ay (ortalama 9.6-10.2)
    '24': 12.2, // 2 yaş
    '36': 14.3, // 3 yaş
    '48': 16.3, // 4 yaş
  };

  // Erkek için WHO kilo alt sınır (%3)
  static const Map<String, double> _maleWeightMin = {
    '0': 2.4, // Doğum
    '1': 3.4, // 1 ay
    '2': 4.3, // 2 ay
    '3': 5.0, // 3 ay
    '4': 5.6, // 4 ay
    '5': 6.1, // 5 ay
    '6': 6.4, // 6 ay
    '7': 6.7, // 7 ay
    '8': 6.9, // 8 ay
    '9': 7.1, // 9 ay
    '10': 7.3, // 10 ay
    '11': 7.5, // 11 ay
    '12': 7.7, // 12 ay
    '24': 9.7, // 2 yaş
    '36': 11.3, // 3 yaş
    '48': 13.0, // 4 yaş
  };

  // Erkek için WHO kilo üst sınır (%97)
  static const Map<String, double> _maleWeightMax = {
    '0': 4.4, // Doğum
    '1': 5.8, // 1 ay
    '2': 7.1, // 2 ay
    '3': 8.0, // 3 ay
    '4': 8.7, // 4 ay
    '5': 9.3, // 5 ay
    '6': 9.8, // 6 ay
    '7': 10.3, // 7 ay
    '8': 10.7, // 8 ay
    '9': 11.0, // 9 ay
    '10': 11.4, // 10 ay
    '11': 11.7, // 11 ay
    '12': 12.0, // 12 ay
    '24': 15.3, // 2 yaş
    '36': 18.3, // 3 yaş
    '48': 21.3, // 4 yaş
  };

  // Kız için WHO kilo verileri (Medyan değerler)
  static const Map<String, double> _femaleWeightMedian = {
    '0': 3.2, // Doğum
    '1': 4.2, // 1 ay
    '2': 5.1, // 2 ay
    '3': 5.8, // 3 ay
    '4': 6.4, // 4 ay
    '5': 6.9, // 5 ay
    '6': 7.3, // 6 ay
    '7': 7.6, // 7 ay
    '8': 7.9, // 8 ay
    '9': 8.2, // 9 ay
    '10': 8.5, // 10 ay
    '11': 8.7, // 11 ay
    '12': 9.35, // 12 ay (ortalama 8.9-9.8)
    '24': 11.5, // 2 yaş
    '36': 13.9, // 3 yaş
    '48': 16.0, // 4 yaş
  };

  // Kız için WHO kilo alt sınır (%3)
  static const Map<String, double> _femaleWeightMin = {
    '0': 2.3, // Doğum
    '1': 3.2, // 1 ay
    '2': 3.9, // 2 ay
    '3': 4.5, // 3 ay
    '4': 5.0, // 4 ay
    '5': 5.4, // 5 ay
    '6': 5.7, // 6 ay
    '7': 5.9, // 7 ay
    '8': 6.1, // 8 ay
    '9': 6.3, // 9 ay
    '10': 6.5, // 10 ay
    '11': 6.6, // 11 ay
    '12': 6.8, // 12 ay
    '24': 8.9, // 2 yaş
    '36': 10.9, // 3 yaş
    '48': 13.0, // 4 yaş
  };

  // Kız için WHO kilo üst sınır (%97)
  static const Map<String, double> _femaleWeightMax = {
    '0': 4.2, // Doğum
    '1': 5.5, // 1 ay
    '2': 6.6, // 2 ay
    '3': 7.5, // 3 ay
    '4': 8.2, // 4 ay
    '5': 8.8, // 5 ay
    '6': 9.3, // 6 ay
    '7': 9.8, // 7 ay
    '8': 10.2, // 8 ay
    '9': 10.6, // 9 ay
    '10': 11.0, // 10 ay
    '11': 11.3, // 11 ay
    '12': 11.7, // 12 ay
    '24': 14.8, // 2 yaş
    '36': 17.9, // 3 yaş
    '48': 21.2, // 4 yaş
  };

  // Erkek için WHO boy alt sınır (%3)
  static const Map<String, double> _maleHeightMin = {
    '0': 46.1, // Doğum
    '1': 50.8, // 1 ay
    '2': 54.4, // 2 ay
    '3': 57.3, // 3 ay
    '4': 59.8, // 4 ay
    '5': 61.7, // 5 ay
    '6': 63.3, // 6 ay
    '7': 64.9, // 7 ay
    '8': 66.3, // 8 ay
    '9': 67.7, // 9 ay
    '10': 69.0, // 10 ay
    '11': 70.2, // 11 ay
    '12': 71.3, // 12 ay
    '24': 82.3, // 2 yaş
    '36': 90.0, // 3 yaş
    '48': 96.8, // 4 yaş
  };

  // Erkek için WHO boy üst sınır (%97)
  static const Map<String, double> _maleHeightMax = {
    '0': 53.7, // Doğum
    '1': 58.6, // 1 ay
    '2': 62.4, // 2 ay
    '3': 65.5, // 3 ay
    '4': 68.1, // 4 ay
    '5': 70.2, // 5 ay
    '6': 72.0, // 6 ay
    '7': 73.7, // 7 ay
    '8': 75.2, // 8 ay
    '9': 76.6, // 9 ay
    '10': 77.9, // 10 ay
    '11': 79.2, // 11 ay
    '12': 80.4, // 12 ay
    '24': 93.2, // 2 yaş
    '36': 102.3, // 3 yaş
    '48': 110.0, // 4 yaş
  };

  // Kız için WHO boy alt sınır (%3)
  static const Map<String, double> _femaleHeightMin = {
    '0': 45.4, // Doğum
    '1': 49.9, // 1 ay
    '2': 53.3, // 2 ay
    '3': 56.0, // 3 ay
    '4': 58.3, // 4 ay
    '5': 60.2, // 5 ay
    '6': 61.0, // 6 ay
    '7': 62.6, // 7 ay
    '8': 64.0, // 8 ay
    '9': 65.4, // 9 ay
    '10': 66.8, // 10 ay
    '11': 68.2, // 11 ay
    '12': 69.3, // 12 ay
    '24': 81.0, // 2 yaş
    '36': 89.0, // 3 yaş
    '48': 96.1, // 4 yaş
  };

  // Kız için WHO boy üst sınır (%97)
  static const Map<String, double> _femaleHeightMax = {
    '0': 52.9, // Doğum
    '1': 57.4, // 1 ay
    '2': 61.0, // 2 ay
    '3': 63.8, // 3 ay
    '4': 66.0, // 4 ay
    '5': 68.0, // 5 ay
    '6': 69.8, // 6 ay
    '7': 71.5, // 7 ay
    '8': 73.0, // 8 ay
    '9': 74.5, // 9 ay
    '10': 75.9, // 10 ay
    '11': 77.3, // 11 ay
    '12': 78.7, // 12 ay
    '24': 92.0, // 2 yaş
    '36': 101.2, // 3 yaş
    '48': 109.4, // 4 yaş
  };

  // Bebeğin yaşına göre uygun WHO ageKey'ini döndür
  static String? _getAgeKey(Baby baby) {
    final now = DateTime.now();
    final birthDate = baby.birthDate;

    int ageInDays = now.difference(birthDate).inDays;
    if (ageInDays < 0) return null;

    int ageInMonths = ageInDays ~/ 30;
    int ageInYears = ageInDays ~/ 365;

    if (ageInDays == 0) {
      return '0';
    } else if (ageInDays < 30) {
      return '0'; // Doğum değerini kullan
    } else if (ageInMonths < 12) {
      return ageInMonths.toString();
    } else if (ageInYears < 5) {
      if (ageInMonths < 24) {
        return '12';
      } else if (ageInMonths < 36) {
        return '24';
      } else if (ageInMonths < 48) {
        return '36';
      } else {
        return '48';
      }
    }
    return null; // 5 yaş üstü için veri yok
  }

  // Bebeğin yaşına göre WHO kilo hedef değerlerini döndür (min, max)
  static Map<String, double>? getWhoWeightTargets(Baby baby) {
    final ageKey = _getAgeKey(baby);
    if (ageKey == null) return null;

    final weightMin = baby.gender == Gender.male
        ? _maleWeightMin
        : _femaleWeightMin;
    final weightMax = baby.gender == Gender.male
        ? _maleWeightMax
        : _femaleWeightMax;

    final min = weightMin[ageKey];
    final max = weightMax[ageKey];

    if (min == null || max == null) return null;

    return {'min': min, 'max': max};
  }

  // Bebeğin yaşına göre WHO boy hedef değerlerini döndür (min, max)
  static Map<String, double>? getWhoHeightTargets(Baby baby) {
    final ageKey = _getAgeKey(baby);
    if (ageKey == null) return null;

    final heightMin = baby.gender == Gender.male
        ? _maleHeightMin
        : _femaleHeightMin;
    final heightMax = baby.gender == Gender.male
        ? _maleHeightMax
        : _femaleHeightMax;

    final min = heightMin[ageKey];
    final max = heightMax[ageKey];

    if (min == null || max == null) return null;

    return {'min': min, 'max': max};
  }

  // Bebeğin yaşını hesapla ve uygun WHO değerini döndür
  static String? getWhoWeightInfo(Baby baby) {
    final now = DateTime.now();
    final birthDate = baby.birthDate;

    // Yaş hesaplama
    int ageInDays = now.difference(birthDate).inDays;

    if (ageInDays < 0) return null; // Gelecek tarih

    int ageInMonths = ageInDays ~/ 30;
    int ageInYears = ageInDays ~/ 365;

    // Veri tablosundan uygun değeri bul
    final ageKey = _getAgeKey(baby);
    if (ageKey == null) return null;

    String ageLabel;

    if (ageInDays == 0) {
      ageLabel = 'doğumda';
    } else if (ageInDays < 30) {
      ageLabel = '1. aya kadar';
    } else if (ageInMonths < 12) {
      final nextMonth = ageInMonths + 1;
      ageLabel = '$nextMonth. aya kadar';
    } else if (ageInYears < 5) {
      // 12, 24, 36, 48 ay değerleri
      if (ageInMonths < 24) {
        ageLabel = '2. yaşa kadar';
      } else if (ageInMonths < 36) {
        ageLabel = '3. yaşa kadar';
      } else if (ageInMonths < 48) {
        ageLabel = '4. yaşa kadar';
      } else {
        ageLabel = '5. yaşa kadar';
      }
    } else {
      // 5 yaş üstü için veri yok
      return null;
    }

    // Cinsiyete göre değerleri al
    final weightMedian = baby.gender == Gender.male
        ? _maleWeightMedian
        : _femaleWeightMedian;
    final weightMin = baby.gender == Gender.male
        ? _maleWeightMin
        : _femaleWeightMin;
    final weightMax = baby.gender == Gender.male
        ? _maleWeightMax
        : _femaleWeightMax;

    final expectedWeight = weightMedian[ageKey];
    final minWeight = weightMin[ageKey];
    final maxWeight = weightMax[ageKey];

    if (expectedWeight == null || minWeight == null || maxWeight == null) {
      return null;
    }

    // Mesaj formatını yaş etiketine göre ayarla
    String message;
    if (ageInDays == 0) {
      message =
          'Dünya Sağlık Örgütü\'nün verilerine göre bebeğiniz doğumda ${expectedWeight.toStringAsFixed(1)} kiloda (alt sınır: ${minWeight.toStringAsFixed(1)} kg, üst sınır: ${maxWeight.toStringAsFixed(1)} kg) olması öngörülmektedir';
    } else {
      message =
          'Dünya Sağlık Örgütü\'nün verilerine göre $ageLabel bebeğiniz ${expectedWeight.toStringAsFixed(1)} kiloda (alt sınır: ${minWeight.toStringAsFixed(1)} kg, üst sınır: ${maxWeight.toStringAsFixed(1)} kg) olması öngörülmektedir';
    }

    return message;
  }
}
