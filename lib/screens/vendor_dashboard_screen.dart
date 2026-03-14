import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/vendor_provider.dart';
import '../widgets/vendor_drawer.dart';
import '../widgets/analytics_card.dart';
import '../widgets/recent_orders_widget.dart';
import '../widgets/quick_stats_widget.dart';
import '../widgets/revenue_chart_widget.dart';
import 'orders_screen.dart';
import 'products_screen.dart';
import 'analytics_screen.dart';
import 'profile_screen.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VendorProvider>(
      builder: (context, vendorProvider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: _buildAppBar(context, vendorProvider),
          drawer: const VendorDrawer(),
          body: RefreshIndicator(
            onRefresh: () => vendorProvider.refreshData(),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(vendorProvider),
                  _buildOrdersTab(vendorProvider),
                  _buildProductsTab(vendorProvider),
                  _buildAnalyticsTab(vendorProvider),
                ],
              ),
            ),
          ),
          floatingActionButton: _buildFloatingActionButton(vendorProvider),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, VendorProvider vendorProvider) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      foregroundColor: const Color(0xFF2D3436),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          if (vendorProvider.currentVendor != null)
            Text(
              vendorProvider.currentVendor!.businessName,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: Badge(
            label: Text(
              vendorProvider.pendingOrdersCount.toString(),
              style: const TextStyle(fontSize: 10),
            ),
            child: const Icon(Icons.notifications_outlined),
          ),
          onPressed: () {
            // Navigate to notifications
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => vendorProvider.refreshData(),
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFFFF6B6B),
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: const Color(0xFFFF6B6B),
        tabs: const [
          Tab(text: 'Overview', icon: Icon(Icons.dashboard_outlined)),
          Tab(text: 'Orders', icon: Icon(Icons.receipt_long_outlined)),
          Tab(text: 'Products', icon: Icon(Icons.inventory_2_outlined)),
          Tab(text: 'Analytics', icon: Icon(Icons.analytics_outlined)),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(VendorProvider vendorProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats
          QuickStatsWidget(vendorProvider: vendorProvider),
          const SizedBox(height: 20),
          
          // Revenue Chart
          RevenueChartWidget(vendorProvider: vendorProvider),
          const SizedBox(height: 20),
          
          // Recent Orders
          RecentOrdersWidget(vendorProvider: vendorProvider),
          const SizedBox(height: 20),
          
          // Analytics Cards
          Row(
            children: [
              Expanded(
                child: AnalyticsCard(
                  title: 'Today\'s Revenue',
                  value: '₹${vendorProvider.todayRevenue.toStringAsFixed(2)}',
                  icon: Icons.trending_up,
                  color: Colors.green,
                  change: '+12.5%',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnalyticsCard(
                  title: 'Active Products',
                  value: vendorProvider.products
                      .where((p) => p.isAvailable)
                      .length
                      .toString(),
                  icon: Icons.inventory,
                  color: Colors.blue,
                  change: '+2 new',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab(VendorProvider vendorProvider) {
    return const OrdersScreen();
  }

  Widget _buildProductsTab(VendorProvider vendorProvider) {
    return const ProductsScreen();
  }

  Widget _buildAnalyticsTab(VendorProvider vendorProvider) {
    return const AnalyticsScreen();
  }

  Widget _buildFloatingActionButton(VendorProvider vendorProvider) {
    return FloatingActionButton.extended(
      onPressed: () {
        _showQuickActionMenu(vendorProvider);
      },
      backgroundColor: const Color(0xFFFF6B6B),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Quick Actions'),
    );
  }

  void _showQuickActionMenu(VendorProvider vendorProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildQuickActionItem(
                  'Add Product',
                  Icons.add_shopping_cart,
                  Colors.blue,
                  () => Navigator.pushNamed(context, '/add-product'),
                ),
                _buildQuickActionItem(
                  'View Orders',
                  Icons.receipt_long,
                  Colors.green,
                  () => _tabController.animateTo(1),
                ),
                _buildQuickActionItem(
                  'Analytics',
                  Icons.analytics,
                  Colors.orange,
                  () => _tabController.animateTo(3),
                ),
                _buildQuickActionItem(
                  'Profile',
                  Icons.person,
                  Colors.purple,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
