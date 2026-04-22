import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vendor_notification.dart';
import '../providers/order_provider.dart';
import '../providers/vendor_notification_provider.dart';
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
  static const Duration _orderToastFreshnessTolerance = Duration(seconds: 15);

  final Set<String> _knownNotificationIds = {};
  final DateTime _mountedAt = DateTime.now();
  bool _hasSeededExistingNotifications = false;
  DateTime? _toastEnabledAt;

  @override
  Widget build(BuildContext context) {
    // Listen to notification state changes
    ref.listen<VendorNotificationState>(vendorNotificationProvider, (
      previous,
      current,
    ) {
      if (previous == null) return;

      if (!_hasSeededExistingNotifications) {
        if (current.isLoading) {
          return;
        }

        _rememberNotifications(current.notifications);
        _hasSeededExistingNotifications = true;
        _toastEnabledAt = DateTime.now();
        return;
      }

      // Check if new notifications were added
      if (current.notifications.length > previous.notifications.length) {
        // Find the newest notification
        final newNotifications = current.notifications
            .where((n) => !_knownNotificationIds.contains(n.id))
            .toList();

        for (final notification in newNotifications) {
          _knownNotificationIds.add(notification.id);

          if (!_shouldShowToast(notification)) {
            continue;
          }

          _showToastNotification(context, notification);
        }
      }
    });

    return widget.child;
  }

  void _rememberNotifications(List<VendorNotification> notifications) {
    _knownNotificationIds.addAll(notifications.map((item) => item.id));
  }

  bool _shouldShowToast(VendorNotification notification) {
    final eventText = _orderEventText(notification);
    final status = _orderStatus(notification);
    final isOrderNotification =
        notification.isOrder ||
        eventText.contains('order') ||
        notification.data?['orderId'] != null ||
        notification.data?['order_id'] != null;

    if (!isOrderNotification) {
      return true;
    }

    if (!_isFreshOrderNotification(notification)) {
      return false;
    }

    if (_isKnownOrder(notification)) {
      return false;
    }

    if (_isCompletedOrderStatus(status) ||
        eventText.contains('completed') ||
        eventText.contains('delivered') ||
        eventText.contains('cancelled') ||
        eventText.contains('canceled') ||
        eventText.contains('refunded')) {
      return false;
    }

    return eventText.contains('new order') ||
        eventText.contains('order placed') ||
        eventText.contains('order created') ||
        eventText.contains('order received') ||
        status == 'pending' ||
        status == 'confirmed';
  }

  bool _isFreshOrderNotification(VendorNotification notification) {
    final toastEnabledAt = _toastEnabledAt ?? _mountedAt;
    final oldestAllowedCreatedAt = toastEnabledAt.subtract(
      _orderToastFreshnessTolerance,
    );

    return !notification.createdAt.isBefore(oldestAllowedCreatedAt);
  }

  bool _isKnownOrder(VendorNotification notification) {
    final orderId = _notificationOrderId(notification);
    if (orderId.isEmpty) {
      return false;
    }

    return ref.read(orderProvider).orders.any((order) {
      return order.id == orderId || order.orderNumber == orderId;
    });
  }

  String _notificationOrderId(VendorNotification notification) {
    final data = notification.data ?? const <String, dynamic>{};
    return (data['orderId'] ??
            data['order_id'] ??
            data['orderNumber'] ??
            data['order_number'] ??
            '')
        .toString();
  }

  String _orderEventText(VendorNotification notification) {
    final data = notification.data ?? const <String, dynamic>{};
    return [
      notification.title,
      notification.body,
      data['event'],
      data['action'],
      data['notificationType'],
      data['type'],
    ].whereType<Object>().map((value) {
      return value.toString().toLowerCase();
    }).join(' ');
  }

  String _orderStatus(VendorNotification notification) {
    final data = notification.data ?? const <String, dynamic>{};
    return (data['orderStatus'] ??
            data['order_status'] ??
            data['status'] ??
            data['newStatus'] ??
            data['new_status'] ??
            '')
        .toString()
        .toLowerCase();
  }

  bool _isCompletedOrderStatus(String status) {
    return status == 'delivered' ||
        status == 'completed' ||
        status == 'cancelled' ||
        status == 'canceled' ||
        status == 'refunded';
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
      ),
    );
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
