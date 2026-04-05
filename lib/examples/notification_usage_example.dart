import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uni_nest_vendor/providers/vendor_notification_provider.dart';
import 'package:uni_nest_vendor/screens/vendor_notification_screen.dart';
import 'package:uni_nest_vendor/utils/app_theme.dart';

/// Example of how to integrate the notification system
class NotificationUsageExample extends ConsumerWidget {
  const NotificationUsageExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the unread count for badge display
    final unreadCount = ref.watch(unreadCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification System Example'),
        backgroundColor: AppTheme.surface,
        actions: [
          // Notification bell with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // Navigate to notification screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VendorNotificationScreen(),
                    ),
                  );
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification System Features:',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Manual controls
            _buildControlSection(
              title: 'Manual Controls',
              children: [
                ElevatedButton(
                  onPressed: () {
                    ref
                        .read(vendorNotificationProvider.notifier)
                        .loadNotifications();
                  },
                  child: const Text('Load Notifications'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    ref
                        .read(vendorNotificationProvider.notifier)
                        .markAllAsRead();
                  },
                  child: const Text('Mark All as Read'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    ref
                        .read(vendorNotificationProvider.notifier)
                        .startPolling();
                  },
                  child: const Text('Start Polling'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    ref.read(vendorNotificationProvider.notifier).stopPolling();
                  },
                  child: const Text('Stop Polling'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Status display
            _buildStatusDisplay(ref),

            const SizedBox(height: 24),

            // Quick actions
            _buildQuickActions(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildControlSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: children),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDisplay(WidgetRef ref) {
    final state = ref.watch(vendorNotificationProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Status:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // Status indicators
            Row(
              children: [
                Icon(
                  state.isLoading ? Icons.hourglass_empty : Icons.check_circle,
                  color: state.isLoading ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  state.isLoading
                      ? 'Loading...'
                      : state.isPolling
                      ? 'Polling active'
                      : 'Idle',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Counts
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Notifications',
                    state.totalCount.toString(),
                    Icons.notifications,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Unread',
                    state.unreadCount.toString(),
                    Icons.mark_email_unread,
                    Colors.red,
                  ),
                ),
              ],
            ),

            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
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

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vendorNotificationProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: state.notifications.isNotEmpty
                        ? () => ref
                              .read(vendorNotificationProvider.notifier)
                              .markAllAsRead()
                        : null,
                    icon: const Icon(Icons.mark_email_read),
                    label: const Text('Mark All Read'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: state.notifications.isNotEmpty
                        ? () {
                            // Clear all notifications
                            final notifications = state.notifications;
                            for (final notification in notifications) {
                              ref
                                  .read(vendorNotificationProvider.notifier)
                                  .deleteNotification(notification.id);
                            }
                          }
                        : null,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            if (state.notifications.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VendorNotificationScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.list),
                  label: const Text('View All Notifications'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget that shows notification count badge
class NotificationBadge extends ConsumerWidget {
  const NotificationBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(
      vendorNotificationProvider.select((state) => state.unreadCount),
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const VendorNotificationScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications, color: Colors.white, size: 18),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
