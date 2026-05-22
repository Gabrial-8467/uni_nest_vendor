import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/vendor_formatters.dart';
import '../providers/analytics_provider.dart';
import '../utils/app_theme.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key, this.showPageHeader = true});

  final bool showPageHeader;

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  static const List<Map<String, String>> _periods = [
    {'label': '24h', 'value': '24h'},
    {'label': '7d', 'value': '7d'},
    {'label': '30d', 'value': '30d'},
    {'label': '90d', 'value': '90d'},
    {'label': 'Monthly', 'value': 'monthly'},
    {'label': 'Yearly', 'value': 'yearly'},
    {'label': 'Lifetime', 'value': 'lifetime'},
  ];

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: widget.showPageHeader
          ? AppBar(
              backgroundColor: AppTheme.surface,
              elevation: 0,
              foregroundColor: AppTheme.textPrimary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text(
                'Analytics',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
              ),
              centerTitle: true,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: AppTheme.surface,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: AppTheme.primary,
                    labelColor: AppTheme.primary,
                    unselectedLabelColor: AppTheme.textSecondary,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    tabs: const [
                      Tab(
                        text: 'Overview',
                        icon: Icon(Icons.dashboard_outlined, size: 18),
                      ),
                      Tab(
                        text: 'Products',
                        icon: Icon(Icons.inventory_2_outlined, size: 18),
                      ),
                      Tab(
                        text: 'Revenue',
                        icon: Icon(Icons.currency_rupee_outlined, size: 18),
                      ),
                      Tab(
                        text: 'Orders',
                        icon: Icon(Icons.receipt_long_outlined, size: 18),
                      ),
                    ],
                    onTap: (index) {
                      final tabs = [
                        AnalyticsTab.overview,
                        AnalyticsTab.products,
                        AnalyticsTab.revenue,
                        AnalyticsTab.orders,
                      ];
                      ref.read(analyticsProvider.notifier).setTab(tabs[index]);
                    },
                  ),
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          if (!widget.showPageHeader)
            Container(
              color: AppTheme.surface,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppTheme.primary,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(
                    text: 'Overview',
                    icon: Icon(Icons.dashboard_outlined, size: 18),
                  ),
                  Tab(
                    text: 'Products',
                    icon: Icon(Icons.inventory_2_outlined, size: 18),
                  ),
                  Tab(
                    text: 'Revenue',
                    icon: Icon(Icons.currency_rupee_outlined, size: 18),
                  ),
                  Tab(
                    text: 'Orders',
                    icon: Icon(Icons.receipt_long_outlined, size: 18),
                  ),
                ],
                onTap: (index) {
                  final tabs = [
                    AnalyticsTab.overview,
                    AnalyticsTab.products,
                    AnalyticsTab.revenue,
                    AnalyticsTab.orders,
                  ];
                  ref.read(analyticsProvider.notifier).setTab(tabs[index]);
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _PeriodSelector(
              selected: state.period,
              periods: _periods,
              onSelect: (value) {
                ref.read(analyticsProvider.notifier).setPeriod(value);
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(),
                _ProductsTab(),
                _RevenueTab(),
                _OrdersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final String selected;
  final List<Map<String, String>> periods;
  final ValueChanged<String> onSelect;

  const _PeriodSelector({
    required this.selected,
    required this.periods,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: periods.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final period = periods[index];
          final isSelected = period['value'] == selected;
          return ChoiceChip(
            label: Text(period['label']!),
            selected: isSelected,
            onSelected: (_) => onSelect(period['value']!),
            selectedColor: AppTheme.primary,
            backgroundColor: AppTheme.surface,
            labelStyle: TextStyle(
              color: isSelected ? AppTheme.textWhite : AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? AppTheme.primary
                    : AppTheme.textLight.withValues(alpha: 0.3),
              ),
            ),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          );
        },
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsProvider);
    final data = state.data;

    if (state.isLoading && data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (data == null) {
      return _ErrorState(
        message: state.errorMessage ?? 'No data',
        onRetry: () => ref.read(analyticsProvider.notifier).refreshCurrentTab(),
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          ref.read(analyticsProvider.notifier).refreshCurrentTab(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.errorMessage != null)
            _ErrorBanner(message: state.errorMessage!),
          _SummaryGrid(data: data),
          const SizedBox(height: 20),
          _OrderStatusSection(data: data),
          const SizedBox(height: 20),
          _TopProductsSection(products: data.topProducts),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final VendorAnalyticsData data;

  const _SummaryGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(
        label: 'Total Orders',
        value: data.totalOrders.toString(),
        icon: Icons.receipt_long_outlined,
        color: AppTheme.primary,
      ),
      _StatItem(
        label: 'Total Revenue',
        value: formatCurrency(data.totalRevenue),
        icon: Icons.currency_rupee_outlined,
        color: AppTheme.success,
      ),
      _StatItem(
        label: 'Avg Order Value',
        value: formatCurrency(data.averageOrderValue),
        icon: Icons.trending_up_outlined,
        color: AppTheme.secondary,
      ),
      _StatItem(
        label: 'Delivered',
        value: data.deliveredOrders.toString(),
        icon: Icons.check_circle_outline,
        color: AppTheme.info,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: items.map((item) => _StatCard(item: item)).toList(),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _StatCard extends StatelessWidget {
  final _StatItem item;

  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const Spacer(),
          Text(
            item.value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderStatusSection extends StatelessWidget {
  final VendorAnalyticsData data;

  const _OrderStatusSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.totalOrders == 0 ? 1 : data.totalOrders;

    final statuses = [
      _StatusItem(
        label: 'Delivered',
        count: data.deliveredOrders,
        color: AppTheme.success,
        icon: Icons.check_circle,
      ),
      _StatusItem(
        label: 'Pending',
        count: data.pendingOrders,
        color: AppTheme.warning,
        icon: Icons.hourglass_empty,
      ),
      _StatusItem(
        label: 'Cancelled',
        count: data.cancelledOrders,
        color: AppTheme.error,
        icon: Icons.cancel,
      ),
    ];

    return _Card(
      title: 'Order Status Breakdown',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: statuses
            .map((s) => _StatusBar(item: s, total: total))
            .toList(),
      ),
    );
  }
}

class _StatusItem {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  _StatusItem({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });
}

class _StatusBar extends StatelessWidget {
  final _StatusItem item;
  final int total;

  const _StatusBar({required this.item, required this.total});

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0.0 : (item.count / total).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.icon, size: 16, color: item.color),
              const SizedBox(width: 8),
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '${item.count}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${percent > 0 ? (percent * 100).toStringAsFixed(0) : 0}%)',
                style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: AppTheme.background,
              color: item.color,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopProductsSection extends StatelessWidget {
  final List<TopProduct> products;

  const _TopProductsSection({required this.products});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Top Products',
      trailing: _Badge(text: '${products.length} items'),
      child: products.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No product data for this period',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return _ProductListTile(
                  index: index + 1,
                  product: products[index],
                );
              },
            ),
    );
  }
}

class _ProductListTile extends StatelessWidget {
  final int index;
  final TopProduct product;

  const _ProductListTile({required this.index, required this.product});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: index <= 3
                  ? AppTheme.primary.withValues(alpha: 0.1)
                  : AppTheme.background,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: index <= 3 ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Sold ${product.totalQuantity} - ${product.totalOrders} orders',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatCurrency(product.totalRevenue),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsProvider);
    final data = state.productData;

    if (state.isLoading && data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (data == null) {
      return _ErrorState(
        message: state.errorMessage ?? 'No data',
        onRetry: () => ref.read(analyticsProvider.notifier).refreshCurrentTab(),
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          ref.read(analyticsProvider.notifier).refreshCurrentTab(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.errorMessage != null)
            _ErrorBanner(message: state.errorMessage!),
          _Card(
            title: 'Product Stats',
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                _StatCard(
                  item: _StatItem(
                    label: 'Total',
                    value: data.productStats.totalProducts.toString(),
                    icon: Icons.inventory_2_outlined,
                    color: AppTheme.primary,
                  ),
                ),
                _StatCard(
                  item: _StatItem(
                    label: 'Active',
                    value: data.productStats.activeProducts.toString(),
                    icon: Icons.check_circle_outline,
                    color: AppTheme.success,
                  ),
                ),
                _StatCard(
                  item: _StatItem(
                    label: 'Pending',
                    value: data.productStats.pendingProducts.toString(),
                    icon: Icons.hourglass_empty,
                    color: AppTheme.warning,
                  ),
                ),
                _StatCard(
                  item: _StatItem(
                    label: 'Rejected',
                    value: data.productStats.rejectedProducts.toString(),
                    icon: Icons.cancel_outlined,
                    color: AppTheme.error,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _Card(
            title: 'Category Breakdown',
            child: data.categoryBreakdown.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No category data',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: data.categoryBreakdown.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                cat.category,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              'Qty: ${cat.totalQuantity}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              formatCurrency(cat.totalRevenue),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 20),
          _TopProductsSection(products: data.topProducts),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _RevenueTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsProvider);
    final data = state.revenueData;

    if (state.isLoading && data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (data == null) {
      return _ErrorState(
        message: state.errorMessage ?? 'No data',
        onRetry: () => ref.read(analyticsProvider.notifier).refreshCurrentTab(),
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          ref.read(analyticsProvider.notifier).refreshCurrentTab(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.errorMessage != null)
            _ErrorBanner(message: state.errorMessage!),
          _Card(
            title: 'Revenue Summary',
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 1,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _RevenueSummaryTile(
                  label: 'Total Revenue',
                  value: formatCurrency(data.summary.totalRevenue),
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppTheme.success,
                ),
                _RevenueSummaryTile(
                  label: 'Total Orders',
                  value: data.summary.totalOrders.toString(),
                  icon: Icons.receipt_long_outlined,
                  color: AppTheme.primary,
                ),
                _RevenueSummaryTile(
                  label: 'Avg Order Value',
                  value: formatCurrency(data.summary.averageOrderValue),
                  icon: Icons.trending_up_outlined,
                  color: AppTheme.secondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _Card(
            title: 'Revenue Trend',
            trailing: _Badge(text: '${data.trend.length} points'),
            child: data.trend.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No trend data for this period',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: data.trend.map((point) {
                      final label = _formatTrendLabel(point.period);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            Text(
                              '${point.orders} orders',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textLight,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              formatCurrency(point.revenue),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _formatTrendLabel(Map<String, dynamic> period) {
    final day = period['day'];
    final month = period['month'];
    final year = period['year'];
    final hour = period['hour'];
    if (hour != null) {
      return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')} $year ${hour.toString().padLeft(2, '0')}:00';
    }
    if (day != null && month != null) {
      return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
    }
    if (month != null) {
      return '${month.toString().padLeft(2, '0')}/$year';
    }
    return year?.toString() ?? '-';
  }
}

class _RevenueSummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _RevenueSummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsProvider);
    final data = state.orderData;

    if (state.isLoading && data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (data == null) {
      return _ErrorState(
        message: state.errorMessage ?? 'No data',
        onRetry: () => ref.read(analyticsProvider.notifier).refreshCurrentTab(),
      );
    }

    final statusColors = {
      'pending': AppTheme.warning,
      'confirmed': AppTheme.info,
      'preparing': AppTheme.secondary,
      'ready': const Color(0xFF8B5CF6),
      'out_for_delivery': const Color(0xFFF59E0B),
      'delivered': AppTheme.success,
      'cancelled': AppTheme.error,
      'refunded': AppTheme.textLight,
    };

    return RefreshIndicator(
      onRefresh: () async =>
          ref.read(analyticsProvider.notifier).refreshCurrentTab(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Card(
            title: 'Order Status',
            trailing: _Badge(text: '${data.totalOrders} total'),
            child: data.statusBreakdown.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No order data',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: data.statusBreakdown.entries.map((entry) {
                      final count = entry.value is int ? entry.value as int : 0;
                      final total = data.totalOrders == 0
                          ? 1
                          : data.totalOrders;
                      final percent = (count / total).clamp(0.0, 1.0);
                      final color =
                          statusColors[entry.key] ?? AppTheme.textSecondary;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  entry.key
                                      .toString()
                                      .split('_')
                                      .map(
                                        (w) =>
                                            w[0].toUpperCase() + w.substring(1),
                                      )
                                      .join(' '),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '$count',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${percent > 0 ? (percent * 100).toStringAsFixed(0) : 0}%)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percent,
                                backgroundColor: AppTheme.background,
                                color: color,
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 20),
          _Card(
            title: 'Daily Trend',
            child: data.dailyTrend.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No daily trend data',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: data.dailyTrend.map((d) {
                      final label =
                          '${d.date['day'].toString().padLeft(2, '0')}/${d.date['month'].toString().padLeft(2, '0')}/${d.date['year']}';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            Text(
                              '${d.orders} orders',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textLight,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              formatCurrency(d.revenue),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 20),
          _Card(
            title: 'Payment Methods',
            child: data.paymentMethods.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No payment method data',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: data.paymentMethods.map((p) {
                      final methodLabel = p.method.toUpperCase();
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                methodLabel,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              '${p.orders} orders',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              formatCurrency(p.revenue),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;

  const _Card({required this.title, this.trailing, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              trailing ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;

  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.primary,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.error,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
