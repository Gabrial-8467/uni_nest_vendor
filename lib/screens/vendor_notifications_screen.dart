import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/app_theme.dart';
import '../../core/vendor_formatters.dart';
import '../../models/ledger_models.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/empty_state.dart';

class VendorNotificationsScreen extends ConsumerStatefulWidget {
  const VendorNotificationsScreen({super.key});

  @override
  ConsumerState<VendorNotificationsScreen> createState() =>
      _VendorNotificationsScreenState();
}

class _VendorNotificationsScreenState
    extends ConsumerState<VendorNotificationsScreen> {
  bool _showUnreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final notifications = _showUnreadOnly
        ? state.notifications.where((item) => !item.isRead).toList()
        : state.notifications;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        title: const Text('Notifications'),
        actions: [
          if (state.notifications.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'mark_all_read') {
                  final ok = await ref
                      .read(notificationProvider.notifier)
                      .markAllAsRead();
                  if (mounted) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'All notifications marked as read.'
                                : 'Unable to mark notifications as read.',
                          ),
                        ),
                      );
                    }
                  }
                }
                if (value == 'clear_all') {
                  final ok = await ref
                      .read(notificationProvider.notifier)
                      .clearAll();
                  if (mounted) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Notifications cleared.'
                                : 'Unable to clear notifications.',
                          ),
                        ),
                      );
                    }
                  }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'mark_all_read',
                  child: Text('Mark all as read'),
                ),
                PopupMenuItem(value: 'clear_all', child: Text('Clear all')),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(notificationProvider.notifier).loadNotifications(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _MetricPill(
                      label: 'Total',
                      value: '${state.notifications.length}',
                      color: AppTheme.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricPill(
                      label: 'Unread',
                      value: '${state.unreadCount}',
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilterChip(
                    label: const Text('Unread only'),
                    selected: _showUnreadOnly,
                    onSelected: (value) {
                      setState(() {
                        _showUnreadOnly = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (state.isLoading && state.notifications.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.errorMessage != null && state.notifications.isEmpty)
              EmptyState(
                icon: Icons.notifications_off_outlined,
                title: 'Unable to load notifications',
                message: state.errorMessage!,
              )
            else if (notifications.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: EmptyState(
                  icon: Icons.notifications_none_outlined,
                  title: 'No notifications',
                  message:
                      'Order, payment, system, and account alerts from the backend will appear here.',
                ),
              )
            else
              ...notifications.map(
                (notification) => _NotificationCard(
                  notification: notification,
                  onTap: () {
                    ref
                        .read(notificationProvider.notifier)
                        .markReadLocally(notification.id);
                    _handleNotificationTap(context, notification);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(
    BuildContext context,
    VendorNotification notification,
  ) {
    final type = humanizeEnum(notification.type);
    final orderId = notification.data?['orderId']?.toString();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          orderId == null || orderId.isEmpty
              ? '$type notification opened.'
              : '$type update for order $orderId.',
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final VendorNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(notification.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead
            ? Colors.white
            : color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead
              ? Colors.grey.withValues(alpha: 0.16)
              : color.withValues(alpha: 0.24),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_iconFor(notification.type), color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.body,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              humanizeEnum(notification.type),
                              style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            formatCompactDate(notification.createdAt),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(String type) {
    switch (type) {
      case 'order':
        return Icons.receipt_long_outlined;
      case 'payment':
        return Icons.payments_outlined;
      case 'review':
        return Icons.star_outline;
      case 'vendor_status':
        return Icons.storefront_outlined;
      case 'account_alert':
        return Icons.shield_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  static Color _colorFor(String type) {
    switch (type) {
      case 'order':
        return AppTheme.info;
      case 'payment':
        return AppTheme.success;
      case 'review':
        return const Color(0xFFF59E0B);
      case 'vendor_status':
        return const Color(0xFF8B5CF6);
      case 'account_alert':
        return Colors.deepOrange;
      default:
        return Colors.blueGrey;
    }
  }
}
