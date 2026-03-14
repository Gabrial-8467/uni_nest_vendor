import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/vendor_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/analytics_card.dart';
import '../widgets/recent_orders_widget.dart';
import '../widgets/quick_stats_widget.dart';
import '../widgets/revenue_chart_widget.dart';
import 'orders_screen.dart';
import 'products_screen.dart';
import 'analytics_screen.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(context),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: [
            _buildOverviewTab(context),
            _buildOrdersTab(context),
            _buildProductsTab(context),
            _buildAnalyticsTab(context),
            _buildProfileTab(context),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final vendorProvider = Provider.of<VendorProvider>(context);

    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      foregroundColor: AppTheme.textPrimary,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getAppBarTitle(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          if (vendorProvider.currentVendor != null)
            Text(
              vendorProvider.currentVendor!.businessName,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ),
                );
              },
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Orders';
      case 2:
        return 'Products';
      case 3:
        return 'Analytics';
      case 4:
        return 'Profile';
      default:
        return 'Dashboard';
    }
  }

  Widget _buildOverviewTab(BuildContext context) {
    return Consumer<VendorProvider>(
      builder: (context, vendorProvider, child) => RefreshIndicator(
        onRefresh: () async {
          await vendorProvider.refreshData();
        },
        color: AppTheme.primary,
        backgroundColor: AppTheme.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 600;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats
                  QuickStatsWidget(vendorProvider: vendorProvider),
                  const SizedBox(height: 16),

                  // Revenue Chart
                  RevenueChartWidget(vendorProvider: vendorProvider),
                  const SizedBox(height: 20),

                  // Recent Orders
                  RecentOrdersWidget(vendorProvider: vendorProvider),
                  const SizedBox(height: 20),

                  // Analytics Cards - Responsive layout
                  isSmallScreen
                      ? Column(
                          children: [
                            AnalyticsCard(
                              title: 'Total Revenue',
                              value:
                                  '₹${(vendorProvider.earnings['total'] ?? 0).toStringAsFixed(2)}',
                              icon: Icons.attach_money,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(height: 12),
                            AnalyticsCard(
                              title: 'Total Orders',
                              value: '${vendorProvider.orders.length}',
                              icon: Icons.shopping_bag,
                              color: AppTheme.primary,
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: AnalyticsCard(
                                title: 'Total Revenue',
                                value:
                                    '₹${(vendorProvider.earnings['total'] ?? 0).toStringAsFixed(2)}',
                                icon: Icons.attach_money,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AnalyticsCard(
                                title: 'Total Orders',
                                value: '${vendorProvider.orders.length}',
                                icon: Icons.shopping_bag,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersTab(BuildContext context) {
    return const OrdersScreen();
  }

  Widget _buildProductsTab(BuildContext context) {
    return const ProductsScreen();
  }

  Widget _buildAnalyticsTab(BuildContext context) {
    return const AnalyticsScreen();
  }

  Widget _buildProfileTab(BuildContext context) {
    return const ProfileScreen();
  }
}
