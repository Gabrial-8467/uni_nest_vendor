import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../utils/app_theme.dart';

/// Filter options for promotions
enum PromotionFilter { all, active, expired, discount, bogo, credit }

/// Screen for displaying promotional offers and deals
class PromotionsScreen extends ConsumerStatefulWidget {
  const PromotionsScreen({super.key});

  @override
  ConsumerState<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends ConsumerState<PromotionsScreen> {
  PromotionFilter _currentFilter = PromotionFilter.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  /// Build app bar
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      foregroundColor: AppTheme.textPrimary,
      title: Row(
        children: [
          const Icon(
            Icons.local_offer_outlined,
            color: AppTheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Text(
            'Promotions & Offers',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => _showFilterDialog(context),
          icon: const Icon(Icons.filter_list),
        ),
        if (_currentFilter != PromotionFilter.all)
          IconButton(
            onPressed: () {
              setState(() {
                _currentFilter = PromotionFilter.all;
              });
            },
            icon: const Icon(Icons.clear),
            tooltip: 'Clear filter',
          ),
      ],
    );
  }

  /// Build body content
  Widget _buildBody(BuildContext context) {
    final filteredPromotions = _getFilteredPromotions();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_currentFilter != PromotionFilter.all) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_list, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Filtered: ${_getFilterDisplayName()}',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (filteredPromotions['active']?.isNotEmpty == true) ...[
            _buildPromotionsSection(
              context,
              'Active Promotions',
              filteredPromotions['active']!,
              true,
            ),
            const SizedBox(height: 24),
          ],
          if (filteredPromotions['expired']?.isNotEmpty == true) ...[
            _buildPromotionsSection(
              context,
              'Expired Promotions',
              filteredPromotions['expired']!,
              false,
            ),
            const SizedBox(height: 24),
          ],
          if (filteredPromotions['active']?.isEmpty != true &&
              filteredPromotions['expired']?.isEmpty != true)
            _buildEmptyState(context),
        ],
      ),
    );
  }

  /// Show filter dialog
  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Promotions'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: PromotionFilter.values.map((filter) {
                final isSelected = _currentFilter == filter;
                return ListTile(
                  title: Text(_getFilterDisplayNameForFilter(filter)),
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected ? AppTheme.primary : null,
                  ),
                  onTap: () {
                    setState(() {
                      _currentFilter = filter;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Get display name for filter
  String _getFilterDisplayName() {
    return _getFilterDisplayNameForFilter(_currentFilter);
  }

  /// Get display name for specific filter
  String _getFilterDisplayNameForFilter(PromotionFilter filter) {
    switch (filter) {
      case PromotionFilter.all:
        return 'All Promotions';
      case PromotionFilter.active:
        return 'Active Only';
      case PromotionFilter.expired:
        return 'Expired Only';
      case PromotionFilter.discount:
        return 'Discount Offers';
      case PromotionFilter.bogo:
        return 'Buy One Get One';
      case PromotionFilter.credit:
        return 'Credit Offers';
    }
  }

  /// Get filtered promotions based on current filter
  Map<String, List<Map<String, dynamic>>> _getFilteredPromotions() {
    final allPromotions = _getAllPromotions();

    if (_currentFilter == PromotionFilter.all) {
      return allPromotions;
    }

    final filtered = <String, List<Map<String, dynamic>>>{};

    for (final entry in allPromotions.entries) {
      final filteredList = entry.key == 'active'
          ? entry.value.where((promo) => _matchesFilter(promo)).toList()
          : entry.value.where((promo) => _matchesFilter(promo)).toList();

      if (filteredList.isNotEmpty) {
        filtered[entry.key] = filteredList;
      }
    }

    return filtered;
  }

  /// Check if promotion matches current filter
  bool _matchesFilter(Map<String, dynamic> promo) {
    switch (_currentFilter) {
      case PromotionFilter.all:
        return true;
      case PromotionFilter.active:
        return promo['isActive'] == true;
      case PromotionFilter.expired:
        return promo['isActive'] == false;
      case PromotionFilter.discount:
        return promo['discount'].contains('%');
      case PromotionFilter.bogo:
        return promo['discount'].contains('BOGO');
      case PromotionFilter.credit:
        return promo['discount'].contains('\$') ||
            promo['discount'].contains('CREDIT');
    }
  }

  /// Get all promotions data
  Map<String, List<Map<String, dynamic>>> _getAllPromotions() {
    return {
      'active': [
        {
          'title': 'Weekend Special',
          'description': 'Get 20% off on all orders above \$50',
          'discount': '20% OFF',
          'validUntil': DateTime.now().add(const Duration(days: 2)),
          'color': Colors.purple,
          'isActive': true,
        },
        {
          'title': 'Flash Sale',
          'description': 'Limited time offer - Buy 2 Get 1 Free',
          'discount': 'BOGO',
          'validUntil': DateTime.now().add(const Duration(hours: 6)),
          'color': Colors.orange,
          'isActive': true,
        },
        {
          'title': 'New Vendor Bonus',
          'description': 'Extra \$5 credit on your next 5 orders',
          'discount': '\$5 CREDIT',
          'validUntil': DateTime.now().add(const Duration(days: 7)),
          'color': Colors.green,
          'isActive': true,
        },
      ],
      'expired': [
        {
          'title': 'Month End Sale',
          'description': 'Was: 15% off on all products',
          'discount': 'EXPIRED',
          'validUntil': DateTime.now().subtract(const Duration(days: 1)),
          'color': Colors.grey,
          'isActive': false,
        },
        {
          'title': 'Early Bird Special',
          'description': 'Was: Free delivery on orders above \$30',
          'discount': 'EXPIRED',
          'validUntil': DateTime.now().subtract(const Duration(days: 3)),
          'color': Colors.grey,
          'isActive': false,
        },
      ],
    };
  }

  /// Build promotions section
  Widget _buildPromotionsSection(
    BuildContext context,
    String title,
    List<Map<String, dynamic>> promotions,
    bool isActive,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        ...promotions.map(
          (promo) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPromotionCard(
              context,
              title: promo['title'],
              description: promo['description'],
              discount: promo['discount'],
              validUntil: promo['validUntil'],
              color: promo['color'],
              isActive: promo['isActive'],
            ),
          ),
        ),
      ],
    );
  }

  /// Build empty state
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.filter_list_off, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No promotions found',
            style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing the filter',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  /// Build individual promotion card
  Widget _buildPromotionCard(
    BuildContext context, {
    required String title,
    required String description,
    required String discount,
    required DateTime validUntil,
    required Color color,
    required bool isActive,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: isActive
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Applied promotion: $title'),
                    backgroundColor: color,
                  ),
                );
              }
            : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? color.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? color : Colors.grey,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      discount,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isActive ? Icons.local_offer : Icons.history,
                    color: isActive ? color : Colors.grey,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isActive
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: isActive ? AppTheme.textSecondary : Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: isActive ? color : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Valid until: ${DateFormat('MMM dd, yyyy').format(validUntil)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive ? color : Colors.grey,
                    ),
                  ),
                ],
              ),
              if (isActive) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Promotion "$title" applied successfully!',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Apply Promotion'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
