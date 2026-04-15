import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vendor_notification.dart';
import '../services/vendor_notification_service.dart';
import '../utils/secure_logger.dart';

/// Vendor Notification state management
@immutable
class VendorNotificationState {
  const VendorNotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.errorMessage,
    this.isPolling = false,
  });

  /// List of all notifications
  final List<VendorNotification> notifications;

  /// Loading state for API operations
  final bool isLoading;

  /// Error message from failed operations
  final String? errorMessage;

  /// Polling status tracking
  final bool isPolling;

  /// Count of unread notifications
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  /// Count of total notifications
  int get totalCount => notifications.length;

  VendorNotificationState copyWith({
    List<VendorNotification>? notifications,
    bool? isLoading,
    String? errorMessage,
    bool? isPolling,
    bool clearError = false,
  }) {
    return VendorNotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isPolling: isPolling ?? this.isPolling,
    );
  }
}

/// Notification controller using StateNotifier
class VendorNotificationController
    extends StateNotifier<VendorNotificationState> {
  VendorNotificationController() : super(const VendorNotificationState());

  Timer? _pollingTimer;
  static const Duration _pollingInterval = Duration(seconds: 45);
  static const Duration _minimumRefreshGap = Duration(seconds: 20);
  bool _isDisposed = false;
  bool _isFetching = false;
  DateTime? _lastLoadedAt;

  @override
  void dispose() {
    _isDisposed = true;
    stopPolling();
    super.dispose();
  }

  /// Load notifications from backend API
  Future<void> loadNotifications({bool silent = false, bool force = false}) async {
    if (_isFetching || (state.isLoading && !silent)) return;

    final now = DateTime.now();
    if (!force &&
        _lastLoadedAt != null &&
        now.difference(_lastLoadedAt!) < _minimumRefreshGap) {
      return;
    }

    _isFetching = true;

    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final notifications = await VendorNotificationService.getNotifications();

      state = state.copyWith(
        notifications: notifications,
        isLoading: false,
        clearError: true,
      );
      _lastLoadedAt = DateTime.now();

      SecureLogger.info(
        'Loaded ${notifications.length} notifications',
        tag: 'NOTIFICATIONS',
      );
    } catch (e) {
      SecureLogger.error(
        'Error loading notifications',
        error: e,
        tag: 'NOTIFICATIONS',
      );
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    } finally {
      _isFetching = false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    if (state.notifications.isEmpty) return true;

    try {
      await VendorNotificationService.markAllRead();

      // Update local state optimistically
      final updatedNotifications = state.notifications
          .map((notification) => notification.copyWith(isRead: true))
          .toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        clearError: true,
      );

      SecureLogger.info('Marked all notifications as read', tag: 'NOTIFICATIONS');
      return true;
    } catch (e) {
      SecureLogger.error(
        'Error marking all as read',
        error: e,
        tag: 'NOTIFICATIONS',
      );
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// Mark a specific notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await VendorNotificationService.markAsRead(notificationId);

      // Update local state optimistically
      final updatedNotifications = state.notifications.map((notification) {
        if (notification.id == notificationId) {
          return notification.copyWith(isRead: true);
        }
        return notification;
      }).toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        clearError: true,
      );

      SecureLogger.info('Marked notification as read', tag: 'NOTIFICATIONS');
      return true;
    } catch (e) {
      SecureLogger.error(
        'Error marking notification as read',
        error: e,
        tag: 'NOTIFICATIONS',
      );
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// Clear all notifications using the backend bulk endpoint
  Future<bool> clearAll() async {
    try {
      await VendorNotificationService.clearAll();
      state = state.copyWith(notifications: const [], clearError: true);
      SecureLogger.info('Cleared all notifications', tag: 'NOTIFICATIONS');
      return true;
    } catch (e) {
      SecureLogger.error(
        'Error clearing notifications',
        error: e,
        tag: 'NOTIFICATIONS',
      );
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// Delete a specific notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await VendorNotificationService.deleteNotification(notificationId);

      // Remove from local state
      final updatedNotifications = state.notifications
          .where((notification) => notification.id != notificationId)
          .toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        clearError: true,
      );

      SecureLogger.info('Deleted notification', tag: 'NOTIFICATIONS');
      return true;
    } catch (e) {
      SecureLogger.error(
        'Error deleting notification',
        error: e,
        tag: 'NOTIFICATIONS',
      );
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// Start automatic polling for new notifications
  void startPolling() {
    if (state.isPolling) {
      SecureLogger.info('Notification polling already active');
      return;
    }

    SecureLogger.info('Starting notification polling');
    state = state.copyWith(isPolling: true);

    _pollingTimer = Timer.periodic(_pollingInterval, (timer) async {
      if (_isDisposed) return;

      await loadNotifications(silent: true);
    });
  }

  /// Stop automatic polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;

    if (!state.isPolling) return;

    SecureLogger.info('Stopped notification polling');
    state = state.copyWith(isPolling: false);
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Add a new notification (for real-time updates)
  void addNotification(VendorNotification notification) {
    final updatedNotifications = [notification, ...state.notifications];
    state = state.copyWith(
      notifications: updatedNotifications,
      clearError: true,
    );
    SecureLogger.info('Added new notification', tag: 'NOTIFICATIONS');
  }
}

/// Provider for notification state
final vendorNotificationProvider =
    StateNotifierProvider<
      VendorNotificationController,
      VendorNotificationState
    >((ref) => VendorNotificationController());

/// Provider for total count (computed)
final totalCountProvider = Provider<int>((ref) {
  return ref.watch(vendorNotificationProvider).totalCount;
});

/// Provider for unread count (computed)
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(vendorNotificationProvider).unreadCount;
});
