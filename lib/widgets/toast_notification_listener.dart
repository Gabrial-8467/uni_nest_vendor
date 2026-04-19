import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vendor_notification.dart';
import '../providers/vendor_notification_provider.dart';
import '../screens/order_details_screen.dart';
import '../utils/app_theme.dart';

/// Widget that listens for new notifications and shows toast messages
/// Only shows notifications when the app is open
class ToastNotificationListener extends ConsumerStatefulWidget {
  final Widget child;

  const ToastNotificationListener({super.key, required this.child});

  @override
  ConsumerState<ToastNotificationListener> createState() =>
      _ToastNotificationListenerState();
}

class _ToastNotificationListenerState
    extends ConsumerState<ToastNotificationListener> {
  final List<String> _shownNotificationIds = [];

  @override
  Widget build(BuildContext context) {
    // Listen to notification state changes
    ref.listen<VendorNotificationState>(vendorNotificationProvider, (
      previous,
      current,
    ) {
      if (previous == null) return;

      // Check if new notifications were added
      if (current.notifications.length > previous.notifications.length) {
        // Find the newest notification
        final newNotifications = current.notifications
            .where((n) => !previous.notifications.any((p) => p.id == n.id))
            .toList();

        for (final notification in newNotifications) {
          // Only show if not already shown
          if (!_shownNotificationIds.contains(notification.id)) {
            _shownNotificationIds.add(notification.id);
            _showToastNotification(context, notification);
          }
        }
      }
    });

    return widget.child;
  }

  void _showToastNotification(
    BuildContext context,
    VendorNotification notification,
  ) {
    // Get the appropriate color and icon
    final color = _getNotificationColor(notification.type);
    final icon = _getNotificationIcon(notification.type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (notification.body.isNotEmpty)
                    Text(
                      notification.body,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: Colors.white,
          onPressed: () {
            _handleNotificationTap(notification);
          },
        ),
      ),
    );
  }

  void _handleNotificationTap(VendorNotification notification) {
    // Navigate based on notification type
    switch (notification.type) {
      case 'order':
        if (notification.data?['orderId'] != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  OrderDetailsScreen(orderId: notification.data!['orderId']),
            ),
          );
        }
        break;
      case 'payment':
        Navigator.of(context).pushNamed('/ledger');
        break;
      case 'vendor_approval':
      case 'vendor_status':
        Navigator.of(context).pushNamed('/profile');
        break;
      default:
        Navigator.of(context).pushNamed('/notifications');
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.receipt_long_outlined;
      case 'payment':
        return Icons.payments_outlined;
      case 'system':
        return Icons.info_outline;
      case 'promotion':
        return Icons.campaign_outlined;
      case 'vendor_approval':
        return Icons.verified_outlined;
      case 'vendor_status':
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'order':
        return Colors.blue;
      case 'payment':
        return Colors.green;
      case 'system':
        return Colors.orange;
      case 'promotion':
        return Colors.purple;
      case 'vendor_approval':
        return Colors.teal;
      case 'vendor_status':
        return Colors.redAccent;
      default:
        return AppTheme.primary;
    }
  }
}
