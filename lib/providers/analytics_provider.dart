import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

class AnalyticsState {
  const AnalyticsState({
    this.isLoading = false,
    this.data,
    this.errorMessage,
    this.period = 'daily',
  });

  final bool isLoading;
  final VendorAnalyticsData? data;
  final String? errorMessage;
  final String period;

  AnalyticsState copyWith({
    bool? isLoading,
    VendorAnalyticsData? data,
    String? errorMessage,
    String? period,
    bool clearError = false,
  }) {
    return AnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      period: period ?? this.period,
    );
  }
}

class VendorAnalyticsData {
  final String period;
  final int totalOrders;
  final double totalRevenue;
  final double averageOrderValue;
  final int deliveredOrders;
  final int cancelledOrders;
  final int pendingOrders;
  final List<TopProduct> topProducts;

  VendorAnalyticsData({
    required this.period,
    required this.totalOrders,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.pendingOrders,
    required this.topProducts,
  });

  factory VendorAnalyticsData.fromJson(Map<String, dynamic> json) {
    return VendorAnalyticsData(
      period: json['period'] ?? 'lifetime',
      totalOrders: json['totalOrders'] ?? 0,
      totalRevenue: _toDouble(json['totalRevenue']),
      averageOrderValue: _toDouble(json['averageOrderValue']),
      deliveredOrders: json['deliveredOrders'] ?? 0,
      cancelledOrders: json['cancelledOrders'] ?? 0,
      pendingOrders: json['pendingOrders'] ?? 0,
      topProducts: (json['topProducts'] as List? ?? [])
          .map((p) => TopProduct.fromJson(p))
          .toList(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class TopProduct {
  final String productId;
  final String name;
  final int totalOrders;
  final int totalQuantity;
  final double totalRevenue;

  TopProduct({
    required this.productId,
    required this.name,
    required this.totalOrders,
    required this.totalQuantity,
    required this.totalRevenue,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      productId: json['productId'] ?? '',
      name: json['name'] ?? 'Unknown',
      totalOrders: json['totalOrders'] ?? 0,
      totalQuantity: json['totalQuantity'] ?? 0,
      totalRevenue: VendorAnalyticsData._toDouble(json['totalRevenue']),
    );
  }
}

class AnalyticsController extends StateNotifier<AnalyticsState> {
  AnalyticsController(this._ref) : super(const AnalyticsState());

  final Ref _ref;
  bool _isFetching = false;

  Future<void> loadAnalytics({String? period}) async {
    if (_isFetching) return;

    final targetPeriod = period ?? state.period;

    _isFetching = true;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final client = _ref.read(vendorApiClientProvider);
      final data = await client.getAnalytics(period: targetPeriod);

      state = state.copyWith(
        isLoading: false,
        data: VendorAnalyticsData.fromJson(data),
        period: targetPeriod,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load analytics: $e',
      );
    } finally {
      _isFetching = false;
    }
  }

  void setPeriod(String period) {
    if (state.period != period) {
      loadAnalytics(period: period);
    }
  }
}

final analyticsProvider =
    StateNotifierProvider<AnalyticsController, AnalyticsState>((ref) {
      return AnalyticsController(ref);
    });
