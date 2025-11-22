import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/models/feeding_model.dart';
import '../../../core/services/feeding_service.dart';
import '../../../shared/widgets/feeding_tracking_sheet.dart';
import '../../../shared/providers/theme_provider.dart';

class FeedingRecordsBottomSheet extends StatefulWidget {
  final List<Feeding> feedings;
  final DateTime selectedDate;

  const FeedingRecordsBottomSheet({
    super.key,
    required this.feedings,
    required this.selectedDate,
  });

  @override
  State<FeedingRecordsBottomSheet> createState() =>
      _FeedingRecordsBottomSheetState();
}

class _FeedingRecordsBottomSheetState extends State<FeedingRecordsBottomSheet> {
  String _formatTime(DateTime dateTime) {
    // dateTime is already in local timezone from fromJson()
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(DateTime start, DateTime? end) {
    if (end == null) return '';

    final duration = end.difference(start);
    final minutes = duration.inMinutes;

    return '${minutes}dk';
  }

  Future<void> _deleteFeeding(Feeding feeding) async {
    try {
      await FeedingService.deleteFeeding(feeding.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Beslenme kaydı silindi'),
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

  void _showDeleteDialog(Feeding feeding) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Beslenme Kaydını Sil'),
        content: Text(
          '${_formatTime(feeding.startTime)}${feeding.endTime != null ? ' - ${_formatTime(feeding.endTime!)}' : ''} '
          'tarihli beslenme kaydını silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteFeeding(feeding);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editFeeding(Feeding feeding) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FeedingTrackingSheet(
        feedingToEdit: feeding, // Edit modunda mevcut veriyi geç
        onFeedingSaved: () {
          Navigator.of(context).pop();
          // Refresh the parent screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Beslenme kaydı güncellendi'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    ).then((_) {
      // Günlük özet sayfasını yenile
      Navigator.of(context).pop(true);
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
                    Text(
                      '🍼',
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Beslenme Kayıtları',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${widget.feedings.length} kayıt',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),

              // Feeding Records List
              if (widget.feedings.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Text(
                        '🍼',
                        style: TextStyle(fontSize: 48),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bu tarihte beslenme kaydı yok',
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
                  itemCount: widget.feedings.length,
                  itemBuilder: (context, index) {
                    final feeding = widget.feedings[index];
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
                                    '${_formatTime(feeding.startTime)}${feeding.endTime != null ? ' - ${_formatTime(feeding.endTime!)}' : ''}',
                                    style: Theme.of(context).textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      // Feeding type indicator
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: feeding.type == FeedingType.breastfeeding
                                              ? AppColors.babyPink.withValues(alpha: 0.2)
                                              : AppColors.primary.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            feeding.type == FeedingType.breastfeeding
                                                ? Icon(
                                                    Icons.favorite,
                                                    size: 14,
                                                    color: AppColors.babyPink,
                                                  )
                                                : Text(
                                                    '🍼',
                                                    style: TextStyle(fontSize: 14),
                                                  ),
                                            const SizedBox(width: 4),
                                            Text(
                                              feeding.type == FeedingType.breastfeeding
                                                  ? 'Emzirme'
                                                  : 'Harici Beslenme',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: feeding.type == FeedingType.breastfeeding
                                                        ? AppColors.babyPink
                                                        : AppColors.primary,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (feeding.type == FeedingType.breastfeeding &&
                                          feeding.side != null) ...[
                                        Text(
                                          '(${feeding.side == 'left' ? 'Sol' : 'Sağ'})',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppColors.mutedForeground,
                                              ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      if (feeding.amount != null) ...[
                                        Text(
                                          '${feeding.amount}ml',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppColors.mutedForeground,
                                              ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Text(
                                        _formatDuration(
                                          feeding.startTime,
                                          feeding.endTime,
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppColors.mutedForeground,
                                            ),
                                      ),
                                    ],
                                  ),
                                  if (feeding.notes != null &&
                                      feeding.notes!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      feeding.notes!,
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
                                  onPressed: () => _editFeeding(feeding),
                                  icon: const Icon(Icons.edit_outlined),
                                  color: AppColors.primary,
                                ),
                                IconButton(
                                  onPressed: () => _showDeleteDialog(feeding),
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
