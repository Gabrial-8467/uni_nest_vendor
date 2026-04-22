/// Cross-Settlement Ledger Summary
///
/// Handles the cross-settlement between ONLINE and COD payments:
/// - Online orders: Platform owes vendor (onlinePayable)
/// - COD orders: Vendor owes platform fees (codPlatformReceivable)
/// - Cross-settlement: COD fees offset against online earnings
///
/// Formula:
/// - reconciledCodFees = min(onlinePayable, codPlatformReceivable)
/// - netBeforePayout = onlinePayable - codPlatformReceivable
/// - availableAmount = max(0, netBeforePayout - paidAmount)
/// - platformReceivable = max(0, codPlatformReceivable - onlinePayable)
class VendorLedgerSummary {
  VendorLedgerSummary({
    required this.totalEarnings,
    required this.pendingBalance,
    required this.availableBalance,
    required this.paidOutAmount,
    required this.commissionOwed,
    required this.platformReceivable,
    required this.entries,
    // Cross-settlement fields
    this.onlineCommissionBalance,
    this.reconciledCodFees,
    this.grossOnlinePayable,
    this.grossCodReceivable,
  });

  final double totalEarnings;
  final double pendingBalance;
  final double availableBalance;
  final double paidOutAmount;
  final double commissionOwed;
  final double platformReceivable;
  final List<VendorLedgerEntry> entries;

  // Cross-settlement fields
  /// Online payable remaining after COD cross-settlement
  final double? onlineCommissionBalance;

  /// COD fees netted against online payable
  final double? reconciledCodFees;

  /// Gross online payable before cross-settlement
  final double? grossOnlinePayable;

  /// Gross COD fees vendor owes before cross-settlement
  final double? grossCodReceivable;

  /// Net amount vendor can withdraw (alias for availableBalance)
  double get netAvailableAmount => availableBalance;

  factory VendorLedgerSummary.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'] ?? json['transactions'] ?? const [];
    return VendorLedgerSummary(
      totalEarnings: _ledgerDouble(json['totalEarnings']),
      pendingBalance: _ledgerDouble(
        json['pendingBalance'] ?? json['pendingAmount'],
      ),
      availableBalance: _ledgerDouble(
        json['availableBalance'] ??
            json['availableAmount'] ??
            json['netAvailableAmount'],
      ),
      paidOutAmount: _ledgerDouble(json['paidOutAmount'] ?? json['paidAmount']),
      commissionOwed: _ledgerDouble(
        json['commissionOwed'] ??
            json['totalCommissionOwed'] ??
            json['platformReceivable'],
      ),
      platformReceivable: _ledgerDouble(json['platformReceivable']),
      entries: (rawEntries as List)
          .whereType<Map>()
          .map(
            (entry) =>
                VendorLedgerEntry.fromJson(Map<String, dynamic>.from(entry)),
          )
          .toList(),
      // Cross-settlement fields
      onlineCommissionBalance: _ledgerDoubleOrNull(
        json['onlineCommissionBalance'],
      ),
      reconciledCodFees: _ledgerDoubleOrNull(json['reconciledCodFees']),
      grossOnlinePayable: _ledgerDoubleOrNull(json['grossOnlinePayable']),
      grossCodReceivable: _ledgerDoubleOrNull(json['grossCodReceivable']),
    );
  }
}

class VendorLedgerEntry {
  VendorLedgerEntry({
    required this.id,
    required this.type,
    required this.direction,
    required this.amount,
    required this.createdAt,
    this.orderId,
    this.description,
  });

  final String id;
  final String type;
  final String direction;
  final double amount;
  final DateTime createdAt;
  final String? orderId;
  final String? description;

  factory VendorLedgerEntry.fromJson(Map<String, dynamic> json) {
    return VendorLedgerEntry(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      type: (json['type'] ?? 'manual_adjustment').toString(),
      direction: (json['direction'] ?? 'credit').toString(),
      amount: _ledgerDouble(json['amount']),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      orderId: json['orderId']?.toString(),
      description: json['description']?.toString(),
    );
  }
}

class VendorPayout {
  VendorPayout({
    required this.id,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.bankReference,
    this.failureReason,
  });

  final String id;
  final double amount;
  final String status;
  final DateTime createdAt;
  final String? bankReference;
  final String? failureReason;

  factory VendorPayout.fromJson(Map<String, dynamic> json) {
    return VendorPayout(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      amount: _ledgerDouble(json['amount']),
      status: (json['status'] ?? 'initiated').toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      bankReference: json['bankReference']?.toString(),
      failureReason: json['failureReason']?.toString(),
    );
  }
}

class VendorNotification {
  VendorNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.data,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  factory VendorNotification.fromJson(Map<String, dynamic> json) {
    final status = (json['status'] ?? '').toString().toLowerCase();
    return VendorNotification(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? json['subject'] ?? 'Notification').toString(),
      body: (json['message'] ?? json['body'] ?? '').toString(),
      type: (json['type'] ?? 'system').toString(),
      isRead: json['isRead'] == true || status == 'read',
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      data: json['data'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['data'] as Map)
          : null,
    );
  }
}

double _ledgerDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse((value ?? '0').toString()) ?? 0;
}

double? _ledgerDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}
