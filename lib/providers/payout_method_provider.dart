import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_models.dart';
import 'auth_provider.dart';

class PayoutMethodState {
  const PayoutMethodState({
    this.method,
    this.isLoading = false,
    this.isUpdating = false,
    this.errorMessage,
    this.updateErrorMessage,
  });

  final PayoutMethod? method;
  final bool isLoading;
  final bool isUpdating;
  final String? errorMessage;
  final String? updateErrorMessage;

  bool get hasMethod => method != null;
  bool get isVerified => method?.isVerified ?? false;

  PayoutMethodState copyWith({
    PayoutMethod? method,
    bool? isLoading,
    bool? isUpdating,
    String? errorMessage,
    String? updateErrorMessage,
    bool clearError = false,
    bool clearUpdateError = false,
  }) {
    return PayoutMethodState(
      method: method ?? this.method,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      updateErrorMessage: clearUpdateError
          ? null
          : updateErrorMessage ?? this.updateErrorMessage,
    );
  }
}

class PayoutMethodController extends StateNotifier<PayoutMethodState> {
  PayoutMethodController(this._ref) : super(const PayoutMethodState()) {
    loadPayoutMethod();
  }

  final Ref _ref;

  Future<void> loadPayoutMethod() async {
    final auth = _ref.read(authProvider);
    if (!auth.isAuthenticated) {
      state = state.copyWith(
        errorMessage: 'Not authenticated',
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final method = await _ref.read(vendorApiClientProvider).getPayoutMethod();

      state = state.copyWith(
        isLoading: false,
        method: method,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  Future<bool> updatePayoutMethod(PayoutMethod method) async {
    final auth = _ref.read(authProvider);
    if (!auth.isAuthenticated) {
      state = state.copyWith(
        updateErrorMessage: 'Not authenticated. Please login again.',
      );
      return false;
    }

    state = state.copyWith(isUpdating: true, clearUpdateError: true);

    try {
      final updatedMethod = await _ref
          .read(vendorApiClientProvider)
          .updatePayoutMethod(method);

      state = state.copyWith(
        isUpdating: false,
        method: updatedMethod,
        clearUpdateError: true,
      );

      // Refresh profile to sync payout method with auth session
      await _ref.read(authProvider.notifier).refreshProfile();

      return true;
    } catch (error) {
      state = state.copyWith(
        isUpdating: false,
        updateErrorMessage: error.toString(),
      );
      return false;
    }
  }

  /// Refresh method from profile (useful when profile is updated elsewhere)
  void syncFromProfile(PayoutMethod? method) {
    if (method != null && method != state.method) {
      state = state.copyWith(method: method);
    }
  }
}

final payoutMethodProvider =
    StateNotifierProvider<PayoutMethodController, PayoutMethodState>((ref) {
      return PayoutMethodController(ref);
    });
