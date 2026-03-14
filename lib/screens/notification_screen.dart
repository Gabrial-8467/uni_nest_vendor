import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class Notification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String type; // 'order', 'payment', 'system', 'promotion'
  final bool isRead;
  final Map<String, dynamic>? data;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.data,
  });
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Notification> notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    // Sample notifications - in real app, these would come from API
    notifications = [
      Notification(
        id: '1',
        title: 'New Order Received',
        message: 'Order #12345 has been placed for ₹1,299.00',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        type: 'order',
        data: {'orderId': '12345'},
      ),
      Notification(
        id: '2',
        title: 'Payment Received',
        message: 'Payment of ₹2,500.00 received for Order #12340',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: 'payment',
        data: {'orderId': '12340', 'amount': 2500.0},
      ),
      Notification(
        id: '3',
        title: 'Low Stock Alert',
        message:
            'Product "Wireless Headphones" is running low on stock (5 units left)',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        type: 'system',
        data: {'productId': 'prod_123', 'stock': 5},
      ),
      Notification(
        id: '4',
        title: 'System Maintenance',
        message: 'Scheduled maintenance on Sunday 2:00 AM - 4:00 AM',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: 'system',
        isRead: true,
      ),
      Notification(
        id: '5',
        title: 'Promotional Opportunity',
        message: 'Boost your sales with our weekend promotion campaign',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        type: 'promotion',
        isRead: true,
      ),
    ];
  }

  void _markAsRead(String notificationId) {
    setState(() {
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        notifications[index] = Notification(
          id: notifications[index].id,
          title: notifications[index].title,
          message: notifications[index].message,
          timestamp: notifications[index].timestamp,
          type: notifications[index].type,
          isRead: true,
          data: notifications[index].data,
        );
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      notifications = notifications
          .map(
            (notification) => Notification(
              id: notification.id,
              title: notification.title,
              message: notification.message,
              timestamp: notification.timestamp,
              type: notification.type,
              isRead: true,
              data: notification.data,
            ),
          )
          .toList();
    });
  }

  void _deleteNotification(String notificationId) {
    setState(() {
      notifications.removeWhere((n) => n.id == notificationId);
    });
  }

  void _clearAllNotifications() {
    setState(() {
      notifications.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        title: const Text(
          'Notifications',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (notifications.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'mark_all_read') {
                  _markAllAsRead();
                } else if (value == 'clear_all') {
                  _showClearAllDialog();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.mark_email_read_outlined),
                      SizedBox(width: 8),
                      Text('Mark all as read'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all_outlined),
                      SizedBox(width: 8),
                      Text('Clear all'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationItem(notification);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Notification notification) {
    final iconData = _getNotificationIcon(notification.type);
    final iconColor = _getNotificationColor(notification.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            _markAsRead(notification.id);
            _handleNotificationTap(notification);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(iconData, color: iconColor, size: 20),
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
                              notification.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: notification.isRead
                                    ? Colors.grey[700]
                                    : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: notification.isRead
                              ? Colors.grey[600]
                              : Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            _formatTimestamp(notification.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                          const Spacer(),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'delete') {
                                _deleteNotification(notification.id);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, size: 16),
                                    SizedBox(width: 8),
                                    Text('Delete'),
                                  ],
                                ),
                              ),
                            ],
                            child: Icon(
                              Icons.more_vert,
                              size: 16,
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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _handleNotificationTap(Notification notification) {
    // Handle navigation based on notification type
    switch (notification.type) {
      case 'order':
        if (notification.data?['orderId'] != null) {
          // Navigate to order details
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening order ${notification.data!['orderId']}'),
            ),
          );
        }
        break;
      case 'payment':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening payment details')),
        );
        break;
      case 'system':
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('System notification')));
        break;
      case 'promotion':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening promotional offers')),
        );
        break;
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to clear all notifications?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllNotifications();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
