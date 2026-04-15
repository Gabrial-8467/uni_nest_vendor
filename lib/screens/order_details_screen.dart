import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/app_theme.dart';
import '../core/vendor_formatters.dart';
import '../models/order_models.dart';
import '../providers/order_provider.dart';
import '../widgets/otp_verify_sheet.dart';
import '../widgets/status_chip.dart';

class OrderDetailsScreen extends ConsumerStatefulWidget {
  const OrderDetailsScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  bool _isBootstrappingOrder = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final state = ref.read(orderProvider);
      final exists = state.orders.any((item) => item.id == widget.orderId);
      if (!exists) {
        await ref.read(orderProvider.notifier).fetchOrderById(widget.orderId);
      }
      if (mounted) {
        setState(() {
          _isBootstrappingOrder = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderId = widget.orderId;
    final state = ref.watch(orderProvider);
    VendorOrder? order;
    for (final item in state.orders) {
      if (item.id == orderId || item.orderNumber == orderId) {
        order = item;
        break;
      }
    }

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order details')),
        body: Center(
          child: _isBootstrappingOrder
              ? const CircularProgressIndicator()
              : const Text('Order not found'),
        ),
      );
    }

    final isBusy = state.activeOrderIds.contains(order.id);
    return Scaffold(
      appBar: AppBar(title: Text('Order #${order.orderNumber}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          StatusChip.order(order.status),
                          StatusChip.payment(order.paymentStatus),
                          StatusChip(
                            label: order.isCod ? 'COD' : 'ONLINE',
                            color: order.isCod
                                ? Colors.deepOrange
                                : AppTheme.info,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatCompactDate(order.createdAt),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  order.customerName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(order.customerPhone),
                const SizedBox(height: 12),
                Text(
                  order.isCod
                      ? '${order.cashCollectionMessage}. Platform commission owed: ${formatCurrency(order.pricing.platformFee)}'
                      : 'Payment already received online. Vendor earning remains pending until delivery, then becomes available.',
                  style: TextStyle(
                    color: order.isCod ? Colors.deepOrange : AppTheme.info,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Panel(
            title: 'Items',
            child: Column(
              children: [
                for (final item in order.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.black.withValues(alpha: 0.05),
                          child: Text(
                            '${item.quantity}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(formatCurrency(item.totalPrice)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Panel(
            title: 'Pricing snapshot',
            subtitle:
                'These values come from backend pricing. The frontend does not recalculate earnings or fees.',
            child: Column(
              children: [
                _priceRow('Base amount', order.pricing.baseAmount),
                _priceRow('Vendor discount', order.pricing.vendorDiscount),
                _priceRow('Platform discount', order.pricing.platformDiscount),
                _priceRow('Tax', order.pricing.taxAmount),
                _priceRow('Delivery fee', order.pricing.deliveryFee),
                _priceRow('Late night fee', order.pricing.lateNightFee),
                _priceRow('Platform fee', order.pricing.platformFee),
                const Divider(height: 24),
                _priceRow(
                  'Vendor earning',
                  order.pricing.vendorEarning,
                  emphasize: true,
                ),
                _priceRow(
                  'Customer payable',
                  order.pricing.finalPayableAmount,
                  emphasize: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Panel(
            title: 'Order timeline',
            child: Column(
              children: [
                for (final event in order.timeline)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(humanizeEnum(event.status)),
                    subtitle: Text(formatCompactDate(event.createdAt)),
                    trailing: event.note == null ? null : Text(event.note!),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (order.canReject)
              Expanded(
                child: OutlinedButton(
                  onPressed: isBusy
                      ? null
                      : () => _rejectOrder(context, ref, order!),
                  child: const Text('Reject'),
                ),
              ),
            if (order.canReject) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: isBusy
                    ? null
                    : () => _handlePrimaryAction(context, ref, order!),
                child: isBusy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_primaryActionLabel(order)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String label, double amount, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            formatCurrency(amount),
            style: TextStyle(
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              color: emphasize ? AppTheme.success : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _primaryActionLabel(VendorOrder order) {
    if (order.status == 'pending') {
      return 'Accept order';
    }
    if (order.status == 'out_for_delivery') {
      return 'Verify OTP and deliver';
    }
    final next = order.nextStatus;
    if (next == null) {
      return 'Up to date';
    }
    return 'Mark ${humanizeEnum(next)}';
  }

  Future<void> _handlePrimaryAction(
    BuildContext context,
    WidgetRef ref,
    VendorOrder order,
  ) async {
    if (order.status == 'out_for_delivery') {
      final otp = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const OtpVerifySheet(),
      );
      if (otp == null || otp.isEmpty) {
        return;
      }
      final success = await ref
          .read(orderProvider.notifier)
          .verifyDeliveryOtp(orderId: order.id, otp: otp);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'OTP verified. Order marked delivered.'
                  : ref.read(orderProvider).errorMessage ??
                        'OTP verification failed',
            ),
          ),
        );
      }
      return;
    }

    final success = await ref.read(orderProvider.notifier).advanceOrder(order);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Order updated to ${humanizeEnum(order.nextStatus ?? '')}.'
                : ref.read(orderProvider).errorMessage ??
                      'Status update failed',
          ),
        ),
      );
    }
  }

  Future<void> _rejectOrder(
    BuildContext context,
    WidgetRef ref,
    VendorOrder order,
  ) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject order'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Reason for rejection'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (reason == null || reason.isEmpty) {
      return;
    }

    final success = await ref
        .read(orderProvider.notifier)
        .rejectOrder(orderId: order.id, reason: reason);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Order rejected.'
                : ref.read(orderProvider).errorMessage ?? 'Reject failed',
          ),
        ),
      );
    }
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.title, this.subtitle});

  final Widget child;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(
              title!,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
          ] else if (title != null)
            const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
