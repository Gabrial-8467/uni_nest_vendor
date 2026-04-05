class VendorLedgerSummary {
  VendorLedgerSummary({
    required this.totalEarnings,
    required this.pendingBalance,
    required this.availableBalance,
    required this.paidOutAmount,
    required this.commissionOwed,
    required this.platformReceivable,
    required this.entries,
  });

  final double totalEarnings;
  final double pendingBalance;
  final double availableBalance;
  final double paidOutAmount;
  final double commissionOwed;
  final double platformReceivable;
  final List<VendorLedgerEntry> entries;

  factory VendorLedgerSummary.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'] ?? json['transactions'] ?? const [];
    return VendorLedgerSummary(
      totalEarnings: _ledgerDouble(json['totalEarnings']),
      pendingBalance: _ledgerDouble(
        json['pendingBalance'] ?? json['pendingAmount'],
      ),
      availableBalance: _ledgerDouble(
        json['availableBalance'] ?? json['availableAmount'],
      ),
      paidOutAmount: _ledgerDouble(json['paidOutAmount'] ?? json['paidAmount']),
      commissionOwed: _ledgerDouble(
        json['commissionOwed'] ?? json['totalCommissionOwed'],
      ),
      platformReceivable: _ledgerDouble(json['platformReceivable']),
      entries: (rawEntries as List)
          .whereType<Map>()
          .map(
            (entry) =>
                VendorLedgerEntry.fromJson(Map<String, dynamic>.from(entry)),
          )
          .toList(),
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
