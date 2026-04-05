import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vendor_notification.dart';
import '../providers/vendor_notification_provider.dart';
import '../services/background_notification_service.dart';
import '../utils/app_theme.dart';
import 'order_details_screen.dart';
import 'payment_details_screen.dart';
import 'promotions_screen.dart';

/// Production-level notification screen with complete UX
class VendorNotificationScreen extends ConsumerWidget {
  const VendorNotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Set ref for background notification handler
    BackgroundNotificationHandler.setRef(ref);

    final state = ref.watch(vendorNotificationProvider);
    final unreadCount = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(context, ref, state, unreadCount),
      body: _buildBody(context, ref, state),
      floatingActionButton: state.notifications.isNotEmpty
          ? _buildFloatingActionButton(context, ref)
          : null,
    );
  }

  /// Build app bar with title and actions
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    NotificationState state,
    int unreadCount,
  ) {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      foregroundColor: AppTheme.textPrimary,
      titleSpacing: 16,
      title: Row(
        children: [
          const Icon(
            Icons.notifications_outlined,
            color: AppTheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Notifications',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          if (unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      actions: [
        if (state.notifications.isNotEmpty)
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'mark_all_read':
                  ref.read(vendorNotificationProvider.notifier).markAllAsRead();
                  break;
                case 'refresh':
                  ref
                      .read(vendorNotificationProvider.notifier)
                      .loadNotifications();
                  break;
                case 'clear_all':
                  _showClearAllDialog(context, ref);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_read_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Mark all as read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 18),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Clear all'),
                  ],
                ),
              ),
            ],
            child: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
          ),
      ],
    );
  }

  /// Build main body content
  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    NotificationState state,
  ) {
    if (state.isLoading) {
      return _buildLoadingState();
    }

    if (state.errorMessage != null) {
      return _buildErrorState(context, ref, state.errorMessage!);
    }

    if (state.notifications.isEmpty) {
      return _buildEmptyState();
    }

    return _buildNotificationList(ref, state.notifications);
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
          SizedBox(height: 16),
          Text(
            'Loading notifications...',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Error loading notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(fontSize: 14, color: Colors.red[400]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref
                    .read(vendorNotificationProvider.notifier)
                    .loadNotifications();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          Text(
            'New notifications will appear here automatically',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  /// Build notification list
  Widget _buildNotificationList(
    WidgetRef ref,
    List<VendorNotification> notifications,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(vendorNotificationProvider.notifier).loadNotifications();
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationItem(context, ref, notification);
        },
      ),
    );
  }

  /// Build individual notification item
  Widget _buildNotificationItem(
    BuildContext context,
    WidgetRef ref,
    VendorNotification notification,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: notification.isRead
            ? Colors.white
            : AppTheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead
              ? Colors.grey.withValues(alpha: 0.2)
              : AppTheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            _handleNotificationTap(context, ref, notification);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notification icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(
                      notification.type,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                // Notification content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and unread indicator
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                color: notification.isRead
                                    ? Colors.grey[700]
                                    : AppTheme.textPrimary,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Message body
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 14,
                          color: notification.isRead
                              ? Colors.grey[600]
                              : Colors.grey[800],
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Timestamp and actions
                      Row(
                        children: [
                          Text(
                            notification.timeAgo,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const Spacer(),
                          // Action menu
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'delete') {
                                _showDeleteDialog(context, ref, notification);
                              } else if (value == 'mark_read') {
                                ref
                                    .read(vendorNotificationProvider.notifier)
                                    .markAsRead(notification.id);
                              }
                            },
                            itemBuilder: (context) => [
                              if (!notification.isRead)
                                const PopupMenuItem(
                                  value: 'mark_read',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.mark_email_read_outlined,
                                        size: 16,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Mark as read'),
                                    ],
                                  ),
                                ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            child: Icon(
                              Icons.more_vert,
                              size: 18,
                              color: Colors.grey[400],
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

  /// Handle notification tap
  void _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    VendorNotification notification,
  ) {
    // Mark as read if unread
    if (!notification.isRead) {
      ref.read(vendorNotificationProvider.notifier).markAsRead(notification.id);
    }

    // Handle navigation based on notification type
    switch (notification.type) {
      case 'order':
        if (notification.data?['orderId'] != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OrderDetailsScreen(
                orderId: notification.data!['orderId'].toString(),
              ),
            ),
          );
        }
        break;
      case 'payment':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PaymentDetailsScreen(
              paymentId:
                  notification.data?['paymentId']?.toString() ??
                  notification.id,
              amount: notification.data?['amount']?.toDouble(),
              status: notification.data?['status']?.toString(),
              date: notification.data?['date'] != null
                  ? DateTime.tryParse(notification.data!['date'].toString())
                  : notification.createdAt,
            ),
          ),
        );
        break;
      case 'system':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('System notification'),
            backgroundColor: Colors.orange,
          ),
        );
        break;
      case 'promotion':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PromotionsScreen()),
        );
        break;
    }
  }

  /// Get notification icon based on type
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
      default:
        return Icons.notifications_outlined;
    }
  }

  /// Get notification color based on type
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
      default:
        return Colors.grey;
    }
  }

  /// Build floating action button
  Widget _buildFloatingActionButton(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () {
        ref.read(vendorNotificationProvider.notifier).markAllAsRead();
      },
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.mark_email_read_outlined),
      label: const Text('Mark All Read'),
    );
  }

  /// Show delete confirmation dialog
  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    VendorNotification notification,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: Text(
          'Are you sure you want to delete "${notification.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(vendorNotificationProvider.notifier)
                  .deleteNotification(notification.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification deleted'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Show clear all confirmation dialog
  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to clear all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(vendorNotificationProvider.notifier).clearError();
              // Clear all by deleting each one
              final notifications = ref
                  .read(vendorNotificationProvider)
                  .notifications;
              for (final notification in notifications) {
                ref
                    .read(vendorNotificationProvider.notifier)
                    .deleteNotification(notification.id);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications cleared'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
