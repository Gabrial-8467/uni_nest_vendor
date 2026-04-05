import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ledger_models.dart';
import 'auth_provider.dart';

class LedgerState {
  const LedgerState({this.isLoading = false, this.ledger, this.errorMessage});

  final bool isLoading;
  final VendorLedgerSummary? ledger;
  final String? errorMessage;

  LedgerState copyWith({
    bool? isLoading,
    VendorLedgerSummary? ledger,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LedgerState(
      isLoading: isLoading ?? this.isLoading,
      ledger: ledger ?? this.ledger,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class LedgerController extends StateNotifier<LedgerState> {
  LedgerController(this._ref) : super(const LedgerState());

  final Ref _ref;
  bool _isFetching = false;

  Future<void> loadLedger({bool silent = false}) async {
    if (!_ref.read(authProvider).isAuthenticated) {
      state = const LedgerState();
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
      final ledger = await _ref.read(vendorApiClientProvider).getLedger();
      state = state.copyWith(
        isLoading: false,
        ledger: ledger,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    } finally {
      _isFetching = false;
    }
  }
}

final ledgerProvider = StateNotifierProvider<LedgerController, LedgerState>(
  (ref) => LedgerController(ref),
);
