import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/vendor_formatters.dart';
import '../models/auth_models.dart';
import '../providers/ledger_provider.dart';
import '../providers/payout_method_provider.dart';
import '../providers/payout_provider.dart';
import '../utils/app_theme.dart';
import '../utils/payout_security.dart';
import 'add_payout_method_screen.dart';

class PayoutRequestScreen extends ConsumerStatefulWidget {
  const PayoutRequestScreen({super.key});

  @override
  ConsumerState<PayoutRequestScreen> createState() =>
      _PayoutRequestScreenState();
}

class _PayoutRequestScreenState extends ConsumerState<PayoutRequestScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showConfirmation = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _setMaxAmount(double maxAmount) {
    _amountController.text = maxAmount.toStringAsFixed(2);
  }

  void _proceedToConfirmation() {
    if (_formKey.currentState!.validate()) {
      setState(() => _showConfirmation = true);
    }
  }

  Future<void> _submitPayoutRequest() async {
    final amount = double.parse(_amountController.text);
    final success = await ref
        .read(payoutProvider.notifier)
        .requestPayout(amount: amount);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payout request of ${formatCurrency(amount)} submitted successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider).ledger;
    final payoutState = ref.watch(payoutProvider);
    final payoutMethodState = ref.watch(payoutMethodProvider);
    final maxAmount = ledger?.netAvailableAmount ?? 0;
    final payoutMethod = payoutMethodState.method;

    // Debug logging
    debugPrint('=== PAYOUT DEBUG ===');
    debugPrint('maxAmount: $maxAmount');
    debugPrint('payoutMethod: $payoutMethod');
    debugPrint('isVerified: ${payoutMethod?.isVerified}');
    debugPrint('===================');

    return SecureScreen(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Request Payout'),
          backgroundColor: AppTheme.surface,
          foregroundColor: AppTheme.textPrimary,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await ref
                    .read(payoutMethodProvider.notifier)
                    .loadPayoutMethod();
                await ref.read(ledgerProvider.notifier).loadLedger();
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Refreshed'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _showConfirmation
            ? _buildConfirmationView(payoutState, payoutMethod)
            : _buildRequestForm(maxAmount, payoutMethod, payoutState),
      ),
    );
  }

  Widget _buildRequestForm(
    double maxAmount,
    PayoutMethod? payoutMethod,
    PayoutState payoutState,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Available Balance Card
        _buildBalanceCard(maxAmount),
        const SizedBox(height: 20),

        // Payout Method Card
        _buildPayoutMethodCard(payoutMethod, payoutState),
        const SizedBox(height: 20),

        // Amount Input Card
        _buildAmountInputCard(maxAmount, payoutState, payoutMethod),
        const SizedBox(height: 20),

        // Important Info
        _buildInfoCard(),
      ],
    );
  }

  Widget _buildBalanceCard(double maxAmount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Colors.white70,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Available for Withdrawal',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatCurrency(maxAmount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'After cross-settlement of COD and online payments',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutMethodCard(PayoutMethod? method, PayoutState payoutState) {
    if (method == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  'No Payout Method Set',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Please add your bank account or UPI details in your profile settings to receive payouts.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AddPayoutMethodScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Payout Method'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warning,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    method.isUpi ? Icons.payment : Icons.account_balance,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    method.isUpi ? 'UPI ID' : 'Payout Method',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (method.isVerified)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, color: Colors.green, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Edit Button
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              AddPayoutMethodScreen(existingMethod: method),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        color: AppTheme.primary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          _buildMethodRow('Account Holder', method.accountHolderName),
          const SizedBox(height: 12),
          if (method.isUpi) ...[
            _buildMethodRow('UPI ID', method.upiId ?? 'N/A'),
          ] else ...[
            _buildMethodRow('Bank Name', method.bankName ?? 'N/A'),
            const SizedBox(height: 12),
            _buildMethodRow('Account Number', method.maskedAccountNumber),
            const SizedBox(height: 12),
            _buildMethodRow('IFSC Code', method.ifscCode ?? 'N/A'),
          ],
        ],
      ),
    );
  }

  Widget _buildMethodRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountInputCard(
    double maxAmount,
    PayoutState payoutState,
    PayoutMethod? payoutMethod,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  color: AppTheme.primary,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Withdrawal Amount',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter amount',
                prefixIcon: const Icon(Icons.currency_rupee),
                suffixIcon: TextButton(
                  onPressed: maxAmount > 0
                      ? () => _setMaxAmount(maxAmount)
                      : null,
                  child: const Text('MAX'),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primary,
                    width: 2,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                if (amount > maxAmount) {
                  return 'Amount cannot exceed available balance (${formatCurrency(maxAmount)})';
                }
                if (amount < 100) {
                  return 'Minimum withdrawal amount is ₹100';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Available: ${formatCurrency(maxAmount)}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            if (payoutState.requestErrorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        payoutState.requestErrorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (payoutMethod == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please add a payout method (UPI or Bank Account) first',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } else if (!payoutMethod.isVerified) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Your payout method is pending verification. Please wait for admin approval.',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } else if (maxAmount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No balance available for withdrawal'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } else {
                    _proceedToConfirmation();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  payoutMethod == null
                      ? 'Add Payout Method First'
                      : !payoutMethod.isVerified
                      ? 'Verify Payout Method'
                      : maxAmount <= 0
                      ? 'No Balance Available'
                      : 'Continue',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 18),
              const SizedBox(width: 8),
              Text(
                'Important Information',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem('Processing Time: 1-2 business days'),
          const SizedBox(height: 8),
          _buildInfoItem('Minimum withdrawal: ₹100'),
          const SizedBox(height: 8),
          _buildInfoItem('No withdrawal fees'),
          const SizedBox(height: 8),
          _buildInfoItem(
            'Money will be transferred to your registered bank account',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationView(PayoutState payoutState, PayoutMethod? method) {
    final amount = double.parse(_amountController.text);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                // Confirmation Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: AppTheme.success,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Confirm Payout Request',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please review your payout details before confirming',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Amount Summary
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        formatCurrency(amount),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Withdrawal Amount',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Payout Details
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payout Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Divider(height: 24),
                      if (method != null) ...[
                        _buildDetailRow('Destination', method.displayLabel),
                        const SizedBox(height: 12),
                        if (method.isUpi) ...[
                          _buildDetailRow('UPI ID', method.upiId ?? 'N/A'),
                        ] else ...[
                          _buildDetailRow(
                            'Account',
                            method.maskedAccountNumber,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow('IFSC', method.ifscCode ?? 'N/A'),
                        ],
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          'Account Holder',
                          method.accountHolderName,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Terms
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'By confirming, you agree that the payout will be processed to the registered bank account. This action cannot be undone.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),

          // Error Message
          if (payoutState.requestErrorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      payoutState.requestErrorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Bottom Actions
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: payoutState.isRequesting
                      ? null
                      : () => setState(() => _showConfirmation = false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: payoutState.isRequesting
                      ? null
                      : _submitPayoutRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: payoutState.isRequesting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Confirm & Request',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
