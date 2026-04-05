import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';
import '../core/vendor_formatters.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.compact = false,
  });

  final String label;
  final Color color;
  final bool compact;

  factory StatusChip.order(String status, {bool compact = false}) {
    return StatusChip(
      label: humanizeEnum(status),
      color: switch (status) {
        'confirmed' => AppTheme.info,
        'preparing' => const Color(0xFF8E44AD),
        'ready' => AppTheme.success,
        'out_for_delivery' => const Color(0xFF3949AB),
        'delivered' => const Color(0xFF00897B),
        'cancelled' || 'refunded' => AppTheme.error,
        'payment_pending' => AppTheme.warning,
        _ => Colors.grey,
      },
      compact: compact,
    );
  }

  factory StatusChip.payment(String paymentStatus, {bool compact = false}) {
    return StatusChip(
      label: humanizeEnum(paymentStatus),
      color: switch (paymentStatus) {
        'paid' || 'cod_collected' => AppTheme.success,
        'cod_pending' => AppTheme.warning,
        'payment_pending' || 'pending' => Colors.orange,
        'refund_pending' => Colors.deepOrange,
        'refunded' => Colors.redAccent,
        _ => Colors.grey,
      },
      compact: compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
