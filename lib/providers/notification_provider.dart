import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ledger_models.dart';
import 'auth_provider.dart';

class NotificationState {
  const NotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.errorMessage,
  });

  final bool isLoading;
  final List<VendorNotification> notifications;
  final String? errorMessage;

  int get unreadCount => notifications.where((item) => !item.isRead).length;

  NotificationState copyWith({
    bool? isLoading,
    List<VendorNotification>? notifications,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class NotificationController extends StateNotifier<NotificationState> {
  NotificationController(this._ref) : super(const NotificationState()) {
    // Use ref.onDispose for automatic cleanup when provider is disposed
    _ref.onDispose(() {
      _pollingTimer?.cancel();
    });
  }

  final Ref _ref;
  Timer? _pollingTimer;
  bool _isFetching = false;

  Future<void> loadNotifications({bool silent = false}) async {
    if (!_ref.read(authProvider).isAuthenticated) {
      state = const NotificationState();
      stopPolling();
      return;
    }

    if (_isFetching) {
      return;
    }
    _isFetching = true;

    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final notifications = await _ref
          .read(vendorApiClientProvider)
          .getNotifications();

      state = state.copyWith(
        isLoading: false,
        notifications: notifications,
        clearError: true,
      );
    } catch (error) {
      // Check if it's a 401 authentication error
      if (error.toString().contains('401') ||
          error.toString().contains('User not found') ||
          error.toString().contains('Session expired')) {
        // Stop polling on authentication errors
        stopPolling();
        state = state.copyWith(
          isLoading: false,
          notifications: const [],
          errorMessage: 'Authentication failed. Please login again.',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        );
      }
    } finally {
      _isFetching = false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      await _ref.read(vendorApiClientProvider).markAllNotificationsRead();

      state = state.copyWith(
        notifications: [
          for (final item in state.notifications)
            VendorNotification(
              id: item.id,
              title: item.title,
              body: item.body,
              type: item.type,
              isRead: true,
              createdAt: item.createdAt,
              data: item.data,
            ),
        ],
        clearError: true,
      );
      return true;
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
      return false;
    }
  }

  Future<bool> clearAll() async {
    try {
      await _ref.read(vendorApiClientProvider).clearAllNotifications();

      state = state.copyWith(notifications: const [], clearError: true);
      return true;
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _ref
          .read(vendorApiClientProvider)
          .deleteNotification(notificationId);

      state = state.copyWith(
        notifications: state.notifications
            .where((notification) => notification.id != notificationId)
            .toList(),
        clearError: true,
      );
      return true;
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
      return false;
    }
  }

  void markReadLocally(String notificationId) {
    state = state.copyWith(
      notifications: [
        for (final item in state.notifications)
          if (item.id == notificationId)
            VendorNotification(
              id: item.id,
              title: item.title,
              body: item.body,
              type: item.type,
              isRead: true,
              createdAt: item.createdAt,
              data: item.data,
            )
          else
            item,
      ],
    );
  }

  void startPolling() {
    _pollingTimer ??= Timer.periodic(
      const Duration(seconds: 45),
      (_) => loadNotifications(silent: true),
    );
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationController, NotificationState>(
      (ref) => NotificationController(ref),
    );
