import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import '../core/vendor_formatters.dart';
import '../models/order_models.dart';
import 'status_chip.dart';

class OrderListCard extends StatelessWidget {
  const OrderListCard({super.key, required this.order, this.onTap});

  final VendorOrder order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.receipt_long_outlined,
                          color: AppTheme.primary,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.orderNumber.isEmpty
                                  ? 'Order'
                                  : 'Order #${order.orderNumber}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF2D3436),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${order.customerName} - ${formatCompactDate(order.createdAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusChip.order(order.status, compact: true),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 1,
                    color: Colors.grey.withValues(alpha: 0.08),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusChip.payment(order.paymentStatus, compact: true),
                      StatusChip(
                        label: order.isCod ? 'COD' : 'ONLINE',
                        color: order.isCod ? Colors.deepOrange : AppTheme.info,
                        compact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order.items
                              .map((item) => '${item.quantity}x ${item.name}')
                              .join(', '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: order.isCod
                          ? const Color(0xFFFFF4EA)
                          : const Color(0xFFEAF4FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          order.isCod ? Icons.payments_outlined : Icons.verified,
                          color: order.isCod ? Colors.deepOrange : AppTheme.info,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            order.isCod
                                ? order.cashCollectionMessage
                                : 'Payment already received by platform',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _AmountColumn(
                        label: 'Customer payable',
                        value: formatCurrency(order.pricing.finalPayableAmount),
                      ),
                      _AmountColumn(
                        label: 'Platform fee',
                        value: formatCurrency(order.pricing.platformFee),
                      ),
                      _AmountColumn(
                        label: 'Vendor earning',
                        value: formatCurrency(order.pricing.vendorEarning),
                        emphasized: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountColumn extends StatelessWidget {
  const _AmountColumn({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: emphasized ? AppTheme.success : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
