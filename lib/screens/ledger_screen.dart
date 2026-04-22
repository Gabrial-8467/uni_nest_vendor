import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/vendor_formatters.dart';
import '../providers/ledger_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/summary_tile.dart';

class VendorLedgerTab extends ConsumerWidget {
  const VendorLedgerTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerState = ref.watch(ledgerProvider);
    final ledger = ledgerState.ledger;

    return RefreshIndicator(
      onRefresh: () => ref.read(ledgerProvider.notifier).loadLedger(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Main summary tiles
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width > 820 ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              SummaryTile(
                title: 'Available',
                value: formatCurrency(ledger?.availableBalance ?? 0),
                icon: Icons.savings_outlined,
                color: Colors.green,
              ),
              SummaryTile(
                title: 'Pending',
                value: formatCurrency(ledger?.pendingBalance ?? 0),
                icon: Icons.hourglass_bottom_outlined,
                color: Colors.orange,
              ),
              SummaryTile(
                title: 'Commission owed',
                value: formatCurrency(ledger?.commissionOwed ?? 0),
                icon: Icons.request_quote_outlined,
                color: Colors.deepOrange,
              ),
              SummaryTile(
                title: 'Total earnings',
                value: formatCurrency(ledger?.totalEarnings ?? 0),
                icon: Icons.trending_up,
                color: Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Cross-Settlement Breakdown Card
          if (ledger != null &&
                  (ledger.reconciledCodFees != null &&
                      ledger.reconciledCodFees! > 0) ||
              (ledger?.grossOnlinePayable != null ||
                  ledger?.grossCodReceivable != null))
            _buildCrossSettlementCard(context, ledger),

          if (ledger != null &&
                  (ledger.reconciledCodFees != null &&
                      ledger.reconciledCodFees! > 0) ||
              (ledger?.grossOnlinePayable != null ||
                  ledger?.grossCodReceivable != null))
            const SizedBox(height: 20),

          // Ledger transactions
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
                  'Ledger transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Credits show order earnings. Debits show COD commission recovery or payouts.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                if (ledgerState.isLoading && ledger == null)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (ledger == null || ledger.entries.isEmpty)
                  const EmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'No ledger entries',
                    message:
                        'Ledger transactions will appear as order earnings, COD commission entries, and payouts are posted by the system.',
                  )
                else
                  ...ledger.entries.map(
                    (entry) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: entry.direction == 'credit'
                            ? Colors.green.withValues(alpha: 0.12)
                            : Colors.red.withValues(alpha: 0.12),
                        child: Icon(
                          entry.direction == 'credit'
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: entry.direction == 'credit'
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      title: Text(humanizeEnum(entry.type)),
                      subtitle: Text(
                        '${formatCompactDate(entry.createdAt)}${entry.orderId == null ? '' : ' • Order ${entry.orderId}'}',
                      ),
                      trailing: Text(
                        '${entry.direction == 'credit' ? '+' : '-'}${formatCurrency(entry.amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: entry.direction == 'credit'
                              ? Colors.green
                              : Colors.red,
                        ),
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

  Widget _buildCrossSettlementCard(BuildContext context, dynamic ledger) {
    final grossOnline = ledger.grossOnlinePayable ?? 0.0;
    final grossCod = ledger.grossCodReceivable ?? 0.0;
    final reconciled = ledger.reconciledCodFees ?? 0.0;
    final netAvailable = ledger.netAvailableAmount;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sync_alt, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Text(
                'Cross-Settlement Breakdown',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Online orders and COD orders are cross-settled automatically',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Online row
          _buildSettlementRow(
            icon: Icons.payment,
            iconColor: Colors.green,
            label: 'Online orders (platform owes you)',
            amount: grossOnline,
            isPositive: true,
          ),

          const SizedBox(height: 12),

          // COD row
          _buildSettlementRow(
            icon: Icons.local_mall,
            iconColor: Colors.orange,
            label: 'COD orders (you owe platform)',
            amount: grossCod,
            isPositive: false,
          ),

          if (reconciled > 0) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),

            // Cross-settled row
            _buildSettlementRow(
              icon: Icons.sync,
              iconColor: Colors.blue,
              label: 'Cross-settled (auto-deducted)',
              amount: reconciled,
              isPositive: null,
              highlight: true,
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),

          // Net available row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Net available for payout',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              Text(
                formatCurrency(netAvailable),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: netAvailable > 0 ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),

          if (ledger.platformReceivable > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Note: You still owe ${formatCurrency(ledger.platformReceivable)} to the platform from COD orders',
                style: TextStyle(color: Colors.orange[700], fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSettlementRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required double amount,
    required bool? isPositive,
    bool highlight = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
          ),
        ),
        Text(
          isPositive == null
              ? formatCurrency(amount)
              : '${isPositive ? '+' : '-'}${formatCurrency(amount)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isPositive == null
                ? Colors.blue[700]
                : isPositive
                ? Colors.green[700]
                : Colors.orange[700],
          ),
        ),
      ],
    );
  }
}
