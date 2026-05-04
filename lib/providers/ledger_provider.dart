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

class LedgerController extends Notifier<LedgerState> {
  @override
  LedgerState build() {
    // Auto-load ledger when provider is first created
    Future.microtask(() => loadLedger());
    return const LedgerState();
  }

  Future<void> loadLedger({bool silent = false}) async {
    if (!ref.read(authProvider).isAuthenticated) {
      return;
    }

    // Prevent concurrent fetches by checking isLoading
    if (state.isLoading) {
      return;
    }

    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final ledger = await ref
          .read(vendorApiClientProvider)
          .getLedger()
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Request timed out after 15 seconds');
            },
          );
      state = state.copyWith(
        isLoading: false,
        ledger: ledger,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }
}

final ledgerProvider = NotifierProvider<LedgerController, LedgerState>(
  LedgerController.new,
);
