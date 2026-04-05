import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/app_assets.dart';
import '../../utils/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/ledger_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/order_provider.dart';
import '../providers/payout_provider.dart';
import 'dashboard_screen.dart';
import 'ledger_screen.dart';
import 'orders_screen.dart';
import 'payouts_screen.dart';
import 'vendor_notifications_screen.dart';
import 'vendor_profile_screen.dart';

class VendorShellScreen extends ConsumerStatefulWidget {
  const VendorShellScreen({super.key});

  @override
  ConsumerState<VendorShellScreen> createState() => _VendorShellScreenState();
}

class _VendorShellScreenState extends ConsumerState<VendorShellScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      unawaited(ref.read(ledgerProvider.notifier).loadLedger());
      unawaited(ref.read(payoutProvider.notifier).loadPayouts(silent: true));
      await Future.wait([
        ref.read(orderProvider.notifier).loadOrders(),
        ref.read(notificationProvider.notifier).loadNotifications(),
      ]);
      unawaited(ref.read(authProvider.notifier).refreshProfile());
      ref.read(orderProvider.notifier).startPolling();
      ref.read(notificationProvider.notifier).startPolling();
    });
  }

  @override
  void dispose() {
    ref.read(orderProvider.notifier).stopPolling();
    ref.read(notificationProvider.notifier).stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
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
        foregroundColor: AppTheme.textPrimary,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: AppLogo(size: 32, withGradient: false, borderRadius: 8),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_titles[_index]),
            Text(
              authState.session?.profile.businessName ?? '',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const VendorNotificationsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.notifications_outlined),
              ),
              if (notifications.unreadCount > 0)
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
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (value) {
            if (value == 2) {
              unawaited(
                ref.read(ledgerProvider.notifier).loadLedger(silent: true),
              );
            }
            if (value == 3) {
              unawaited(
                ref.read(payoutProvider.notifier).loadPayouts(silent: true),
              );
            }
            if (value == 4) {
              unawaited(ref.read(authProvider.notifier).refreshProfile());
            }
            setState(() {
              _index = value;
            });
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
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Ledger',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.payments_outlined),
              activeIcon: Icon(Icons.payments),
              label: 'Payouts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

const _titles = ['Dashboard', 'Orders', 'Ledger', 'Payouts', 'Profile'];
