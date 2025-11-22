import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/memory_model.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../core/services/memory_service.dart';

class MemoryCard extends StatefulWidget {
  final Memory memory;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteChanged;

  const MemoryCard({
    super.key,
    required this.memory,
    this.onTap,
    this.onFavoriteChanged,
  });

  @override
  State<MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends State<MemoryCard> {
  late Memory _currentMemory;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _currentMemory = widget.memory;
  }

  @override
  void didUpdateWidget(MemoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.memory.id != oldWidget.memory.id ||
        widget.memory.isFavorite != oldWidget.memory.isFavorite) {
      _currentMemory = widget.memory;
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isToggling) return;

    setState(() {
      _isToggling = true;
    });

    try {
      final updatedMemory = await MemoryService.toggleFavorite(_currentMemory.id);
      setState(() {
        _currentMemory = updatedMemory;
        _isToggling = false;
      });

      // Callback to refresh parent
      widget.onFavoriteChanged?.call();
    } catch (e) {
      setState(() {
        _isToggling = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Favori durumu güncellenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return GestureDetector(
          onTap: widget.onTap,
          child: CustomCard(
            padding: EdgeInsets.zero,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Media Preview - Skip for note type
                    if (_currentMemory.type != MemoryType.note)
                      _buildMediaPreview(themeProvider),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and Type
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _currentMemory.title,
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
                              _buildTypeBadge(themeProvider),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Description
                          if (_currentMemory.description != null &&
                              _currentMemory.description!.isNotEmpty) ...[
                            Text(
                              _currentMemory.description!,
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
                                '${_currentMemory.memoryDate.day}/${_currentMemory.memoryDate.month}/${_currentMemory.memoryDate.year}',
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
                // Heart Icon - Bottom Right
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      _toggleFavorite();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: themeProvider.cardBackground.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _isToggling
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              _currentMemory.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _currentMemory.isFavorite
                                  ? Colors.red
                                  : themeProvider.mutedForegroundColor,
                              size: 20,
                            ),
                    ),
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
    if (_currentMemory.type == MemoryType.note) {
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

    if (_currentMemory.mediaUrl != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(color: themeProvider.cardBackground),
          child: _currentMemory.type == MemoryType.photo
              ? Image.network(
                  _currentMemory.mediaUrl!,
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
    switch (_currentMemory.type) {
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
    switch (_currentMemory.type) {
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
    final difference = now.difference(_currentMemory.memoryDate);

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
