import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/memory_model.dart';
import '../../../shared/providers/theme_provider.dart';
import '../screens/add_media_memory_screen.dart';
import '../screens/add_note_memory_screen.dart';

class AddMemorySheet extends StatefulWidget {
  final VoidCallback? onMemoryAdded;

  const AddMemorySheet({super.key, this.onMemoryAdded});

  @override
  State<AddMemorySheet> createState() => _AddMemorySheetState();
}

class _AddMemorySheetState extends State<AddMemorySheet> {
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
              // Title
              Text(
                'Anı Ekle',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: themeProvider.cardForeground,
                ),
              ),
              const SizedBox(height: 24),
              // Memory Type Options
              Row(
                children: [
                  Expanded(
                    child: _buildMemoryTypeOption(
                      context,
                      MemoryType.photo,
                      'Fotoğraf',
                      Icons.photo_camera,
                      Colors.blue,
                      () => _showMediaMemorySheet(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMemoryTypeOption(
                      context,
                      MemoryType.note,
                      'Not',
                      Icons.note,
                      Colors.orange,
                      () => _showNoteMemorySheet(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMemoryTypeOption(
    BuildContext context,
    MemoryType type,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showMediaMemorySheet(BuildContext context) {
    Navigator.pop(context);
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (context) => const AddMediaMemoryScreen()),
        )
        .then((result) {
          if (result == true && widget.onMemoryAdded != null) {
            widget.onMemoryAdded!();
          }
        });
  }

  void _showNoteMemorySheet(BuildContext context) {
    Navigator.pop(context);
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (context) => const AddNoteMemoryScreen()),
        )
        .then((result) {
          if (result == true && widget.onMemoryAdded != null) {
            widget.onMemoryAdded!();
          }
        });
  }
}
