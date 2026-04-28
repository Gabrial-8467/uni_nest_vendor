import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/app_theme.dart';
import '../models/order_models.dart';
import '../providers/order_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/order_list_card.dart';
import 'order_details_screen.dart';

class VendorOrdersTab extends ConsumerStatefulWidget {
  const VendorOrdersTab({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  ConsumerState<VendorOrdersTab> createState() => _VendorOrdersTabState();
}

class _VendorOrdersTabState extends ConsumerState<VendorOrdersTab>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;
  final TextEditingController _searchController = TextEditingController();
  static const _key = ValueKey('orders_tab_v2');

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 6, vsync: this);
    _controller.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(orderProvider.notifier).loadOrders();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(() {});
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final filtered = _filter(orderState.orders);
    final newCount = filtered
        .where(
          (order) =>
              order.status.toLowerCase() == 'pending' ||
              order.status.toLowerCase() == 'confirmed',
        )
        .length;
    final preparingCount = filtered
        .where((order) => order.status.toLowerCase() == 'preparing')
        .length;
    final readyCount = filtered
        .where((order) => order.status.toLowerCase() == 'ready')
        .length;
    final deliveryCount = filtered
        .where((order) => order.status.toLowerCase() == 'delivered')
        .length;

    return Scaffold(
      key: _key,
      backgroundColor: AppTheme.background,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: AppTheme.surface,
              elevation: 0,
              foregroundColor: AppTheme.textPrimary,
              titleSpacing: 16,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manage Orders',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    orderState.isLoading
                        ? 'Loading order queues...'
                        : '${orderState.orders.length} order${orderState.orders.length == 1 ? '' : 's'} total',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Refresh orders',
                  icon: const Icon(Icons.refresh),
                  onPressed: orderState.isLoading
                      ? null
                      : () => ref
                            .read(orderProvider.notifier)
                            .loadOrders(force: true),
                ),
              ],
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search orders by ID, customer, phone...',
                          prefixIcon: const Icon(Icons.search_outlined),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.clear),
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 92,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _QueueChip(
                        label: 'New',
                        count: newCount,
                        icon: Icons.receipt_long_outlined,
                        color: AppTheme.primary,
                      ),
                      _QueueChip(
                        label: 'Preparing',
                        count: preparingCount,
                        icon: Icons.restaurant_outlined,
                        color: const Color(0xFF8B5CF6),
                      ),
                      _QueueChip(
                        label: 'Ready',
                        count: readyCount,
                        icon: Icons.inventory_2_outlined,
                        color: const Color(0xFF10B981),
                      ),
                      _QueueChip(
                        label: 'Delivery',
                        count: deliveryCount,
                        icon: Icons.local_shipping_outlined,
                        color: const Color(0xFF6366F1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: AppTheme.surface,
            child: TabBar(
              controller: _controller,
              labelColor: AppTheme.primary,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: AppTheme.primary,
              indicatorWeight: 3,
              isScrollable: true,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'New'),
                Tab(text: 'Preparing'),
                Tab(text: 'Ready'),
                Tab(text: 'Out for delivery'),
                Tab(text: 'Completed'),
                Tab(text: 'Cancelled'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _controller,
              children: [
                _OrderListView(
                  orders: filtered
                      .where(
                        (order) =>
                            order.status == 'pending' ||
                            order.status == 'confirmed',
                      )
                      .toList(),
                ),
                _OrderListView(orders: _ordersByStatus(filtered, 'preparing')),
                _OrderListView(orders: _ordersByStatus(filtered, 'ready')),
                _OrderListView(
                  orders: _ordersByStatus(filtered, 'out_for_delivery'),
                ),
                _OrderListView(orders: _ordersByStatus(filtered, 'delivered')),
                _OrderListView(
                  orders: filtered
                      .where((order) => order.status == 'cancelled')
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<VendorOrder> _filter(List<VendorOrder> orders) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return orders;
    }
    return orders.where((order) {
      return order.orderNumber.toLowerCase().contains(query) ||
          order.customerName.toLowerCase().contains(query) ||
          order.customerPhone.toLowerCase().contains(query);
    }).toList();
  }

  List<VendorOrder> _ordersByStatus(List<VendorOrder> orders, String status) {
    return orders.where((order) => order.status == status).toList();
  }
}

class _OrderListView extends ConsumerWidget {
  const _OrderListView({required this.orders});

  final List<VendorOrder> orders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(orderProvider.notifier).loadOrders(force: true),
      child: orders.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 120),
                if (orderState.isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  EmptyState(
                    icon: orderState.errorMessage == null
                        ? Icons.inbox_outlined
                        : Icons.error_outline,
                    title: orderState.errorMessage == null
                        ? 'No orders here'
                        : 'Could not load orders',
                    message:
                        orderState.errorMessage ??
                        'Orders for this stage will appear once they are moved into this queue.',
                  ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return OrderListCard(
                  order: order,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrderDetailsScreen(orderId: order.id),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _QueueChip extends StatelessWidget {
  const _QueueChip({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 126,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
        ],
      ),
    );
  }
}
