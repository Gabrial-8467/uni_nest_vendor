import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order_models.dart';
import 'auth_provider.dart';
import 'ledger_provider.dart';
import 'payout_provider.dart';

class OrderState {
  const OrderState({
    this.isLoading = false,
    this.orders = const [],
    this.errorMessage,
    this.lastUpdatedAt,
    this.activeOrderIds = const <String>{},
  });

  final bool isLoading;
  final List<VendorOrder> orders;
  final String? errorMessage;
  final DateTime? lastUpdatedAt;
  final Set<String> activeOrderIds;

  OrderState copyWith({
    bool? isLoading,
    List<VendorOrder>? orders,
    String? errorMessage,
    bool clearError = false,
    DateTime? lastUpdatedAt,
    Set<String>? activeOrderIds,
  }) {
    return OrderState(
      isLoading: isLoading ?? this.isLoading,
      orders: orders ?? this.orders,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      activeOrderIds: activeOrderIds ?? this.activeOrderIds,
    );
  }
}

class OrderController extends StateNotifier<OrderState> {
  OrderController(this._ref) : super(const OrderState());

  final Ref _ref;
  Timer? _pollingTimer;
  bool _isFetching = false;
  static const Duration _pollingInterval = Duration(seconds: 45);
  static const Duration _minimumRefreshGap = Duration(seconds: 15);

  Future<void> loadOrders({bool silent = false, bool force = false}) async {
    if (!_ref.read(authProvider).isAuthenticated) {
      state = const OrderState();
      return;
    }

    if (_isFetching) {
      return;
    }

    if (!force && state.lastUpdatedAt != null) {
      final elapsed = DateTime.now().difference(state.lastUpdatedAt!);
      if (elapsed < _minimumRefreshGap) {
        return;
      }
    }

    _isFetching = true;

    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final orders = await _ref.read(vendorApiClientProvider).getVendorOrders();
      state = state.copyWith(
        isLoading: false,
        orders: orders,
        lastUpdatedAt: DateTime.now(),
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    } finally {
      _isFetching = false;
    }
  }

  void startPolling() {
    _pollingTimer ??= Timer.periodic(
      _pollingInterval,
      (_) => loadOrders(silent: true),
    );
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<bool> advanceOrder(VendorOrder order) async {
    final nextStatus = order.nextStatus;
    if (nextStatus == null) {
      return false;
    }
    return updateOrderStatus(orderId: order.id, status: nextStatus);
  }

  Future<bool> updateOrderStatus({
    required String orderId,
    required String status,
    String? note,
  }) async {
    return _runOrderAction(
      orderId,
      () => _ref
          .read(vendorApiClientProvider)
          .updateOrderStatus(orderId: orderId, status: status, note: note),
    );
  }

  Future<VendorOrder?> fetchOrderById(String orderId) async {
    if (!_ref.read(authProvider).isAuthenticated) {
      return null;
    }

    try {
      final order = await _ref
          .read(vendorApiClientProvider)
          .getOrderById(orderId);
      final updatedOrders = [
        for (final existing in state.orders)
          if (existing.id == order.id) order else existing,
        if (!state.orders.any((existing) => existing.id == order.id)) order,
      ];
      state = state.copyWith(
        orders: updatedOrders,
        lastUpdatedAt: DateTime.now(),
        clearError: true,
      );
      return order;
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
      return null;
    }
  }

  Future<bool> rejectOrder({
    required String orderId,
    required String reason,
  }) async {
    return _runOrderAction(
      orderId,
      () => _ref
          .read(vendorApiClientProvider)
          .rejectOrder(orderId: orderId, reason: reason),
    );
  }

  Future<bool> verifyDeliveryOtp({
    required String orderId,
    required String otp,
  }) async {
    return _runOrderAction(
      orderId,
      () => _ref
          .read(vendorApiClientProvider)
          .verifyDeliveryOtp(orderId: orderId, otp: otp),
    );
  }

  Future<bool> _runOrderAction(
    String orderId,
    Future<VendorOrder> Function() action,
  ) async {
    final nextActive = {...state.activeOrderIds, orderId};
    state = state.copyWith(activeOrderIds: nextActive, clearError: true);
    try {
      final updatedOrder = await action();
      // Match by both id and orderNumber since backend might return different formats
      final updatedOrders = [
        for (final order in state.orders)
          if (order.id == orderId || order.orderNumber == orderId)
            updatedOrder
          else
            order,
      ];
      // If order wasn't found in existing list, add it
      final orderExists = state.orders.any(
        (o) => o.id == orderId || o.orderNumber == orderId,
      );
      final finalOrders = orderExists
          ? updatedOrders
          : [...updatedOrders, updatedOrder];
      nextActive.remove(orderId);
      state = state.copyWith(
        orders: finalOrders,
        activeOrderIds: nextActive,
        lastUpdatedAt: DateTime.now(),
      );
      _ref.read(ledgerProvider.notifier).loadLedger(silent: true);
      _ref.read(payoutProvider.notifier).loadPayouts(silent: true);
      return true;
    } catch (error) {
      nextActive.remove(orderId);
      final errorMsg = error.toString();
      debugPrint('Order action failed for order $orderId: $errorMsg');
      state = state.copyWith(
        activeOrderIds: nextActive,
        errorMessage: errorMsg,
      );
      return false;
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}

final orderProvider = StateNotifierProvider<OrderController, OrderState>(
  (ref) => OrderController(ref),
);

final activeOrdersProvider = Provider<List<VendorOrder>>((ref) {
  final orders = ref.watch(orderProvider).orders;
  return orders
      .where(
        (order) => [
          'pending',
          'confirmed',
          'preparing',
          'ready',
          'out_for_delivery',
        ].contains(order.status),
      )
      .toList();
});

final completedOrdersProvider = Provider<List<VendorOrder>>((ref) {
  final orders = ref.watch(orderProvider).orders;
  return orders.where((order) => order.status == 'delivered').toList();
});

final cancelledOrdersProvider = Provider<List<VendorOrder>>((ref) {
  final orders = ref.watch(orderProvider).orders;
  return orders
      .where(
        (order) => order.status == 'cancelled' || order.status == 'refunded',
      )
      .toList();
});
