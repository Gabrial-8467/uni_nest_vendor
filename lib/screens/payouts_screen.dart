import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/app_theme.dart';
import '../core/vendor_formatters.dart';
import '../providers/ledger_provider.dart';
import '../providers/payout_provider.dart';
import '../widgets/empty_state.dart';
import 'payout_request_screen.dart';

class VendorPayoutsTab extends ConsumerWidget {
  const VendorPayoutsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payoutState = ref.watch(payoutProvider);
    final ledger = ref.watch(ledgerProvider).ledger;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait<void>([
          ref.read(payoutProvider.notifier).loadPayouts(),
          ref.read(ledgerProvider.notifier).loadLedger(silent: true),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payout balance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Available after cross-settlement between online and COD orders.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 18),
                Text(
                  formatCurrency(ledger?.netAvailableAmount ?? 0),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.success,
                  ),
                ),

                // Cross-settlement mini breakdown
                if (ledger != null &&
                    (ledger.reconciledCodFees != null &&
                        ledger.reconciledCodFees! > 0))
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.sync,
                                size: 16,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Cross-settlement applied',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (ledger.grossOnlinePayable != null)
                            _buildMiniRow(
                              'Online payable',
                              ledger.grossOnlinePayable!,
                              Colors.green,
                            ),
                          if (ledger.grossCodReceivable != null &&
                              ledger.grossCodReceivable! > 0)
                            _buildMiniRow(
                              'COD fees owed',
                              -ledger.grossCodReceivable!,
                              Colors.orange,
                            ),
                          const Divider(height: 16),
                          _buildMiniRow(
                            'Net after settlement',
                            ledger.netAvailableAmount,
                            ledger.netAvailableAmount >= 0
                                ? Colors.green
                                : Colors.red,
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: (ledger?.netAvailableAmount ?? 0) > 0
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PayoutRequestScreen(),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Request payout'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payout history',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                if (payoutState.isLoading && payoutState.payouts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (payoutState.payouts.isEmpty)
                  const EmptyState(
                    icon: Icons.payments_outlined,
                    title: 'No payouts yet',
                    message:
                        'Completed, processing, and failed payouts from the system will appear here.',
                  )
                else
                  ...payoutState.payouts.map(
                    (payout) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        child: Icon(Icons.account_balance),
                      ),
                      title: Text(formatCurrency(payout.amount)),
                      subtitle: Text(formatCompactDate(payout.createdAt)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            humanizeEnum(payout.status),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (payout.bankReference != null)
                            Text(
                              payout.bankReference!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
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

  Widget _buildMiniRow(
    String label,
    double amount,
    Color color, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            '${amount >= 0 ? '+' : ''}${formatCurrency(amount)}',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
