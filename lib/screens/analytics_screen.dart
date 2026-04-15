import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../utils/app_theme.dart';
import '../providers/order_provider.dart';

// =============================================================================
// ANALYTICS SCREEN
// =============================================================================
//
// Purpose: Comprehensive analytics and reporting for vendor performance
// Features:
// - Revenue analytics with charts
// - Order trends and patterns
// - Product performance metrics
// - Customer insights
// - Time-based filtering (daily, weekly, monthly)
// - Export functionality for reports
//
// Sections:
// 1. Analytics Header - Period selection and summary stats
// 2. Revenue Analytics - Revenue charts and trends
// 3. Order Analytics - Order volume and status breakdown
// 4. Product Analytics - Best/worst performing products
// 5. Customer Analytics - Customer behavior insights
// 6. Export Options - Report generation and download
// =============================================================================

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key, this.showPageHeader = true});

  final bool showPageHeader;

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = '7d';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load orders when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderProvider.notifier).loadOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper methods to calculate analytics from order data
  double get _totalRevenue {
    final orders = ref.read(orderProvider).orders;
    return orders.fold(
      0.0,
      (sum, order) => sum + order.pricing.finalPayableAmount,
    );
  }

  double get _averageOrderValue {
    final orders = ref.read(orderProvider).orders;
    if (orders.isEmpty) return 0.0;
    return _totalRevenue / orders.length;
  }

  int get _pendingOrdersCount {
    final orders = ref.read(orderProvider).orders;
    return orders
        .where((o) => ['pending', 'confirmed'].contains(o.status))
        .length;
  }

  List<double> get _dailyRevenueLast7Days {
    final orders = ref.read(orderProvider).orders;
    final now = DateTime.now();
    final List<double> dailyRevenue = List.filled(7, 0.0);

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final dayOrders = orders.where((order) {
        return order.createdAt.isAfter(dayStart) &&
            order.createdAt.isBefore(dayEnd);
      }).toList();

      final dayRevenue = dayOrders.fold(
        0.0,
        (sum, order) => sum + order.pricing.finalPayableAmount,
      );
      dailyRevenue[6 - i] = dayRevenue;
    }

    return dailyRevenue;
  }

  // Helper method to calculate grid interval for Y-axis
  double _calculateGridInterval() {
    final dailyRevenue = _dailyRevenueLast7Days;
    if (dailyRevenue.isEmpty) return 50.0;

    final maxValue = dailyRevenue.reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) return 50.0;

    // Calculate a nice interval (aim for 4-5 grid lines)
    final roughInterval = maxValue / 4;
    final magnitude = math
        .pow(10, (math.log(roughInterval) / math.log(10)).floor())
        .toDouble();
    final normalizedInterval = roughInterval / magnitude;

    double interval;
    if (normalizedInterval <= 1) {
      interval = magnitude;
    } else if (normalizedInterval <= 2) {
      interval = (2 * magnitude).toDouble();
    } else if (normalizedInterval <= 5) {
      interval = (5 * magnitude).toDouble();
    } else {
      interval = (10 * magnitude).toDouble();
    }

    return interval;
  }

  // Helper method to get revenue trend percentage
  double _getRevenueTrend() {
    final dailyRevenue = _dailyRevenueLast7Days;
    if (dailyRevenue.length < 2) return 0.0;

    final firstHalf = dailyRevenue.take(3).reduce((a, b) => a + b);
    final secondHalf = dailyRevenue.skip(4).take(3).reduce((a, b) => a + b);

    if (firstHalf == 0) return 0.0;
    return ((secondHalf - firstHalf) / firstHalf) * 100;
  }

  // Helper method to get average revenue
  double get _averageRevenue {
    final dailyRevenue = _dailyRevenueLast7Days;
    if (dailyRevenue.isEmpty) return 0.0;
    return dailyRevenue.reduce((a, b) => a + b) / dailyRevenue.length;
  }

  // Helper method to format revenue values
  String _formatRevenue(double value) {
    if (value >= 1000) {
      return '₹${(value / 1000).toStringAsFixed(1)}k';
    }
    return '₹${value.toInt()}';
  }

  @override
  Widget build(BuildContext context) {
    // final orderState = ref.watch(orderProvider); // Not used currently

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        automaticallyImplyLeading: widget.showPageHeader,
        toolbarHeight: widget.showPageHeader ? kToolbarHeight : 0,
        leading: widget.showPageHeader
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: widget.showPageHeader
            ? const Text(
                'Analytics',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
              )
            : null,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Revenue'),
            Tab(text: 'Orders'),
            Tab(text: 'Products'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Period Selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Period:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['24h', '7d', '30d', '3m', '6m', '1y'].map((
                        period,
                      ) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(period),
                            selected: _selectedPeriod == period,
                            onSelected: (selected) {
                              setState(() {
                                _selectedPeriod = selected ? period : '7d';
                              });
                            },
                            backgroundColor: Colors.white,
                            selectedColor: AppTheme.primary,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Analytics Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRevenueAnalytics(),
                _buildOrdersAnalytics(),
                _buildProductsAnalytics(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueAnalytics() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Revenue Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Revenue',
                  '₹${_totalRevenue.toStringAsFixed(2)}',
                  Icons.trending_up,
                  Colors.green,
                  '+12.5%', // Placeholder growth
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Average Order Value',
                  '₹${_averageOrderValue.toStringAsFixed(2)}',
                  Icons.receipt_long,
                  Colors.blue,
                  '+8.2%', // Placeholder growth
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Revenue Chart
          _buildRevenueChart(),
          const SizedBox(height: 16),
          // Revenue by Category
          _buildRevenueByCategory(),
        ],
      ),
    );
  }

  Widget _buildOrdersAnalytics() {
    final orders = ref.read(orderProvider).orders;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Orders Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Orders',
                  orders.length.toString(),
                  Icons.shopping_cart,
                  Colors.orange,
                  '+15.3%', // Placeholder growth
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Pending Orders',
                  _pendingOrdersCount.toString(),
                  Icons.pending_actions,
                  Colors.red,
                  'Need action',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Orders by Status
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${orders.length} Total Orders',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...orders.take(10).map((order) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              order.status,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getStatusIcon(order.status),
                            color: _getStatusColor(order.status),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order #${order.id}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${order.customerName} • ${order.customerPhone}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${order.pricing.finalPayableAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(order.status),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                order.status.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                if (orders.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No orders yet',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Orders will appear here once customers start placing orders',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsAnalytics() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Products Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Products',
                  '0', // Placeholder - no products provider yet
                  Icons.inventory,
                  Colors.purple,
                  '+0 new', // Placeholder
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Active Products',
                  '0', // Placeholder - no products provider yet
                  Icons.check_circle,
                  Colors.teal,
                  '0% active', // Placeholder
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Products List
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.inventory_outlined,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '0 Products', // Placeholder
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Placeholder for products
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Product analytics coming soon',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Product data will be available once the products provider is implemented',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                subtitle,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    final dailyRevenue = _dailyRevenueLast7Days;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue Trend (Last 7 Days)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 280,
            child: Column(
              children: [
                // Chart legend and stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₹${_totalRevenue.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Total Revenue',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getRevenueTrend() > 0
                            ? Colors.green[100]
                            : Colors.red[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getRevenueTrend() > 0
                              ? Colors.green
                              : Colors.red,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getRevenueTrend() > 0
                                ? Icons.trending_up
                                : Icons.trending_down,
                            size: 16,
                            color: _getRevenueTrend() > 0
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_getRevenueTrend() > 0 ? '+' : ''}${_getRevenueTrend().toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getRevenueTrend() > 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Enhanced chart
                Expanded(
                  child: LineChart(
                    LineChartData(
                      // Enhanced grid configuration
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _calculateGridInterval(),
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[200]!,
                            strokeWidth: 1,
                            dashArray: [3, 3],
                          );
                        },
                      ),

                      // Enhanced titles configuration
                      titlesData: FlTitlesData(
                        show: true,
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: _calculateGridInterval(),
                            reservedSize: 45,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  _formatRevenue(value),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 35,
                            getTitlesWidget: (value, meta) {
                              final dayNames = [
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                                'Sun',
                              ];
                              final index = value.toInt() - 1;
                              if (index >= 0 && index < dayNames.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    dayNames[index],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),

                      // Enhanced border configuration
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                          left: BorderSide(color: Colors.grey[300]!, width: 1),
                          right: const BorderSide(color: Colors.transparent),
                          top: const BorderSide(color: Colors.transparent),
                        ),
                      ),

                      // Enhanced line data with multiple elements
                      lineBarsData: [
                        // Main revenue line
                        LineChartBarData(
                          spots: List.generate(7, (index) {
                            return FlSpot(
                              (index + 1).toDouble(),
                              dailyRevenue[index],
                            );
                          }),
                          isCurved: true,
                          color: AppTheme.primary,
                          barWidth: 4,
                          isStrokeCapRound: true,

                          // Enhanced dots with animation
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 5,
                                color: AppTheme.primary,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),

                          // Enhanced gradient fill
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primary.withValues(alpha: 0.4),
                                AppTheme.primary.withValues(alpha: 0.2),
                                AppTheme.primary.withValues(alpha: 0.05),
                                Colors.transparent,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.0, 0.3, 0.6, 1.0],
                            ),
                          ),

                          // Shadow effect
                          shadow: Shadow(
                            blurRadius: 12,
                            color: AppTheme.primary.withValues(alpha: 0.4),
                            offset: const Offset(0, 4),
                          ),
                        ),

                        // Average line (subtle)
                        LineChartBarData(
                          spots: List.generate(7, (index) {
                            return FlSpot(
                              (index + 1).toDouble(),
                              _averageRevenue,
                            );
                          }),
                          isCurved: false,
                          color: Colors.grey[400]!,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dashArray: [5, 5],
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],

                      // Enhanced axis configuration
                      minX: 1,
                      maxX: 7,
                      minY: 0,
                      maxY: dailyRevenue.isNotEmpty
                          ? (dailyRevenue.reduce((a, b) => a > b ? a : b) * 1.3)
                                .ceilToDouble()
                          : 100,

                      // Enhanced touch interactions
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: Colors.black87,
                          tooltipPadding: const EdgeInsets.all(12),
                          tooltipMargin: 8,
                          getTooltipItems: (spots) {
                            return spots.map((spot) {
                              final dayNames = [
                                'Monday',
                                'Tuesday',
                                'Wednesday',
                                'Thursday',
                                'Friday',
                                'Saturday',
                                'Sunday',
                              ];
                              final index = spot.x.toInt() - 1;
                              final dayName =
                                  index >= 0 && index < dayNames.length
                                  ? dayNames[index]
                                  : 'Day';

                              // Check if this is above or below average
                              final isAboveAverage = spot.y > _averageRevenue;
                              final trendIcon = isAboveAverage ? '📈' : '📉';

                              return LineTooltipItem(
                                '$trendIcon $dayName\n₹${spot.y.toStringAsFixed(2)}\n${isAboveAverage ? 'Above' : 'Below'} avg: ₹${_averageRevenue.toStringAsFixed(2)}',
                                const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }).toList();
                          },
                        ),
                        handleBuiltInTouches: true,
                        touchSpotThreshold: 20,
                      ),

                      // Animation configuration (fl_chart doesn't support animationDuration directly)
                      // The chart will animate automatically when data changes
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueByCategory() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue by Category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          // Placeholder for category chart
          SizedBox(
            height: 150,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.donut_large_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Category analytics coming soon',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'ready':
        return Colors.green;
      case 'out_for_delivery':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'confirmed':
        return Icons.check_circle;
      case 'preparing':
        return Icons.restaurant;
      case 'ready':
        return Icons.done_all;
      case 'out_for_delivery':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.task_alt;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}
