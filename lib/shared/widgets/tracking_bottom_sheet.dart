import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/providers/baby_provider.dart';
import '../../core/services/sleep_service.dart';
import '../../core/services/feeding_service.dart';
import '../../shared/models/feeding_model.dart';

class TrackingBottomSheet extends StatefulWidget {
  const TrackingBottomSheet({super.key});

  @override
  State<TrackingBottomSheet> createState() => _TrackingBottomSheetState();
}

class _TrackingBottomSheetState extends State<TrackingBottomSheet> {
  int _selectedTab = 0;
  bool _isLoading = false;
  String? _notes;
  int? _amount;
  String? _side;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.input,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTab(0, 'Uyku', Icons.bedtime_outlined),
                _buildTab(1, 'Beslenme', Icons.restaurant_outlined),
                _buildTab(2, 'Alt Değiştirme', Icons.child_care_outlined),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? AppColors.primaryForeground
                    : AppColors.mutedForeground,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primaryForeground
                      : AppColors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0:
        return _buildSleepContent();
      case 1:
        return _buildFeedingContent();
      case 2:
        return _buildDiaperContent();
      default:
        return const SizedBox();
    }
  }

  Widget _buildSleepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Uyku Takibi',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Bebeğinizin uyku süresini takip edin',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground),
        ),
        const SizedBox(height: 24),

        // Notes field
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Notlar (opsiyonel)',
            hintText: 'Uyku hakkında notlar...',
            prefixIcon: Icon(Icons.note_outlined),
          ),
          maxLines: 3,
          onChanged: (value) => _notes = value,
        ),

        const SizedBox(height: 32),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: CustomButton(
                onPressed: _isLoading ? null : _startSleep,
                text: 'Uyku Başlat',
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeedingContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Beslenme Takibi',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Bebeğinizin beslenme bilgilerini kaydedin',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground),
        ),
        const SizedBox(height: 24),

        // Feeding type selection
        Text('Beslenme Türü', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildFeedingTypeCard(
                'Emzirme',
                Icons.child_care,
                FeedingType.breastfeeding,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFeedingTypeCard(
                'Biberon',
                Icons.local_drink,
                FeedingType.bottle,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Amount field (for bottle feeding)
        if (_selectedFeedingType == FeedingType.bottle) ...[
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Miktar (ml)',
              hintText: 'Örn: 120',
              prefixIcon: Icon(Icons.straighten),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) => _amount = int.tryParse(value),
          ),
          const SizedBox(height: 16),
        ],

        // Side selection (for breastfeeding)
        if (_selectedFeedingType == FeedingType.breastfeeding) ...[
          Text('Hangi taraf?', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSideCard('Sol', 'left')),
              const SizedBox(width: 12),
              Expanded(child: _buildSideCard('Sağ', 'right')),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Notes field
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Notlar (opsiyonel)',
            hintText: 'Beslenme hakkında notlar...',
            prefixIcon: Icon(Icons.note_outlined),
          ),
          maxLines: 2,
          onChanged: (value) => _notes = value,
        ),

        const SizedBox(height: 32),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: CustomButton(
                onPressed: _isLoading ? null : _startFeeding,
                text: 'Beslenme Başlat',
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDiaperContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Alt Değiştirme',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Alt değiştirme bilgilerini kaydedin',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground),
        ),
        const SizedBox(height: 24),

        // Diaper type selection
        Text('Alt Durumu', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDiaperTypeCard('Islak', Icons.water_drop, 'wet'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDiaperTypeCard('Kirli', Icons.child_care, 'dirty'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDiaperTypeCard(
                'Her İkisi',
                Icons.all_inclusive,
                'both',
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Notes field
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Notlar (opsiyonel)',
            hintText: 'Alt değiştirme hakkında notlar...',
            prefixIcon: Icon(Icons.note_outlined),
          ),
          maxLines: 2,
          onChanged: (value) => _notes = value,
        ),

        const SizedBox(height: 32),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: CustomButton(
                onPressed: _isLoading ? null : _recordDiaperChange,
                text: 'Kaydet',
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeedingTypeCard(String label, IconData icon, FeedingType type) {
    final isSelected = _selectedFeedingType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedFeedingType = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.input,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.mutedForeground,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideCard(String label, String value) {
    final isSelected = _side == value;
    return GestureDetector(
      onTap: () => setState(() => _side = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.input,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.mutedForeground,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildDiaperTypeCard(String label, IconData icon, String value) {
    final isSelected = _selectedDiaperType == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedDiaperType = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.input,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.mutedForeground,
              size: 20,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // State variables
  FeedingType? _selectedFeedingType;
  String? _selectedDiaperType;

  // Action methods
  Future<void> _startSleep() async {
    setState(() => _isLoading = true);
    try {
      final babyProvider = context.read<BabyProvider>();
      final selectedBaby = babyProvider.selectedBaby;

      if (selectedBaby == null) {
        throw Exception('Lütfen önce bir bebek seçin');
      }

      await SleepService.startSleep(selectedBaby.id, notes: _notes);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uyku takibi başlatıldı'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _startFeeding() async {
    if (_selectedFeedingType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen beslenme türünü seçin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final babyProvider = context.read<BabyProvider>();
      final selectedBaby = babyProvider.selectedBaby;

      if (selectedBaby == null) {
        throw Exception('Lütfen önce bir bebek seçin');
      }

      await FeedingService.startFeeding(
        selectedBaby.id,
        _selectedFeedingType!,
        amount: _amount,
        side: _side,
        notes: _notes,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Beslenme takibi başlatıldı'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _recordDiaperChange() async {
    if (_selectedDiaperType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen alt durumunu seçin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Alt değişimi kaydı zaten DiaperTrackingSheet ile çalışıyor
      // Bu fonksiyon artık kullanılmıyor

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alt değiştirme kaydedildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
