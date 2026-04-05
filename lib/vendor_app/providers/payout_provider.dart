import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ledger_models.dart';
import 'auth_provider.dart';

class PayoutState {
  const PayoutState({
    this.isLoading = false,
    this.payouts = const [],
    this.errorMessage,
  });

  final bool isLoading;
  final List<VendorPayout> payouts;
  final String? errorMessage;

  PayoutState copyWith({
    bool? isLoading,
    List<VendorPayout>? payouts,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PayoutState(
      isLoading: isLoading ?? this.isLoading,
      payouts: payouts ?? this.payouts,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
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
}

final payoutProvider = StateNotifierProvider<PayoutController, PayoutState>(
  (ref) => PayoutController(ref),
);
