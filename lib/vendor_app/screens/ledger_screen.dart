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
}
