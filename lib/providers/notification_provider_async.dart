import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

import '../models/ledger_models.dart';
import 'auth_provider.dart';

// Async State for better error handling
@immutable
class NotificationAsyncState {
  const NotificationAsyncState({
    required this.notifications,
    required this.isLoading,
    required this.error,
  });

  final List<VendorNotification> notifications;
  final bool isLoading;
  final String? error;

  const NotificationAsyncState.initial()
    : notifications = const [],
      isLoading = false,
      error = null;

  NotificationAsyncState copyWith({
    List<VendorNotification>? notifications,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return NotificationAsyncState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationAsyncState &&
        other.notifications == notifications &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(notifications, isLoading, error);
}

// Production-grade AsyncNotifier implementation
class NotificationAsyncController
    extends AsyncNotifier<NotificationAsyncState> {
  Timer? _pollingTimer;

  @override
  NotificationAsyncState build() {
    // Initial state - auto-loading happens in refreshNotifications
    ref.onDispose(() {
      _pollingTimer?.cancel();
    });
    return NotificationAsyncState.initial();
  }

  // Clean API call with proper error handling
  Future<List<VendorNotification>> _loadNotificationsFromApi({
    bool silent = false,
  }) async {
    if (!ref.read(authProvider).isAuthenticated) {
      return [];
    }

    try {
      return await ref.read(vendorApiClientProvider).getNotifications();
    } catch (error) {
      if (!silent) {
        // Let the UI handle the error through state
        rethrow;
      }
      return [];
    }
  }

  // Public method for manual refresh
  Future<void> refreshNotifications() async {
    state = const AsyncValue.data(
      NotificationAsyncState(notifications: [], isLoading: true, error: null),
    );

    try {
      final notifications = await _loadNotificationsFromApi();
      state = AsyncValue.data(
        NotificationAsyncState(
          notifications: notifications,
          isLoading: false,
          error: null,
        ),
      );
    } catch (error) {
      state = AsyncValue.data(
        NotificationAsyncState(
          notifications: [],
          isLoading: false,
          error: error.toString(),
        ),
      );
    }
  }

  // Silent refresh for polling
  Future<void> _silentRefresh() async {
    try {
      final notifications = await _loadNotificationsFromApi(silent: true);
      state = AsyncValue.data(
        NotificationAsyncState(
          notifications: notifications,
          isLoading: false,
          error: state.value?.error, // Preserve existing error
        ),
      );
    } catch (error) {
      // Silent failures don't update error state
      // Could log to analytics/crashlytics here
    }
  }

  // Mark all as read
  Future<bool> markAllAsRead() async {
    try {
      await ref.read(vendorApiClientProvider).markAllNotificationsRead();

      final updatedNotifications = state.value!.notifications
          .map(
            (item) => VendorNotification(
              id: item.id,
              title: item.title,
              body: item.body,
              type: item.type,
              isRead: true,
              createdAt: item.createdAt,
              data: item.data,
            ),
          )
          .toList();

      state = AsyncValue.data(
        NotificationAsyncState(
          notifications: updatedNotifications,
          isLoading: false,
          error: null,
        ),
      );
      return true;
    } catch (error) {
      state = AsyncValue.data(
        NotificationAsyncState(
          notifications: state.value!.notifications,
          isLoading: false,
          error: error.toString(),
        ),
      );
      return false;
    }
  }

  // Clear all notifications
  Future<bool> clearAll() async {
    try {
      await ref.read(vendorApiClientProvider).clearAllNotifications();
      state = const AsyncValue.data(
        NotificationAsyncState(
          notifications: [],
          isLoading: false,
          error: null,
        ),
      );
      return true;
    } catch (error) {
      state = AsyncValue.data(
        NotificationAsyncState(
          notifications: state.value!.notifications,
          isLoading: false,
          error: error.toString(),
        ),
      );
      return false;
    }
  }

  // Mark single notification as read (optimistic update)
  void markReadLocally(String notificationId) {
    final updatedNotifications = state.value!.notifications.map((item) {
      if (item.id == notificationId) {
        return VendorNotification(
          id: item.id,
          title: item.title,
          body: item.body,
          type: item.type,
          isRead: true,
          createdAt: item.createdAt,
          data: item.data,
        );
      }
      return item;
    }).toList();

    state = AsyncValue.data(
      NotificationAsyncState(
        notifications: updatedNotifications,
        isLoading: false,
        error: state.value!.error,
      ),
    );
  }

  // Start polling (safe automatic updates)
  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => _silentRefresh(),
    );
  }

  // Stop polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // Cleanup method
  void dispose() {
    _pollingTimer?.cancel();
  }
}

// Modern provider declaration
final notificationAsyncProvider =
    AsyncNotifierProvider<NotificationAsyncController, NotificationAsyncState>(
      NotificationAsyncController.new,
    );
