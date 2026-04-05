import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/app_assets.dart';
import '../../utils/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/ledger_provider.dart';
import '../providers/payout_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/order_provider.dart';
import 'dashboard_screen.dart';
import 'ledger_screen.dart';
import 'orders_screen.dart';
import 'vendor_profile_screen.dart';
import 'payouts_screen.dart';
import 'notification_screen.dart';

class VendorShellScreen extends ConsumerStatefulWidget {
  const VendorShellScreen({super.key});

  @override
  ConsumerState<VendorShellScreen> createState() => _VendorShellScreenState();
}

class _VendorShellScreenState extends ConsumerState<VendorShellScreen> {
  int _index = 0;

  void _showNotificationDialog() {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to view notifications'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationScreen()),
    );
  }

  @override
  void initState() {
    super.initState();

    // Safe initialization with proper error handling
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      try {
        ref.read(ledgerProvider.notifier).loadLedger();
        ref.read(payoutProvider.notifier).loadPayouts(silent: true);
      } catch (e) {
        // Handle initialization errors gracefully
      }
    });

    // Delay notifications loading to avoid lifecycle issues
    Future.delayed(const Duration(milliseconds: 100), () async {
      if (!mounted) return;

      // Check if user is authenticated before loading notifications
      final authState = ref.read(authProvider);
      if (!authState.isAuthenticated) {
        return;
      }

      try {
        await ref.read(notificationProvider.notifier).loadNotifications();
        ref.read(notificationProvider.notifier).startPolling();
      } catch (e) {
        // Handle notification loading errors
      }
    });

    // Load orders and start polling
    Future.delayed(const Duration(milliseconds: 200), () async {
      if (!mounted) return;

      try {
        await ref.read(orderProvider.notifier).loadOrders();
        ref.read(orderProvider.notifier).startPolling();
      } catch (e) {
        // Handle order loading errors
      }
    });

    // Refresh profile separately to avoid blocking
    Future.delayed(const Duration(milliseconds: 300), () async {
      if (!mounted) return;

      try {
        ref.read(authProvider.notifier).refreshProfile();
      } catch (e) {
        // Handle profile refresh errors
      }
    });
  }

  @override
  void dispose() {
    // Stop polling when widget is disposed
    ref.read(notificationProvider.notifier).stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationProvider);
    final pages = const [
      VendorDashboardTab(),
      VendorOrdersTab(),
      VendorLedgerTab(),
      VendorPayoutsTab(),
      VendorProfileTab(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        centerTitle: true,
        titleSpacing: 16,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(AppAssets.logoImage, height: 28),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'UNINEST',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.store_outlined,
                        size: 12,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Vendor Portal',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Enhanced notification bell with badge
          Stack(
            children: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: _showNotificationDialog,
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ),
              if (notifications.notifications.isNotEmpty)
                Positioned(
                  right: 20,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      notifications.notifications.length > 99
                          ? '99+'
                          : notifications.notifications.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  index: 0,
                  isSelected: _index == 0,
                ),
                _buildNavItem(
                  icon: Icons.receipt_long_outlined,
                  label: 'Orders',
                  index: 1,
                  isSelected: _index == 1,
                ),
                _buildNavItem(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Ledger',
                  index: 2,
                  isSelected: _index == 2,
                ),
                _buildNavItem(
                  icon: Icons.payments_outlined,
                  label: 'Payouts',
                  index: 3,
                  isSelected: _index == 3,
                ),
                _buildNavItem(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  index: 4,
                  isSelected: _index == 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _index = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 24,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
