import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

// =========================== SHARED HELPERS ===========================

class _Converters {
  static double toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int toInt(dynamic value) =>
      (value is num) ? value.toInt() : (int.tryParse(value.toString()) ?? 0);
}

// =========================== OVERVIEW DATA ===========================

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
      totalOrders: _Converters.toInt(json['totalOrders']),
      totalRevenue: _Converters.toDouble(json['totalRevenue']),
      averageOrderValue: _Converters.toDouble(json['averageOrderValue']),
      deliveredOrders: _Converters.toInt(json['deliveredOrders']),
      cancelledOrders: _Converters.toInt(json['cancelledOrders']),
      pendingOrders: _Converters.toInt(json['pendingOrders']),
      topProducts: (json['topProducts'] as List? ?? [])
          .map((p) => TopProduct.fromJson(p))
          .toList(),
    );
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
      totalOrders: _Converters.toInt(json['totalOrders']),
      totalQuantity: _Converters.toInt(json['totalQuantity']),
      totalRevenue: _Converters.toDouble(json['totalRevenue']),
    );
  }
}

// =========================== PRODUCTS DATA ===========================

class ProductStats {
  final int totalProducts;
  final int activeProducts;
  final int pendingProducts;
  final int rejectedProducts;
  final Map<String, dynamic> statusBreakdown;

  ProductStats({
    required this.totalProducts,
    required this.activeProducts,
    required this.pendingProducts,
    required this.rejectedProducts,
    required this.statusBreakdown,
  });

  factory ProductStats.fromJson(Map<String, dynamic> json) {
    return ProductStats(
      totalProducts: _Converters.toInt(json['totalProducts']),
      activeProducts: _Converters.toInt(json['activeProducts']),
      pendingProducts: _Converters.toInt(json['pendingProducts']),
      rejectedProducts: _Converters.toInt(json['rejectedProducts']),
      statusBreakdown:
          (json['statusBreakdown'] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }
}

class CategoryBreakdown {
  final String category;
  final double totalRevenue;
  final int totalQuantity;

  CategoryBreakdown({
    required this.category,
    required this.totalRevenue,
    required this.totalQuantity,
  });

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdown(
      category: json['category']?.toString() ?? 'Uncategorized',
      totalRevenue: _Converters.toDouble(json['totalRevenue']),
      totalQuantity: _Converters.toInt(json['totalQuantity']),
    );
  }
}

class ProductAnalyticsData {
  final String period;
  final ProductStats productStats;
  final List<TopProduct> topProducts;
  final List<CategoryBreakdown> categoryBreakdown;

  ProductAnalyticsData({
    required this.period,
    required this.productStats,
    required this.topProducts,
    required this.categoryBreakdown,
  });

  factory ProductAnalyticsData.fromJson(Map<String, dynamic> json) {
    return ProductAnalyticsData(
      period: json['period'] ?? 'lifetime',
      productStats: ProductStats.fromJson(json['productStats'] ?? {}),
      topProducts: (json['topProducts'] as List? ?? [])
          .map((p) => TopProduct.fromJson(p))
          .toList(),
      categoryBreakdown: (json['categoryBreakdown'] as List? ?? [])
          .map((c) => CategoryBreakdown.fromJson(c))
          .toList(),
    );
  }
}

// =========================== REVENUE DATA ===========================

class RevenueTrendPoint {
  final Map<String, dynamic> period;
  final double revenue;
  final int orders;

  RevenueTrendPoint({
    required this.period,
    required this.revenue,
    required this.orders,
  });

  factory RevenueTrendPoint.fromJson(Map<String, dynamic> json) {
    return RevenueTrendPoint(
      period: (json['period'] as Map?)?.cast<String, dynamic>() ?? {},
      revenue: _Converters.toDouble(json['revenue']),
      orders: _Converters.toInt(json['orders']),
    );
  }
}

class RevenueSummary {
  final double totalRevenue;
  final int totalOrders;
  final double averageOrderValue;

  RevenueSummary({
    required this.totalRevenue,
    required this.totalOrders,
    required this.averageOrderValue,
  });

  factory RevenueSummary.fromJson(Map<String, dynamic> json) {
    return RevenueSummary(
      totalRevenue: _Converters.toDouble(json['totalRevenue']),
      totalOrders: _Converters.toInt(json['totalOrders']),
      averageOrderValue: _Converters.toDouble(json['averageOrderValue']),
    );
  }
}

class RevenueAnalyticsData {
  final String period;
  final RevenueSummary summary;
  final List<RevenueTrendPoint> trend;

  RevenueAnalyticsData({
    required this.period,
    required this.summary,
    required this.trend,
  });

  factory RevenueAnalyticsData.fromJson(Map<String, dynamic> json) {
    return RevenueAnalyticsData(
      period: json['period'] ?? 'lifetime',
      summary: RevenueSummary.fromJson(json['summary'] ?? {}),
      trend: (json['trend'] as List? ?? [])
          .map((t) => RevenueTrendPoint.fromJson(t))
          .toList(),
    );
  }
}

// =========================== ORDERS DATA ===========================

class DailyTrendPoint {
  final Map<String, dynamic> date;
  final int orders;
  final double revenue;

  DailyTrendPoint({
    required this.date,
    required this.orders,
    required this.revenue,
  });

  factory DailyTrendPoint.fromJson(Map<String, dynamic> json) {
    return DailyTrendPoint(
      date: (json['date'] as Map?)?.cast<String, dynamic>() ?? {},
      orders: _Converters.toInt(json['orders']),
      revenue: _Converters.toDouble(json['revenue']),
    );
  }
}

class PaymentMethodStat {
  final String method;
  final int orders;
  final double revenue;

  PaymentMethodStat({
    required this.method,
    required this.orders,
    required this.revenue,
  });

  factory PaymentMethodStat.fromJson(Map<String, dynamic> json) {
    return PaymentMethodStat(
      method: json['method']?.toString() ?? 'unknown',
      orders: _Converters.toInt(json['orders']),
      revenue: _Converters.toDouble(json['revenue']),
    );
  }
}

class OrderAnalyticsData {
  final String period;
  final int totalOrders;
  final Map<String, dynamic> statusBreakdown;
  final List<DailyTrendPoint> dailyTrend;
  final List<PaymentMethodStat> paymentMethods;

  OrderAnalyticsData({
    required this.period,
    required this.totalOrders,
    required this.statusBreakdown,
    required this.dailyTrend,
    required this.paymentMethods,
  });

  factory OrderAnalyticsData.fromJson(Map<String, dynamic> json) {
    return OrderAnalyticsData(
      period: json['period'] ?? 'lifetime',
      totalOrders: _Converters.toInt(json['totalOrders']),
      statusBreakdown:
          (json['statusBreakdown'] as Map?)?.cast<String, dynamic>() ?? {},
      dailyTrend: (json['dailyTrend'] as List? ?? [])
          .map((d) => DailyTrendPoint.fromJson(d))
          .toList(),
      paymentMethods: (json['paymentMethods'] as List? ?? [])
          .map((p) => PaymentMethodStat.fromJson(p))
          .toList(),
    );
  }
}

// =========================== STATE & CONTROLLER ===========================

class AnalyticsTab {
  static const String overview = 'overview';
  static const String products = 'products';
  static const String revenue = 'revenue';
  static const String orders = 'orders';
}

class AnalyticsState {
  const AnalyticsState({
    this.isLoading = false,
    this.data,
    this.productData,
    this.revenueData,
    this.orderData,
    this.errorMessage,
    this.period = '7d',
    this.activeTab = AnalyticsTab.overview,
  });

  final bool isLoading;
  final VendorAnalyticsData? data;
  final ProductAnalyticsData? productData;
  final RevenueAnalyticsData? revenueData;
  final OrderAnalyticsData? orderData;
  final String? errorMessage;
  final String period;
  final String activeTab;

  AnalyticsState copyWith({
    bool? isLoading,
    VendorAnalyticsData? data,
    ProductAnalyticsData? productData,
    RevenueAnalyticsData? revenueData,
    OrderAnalyticsData? orderData,
    String? errorMessage,
    String? period,
    String? activeTab,
    bool clearError = false,
  }) {
    return AnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      productData: productData ?? this.productData,
      revenueData: revenueData ?? this.revenueData,
      orderData: orderData ?? this.orderData,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      period: period ?? this.period,
      activeTab: activeTab ?? this.activeTab,
    );
  }
}

class AnalyticsController extends StateNotifier<AnalyticsState> {
  AnalyticsController(this._ref) : super(const AnalyticsState());

  final Ref _ref;
  bool _isFetching = false;

  String _lastLoadedPeriod = '';

  Future<void> _loadOverview(String targetPeriod) async {
    try {
      final client = _ref.read(vendorApiClientProvider);
      final data = await client.getAnalytics(period: targetPeriod);
      state = state.copyWith(
        isLoading: false,
        data: VendorAnalyticsData.fromJson(data),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Overview failed: ${_shortError(e)}',
      );
    }
  }

  Future<void> _loadProducts(String targetPeriod) async {
    try {
      final client = _ref.read(vendorApiClientProvider);
      final data = await client.getProductAnalytics(period: targetPeriod);
      state = state.copyWith(
        isLoading: false,
        productData: ProductAnalyticsData.fromJson(data),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Products failed: ${_shortError(e)}',
      );
    }
  }

  Future<void> _loadRevenue(String targetPeriod) async {
    try {
      final client = _ref.read(vendorApiClientProvider);
      final data = await client.getRevenueAnalytics(period: targetPeriod);
      state = state.copyWith(
        isLoading: false,
        revenueData: RevenueAnalyticsData.fromJson(data),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Revenue failed: ${_shortError(e)}',
      );
    }
  }

  Future<void> _loadOrders(String targetPeriod) async {
    try {
      final client = _ref.read(vendorApiClientProvider);
      final data = await client.getOrderAnalytics(period: targetPeriod);
      state = state.copyWith(
        isLoading: false,
        orderData: OrderAnalyticsData.fromJson(data),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Orders failed: ${_shortError(e)}',
      );
    }
  }

  static String _shortError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('404')) return 'Not found';
    if (msg.contains('401')) return 'Unauthorized';
    if (msg.contains('403')) return 'Forbidden';
    if (msg.contains('timeout') || msg.contains('Timeout')) return 'Timeout';
    if (msg.contains('SocketException') || msg.contains('Connection')) {
      return 'No connection';
    }
    return msg.length > 60 ? '${msg.substring(0, 60)}...' : msg;
  }

  Future<void> _loadForTab(String tab, String targetPeriod) async {
    if (_isFetching) return;
    _isFetching = true;
    state = state.copyWith(isLoading: true, clearError: true);

    switch (tab) {
      case AnalyticsTab.overview:
        await _loadOverview(targetPeriod);
        break;
      case AnalyticsTab.products:
        await _loadProducts(targetPeriod);
        break;
      case AnalyticsTab.revenue:
        await _loadRevenue(targetPeriod);
        break;
      case AnalyticsTab.orders:
        await _loadOrders(targetPeriod);
        break;
    }

    _lastLoadedPeriod = targetPeriod;
    _isFetching = false;
  }

  void loadInitial() {
    final targetPeriod = state.period;
    if (_lastLoadedPeriod != targetPeriod || state.data == null) {
      _loadForTab(AnalyticsTab.overview, targetPeriod);
    }
  }

  void setPeriod(String period) {
    if (state.period != period) {
      state = state.copyWith(period: period);
      _loadForTab(state.activeTab, period);
    }
  }

  void setTab(String tab) {
    if (state.activeTab != tab) {
      state = state.copyWith(activeTab: tab);
      final targetPeriod = state.period;
      final needsLoad = switch (tab) {
        AnalyticsTab.overview =>
          state.data == null || _lastLoadedPeriod != targetPeriod,
        AnalyticsTab.products =>
          state.productData == null || _lastLoadedPeriod != targetPeriod,
        AnalyticsTab.revenue =>
          state.revenueData == null || _lastLoadedPeriod != targetPeriod,
        AnalyticsTab.orders =>
          state.orderData == null || _lastLoadedPeriod != targetPeriod,
        _ => true,
      };
      if (needsLoad) {
        _loadForTab(tab, targetPeriod);
      }
    }
  }

  void refreshCurrentTab() {
    _loadForTab(state.activeTab, state.period);
  }
}

final analyticsProvider =
    StateNotifierProvider<AnalyticsController, AnalyticsState>((ref) {
      return AnalyticsController(ref);
    });
