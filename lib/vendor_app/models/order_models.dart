class VendorOrder {
  VendorOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.fulfillmentType,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.pricing,
    required this.createdAt,
    required this.deliveryAddress,
    required this.timeline,
    this.customerNotes,
    this.deliveryOtpRequired = false,
  });

  final String id;
  final String orderNumber;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final String fulfillmentType;
  final String customerName;
  final String customerPhone;
  final List<VendorOrderItem> items;
  final OrderPricingSnapshot pricing;
  final DateTime createdAt;
  final Map<String, dynamic> deliveryAddress;
  final List<OrderTimelineEvent> timeline;
  final String? customerNotes;
  final bool deliveryOtpRequired;

  factory VendorOrder.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] is Map<String, dynamic>
        ? json['customer'] as Map<String, dynamic>
        : <String, dynamic>{};
    final deliveryAddress = json['deliveryAddress'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['deliveryAddress'] as Map)
        : json['fulfillment'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(
            (json['fulfillment'] as Map<String, dynamic>)['deliveryAddress'] ??
                const {},
          )
        : <String, dynamic>{};
    final fulfillment = json['fulfillment'] is Map<String, dynamic>
        ? json['fulfillment'] as Map<String, dynamic>
        : <String, dynamic>{};
    final deliveryOtp = json['deliveryOtp'] is Map<String, dynamic>
        ? json['deliveryOtp'] as Map<String, dynamic>
        : <String, dynamic>{};

    return VendorOrder(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      orderNumber: (json['orderNumber'] ?? json['_id'] ?? '').toString(),
      status: (json['orderStatus'] ?? json['status'] ?? 'confirmed').toString(),
      paymentMethod:
          (json['paymentMethod'] ?? json['payment']?['method'] ?? 'online')
              .toString(),
      paymentStatus:
          (json['paymentStatus'] ?? json['payment']?['status'] ?? 'pending')
              .toString(),
      fulfillmentType:
          (fulfillment['type'] ?? json['fulfillmentType'] ?? 'delivery')
              .toString(),
      customerName:
          (json['customerName'] ??
                  customer['name'] ??
                  deliveryAddress['name'] ??
                  '')
              .toString(),
      customerPhone:
          (json['customerPhone'] ??
                  customer['phone'] ??
                  deliveryAddress['phone'] ??
                  '')
              .toString(),
      items: ((json['items'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (item) => VendorOrderItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      pricing: OrderPricingSnapshot.fromJson(
        Map<String, dynamic>.from(json['pricing'] ?? const {}),
      ),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      deliveryAddress: deliveryAddress,
      timeline: ((json['timeline'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (event) =>
                OrderTimelineEvent.fromJson(Map<String, dynamic>.from(event)),
          )
          .toList(),
      customerNotes: json['customerNotes']?.toString(),
      deliveryOtpRequired:
          fulfillment['type'] == 'delivery' &&
          statusNeedsOtp(
            (json['orderStatus'] ?? json['status'] ?? '').toString(),
          ) &&
          deliveryOtp['verifiedAt'] == null,
    );
  }

  VendorOrder copyWith({
    String? status,
    String? paymentStatus,
    List<OrderTimelineEvent>? timeline,
  }) {
    return VendorOrder(
      id: id,
      orderNumber: orderNumber,
      status: status ?? this.status,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      fulfillmentType: fulfillmentType,
      customerName: customerName,
      customerPhone: customerPhone,
      items: items,
      pricing: pricing,
      createdAt: createdAt,
      deliveryAddress: deliveryAddress,
      timeline: timeline ?? this.timeline,
      customerNotes: customerNotes,
      deliveryOtpRequired: deliveryOtpRequired,
    );
  }

  bool get isCod => paymentMethod.toLowerCase() == 'cod';
  bool get isOnline => !isCod;
  bool get isCompleted => status == 'delivered';
  bool get isCancelled => status == 'cancelled' || status == 'refunded';
  bool get canReject => status == 'pending' || status == 'confirmed';

  String? get nextStatus {
    switch (status) {
      case 'pending':
        return 'confirmed';
      case 'confirmed':
        return 'preparing';
      case 'preparing':
        return 'ready';
      case 'ready':
        return 'out_for_delivery';
      default:
        return null;
    }
  }

  String get cashCollectionMessage =>
      'Collect ${pricing.finalPayableLabel} from customer';
}

class VendorOrderItem {
  VendorOrderItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  final String name;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  factory VendorOrderItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] is Map<String, dynamic>
        ? json['product'] as Map<String, dynamic>
        : <String, dynamic>{};
    return VendorOrderItem(
      name: (json['name'] ?? json['productName'] ?? product['name'] ?? 'Item')
          .toString(),
      quantity: (json['quantity'] is num)
          ? (json['quantity'] as num).toInt()
          : int.tryParse((json['quantity'] ?? '0').toString()) ?? 0,
      unitPrice: _readDouble(json['unitPrice'] ?? json['price']),
      totalPrice: _readDouble(
        json['totalPrice'] ?? json['lineTotal'] ?? json['subtotal'],
      ),
    );
  }
}

class OrderPricingSnapshot {
  OrderPricingSnapshot({
    required this.baseAmount,
    required this.vendorDiscount,
    required this.platformDiscount,
    required this.taxAmount,
    required this.deliveryFee,
    required this.lateNightFee,
    required this.platformFee,
    required this.vendorEarning,
    required this.finalPayableAmount,
    required this.currency,
  });

  final double baseAmount;
  final double vendorDiscount;
  final double platformDiscount;
  final double taxAmount;
  final double deliveryFee;
  final double lateNightFee;
  final double platformFee;
  final double vendorEarning;
  final double finalPayableAmount;
  final String currency;

  factory OrderPricingSnapshot.fromJson(Map<String, dynamic> json) {
    return OrderPricingSnapshot(
      baseAmount: _readDouble(json['baseAmount'] ?? json['itemSubtotal']),
      vendorDiscount: _readDouble(json['vendorDiscount']),
      platformDiscount: _readDouble(json['platformDiscount']),
      taxAmount: _readDouble(json['taxAmount']),
      deliveryFee: _readDouble(json['deliveryFee']),
      lateNightFee: _readDouble(json['lateNightFee']),
      platformFee: _readDouble(json['platformFee']),
      vendorEarning: _readDouble(json['vendorEarning']),
      finalPayableAmount: _readDouble(
        json['finalPayableAmount'] ?? json['customerPayable'],
      ),
      currency: (json['currency'] ?? 'INR').toString(),
    );
  }

  String get finalPayableLabel => 'Rs ${finalPayableAmount.toStringAsFixed(2)}';
}

class OrderTimelineEvent {
  OrderTimelineEvent({
    required this.status,
    required this.createdAt,
    this.note,
  });

  final String status;
  final DateTime createdAt;
  final String? note;

  factory OrderTimelineEvent.fromJson(Map<String, dynamic> json) {
    return OrderTimelineEvent(
      status: (json['status'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      note: json['note']?.toString(),
    );
  }
}

bool statusNeedsOtp(String status) => status == 'out_for_delivery';

double _readDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse((value ?? '0').toString()) ?? 0;
}
