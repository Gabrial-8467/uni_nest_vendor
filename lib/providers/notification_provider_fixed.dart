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

// Production-grade StateNotifier with lifecycle safety
class NotificationController extends StateNotifier<NotificationState> {
  NotificationController(this._ref) : super(const NotificationState());

  final Ref _ref;
  Timer? _pollingTimer;
  bool _isFetching = false;

  // Add lifecycle tracking
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _pollingTimer?.cancel();
    super.dispose();
  }

  // Safe state update method
  void _safeUpdate(NotificationState Function() updater) {
    if (!_isDisposed) {
      try {
        updater();
      } catch (e) {
        // Widget was disposed, ignore state update
      }
    }
  }

  Future<void> loadNotifications({bool silent = false}) async {
    if (!_ref.read(authProvider).isAuthenticated) {
      _safeUpdate(() => state = const NotificationState());
      return;
    }

    if (_isFetching) {
      return;
    }
    _isFetching = true;

    if (!silent) {
      _safeUpdate(
        () => state = state.copyWith(isLoading: true, clearError: true),
      );
    }

    try {
      final notifications = await _ref
          .read(vendorApiClientProvider)
          .getNotifications();

      _safeUpdate(
        () => state = state.copyWith(
          isLoading: false,
          notifications: notifications,
          clearError: true,
        ),
      );
    } catch (error) {
      _safeUpdate(
        () => state = state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        ),
      );
    } finally {
      _isFetching = false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      await _ref.read(vendorApiClientProvider).markAllNotificationsRead();

      _safeUpdate(
        () => state = state.copyWith(
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
        ),
      );
      return true;
    } catch (error) {
      _safeUpdate(() => state = state.copyWith(errorMessage: error.toString()));
      return false;
    }
  }

  Future<bool> clearAll() async {
    try {
      await _ref.read(vendorApiClientProvider).clearAllNotifications();

      _safeUpdate(
        () => state = state.copyWith(notifications: const [], clearError: true),
      );
      return true;
    } catch (error) {
      _safeUpdate(() => state = state.copyWith(errorMessage: error.toString()));
      return false;
    }
  }

  void markReadLocally(String notificationId) {
    _safeUpdate(
      () => state = state.copyWith(
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
      ),
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
