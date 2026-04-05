import 'package:flutter/material.dart';

import '../core/vendor_formatters.dart';
import '../utils/app_theme.dart';

class PaymentDetailsScreen extends StatelessWidget {
  const PaymentDetailsScreen({
    super.key,
    required this.paymentId,
    this.amount,
    this.status,
    this.date,
  });

  final String paymentId;
  final double? amount;
  final String? status;
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Details'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PaymentInfoCard(
            paymentId: paymentId,
            amount: amount,
            status: status,
            date: date,
          ),
          const SizedBox(height: 20),
          _buildActionsCard(context),
        ],
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Download receipt feature coming soon'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Download Receipt'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Share payment details feature coming soon',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentInfoCard extends StatelessWidget {
  const _PaymentInfoCard({
    required this.paymentId,
    this.amount,
    this.status,
    this.date,
  });

  final String paymentId;
  final double? amount;
  final String? status;
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment ID
          _buildInfoRow('Payment ID', paymentId, Icons.payment_outlined),
          const Divider(height: 24),

          // Amount
          if (amount != null) ...[
            _buildInfoRow(
              'Amount',
              formatCurrency(amount!),
              Icons.attach_money,
              valueStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.success,
              ),
            ),
            const Divider(height: 24),
          ],

          // Status
          if (status != null) ...[
            _buildInfoRow(
              'Status',
              _formatStatus(status!),
              Icons.info_outline,
              valueWidget: _StatusChip(status: status!),
            ),
            const Divider(height: 24),
          ],

          // Date
          if (date != null) ...[
            _buildInfoRow(
              'Date',
              formatCompactDate(date!),
              Icons.calendar_today_outlined,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    TextStyle? valueStyle,
    Widget? valueWidget,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              if (valueWidget != null)
                valueWidget
              else
                Text(
                  value,
                  style:
                      valueStyle ??
                      const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      case 'processing':
        return 'Processing';
      default:
        return status;
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String displayText;

    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        displayText = 'Completed';
        break;
      case 'pending':
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange;
        displayText = 'Pending';
        break;
      case 'failed':
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red;
        displayText = 'Failed';
        break;
      case 'processing':
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
        displayText = 'Processing';
        break;
      default:
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey;
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
