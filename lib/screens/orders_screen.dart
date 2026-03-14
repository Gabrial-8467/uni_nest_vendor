import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/vendor_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/order_card.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VendorProvider>(
      builder: (context, vendorProvider, child) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: AppTheme.surface,
            elevation: 0,
            foregroundColor: AppTheme.textPrimary,
            toolbarHeight: 10,
          ),
          body: Column(
            children: [
              // Search and Filter Section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // Search Bar
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search orders by ID, customer...',
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.primary,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Filter Button
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () {
                          _showFilterDialog(context);
                        },
                        icon: const Icon(
                          Icons.filter_list_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tabs
              Container(
                color: AppTheme.surface,
                child: TabBar(
                  controller: _tabController,
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
                    Tab(text: 'All'),
                    Tab(text: 'Pending'),
                    Tab(text: 'Confirmed'),
                    Tab(text: 'Preparing'),
                    Tab(text: 'Completed'),
                  ],
                ),
              ),

              // Orders List
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOrdersList(
                      _getFilteredOrders(vendorProvider.orders),
                      'All',
                    ),
                    _buildOrdersList(
                      _getFilteredOrders(
                        vendorProvider.getOrdersByStatus('pending'),
                      ),
                      'Pending',
                    ),
                    _buildOrdersList(
                      _getFilteredOrders(
                        vendorProvider.getOrdersByStatus('confirmed'),
                      ),
                      'Confirmed',
                    ),
                    _buildOrdersList(
                      _getFilteredOrders(
                        vendorProvider.getOrdersByStatus('preparing'),
                      ),
                      'Preparing',
                    ),
                    _buildOrdersList(
                      _getFilteredOrders(
                        vendorProvider.getOrdersByStatus('delivered'),
                      ),
                      'Completed',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List _getFilteredOrders(List orders) {
    if (_searchController.text.isEmpty) {
      return orders;
    }

    final searchQuery = _searchController.text.toLowerCase();
    return orders.where((order) {
      return order.id.toLowerCase().contains(searchQuery) ||
          order.customerName.toLowerCase().contains(searchQuery) ||
          order.customerPhone.toLowerCase().contains(searchQuery);
    }).toList();
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Orders'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Date Range'),
              leading: const Icon(Icons.date_range_outlined),
              onTap: () {
                Navigator.pop(context);
                // Show date range picker
              },
            ),
            ListTile(
              title: const Text('Order Status'),
              leading: const Icon(Icons.filter_list_outlined),
              onTap: () {
                Navigator.pop(context);
                // Show status filter
              },
            ),
            ListTile(
              title: const Text('Amount Range'),
              leading: const Icon(Icons.attach_money_outlined),
              onTap: () {
                Navigator.pop(context);
                // Show amount filter
              },
            ),
          ],
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

  Widget _buildOrdersList(List orders, String category) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 64,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No $category orders',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Orders will appear here when customers place them',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh orders
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return OrderCard(order: orders[index]);
        },
      ),
    );
  }
}
