import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/app_theme.dart';
import '../core/vendor_formatters.dart';
import '../providers/ledger_provider.dart';
import '../providers/payout_provider.dart';
import '../widgets/empty_state.dart';

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
                  'Admin controls transfers. Available balance below is ready for payout according to system settlement rules.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 18),
                Text(
                  formatCurrency(ledger?.availableBalance ?? 0),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Payout requests are admin-controlled on the current backend.',
                          ),
                        ),
                      );
                    },
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
}
