import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/bottom_navigation.dart';
import '../../../shared/widgets/no_baby_warning.dart';
import '../../../shared/widgets/baby_selector_sheet.dart';
import '../../../shared/providers/baby_provider.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/models/memory_model.dart';
import '../../../core/services/memory_service.dart';
import '../../../core/services/ad_service.dart';
import '../widgets/memory_card.dart';
import '../widgets/add_memory_sheet.dart';
import 'memory_detail_screen.dart';

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  List<Memory> _memories = [];
  bool _isLoading = true;
  MemoryType? _selectedFilter;
  String _searchQuery = '';
  bool _isGridView = false; // Grid görünümü için

  // Gelişmiş filtreleme için
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showFavoritesOnly = false;
  String _sortBy = 'date'; // 'date', 'title', 'type'
  bool _sortAscending = false;

  // Gruplama için
  String _groupBy = 'none'; // 'none', 'month', 'week', 'year'

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    final selectedBaby = babyProvider.selectedBaby;

    if (selectedBaby == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final memories = await MemoryService.getMemories(selectedBaby.id);
      setState(() {
        _memories = memories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Anılar yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Memory> get _filteredMemories {
    var filtered = _memories;

    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (memory) =>
                memory.title.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                (memory.description?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();
    }

    // Tür filtresi
    if (_selectedFilter != null) {
      filtered = filtered
          .where((memory) => memory.type == _selectedFilter)
          .toList();
    }

    // Tarih aralığı filtresi
    if (_startDate != null) {
      filtered = filtered
          .where(
            (memory) =>
                memory.memoryDate.isAfter(_startDate!) ||
                memory.memoryDate.isAtSameMomentAs(_startDate!),
          )
          .toList();
    }

    if (_endDate != null) {
      filtered = filtered
          .where(
            (memory) =>
                memory.memoryDate.isBefore(
                  _endDate!.add(const Duration(days: 1)),
                ) ||
                memory.memoryDate.isAtSameMomentAs(_endDate!),
          )
          .toList();
    }

    // Favori filtresi
    if (_showFavoritesOnly) {
      filtered = filtered.where((memory) => memory.isFavorite).toList();
    }

    // Sıralama
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'date':
          comparison = a.memoryDate.compareTo(b.memoryDate);
          break;
        case 'title':
          comparison = a.title.compareTo(b.title);
          break;
        case 'type':
          comparison = a.type.toString().compareTo(b.type.toString());
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  Widget _buildGridCard(Memory memory, ThemeProvider themeProvider) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MemoryDetailScreen(
              memory: memory,
              onMemoryDeleted: _loadMemories,
              onMemoryUpdated: _loadMemories,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: themeProvider.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: memory.type == MemoryType.note
            ? _buildNoteGridCard(memory, themeProvider)
            : _buildMediaGridCard(memory, themeProvider),
      ),
    );
  }

  Widget _buildNoteGridCard(Memory memory, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and favorite
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTypeIcon(memory.type),
                  size: 20,
                  color: themeProvider.primaryColor,
                ),
              ),
              const Spacer(),
              if (memory.isFavorite)
                Icon(Icons.favorite, size: 16, color: Colors.red),
            ],
          ),

          const SizedBox(height: 12),

          // Title
          Text(
            memory.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: themeProvider.cardForeground,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          // Description
          if (memory.description != null && memory.description!.isNotEmpty)
            Expanded(
              child: Text(
                memory.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: themeProvider.mutedForegroundColor,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          const SizedBox(height: 8),

          // Footer
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getTypeName(memory.type),
                    style: TextStyle(
                      color: themeProvider.primaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${memory.memoryDate.day}/${memory.memoryDate.month}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: themeProvider.mutedForegroundColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGridCard(Memory memory, ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Media Preview
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(color: themeProvider.cardBackground),
              child: memory.mediaUrl != null
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
                            _getTypeIcon(memory.type),
                            size: 32,
                            color: themeProvider.primaryColor,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: themeProvider.cardBackground,
                      child: Center(
                        child: Icon(
                          _getTypeIcon(memory.type),
                          size: 32,
                          color: themeProvider.primaryColor,
                        ),
                      ),
                    ),
            ),
          ),
        ),

        // Content
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Favorite Icon
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        memory.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: themeProvider.cardForeground,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Favorite Icon
                    if (memory.isFavorite) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.favorite, size: 14, color: Colors.red),
                    ],
                  ],
                ),

                const SizedBox(height: 4),

                // Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getTypeName(memory.type),
                    style: TextStyle(
                      color: themeProvider.primaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                    ),
                  ),
                ),

                const Spacer(),

                // Date
                Text(
                  '${memory.memoryDate.day}/${memory.memoryDate.month}/${memory.memoryDate.year}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: themeProvider.mutedForegroundColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getTypeIcon(MemoryType type) {
    switch (type) {
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

  String _getTypeName(MemoryType type) {
    switch (type) {
      case MemoryType.photo:
        return 'Fotoğraf';
      case MemoryType.note:
        return 'Not';
      case MemoryType.milestone:
        return 'Kilometre Taşı';
      case MemoryType.development:
        return 'Gelişim';
    }
  }

  void _showAdvancedFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: themeProvider.cardBackground,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
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
                  'Gelişmiş Filtreleme',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: themeProvider.cardForeground,
                  ),
                ),
                const SizedBox(height: 24),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Range
                        _buildDateRangeSection(themeProvider),
                        const SizedBox(height: 24),

                        // Sort Options
                        _buildSortSection(themeProvider),
                        const SizedBox(height: 24),

                        // Quick Filters
                        _buildQuickFiltersSection(themeProvider),
                        const SizedBox(height: 24),

                        // Favorite Filter
                        _buildFavoriteFilterSection(themeProvider),
                        const SizedBox(height: 24),

                        // Grouping Options
                        _buildGroupingSection(themeProvider),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clearFilters,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: themeProvider.primaryColor,
                            side: BorderSide(color: themeProvider.primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Temizle'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {});
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeProvider.primaryColor,
                            foregroundColor:
                                themeProvider.primaryForegroundColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Uygula'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateRangeSection(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tarih Aralığı',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: themeProvider.cardForeground,
          ),
        ),
        const SizedBox(height: 12),

        // Start Date
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: themeProvider.isDarkMode
                              ? ColorScheme.dark(
                                  primary: themeProvider.primaryColor,
                                )
                              : ColorScheme.light(
                                  primary: themeProvider.primaryColor,
                                ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (date != null) {
                    setState(() {
                      _startDate = date;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: themeProvider.borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: themeProvider.mutedForegroundColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _startDate != null
                            ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                            : 'Başlangıç tarihi',
                        style: TextStyle(
                          color: _startDate != null
                              ? themeProvider.cardForeground
                              : themeProvider.mutedForegroundColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now(),
                    firstDate: _startDate ?? DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: themeProvider.isDarkMode
                              ? ColorScheme.dark(
                                  primary: themeProvider.primaryColor,
                                )
                              : ColorScheme.light(
                                  primary: themeProvider.primaryColor,
                                ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (date != null) {
                    setState(() {
                      _endDate = date;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: themeProvider.borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: themeProvider.mutedForegroundColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _endDate != null
                            ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                            : 'Bitiş tarihi',
                        style: TextStyle(
                          color: _endDate != null
                              ? themeProvider.cardForeground
                              : themeProvider.mutedForegroundColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortSection(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sıralama',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: themeProvider.cardForeground,
          ),
        ),
        const SizedBox(height: 12),

        // Sort By
        DropdownButtonFormField<String>(
          value: _sortBy,
          decoration: InputDecoration(
            labelText: 'Sırala',
            labelStyle: TextStyle(color: themeProvider.mutedForegroundColor),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: themeProvider.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: themeProvider.primaryColor),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'date', child: Text('Tarih')),
            DropdownMenuItem(value: 'title', child: Text('Başlık')),
            DropdownMenuItem(value: 'type', child: Text('Tür')),
          ],
          onChanged: (value) {
            setState(() {
              _sortBy = value!;
            });
          },
        ),
        const SizedBox(height: 12),

        // Sort Order
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _sortAscending = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _sortAscending
                        ? themeProvider.primaryColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    border: Border.all(
                      color: _sortAscending
                          ? themeProvider.primaryColor
                          : themeProvider.borderColor,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_upward,
                        size: 16,
                        color: _sortAscending
                            ? themeProvider.primaryColor
                            : themeProvider.mutedForegroundColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Artan',
                        style: TextStyle(
                          color: _sortAscending
                              ? themeProvider.primaryColor
                              : themeProvider.mutedForegroundColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _sortAscending = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: !_sortAscending
                        ? themeProvider.primaryColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    border: Border.all(
                      color: !_sortAscending
                          ? themeProvider.primaryColor
                          : themeProvider.borderColor,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_downward,
                        size: 16,
                        color: !_sortAscending
                            ? themeProvider.primaryColor
                            : themeProvider.mutedForegroundColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Azalan',
                        style: TextStyle(
                          color: !_sortAscending
                              ? themeProvider.primaryColor
                              : themeProvider.mutedForegroundColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickFiltersSection(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hızlı Filtreler',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: themeProvider.cardForeground,
          ),
        ),
        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickFilterChip('Bu Hafta', () {
              final now = DateTime.now();
              final weekStart = now.subtract(Duration(days: now.weekday - 1));
              setState(() {
                _startDate = weekStart;
                _endDate = now;
              });
            }, themeProvider),
            _buildQuickFilterChip('Bu Ay', () {
              final now = DateTime.now();
              final monthStart = DateTime(now.year, now.month, 1);
              setState(() {
                _startDate = monthStart;
                _endDate = now;
              });
            }, themeProvider),
            _buildQuickFilterChip('Son 3 Ay', () {
              final now = DateTime.now();
              final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
              setState(() {
                _startDate = threeMonthsAgo;
                _endDate = now;
              });
            }, themeProvider),
            _buildQuickFilterChip('Bu Yıl', () {
              final now = DateTime.now();
              final yearStart = DateTime(now.year, 1, 1);
              setState(() {
                _startDate = yearStart;
                _endDate = now;
              });
            }, themeProvider),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickFilterChip(
    String label,
    VoidCallback onTap,
    ThemeProvider themeProvider,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: themeProvider.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: themeProvider.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: themeProvider.primaryColor,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _showFavoritesOnly = false;
      _sortBy = 'date';
      _sortAscending = false;
      _groupBy = 'none';
    });
  }

  Widget _buildFavoriteFilterSection(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Favori Filtresi',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: themeProvider.cardForeground,
          ),
        ),
        const SizedBox(height: 12),

        GestureDetector(
          onTap: () {
            setState(() {
              _showFavoritesOnly = !_showFavoritesOnly;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _showFavoritesOnly
                  ? themeProvider.primaryColor.withValues(alpha: 0.1)
                  : Colors.transparent,
              border: Border.all(
                color: _showFavoritesOnly
                    ? themeProvider.primaryColor
                    : themeProvider.borderColor,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
                  color: _showFavoritesOnly
                      ? themeProvider.primaryColor
                      : themeProvider.mutedForegroundColor,
                ),
                const SizedBox(width: 12),
                Text(
                  'Sadece Favori Anıları Göster',
                  style: TextStyle(
                    color: _showFavoritesOnly
                        ? themeProvider.primaryColor
                        : themeProvider.cardForeground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (_showFavoritesOnly)
                  Icon(
                    Icons.check,
                    color: themeProvider.primaryColor,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Map<String, List<Memory>> get _groupedMemories {
    if (_groupBy == 'none') {
      return {'Tümü': _filteredMemories};
    }

    Map<String, List<Memory>> grouped = {};

    for (Memory memory in _filteredMemories) {
      String groupKey;

      switch (_groupBy) {
        case 'month':
          groupKey =
              '${memory.memoryDate.year}/${memory.memoryDate.month.toString().padLeft(2, '0')}';
          break;
        case 'week':
          final weekStart = memory.memoryDate.subtract(
            Duration(days: memory.memoryDate.weekday - 1),
          );
          groupKey =
              '${weekStart.year}/${weekStart.month.toString().padLeft(2, '0')}/${weekStart.day.toString().padLeft(2, '0')}';
          break;
        case 'year':
          groupKey = memory.memoryDate.year.toString();
          break;
        default:
          groupKey = 'Tümü';
      }

      if (!grouped.containsKey(groupKey)) {
        grouped[groupKey] = [];
      }
      grouped[groupKey]!.add(memory);
    }

    // Sort groups
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    Map<String, List<Memory>> sortedGrouped = {};
    for (String key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
    }

    return sortedGrouped;
  }

  String _getGroupDisplayName(String groupKey) {
    if (groupKey == 'Tümü') return groupKey;

    switch (_groupBy) {
      case 'month':
        final parts = groupKey.split('/');
        final year = parts[0];
        final monthIndex = int.parse(parts[1]);
        final monthNames = [
          '',
          'Ocak',
          'Şubat',
          'Mart',
          'Nisan',
          'Mayıs',
          'Haziran',
          'Temmuz',
          'Ağustos',
          'Eylül',
          'Ekim',
          'Kasım',
          'Aralık',
        ];
        return '${monthNames[monthIndex]} $year';
      case 'week':
        final parts = groupKey.split('/');
        final year = parts[0];
        final monthIndex = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        final monthNames = [
          '',
          'Ocak',
          'Şubat',
          'Mart',
          'Nisan',
          'Mayıs',
          'Haziran',
          'Temmuz',
          'Ağustos',
          'Eylül',
          'Ekim',
          'Kasım',
          'Aralık',
        ];
        return '$day ${monthNames[monthIndex]} $year Haftası';
      case 'year':
        return '$groupKey Yılı';
      default:
        return groupKey;
    }
  }

  Widget _buildGroupedListView(ThemeProvider themeProvider) {
    final groupedMemories = _groupedMemories;

    if (groupedMemories.isEmpty) {
      return const Center(child: Text('Anı bulunamadı'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: groupedMemories.length,
      itemBuilder: (context, groupIndex) {
        final groupKey = groupedMemories.keys.elementAt(groupIndex);
        final memories = groupedMemories[groupKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Header
            if (_groupBy != 'none') ...[
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  _getGroupDisplayName(groupKey),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: themeProvider.cardForeground,
                  ),
                ),
              ),
            ],

            // Memories in this group
            ...memories
                .map(
                  (memory) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MemoryCard(
                      memory: memory,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => MemoryDetailScreen(
                              memory: memory,
                              onMemoryDeleted: _loadMemories,
                              onMemoryUpdated: _loadMemories,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
                .toList(),

            // Banner Ad (only show in first group to avoid multiple ads)
            if (groupIndex == 0) ...[
              const SizedBox(height: 24),
              const Center(child: BannerAdWidget()),
              const SizedBox(height: 24),
            ],
          ],
        );
      },
    );
  }

  Widget _buildGroupedGridView(ThemeProvider themeProvider) {
    final groupedMemories = _groupedMemories;

    if (groupedMemories.isEmpty) {
      return const Center(child: Text('Anı bulunamadı'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: groupedMemories.length,
      itemBuilder: (context, groupIndex) {
        final groupKey = groupedMemories.keys.elementAt(groupIndex);
        final memories = groupedMemories[groupKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Header
            if (_groupBy != 'none') ...[
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  _getGroupDisplayName(groupKey),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: themeProvider.cardForeground,
                  ),
                ),
              ),
            ],

            // Grid for this group
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: memories.length,
              itemBuilder: (context, index) {
                final memory = memories[index];
                return _buildGridCard(memory, themeProvider);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildGroupingSection(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gruplama',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: themeProvider.cardForeground,
          ),
        ),
        const SizedBox(height: 12),

        // Group By Options
        DropdownButtonFormField<String>(
          value: _groupBy,
          decoration: InputDecoration(
            labelText: 'Grupla',
            labelStyle: TextStyle(color: themeProvider.mutedForegroundColor),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: themeProvider.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: themeProvider.primaryColor),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'none', child: Text('Gruplama Yok')),
            DropdownMenuItem(value: 'month', child: Text('Aylık')),
            DropdownMenuItem(value: 'week', child: Text('Haftalık')),
            DropdownMenuItem(value: 'year', child: Text('Yıllık')),
          ],
          onChanged: (value) {
            setState(() {
              _groupBy = value!;
            });
          },
        ),
      ],
    );
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
                  // Back Button Header - Transparent
                  Container(
                    decoration: const BoxDecoration(color: Colors.transparent),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.go('/'),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Anılar',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: themeProvider.cardForeground,
                              ),
                        ),
                        const Spacer(),
                        // Advanced Filter Button
                        GestureDetector(
                          onTap: _showAdvancedFilterSheet,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.filter_list,
                              color: themeProvider.primaryColor,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // View Mode Toggle
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isGridView = !_isGridView;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _isGridView ? Icons.view_list : Icons.grid_view,
                              color: themeProvider.primaryColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Search and Filter Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Search Bar
                        TextField(
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Anı ara...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('Tümü', null),
                              const SizedBox(width: 8),
                              _buildMediaFilterChip(),
                              const SizedBox(width: 8),
                              _buildNoteFilterChip(),
                              const SizedBox(width: 8),
                              _buildFavoriteFilterChip(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Content
                  Expanded(
                    child: Consumer<BabyProvider>(
                      builder: (context, babyProvider, _) {
                        if (babyProvider.babies.isEmpty) {
                          return Center(
                            child: SingleChildScrollView(
                              child: NoBabyWarning(
                                title: 'Henüz Kayıtlı Bebek Yok',
                                message:
                                    'Anı kaydetmek için önce bir bebek eklemeniz gerekiyor.',
                                buttonText: 'Bebek Ekle',
                                onPressed: () => context.go('/add-baby'),
                              ),
                            ),
                          );
                        }

                        if (babyProvider.selectedBaby == null) {
                          return Center(
                            child: NoBabyWarning(
                              title: 'Bebek Seçin',
                              message: 'Anıları görmek için bir bebek seçin.',
                              buttonText: 'Bebek Seç',
                              onPressed: () {
                                _showBabySelector(context);
                              },
                            ),
                          );
                        }

                        if (_isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (_filteredMemories.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.photo_library_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty ||
                                          _selectedFilter != null
                                      ? 'Arama kriterlerinize uygun anı bulunamadı'
                                      : 'Henüz anı eklenmemiş',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'İlk anınızı eklemek için + butonuna basın',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: _loadMemories,
                          child: _isGridView
                              ? _buildGroupedGridView(themeProvider)
                              : _buildGroupedListView(themeProvider),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddMemorySheet(context),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          bottomNavigationBar: const BottomNavigation(currentIndex: 3),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, MemoryType? type) {
    final isSelected = _selectedFilter == type;
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedFilter = selected ? type : null;
              _showFavoritesOnly = false; // Favori filtresini kapat
            });
          },
          selectedColor: themeProvider.primaryColor.withValues(alpha: 0.2),
          checkmarkColor: themeProvider.primaryColor,
          labelStyle: TextStyle(
            color: isSelected
                ? themeProvider.primaryColor
                : themeProvider.mutedForegroundColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      },
    );
  }

  Widget _buildMediaFilterChip() {
    final isSelected = _selectedFilter == MemoryType.photo;
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.photo,
                size: 16,
                color: isSelected
                    ? themeProvider.primaryColor
                    : themeProvider.mutedForegroundColor,
              ),
              const SizedBox(width: 4),
              Text('Fotoğraf'),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedFilter = selected ? MemoryType.photo : null;
              _showFavoritesOnly = false; // Favori filtresini kapat
            });
          },
          selectedColor: themeProvider.primaryColor.withValues(alpha: 0.2),
          checkmarkColor: themeProvider.primaryColor,
          labelStyle: TextStyle(
            color: isSelected
                ? themeProvider.primaryColor
                : themeProvider.mutedForegroundColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      },
    );
  }

  Widget _buildNoteFilterChip() {
    final isSelected = _selectedFilter == MemoryType.note;
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.note,
                size: 16,
                color: isSelected
                    ? themeProvider.primaryColor
                    : themeProvider.mutedForegroundColor,
              ),
              const SizedBox(width: 4),
              Text('Not'),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedFilter = selected ? MemoryType.note : null;
              _showFavoritesOnly = false; // Favori filtresini kapat
            });
          },
          selectedColor: themeProvider.primaryColor.withValues(alpha: 0.2),
          checkmarkColor: themeProvider.primaryColor,
          labelStyle: TextStyle(
            color: isSelected
                ? themeProvider.primaryColor
                : themeProvider.mutedForegroundColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      },
    );
  }

  Widget _buildFavoriteFilterChip() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite,
                size: 16,
                color: _showFavoritesOnly
                    ? themeProvider.primaryColor
                    : themeProvider.mutedForegroundColor,
              ),
              const SizedBox(width: 4),
              Text('Favoriler'),
            ],
          ),
          selected: _showFavoritesOnly,
          onSelected: (selected) {
            setState(() {
              _showFavoritesOnly = selected;
              _selectedFilter = null; // Tür filtresini kapat
            });
          },
          selectedColor: themeProvider.primaryColor.withValues(alpha: 0.2),
          checkmarkColor: themeProvider.primaryColor,
          labelStyle: TextStyle(
            color: _showFavoritesOnly
                ? themeProvider.primaryColor
                : themeProvider.mutedForegroundColor,
            fontWeight: _showFavoritesOnly
                ? FontWeight.w600
                : FontWeight.normal,
          ),
        );
      },
    );
  }

  void _showAddMemorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddMemorySheet(
        onMemoryAdded: _loadMemories, // Callback'i geç
      ),
    );
  }

  void _showBabySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BabySelectorSheet(),
    ).then((_) {
      // Refresh memories when baby selection changes
      _loadMemories();
    });
  }
}
