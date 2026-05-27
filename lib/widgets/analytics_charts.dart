import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/analytics_provider.dart';
import '../utils/app_theme.dart';
import '../core/vendor_formatters.dart';

// =========================== ORDER STATUS DONUT ===========================

class OrderStatusDonutChart extends StatelessWidget {
  final int delivered;
  final int pending;
  final int cancelled;

  const OrderStatusDonutChart({
    super.key,
    required this.delivered,
    required this.pending,
    required this.cancelled,
  });

  @override
  Widget build(BuildContext context) {
    final total = delivered + pending + cancelled;
    if (total == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'No order data',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    final sections = <PieChartSectionData>[];
    final legend = <Map<String, dynamic>>[];

    void addSection(String label, int count, Color color) {
      if (count > 0) {
        sections.add(
          PieChartSectionData(
            value: count.toDouble(),
            color: color,
            radius: 45,
            title: '$count',
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textWhite,
            ),
            titlePositionPercentageOffset: 0.55,
          ),
        );
        legend.add({'label': label, 'count': count, 'color': color});
      }
    }

    addSection('Delivered', delivered, AppTheme.success);
    addSection('Pending', pending, AppTheme.warning);
    addSection('Cancelled', cancelled, AppTheme.error);

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 35,
              sections: sections,
              startDegreeOffset: -90,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: legend.map((item) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: item['color'] as Color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${item['label']} (${item['count']})',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

// =========================== REVENUE LINE CHART ===========================

class RevenueLineChart extends StatelessWidget {
  final List<RevenueTrendPoint> trend;

  const RevenueLineChart({super.key, required this.trend});

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'No trend data for this period',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    final maxRevenue = trend
        .map((t) => t.revenue)
        .reduce((a, b) => a > b ? a : b);
    final interval = maxRevenue > 0 ? maxRevenue / 4 : 1.0;

    String buildLabel(int index) {
      final p = trend[index].period;
      final day = p['day'];
      final month = p['month'];
      if (day != null && month != null) {
        return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}';
      }
      if (month != null) {
        final y = p['year']?.toString() ?? '';
        return '${month.toString().padLeft(2, '0')}/${y.substring(y.length > 2 ? y.length - 2 : 0)}';
      }
      return p['year']?.toString() ?? '';
    }

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppTheme.textLight.withValues(alpha: 0.15),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  return Text(
                    formatCompactCurrency(value),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textLight,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 ||
                      index >= trend.length ||
                      index % ((trend.length / 6).ceil().clamp(1, 99)) != 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      buildLabel(index),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textLight,
                      ),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: trend.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value.revenue);
              }).toList(),
              isCurved: true,
              curveSmoothness: 0.3,
              color: AppTheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primary.withValues(alpha: 0.1),
              ),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppTheme.primary,
                    strokeWidth: 2,
                    strokeColor: AppTheme.surface,
                  );
                },
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: AppTheme.darkSurface,
              tooltipRoundedRadius: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    formatCurrency(spot.y),
                    const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textWhite,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          minY: 0,
        ),
      ),
    );
  }
}

// =========================== DAILY ORDERS BAR CHART ===========================

class DailyOrdersBarChart extends StatelessWidget {
  final List<DailyTrendPoint> dailyTrend;

  const DailyOrdersBarChart({super.key, required this.dailyTrend});

  @override
  Widget build(BuildContext context) {
    if (dailyTrend.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'No daily trend data',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    final maxOrders = dailyTrend
        .map((d) => d.orders)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final interval = maxOrders > 0 ? (maxOrders / 4).ceilToDouble() : 1.0;

    String buildLabel(int index) {
      final d = dailyTrend[index].date;
      final day = d['day'];
      final month = d['month'];
      if (day != null && month != null) {
        return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}';
      }
      return '';
    }

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppTheme.textLight.withValues(alpha: 0.15),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textLight,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= dailyTrend.length) {
                    return const SizedBox.shrink();
                  }
                  final step = (dailyTrend.length / 6).ceil().clamp(1, 99);
                  if (index % step != 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      buildLabel(index),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textLight,
                      ),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: dailyTrend.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.orders.toDouble(),
                  color: AppTheme.primary,
                  width: 14,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: AppTheme.darkSurface,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final point = dailyTrend[groupIndex];
                return BarTooltipItem(
                  '${point.orders} orders\n${formatCurrency(point.revenue)}',
                  const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// =========================== TOP PRODUCTS HORIZONTAL BAR ===========================

class TopProductsBarChart extends StatelessWidget {
  final List<TopProduct> products;

  const TopProductsBarChart({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'No product data',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    final maxRevenue = products
        .map((p) => p.totalRevenue)
        .reduce((a, b) => a > b ? a : b);
    final displayProducts = products.take(5).toList();

    return Column(
      children: displayProducts.asMap().entries.map((e) {
        final index = e.key;
        final product = e.value;
        final percent = maxRevenue > 0
            ? (product.totalRevenue / maxRevenue).clamp(0.0, 1.0)
            : 0.0;
        final colors = [
          AppTheme.primary,
          AppTheme.secondary,
          AppTheme.success,
          AppTheme.warning,
          AppTheme.info,
        ];
        final barColor = colors[index % colors.length];

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatCurrency(product.totalRevenue),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percent,
                  backgroundColor: AppTheme.background,
                  color: barColor,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${product.totalQuantity} sold · ${product.totalOrders} orders',
                style: const TextStyle(fontSize: 10, color: AppTheme.textLight),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// =========================== CATEGORY PIE CHART ===========================

class CategoryPieChart extends StatelessWidget {
  final List<CategoryBreakdown> categories;

  const CategoryPieChart({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'No category data',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    final totalRevenue = categories
        .map((c) => c.totalRevenue)
        .reduce((a, b) => a + b);
    final chartColors = [
      AppTheme.primary,
      AppTheme.secondary,
      AppTheme.success,
      AppTheme.warning,
      AppTheme.info,
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
    ];

    final sections = categories.asMap().entries.map((e) {
      final index = e.key;
      final cat = e.value;
      final percent = totalRevenue > 0 ? cat.totalRevenue / totalRevenue : 0;
      return PieChartSectionData(
        value: cat.totalRevenue,
        color: chartColors[index % chartColors.length],
        radius: 50,
        title: percent > 0.05 ? '${(percent * 100).toStringAsFixed(0)}%' : '',
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textWhite,
        ),
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              sections: sections,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: categories.asMap().entries.map((e) {
            final index = e.key;
            final cat = e.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: chartColors[index % chartColors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${cat.category} (${formatCompactCurrency(cat.totalRevenue)})',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

// =========================== ORDER STATUS DONUT (from Map) ===========================

class OrderStatusMapDonutChart extends StatelessWidget {
  final Map<String, dynamic> statusBreakdown;
  final int totalOrders;

  const OrderStatusMapDonutChart({
    super.key,
    required this.statusBreakdown,
    required this.totalOrders,
  });

  @override
  Widget build(BuildContext context) {
    final statusColors = {
      'pending': AppTheme.warning,
      'confirmed': AppTheme.info,
      'preparing': AppTheme.secondary,
      'ready': const Color(0xFF8B5CF6),
      'out_for_delivery': const Color(0xFFF59E0B),
      'delivered': AppTheme.success,
      'cancelled': AppTheme.error,
      'refunded': AppTheme.textLight,
    };

    final entries = statusBreakdown.entries.where((e) {
      final count = e.value is int ? e.value as int : 0;
      return count > 0;
    }).toList();

    if (entries.isEmpty || totalOrders == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'No order data',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    final sections = entries.map((e) {
      final count = e.value is int ? e.value as int : 0;
      final color = statusColors[e.key] ?? AppTheme.textSecondary;
      final percent = totalOrders > 0 ? count / totalOrders : 0.0;
      return PieChartSectionData(
        value: count.toDouble(),
        color: color,
        radius: 45,
        title: percent > 0.08 ? '$count' : '',
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textWhite,
        ),
        titlePositionPercentageOffset: 0.6,
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 35,
              sections: sections,
              startDegreeOffset: -90,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 14,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: entries.map((e) {
            final count = e.value is int ? e.value as int : 0;
            final color = statusColors[e.key] ?? AppTheme.textSecondary;
            final label = e.key
                .toString()
                .split('_')
                .map((w) => w[0].toUpperCase() + w.substring(1))
                .join(' ');
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$label ($count)',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
