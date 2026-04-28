import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ledger_models.dart';
import 'auth_provider.dart';

class PayoutState {
  const PayoutState({
    this.isLoading = false,
    this.isRequesting = false,
    this.payouts = const [],
    this.errorMessage,
    this.requestErrorMessage,
    this.lastRequestedPayout,
  });

  final bool isLoading;
  final bool isRequesting;
  final List<VendorPayout> payouts;
  final String? errorMessage;
  final String? requestErrorMessage;
  final VendorPayout? lastRequestedPayout;

  PayoutState copyWith({
    bool? isLoading,
    bool? isRequesting,
    List<VendorPayout>? payouts,
    String? errorMessage,
    String? requestErrorMessage,
    VendorPayout? lastRequestedPayout,
    bool clearError = false,
    bool clearRequestError = false,
  }) {
    return PayoutState(
      isLoading: isLoading ?? this.isLoading,
      isRequesting: isRequesting ?? this.isRequesting,
      payouts: payouts ?? this.payouts,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      requestErrorMessage: clearRequestError
          ? null
          : requestErrorMessage ?? this.requestErrorMessage,
      lastRequestedPayout: lastRequestedPayout ?? this.lastRequestedPayout,
    );
  }
}

class PayoutController extends StateNotifier<PayoutState> {
  PayoutController(this._ref) : super(const PayoutState());

  final Ref _ref;
  bool _isFetching = false;

  Future<void> loadPayouts({bool silent = false}) async {
    if (!_ref.read(authProvider).isAuthenticated) {
      state = const PayoutState();
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
      final payouts = await _ref.read(vendorApiClientProvider).getPayouts();
      state = state.copyWith(
        isLoading: false,
        payouts: payouts,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    } finally {
      _isFetching = false;
    }
  }

  Future<bool> requestPayout({required double amount}) async {
    if (!_ref.read(authProvider).isAuthenticated) {
      state = state.copyWith(
        requestErrorMessage: 'Not authenticated. Please login again.',
      );
      return false;
    }

    state = state.copyWith(isRequesting: true, clearRequestError: true);

    try {
      final payout = await _ref
          .read(vendorApiClientProvider)
          .requestPayout(amount: amount);

      state = state.copyWith(
        isRequesting: false,
        lastRequestedPayout: payout,
        clearRequestError: true,
      );

      await loadPayouts(silent: true);
      return true;
    } catch (error) {
      state = state.copyWith(
        isRequesting: false,
        requestErrorMessage: error.toString(),
      );
      return false;
    }
  }
}

final payoutProvider = StateNotifierProvider<PayoutController, PayoutState>(
  (ref) => PayoutController(ref),
);
