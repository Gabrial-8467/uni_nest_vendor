import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../utils/app_theme.dart';
import '../../core/vendor_formatters.dart';
import '../../models/order_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ledger_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/payout_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/order_list_card.dart';
import '../../widgets/summary_tile.dart';
import 'order_details_screen.dart';
import 'products_screen.dart';
import 'add_product_screen.dart';

class VendorDashboardTab extends ConsumerWidget {
  const VendorDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerState = ref.watch(ledgerProvider);
    final orderState = ref.watch(orderProvider);
    final payoutState = ref.watch(payoutProvider);
    final activeOrders = ref.watch(activeOrdersProvider);
    final deliveredCount = ref.watch(completedOrdersProvider).length;
    final cancelledCount = ref.watch(cancelledOrdersProvider).length;
    final ledger = ledgerState.ledger;
    final authState = ref.watch(authProvider);
    final profile = authState.session?.profile;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait<void>([
          ref.read(orderProvider.notifier).loadOrders(),
          ref.read(ledgerProvider.notifier).loadLedger(),
          ref.read(payoutProvider.notifier).loadPayouts(),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DashboardHero(
            businessName: profile?.businessName ?? 'Vendor',
            activeOrders: activeOrders.length,
            deliveredOrders: deliveredCount,
            cancelledOrders: cancelledCount,
          ),
          const SizedBox(height: 16),
          _CanteenStatusSwitch(
            isOpen: profile?.isOpenValue ?? true,
            isUpdating: authState.isLoading,
            onChanged: profile == null
                ? null
                : (value) => _updateCanteenStatus(context, ref, value),
          ),
          const SizedBox(height: 16),
          _SectionBox(
            title: 'Quick Actions',
            subtitle: 'Manage your products and view analytics',
            child: Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.inventory_2_outlined,
                    title: 'Manage Products',
                    subtitle: 'Add, edit, or remove products',
                    color: AppTheme.primary,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProductsScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.add_circle_outline,
                    title: 'Add Product',
                    subtitle: 'Create a new product listing',
                    color: AppTheme.success,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AddProductScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionBox(
            title: 'Payments and Settlements',
            subtitle:
                'Live balance and payout visibility from the backend ledger.',
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 820 ? 4 : 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.8,
              children: [
                SummaryTile(
                  title: 'Available balance',
                  value: formatCurrency(ledger?.availableBalance ?? 0),
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppTheme.success,
                  subtitle: 'Delivered orders ready for payout',
                ),
                SummaryTile(
                  title: 'Pending balance',
                  value: formatCurrency(ledger?.pendingBalance ?? 0),
                  icon: Icons.hourglass_bottom_outlined,
                  color: Colors.orange,
                  subtitle: 'Paid online orders not delivered yet',
                ),
                SummaryTile(
                  title: 'COD commission owed',
                  value: formatCurrency(ledger?.commissionOwed ?? 0),
                  icon: Icons.receipt_long_outlined,
                  color: Colors.deepOrange,
                  subtitle: 'Receivable by the platform',
                ),
                SummaryTile(
                  title: 'Paid out',
                  value: formatCurrency(ledger?.paidOutAmount ?? 0),
                  icon: Icons.payments_outlined,
                  color: AppTheme.info,
                  subtitle: payoutState.payouts.isEmpty
                      ? 'No payouts recorded yet'
                      : 'Latest: ${humanizeEnum(payoutState.payouts.first.status)}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionBox(
            title: 'Order momentum',
            subtitle:
                'Seven-day order trend based on order timestamps already synced in the app.',
            child: _OrderTrendChart(orders: orderState.orders),
          ),
          const SizedBox(height: 20),
          _SectionBox(
            title: 'Live order queue',
            subtitle:
                'Confirmed orders only. Payment and pricing shown here come directly from the order snapshot.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (orderState.isLoading && orderState.orders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (activeOrders.isEmpty)
                  const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No active orders',
                    message:
                        'Confirmed, preparing, ready, and delivery orders will appear here.',
                  )
                else
                  ...activeOrders
                      .take(4)
                      .map(
                        (order) => OrderListCard(
                          order: order,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    OrderDetailsScreen(orderId: order.id),
                              ),
                            );
                          },
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateCanteenStatus(
    BuildContext context,
    WidgetRef ref,
    bool isOpen,
  ) async {
    final success = await ref
        .read(authProvider.notifier)
        .updateCanteenOpenStatus(isOpen);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Canteen is now ${isOpen ? 'open' : 'closed'}'
              : 'Failed to update canteen status',
        ),
        backgroundColor: success ? Colors.green : Colors.redAccent,
      ),
    );
  }
}

class _CanteenStatusSwitch extends StatelessWidget {
  const _CanteenStatusSwitch({
    required this.isOpen,
    required this.isUpdating,
    required this.onChanged,
  });

  final bool isOpen;
  final bool isUpdating;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return _SectionBox(
      title: isOpen ? 'Canteen Open' : 'Canteen Closed',
      subtitle: isOpen
          ? 'Customers can place orders from this canteen.'
          : 'Ordering is paused across the app ecosystem.',
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: (isOpen ? Colors.green : Colors.redAccent).withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isOpen ? Icons.storefront : Icons.storefront_outlined,
              color: isOpen ? Colors.green : Colors.redAccent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              isOpen
                  ? 'Visible as open to customers and admin.'
                  : 'Visible as closed to customers and admin.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(width: 12),
          if (isUpdating)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch.adaptive(
              value: isOpen,
              activeThumbColor: Colors.green,
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}

class _OrderTrendChart extends StatelessWidget {
  const _OrderTrendChart({required this.orders});

  final List<VendorOrder> orders;

  @override
  Widget build(BuildContext context) {
    final points = _buildDailyPoints(orders);
    final maxY = points.fold<double>(
      0,
      (current, point) => point.y > current ? point.y : current,
    );

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY < 4 ? 4 : maxY + 1,
          gridData: FlGridData(
            show: true,
            horizontalInterval: 1,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: Color(0x11000000), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      points[index].label,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].y),
              ],
              isCurved: true,
              barWidth: 4,
              color: AppTheme.primary,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.24),
                    AppTheme.primary.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 3,
                  strokeColor: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_TrendPoint> _buildDailyPoints(List<VendorOrder> orders) {
    final now = DateTime.now();
    final buckets = <DateTime, int>{};
    for (var i = 6; i >= 0; i--) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      buckets[day] = 0;
    }

    for (final order in orders) {
      final createdAt = order.createdAt;
      final key = DateTime(createdAt.year, createdAt.month, createdAt.day);
      if (buckets.containsKey(key)) {
        buckets[key] = (buckets[key] ?? 0) + 1;
      }
    }

    return buckets.entries
        .map(
          (entry) => _TrendPoint(
            label: _weekday(entry.key.weekday),
            y: entry.value.toDouble(),
          ),
        )
        .toList();
  }

  String _weekday(int weekday) {
    const values = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return values[weekday - 1];
  }
}

class _TrendPoint {
  const _TrendPoint({required this.label, required this.y});

  final String label;
  final double y;
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.businessName,
    required this.activeOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
  });

  final String businessName;
  final int activeOrders;
  final int deliveredOrders;
  final int cancelledOrders;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFFEF5350)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            businessName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            'Orders',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _HeroMetric(label: 'Active', value: '$activeOrders'),
              _HeroMetric(label: 'Delivered', value: '$deliveredOrders'),
              _HeroMetric(label: 'Cancelled', value: '$cancelledOrders'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionBox extends StatelessWidget {
  const _SectionBox({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
