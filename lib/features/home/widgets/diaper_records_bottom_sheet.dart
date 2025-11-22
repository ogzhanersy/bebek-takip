import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/models/diaper_model.dart';
import '../../../core/services/diaper_service.dart';
import '../../../shared/widgets/diaper_tracking_sheet.dart';
import '../../../shared/providers/theme_provider.dart';

class DiaperRecordsBottomSheet extends StatefulWidget {
  final List<Diaper> diapers;
  final DateTime selectedDate;

  const DiaperRecordsBottomSheet({
    super.key,
    required this.diapers,
    required this.selectedDate,
  });

  @override
  State<DiaperRecordsBottomSheet> createState() =>
      _DiaperRecordsBottomSheetState();
}

class _DiaperRecordsBottomSheetState extends State<DiaperRecordsBottomSheet> {
  String _formatTime(DateTime dateTime) {
    // dateTime is already in local timezone from fromJson()
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getDiaperTypeText(DiaperType type) {
    switch (type) {
      case DiaperType.wet:
        return 'Islak';
      case DiaperType.dirty:
        return 'Kirli';
      case DiaperType.mixed:
        return 'Hem Islak Hem Kirli';
    }
  }

  Color _getDiaperTypeColor(DiaperType type) {
    switch (type) {
      case DiaperType.wet:
        return Colors.red; // Kırmızı
      case DiaperType.dirty:
        return Colors.red; // Kırmızı
      case DiaperType.mixed:
        return Colors.orange;
    }
  }

  Future<void> _deleteDiaper(Diaper diaper) async {
    try {
      await DiaperService.deleteDiaper(diaper.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alt değişimi kaydı silindi'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to refresh parent
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silme işlemi başarısız: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteDialog(Diaper diaper) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alt Değişimi Kaydını Sil'),
        content: Text(
          '${_formatTime(diaper.time)} - ${_getDiaperTypeText(diaper.type)} '
          'tarihli alt değişimi kaydını silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteDiaper(diaper);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editDiaper(Diaper diaper) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DiaperTrackingSheet(
        diaperToEdit: diaper, // Edit modunda mevcut veriyi geç
        onDiaperSaved: () {
          if (mounted) {
            Navigator.of(context).pop();
            // Refresh the parent screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Alt değişimi kaydı güncellendi'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    ).then((_) {
      // Günlük özet sayfasını yenile
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    });
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: themeProvider.mutedForegroundColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.child_care_outlined,
                      color: AppColors.babyGreen,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Alt Değişimi Kayıtları',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${widget.diapers.length} kayıt',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),

              // Diaper Records List
              if (widget.diapers.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.child_care_outlined,
                        size: 48,
                        color: AppColors.mutedForeground,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bu tarihte alt değişimi kaydı yok',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.diapers.length,
                  itemBuilder: (context, index) {
                    final diaper = widget.diapers[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      child: CustomCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Time Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatTime(diaper.time),
                                    style: Theme.of(context).textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getDiaperTypeColor(
                                        diaper.type,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _getDiaperTypeText(diaper.type),
                                      style: Theme.of(context).textTheme.bodySmall
                                          ?.copyWith(
                                            color: _getDiaperTypeColor(diaper.type),
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                  if (diaper.notes != null &&
                                      diaper.notes!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      diaper.notes!,
                                      style: Theme.of(context).textTheme.bodySmall
                                          ?.copyWith(
                                            color: AppColors.mutedForeground,
                                            fontStyle: FontStyle.italic,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Actions
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => _editDiaper(diaper),
                                  icon: const Icon(Icons.edit_outlined),
                                  color: AppColors.primary,
                                ),
                                IconButton(
                                  onPressed: () => _showDeleteDialog(diaper),
                                  icon: const Icon(Icons.delete_outline),
                                  color: Colors.red,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              // Bottom padding
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
