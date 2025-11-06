import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/memory_model.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../core/services/memory_service.dart';
import 'memory_edit_screen.dart';

class MemoryDetailScreen extends StatefulWidget {
  final Memory memory;
  final VoidCallback? onMemoryDeleted;
  final VoidCallback? onMemoryUpdated;

  const MemoryDetailScreen({
    super.key,
    required this.memory,
    this.onMemoryDeleted,
    this.onMemoryUpdated,
  });

  @override
  State<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends State<MemoryDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Memory _currentMemory;

  @override
  void initState() {
    super.initState();
    _currentMemory = widget.memory;
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: themeProvider.homeBackgroundGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(themeProvider),

                  // Content
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Media Section
                              _buildMediaSection(themeProvider),

                              const SizedBox(height: 24),

                              // Details Section
                              _buildDetailsSection(themeProvider),

                              const SizedBox(height: 24),

                              // Actions Section
                              _buildActionsSection(themeProvider),

                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeProvider themeProvider) {
    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_back_ios,
                color: themeProvider.primaryColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _currentMemory.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: themeProvider.cardForeground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: _deleteMemory,
            icon: Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection(ThemeProvider themeProvider) {
    // Don't show media section for note type
    if (_currentMemory.type == MemoryType.note) {
      return const SizedBox.shrink();
    }

    return CustomCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildMediaContent(themeProvider),
      ),
    );
  }

  Widget _buildMediaContent(ThemeProvider themeProvider) {
    switch (_currentMemory.type) {
      case MemoryType.photo:
        if (_currentMemory.mediaUrl != null) {
          return AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
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
                  height: 200,
                  color: themeProvider.cardBackground,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 48,
                          color: themeProvider.mutedForegroundColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Fotoğraf yüklenemedi',
                          style: TextStyle(
                            color: themeProvider.mutedForegroundColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }
        break;
      case MemoryType.note:
        return Container(
          padding: const EdgeInsets.all(24),
          child: Icon(
            Icons.note_alt,
            size: 64,
            color: themeProvider.primaryColor,
          ),
        );
      case MemoryType.milestone:
        return Container(
          padding: const EdgeInsets.all(24),
          child: Icon(
            Icons.emoji_events,
            size: 64,
            color: themeProvider.primaryColor,
          ),
        );
      case MemoryType.development:
        return Container(
          padding: const EdgeInsets.all(24),
          child: Icon(
            Icons.trending_up,
            size: 64,
            color: themeProvider.primaryColor,
          ),
        );
    }

    // Default fallback
    return Container(
      height: 200,
      color: themeProvider.cardBackground,
      child: Center(
        child: Icon(
          Icons.memory,
          size: 64,
          color: themeProvider.mutedForegroundColor,
        ),
      ),
    );
  }

  Widget _buildDetailsSection(ThemeProvider themeProvider) {
    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Memory Type Badge
          _buildTypeBadge(themeProvider),

          const SizedBox(height: 16),

          // Description
          if (_currentMemory.description != null &&
              _currentMemory.description!.isNotEmpty) ...[
            Text(
              'Açıklama',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: themeProvider.cardForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentMemory.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: themeProvider.mutedForegroundColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Date Information
          _buildDateInfo(themeProvider),

          const SizedBox(height: 16),

          // Metadata
          if (_currentMemory.metadata != null &&
              _currentMemory.metadata!.isNotEmpty) ...[
            Text(
              'Detaylar',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: themeProvider.cardForeground,
              ),
            ),
            const SizedBox(height: 8),
            _buildMetadataInfo(themeProvider),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeBadge(ThemeProvider themeProvider) {
    final typeInfo = _getTypeInfo();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: themeProvider.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: themeProvider.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(typeInfo['icon'], size: 16, color: themeProvider.primaryColor),
          const SizedBox(width: 6),
          Text(
            typeInfo['name'],
            style: TextStyle(
              color: themeProvider.primaryColor,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(ThemeProvider themeProvider) {
    final now = DateTime.now();
    final memoryDate = _currentMemory.memoryDate;
    final difference = now.difference(memoryDate);

    String timeAgo;
    if (difference.inDays > 0) {
      timeAgo = '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      timeAgo = '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      timeAgo = '${difference.inMinutes} dakika önce';
    } else {
      timeAgo = 'Az önce';
    }

    return Row(
      children: [
        Icon(
          Icons.calendar_today,
          size: 16,
          color: themeProvider.mutedForegroundColor,
        ),
        const SizedBox(width: 8),
        Text(
          '${memoryDate.day}/${memoryDate.month}/${memoryDate.year}',
          style: TextStyle(
            color: themeProvider.cardForeground,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Icon(
          Icons.access_time,
          size: 16,
          color: themeProvider.mutedForegroundColor,
        ),
        const SizedBox(width: 8),
        Text(
          timeAgo,
          style: TextStyle(color: themeProvider.mutedForegroundColor),
        ),
      ],
    );
  }

  Widget _buildMetadataInfo(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _currentMemory.metadata!.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  '${entry.key}:',
                  style: TextStyle(
                    color: themeProvider.mutedForegroundColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  entry.value.toString(),
                  style: TextStyle(color: themeProvider.cardForeground),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionsSection(ThemeProvider themeProvider) {
    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: _currentMemory.isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                  label: _currentMemory.isFavorite
                      ? 'Favoriden Çıkar'
                      : 'Favorile',
                  onTap: _toggleFavorite,
                  themeProvider: themeProvider,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.share,
                  label: 'Paylaş',
                  onTap: _shareMemory,
                  themeProvider: themeProvider,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.edit,
                  label: 'Düzenle',
                  onTap: _editMemory,
                  themeProvider: themeProvider,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeProvider themeProvider,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: themeProvider.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: themeProvider.borderColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: themeProvider.primaryColor, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: themeProvider.cardForeground,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
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

  void _toggleFavorite() async {
    try {
      // Toggle favorite status in Supabase
      await MemoryService.toggleFavorite(_currentMemory.id);

      // Update local state
      setState(() {
        _currentMemory = _currentMemory.copyWith(
          isFavorite: !_currentMemory.isFavorite,
        );
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _currentMemory.isFavorite
                  ? 'Favorilere eklendi ❤️'
                  : 'Favorilerden çıkarıldı',
            ),
            backgroundColor: _currentMemory.isFavorite
                ? Colors.red
                : Colors.grey,
            duration: const Duration(seconds: 2),
          ),
        );

        // Callback to refresh the memories list
        if (widget.onMemoryUpdated != null) {
          widget.onMemoryUpdated!();
        }
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Favori durumu güncellenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _shareMemory() {
    try {
      final memory = _currentMemory;
      final dateFormatter = DateFormat('dd MMMM yyyy', 'tr_TR');
      final timeFormatter = DateFormat('HH:mm', 'tr_TR');

      String shareText = '${memory.typeEmoji} ${memory.title}\n\n';

      if (memory.description != null && memory.description!.isNotEmpty) {
        shareText += '${memory.description}\n\n';
      }

      shareText += '📅 Tarih: ${dateFormatter.format(memory.memoryDate)}\n';
      shareText += '🕐 Saat: ${timeFormatter.format(memory.memoryDate)}\n';
      shareText += '👶 Bebek Takip Uygulaması ile paylaşıldı';

      Share.share(shareText, subject: memory.title);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paylaşım sırasında hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editMemory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MemoryEditScreen(
          memory: _currentMemory,
          onMemoryUpdated:
              widget.onMemoryDeleted, // Use same callback for refresh
        ),
      ),
    );
  }

  void _deleteMemory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anıyı Sil'),
        content: const Text(
          'Bu anıyı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDelete();
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Delete media if exists
      if (_currentMemory.mediaUrl != null) {
        await MemoryService.deleteMemoryMedia(_currentMemory.mediaUrl!);
      }

      // Delete memory from database
      await MemoryService.deleteMemory(_currentMemory.id);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anı başarıyla silindi'),
            backgroundColor: Colors.green,
          ),
        );

        // Call callback to refresh memories list
        if (widget.onMemoryDeleted != null) {
          widget.onMemoryDeleted!();
        }

        // Navigate back to memories list
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Anı silinirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
