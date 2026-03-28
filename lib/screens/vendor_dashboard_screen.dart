import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/vendor_api_service.dart';
import '../state/vendor_provider.dart';
import '../utils/app_theme.dart';
import '../utils/app_assets.dart';
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
  bool _hasUnreadNotifications = false;
  bool _isFetchingNotificationStatus = false;
  DateTime? _lastNotificationFetchAt;
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Timer? _notificationPollTimer;
  static const Duration _notificationPollInterval = Duration(seconds: 60);
  static const Duration _notificationMinFetchGap = Duration(seconds: 45);

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
    _loadUnreadNotificationStatus(force: true);
    _notificationPollTimer = Timer.periodic(
      _notificationPollInterval,
      (_) => _loadUnreadNotificationStatus(),
    );
  }

  @override
  void dispose() {
    _notificationPollTimer?.cancel();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadNotificationStatus({bool force = false}) async {
    if (_isFetchingNotificationStatus) {
      return;
    }

    if (!force && _lastNotificationFetchAt != null) {
      final elapsed = DateTime.now().difference(_lastNotificationFetchAt!);
      if (elapsed < _notificationMinFetchGap) {
        return;
      }
    }

    _isFetchingNotificationStatus = true;
    try {
      final authToken = await AuthService().getAuthToken();
      if (authToken == null || authToken.isEmpty) {
        if (mounted && _hasUnreadNotifications) {
          setState(() {
            _hasUnreadNotifications = false;
          });
        }
        return;
      }

      final response = await VendorApiService.getNotifications(authToken);
      _lastNotificationFetchAt = DateTime.now();
      final notifications =
          (response['data']?['notifications'] as List<dynamic>?) ?? [];

      final hasUnread = notifications.any((raw) {
        if (raw is! Map) {
          return false;
        }

        final status = raw['status']?.toString().toLowerCase() ?? '';
        final isRead = raw['isRead'] == true || status == 'read';
        return !isRead;
      });

      if (mounted && _hasUnreadNotifications != hasUnread) {
        setState(() {
          _hasUnreadNotifications = hasUnread;
        });
      }
    } catch (_) {
      // Keep last known indicator state; avoid noisy UI failures for badge poll.
    } finally {
      _isFetchingNotificationStatus = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(context),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: PageView.builder(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          itemBuilder: (context, index) => _buildTab(index),
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildTab(int index) {
    switch (index) {
      case 0:
        return const _OverviewTabHost();
      case 1:
        return const OrdersScreen();
      case 2:
        return const ProductsScreen();
      case 3:
        return const AnalyticsScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final vendorProvider = Provider.of<VendorProvider>(context);

    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      foregroundColor: AppTheme.textPrimary,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: AppLogo(size: 32, withGradient: false, borderRadius: 8.0),
      ),
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
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ),
                );
                await _loadUnreadNotificationStatus(force: true);
              },
            ),
            if (_hasUnreadNotifications)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
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
        onTap: (index) async {
          if (index == _currentIndex) return;
          final previousIndex = _currentIndex;
          setState(() {
            _currentIndex = index;
          });
          if (!mounted || !_pageController.hasClients) return;

          final isAdjacent = (index - previousIndex).abs() == 1;
          if (isAdjacent) {
            await _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
            );
          } else {
            _pageController.jumpToPage(index);
          }
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

  Future<void> _goToTab(int index) async {
    if (index == _currentIndex) return;
    final previousIndex = _currentIndex;
    setState(() {
      _currentIndex = index;
    });
    if (!mounted || !_pageController.hasClients) return;

    final isAdjacent = (index - previousIndex).abs() == 1;
    if (isAdjacent) {
      await _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    } else {
      _pageController.jumpToPage(index);
    }
  }

  Widget _buildOverviewTab(BuildContext context) {
    return Consumer<VendorProvider>(
      builder: (context, vendorProvider, child) => RefreshIndicator(
        onRefresh: () async {
          await vendorProvider.refreshData();
          await _loadUnreadNotificationStatus(force: true);
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
                  RecentOrdersWidget(
                    vendorProvider: vendorProvider,
                    onViewAll: () {
                      _goToTab(1);
                    },
                  ),
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

}

class _OverviewTabHost extends StatelessWidget {
  const _OverviewTabHost();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_VendorDashboardScreenState>();
    if (state == null) {
      return const SizedBox.shrink();
    }
    return state._buildOverviewTab(context);
  }
}
