import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/memory_model.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/widgets/custom_card.dart';

class MemoryCard extends StatelessWidget {
  final Memory memory;
  final VoidCallback? onTap;

  const MemoryCard({super.key, required this.memory, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return GestureDetector(
          onTap: onTap,
          child: CustomCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Media Preview - Skip for note type
                if (memory.type != MemoryType.note)
                  _buildMediaPreview(themeProvider),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title, Favorite and Type
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              memory.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: themeProvider.cardForeground,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Favorite Icon
                          if (memory.isFavorite) ...[
                            Icon(Icons.favorite, size: 16, color: Colors.red),
                            const SizedBox(width: 8),
                          ],
                          _buildTypeBadge(themeProvider),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Description
                      if (memory.description != null &&
                          memory.description!.isNotEmpty) ...[
                        Text(
                          memory.description!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: themeProvider.mutedForegroundColor,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Date and Time
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: themeProvider.mutedForegroundColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${memory.memoryDate.day}/${memory.memoryDate.month}/${memory.memoryDate.year}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: themeProvider.mutedForegroundColor,
                                ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: themeProvider.mutedForegroundColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getTimeAgo(),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: themeProvider.mutedForegroundColor,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMediaPreview(ThemeProvider themeProvider) {
    // For note type, always show icon preview regardless of mediaUrl
    if (memory.type == MemoryType.note) {
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: themeProvider.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Center(
          child: Icon(
            _getTypeIcon(),
            size: 48,
            color: themeProvider.primaryColor,
          ),
        ),
      );
    }

    if (memory.mediaUrl != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(color: themeProvider.cardBackground),
          child: memory.type == MemoryType.photo
              ? Image.network(
                  memory.mediaUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: themeProvider.cardBackground,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: themeProvider.cardBackground,
                      child: Icon(
                        Icons.broken_image,
                        size: 48,
                        color: themeProvider.mutedForegroundColor,
                      ),
                    );
                  },
                )
              : Container(
                  color: themeProvider.cardBackground,
                  child: Center(
                    child: Icon(
                      _getTypeIcon(),
                      size: 48,
                      color: themeProvider.primaryColor,
                    ),
                  ),
                ),
        ),
      );
    }

    // Default preview for memories without media
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: themeProvider.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Center(
        child: Icon(
          _getTypeIcon(),
          size: 48,
          color: themeProvider.primaryColor,
        ),
      ),
    );
  }

  Widget _buildTypeBadge(ThemeProvider themeProvider) {
    final typeInfo = _getTypeInfo();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: themeProvider.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeProvider.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(typeInfo['icon'], size: 12, color: themeProvider.primaryColor),
          const SizedBox(width: 4),
          Text(
            typeInfo['name'],
            style: TextStyle(
              color: themeProvider.primaryColor,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (memory.type) {
      case MemoryType.photo:
        return Icons.photo;
      case MemoryType.note:
        return Icons.note_alt;
      case MemoryType.milestone:
        return Icons.emoji_events;
      case MemoryType.development:
        return Icons.trending_up;
    }
  }

  Map<String, dynamic> _getTypeInfo() {
    switch (memory.type) {
      case MemoryType.photo:
        return {'icon': Icons.photo, 'name': 'Fotoğraf'};
      case MemoryType.note:
        return {'icon': Icons.note_alt, 'name': 'Not'};
      case MemoryType.milestone:
        return {'icon': Icons.emoji_events, 'name': 'Kilometre Taşı'};
      case MemoryType.development:
        return {'icon': Icons.trending_up, 'name': 'Gelişim'};
    }
  }

  String _getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(memory.memoryDate);

    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }
}
