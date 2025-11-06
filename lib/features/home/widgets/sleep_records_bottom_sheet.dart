import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/models/sleep_model.dart';
import '../../../core/services/sleep_service.dart';
import '../../../shared/widgets/sleep_tracking_sheet.dart';

class SleepRecordsBottomSheet extends StatefulWidget {
  final List<Sleep> sleeps;
  final DateTime selectedDate;

  const SleepRecordsBottomSheet({
    super.key,
    required this.sleeps,
    required this.selectedDate,
  });

  @override
  State<SleepRecordsBottomSheet> createState() =>
      _SleepRecordsBottomSheetState();
}

class _SleepRecordsBottomSheetState extends State<SleepRecordsBottomSheet> {
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(DateTime start, DateTime? end) {
    if (end == null) return 'Devam ediyor';

    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}s ${minutes}dk';
    } else {
      return '${minutes}dk';
    }
  }

  Future<void> _deleteSleep(Sleep sleep) async {
    try {
      await SleepService.deleteSleep(sleep.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uyku kaydı silindi'),
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

  void _showDeleteDialog(Sleep sleep) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uyku Kaydını Sil'),
        content: Text(
          '${_formatTime(sleep.startTime)} - ${sleep.endTime != null ? _formatTime(sleep.endTime!) : 'Devam ediyor'} '
          'tarihli uyku kaydını silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteSleep(sleep);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editSleep(Sleep sleep) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SleepTrackingSheet(
        sleepToEdit: sleep, // Edit modunda mevcut veriyi geç
        onSleepSaved: () {
          Navigator.of(context).pop();
          // Refresh the parent screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Uyku kaydı güncellendi'),
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.bedtime_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Uyku Kayıtları',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${widget.sleeps.length} kayıt',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),

          // Sleep Records List
          if (widget.sleeps.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.bedtime_outlined,
                    size: 48,
                    color: AppColors.mutedForeground,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bu tarihte uyku kaydı yok',
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
              itemCount: widget.sleeps.length,
              itemBuilder: (context, index) {
                final sleep = widget.sleeps[index];
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
                                '${_formatTime(sleep.startTime)} - ${sleep.endTime != null ? _formatTime(sleep.endTime!) : 'Devam ediyor'}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDuration(sleep.startTime, sleep.endTime),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.mutedForeground,
                                    ),
                              ),
                              if (sleep.notes != null &&
                                  sleep.notes!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  sleep.notes!,
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
                              onPressed: () => _editSleep(sleep),
                              icon: const Icon(Icons.edit_outlined),
                              color: AppColors.primary,
                            ),
                            IconButton(
                              onPressed: () => _showDeleteDialog(sleep),
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
  }
}
