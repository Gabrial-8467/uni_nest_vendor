import 'package:flutter/material.dart';
import 'package:uni_nest_vendor/core/vendor_formatters.dart';

// Location Data Model
class LocationData {
  final List<double> coordinates; // [longitude, latitude]
  final String address;
  final String? landmark; // optional
  final String city;
  final String state;
  final String pincode;

  LocationData({
    required this.coordinates,
    required this.address,
    this.landmark,
    required this.city,
    required this.state,
    required this.pincode,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      coordinates:
          (json['coordinates'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [0.0, 0.0],
      address: json['address']?.toString() ?? '',
      landmark: json['landmark']?.toString(),
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coordinates': coordinates,
      'address': address,
      if (landmark != null) 'landmark': landmark,
      'city': city,
      'state': state,
      'pincode': pincode,
    };
  }
}

// Vendor Models
class Vendor {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String businessName;
  final String businessType;
  final String location; // Keep for backward compatibility
  final LocationData? locationData; // New structured location
  final double rating;
  final bool isActive;
  final DateTime createdAt;
  final String? profileImage;
  final Map<String, dynamic> businessDetails;
  final NotificationSettings notificationSettings;
  final bool isOpen;

  Vendor({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.businessName,
    required this.businessType,
    required this.location,
    this.locationData,
    required this.rating,
    required this.isActive,
    required this.createdAt,
    this.profileImage,
    required this.businessDetails,
    required this.notificationSettings,
    this.isOpen = true,
  });

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  factory Vendor.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'])
        : <String, dynamic>{};
    final contactInfo = json['contactInfo'] is Map
        ? Map<String, dynamic>.from(json['contactInfo'])
        : <String, dynamic>{};
    final rawRating = json['rating'];
    final ratingValue = rawRating is Map
        ? _toDouble(rawRating['average'])
        : _toDouble(rawRating);
    final status = (json['status'] ?? '').toString().toLowerCase();
    final businessDetails = json['businessDetails'] is Map
        ? Map<String, dynamic>.from(json['businessDetails'])
        : <String, dynamic>{};
    final rawOpenStatus =
        json['isOpen'] ??
        json['isAvailable'] ??
        json['isAcceptingOrders'] ??
        json['acceptingOrders'] ??
        json['canteenOpen'] ??
        businessDetails['isOpen'] ??
        businessDetails['isAvailable'] ??
        businessDetails['isAcceptingOrders'] ??
        businessDetails['acceptingOrders'] ??
        businessDetails['canteenOpen'];

    return Vendor(
      id: (json['id'] ?? json['_id'] ?? user['_id'] ?? '').toString(),
      name: capitalizeWords((json['name'] ?? user['name'] ?? '').toString()),
      email: (json['email'] ?? contactInfo['email'] ?? user['email'] ?? '')
          .toString(),
      phone: (json['phone'] ?? contactInfo['phone'] ?? user['phone'] ?? '')
          .toString(),
      businessName: capitalizeWords((json['businessName'] ?? '').toString()),
      businessType: (json['businessType'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      locationData: json['location'] is Map
          ? LocationData.fromJson(json['location'])
          : null,
      rating: ratingValue,
      isActive: json['isActive'] == true || status == 'active',
      createdAt: _parseDate(json['createdAt']),
      profileImage: (json['profileImage'] ?? user['avatar'])?.toString(),
      businessDetails: businessDetails,
      notificationSettings: NotificationSettings.fromJson(
        json['notificationSettings'] ?? {},
      ),
      isOpen: _toBool(rawOpenStatus, defaultValue: true),
    );
  }

  static bool _toBool(dynamic value, {required bool defaultValue}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if ([
        'true',
        '1',
        'yes',
        'open',
        'available',
        'active',
      ].contains(normalized)) {
        return true;
      }
      if ([
        'false',
        '0',
        'no',
        'closed',
        'unavailable',
        'inactive',
      ].contains(normalized)) {
        return false;
      }
    }
    return defaultValue;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'businessName': businessName,
      'businessType': businessType,
      'location': location,
      if (locationData != null) 'location': locationData!.toJson(),
      'rating': rating,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'profileImage': profileImage,
      'businessDetails': businessDetails,
      'notificationSettings': notificationSettings.toJson(),
      'isOpen': isOpen,
      'isAcceptingOrders': isOpen,
    };
  }

  Vendor copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? businessName,
    String? businessType,
    String? location,
    double? rating,
    bool? isActive,
    DateTime? createdAt,
    String? profileImage,
    Map<String, dynamic>? businessDetails,
    NotificationSettings? notificationSettings,
    bool? isOpen,
  }) {
    return Vendor(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      location: location ?? this.location,
      rating: rating ?? this.rating,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      profileImage: profileImage ?? this.profileImage,
      businessDetails: businessDetails ?? this.businessDetails,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      isOpen: isOpen ?? this.isOpen,
    );
  }
}

class Product {
  final String id;
  final String vendorId;
  final String name;
  final String description;
  final double price;
  final String category;
  final List<String> images;
  final bool isAvailable;
  final int stockQuantity;
  final List<String> tags;
  final Map<String, dynamic> nutritionalInfo;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double? discountPercentage;

  Product({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.images,
    required this.isAvailable,
    required this.stockQuantity,
    required this.tags,
    required this.nutritionalInfo,
    required this.createdAt,
    this.updatedAt,
    this.discountPercentage,
  });

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _readString(dynamic value) {
    if (value == null) return '';
    final text = value.toString().trim();
    return text;
  }

  static String? _extractImageString(dynamic value) {
    if (value == null) return null;

    if (value is String) {
      final text = value.trim();
      return text.isEmpty ? null : text;
    }

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final candidates = [
        map['url'],
        map['secure_url'],
        map['location'],
        map['imageUrl'],
        map['assetUrl'],
        map['uploadedImageUrl'],
        map['image'],
        map['path'],
        map['src'],
      ];

      for (final candidate in candidates) {
        final resolved = _extractImageString(candidate);
        if (resolved != null && resolved.isNotEmpty) {
          return resolved;
        }
      }
    }

    return null;
  }

  static bool _toBool(dynamic value, {bool defaultValue = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return defaultValue;
  }

  static List<String> _extractImages(Map<String, dynamic> json) {
    final rawImages =
        json['images'] ??
        json['imageUrls'] ??
        json['uploadedImages'] ??
        json['productImages'] ??
        json['photos'] ??
        json['gallery'] ??
        json['media'];

    if (rawImages is List) {
      return rawImages.map(_extractImageString).whereType<String>().toList();
    }

    if (rawImages is Map) {
      final map = Map<String, dynamic>.from(rawImages);
      final nestedImages =
          map['images'] ?? map['items'] ?? map['files'] ?? map['data'];
      if (nestedImages is List) {
        return nestedImages
            .map(_extractImageString)
            .whereType<String>()
            .toList();
      }
    }

    final singleImage = _extractImageString(
      json['image'] ??
          json['imageUrl'] ??
          json['thumbnail'] ??
          json['featuredImage'] ??
          json['coverImage'] ??
          rawImages,
    );

    return singleImage == null ? <String>[] : <String>[singleImage];
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawVendor = json['vendorId'] ?? json['vendor'];
    final vendorId = rawVendor is Map
        ? _readString(rawVendor['id'] ?? rawVendor['_id'])
        : _readString(rawVendor);
    final availability = _readString(json['availability']).toLowerCase();
    final stockQuantity = _toInt(
      json['stockQuantity'] ?? json['inStock'] ?? json['stock'],
    );
    final isAvailable = json.containsKey('isAvailable')
        ? _toBool(json['isAvailable'], defaultValue: true)
        : availability.isNotEmpty
        ? availability == 'in_stock'
        : stockQuantity > 0;

    return Product(
      id: _readString(json['id'] ?? json['_id']),
      vendorId: vendorId,
      name: _readString(json['name']),
      description: _readString(json['description']),
      price: _toDouble(json['price']),
      category: _readString(json['category']),
      images: _extractImages(json),
      isAvailable: isAvailable,
      stockQuantity: stockQuantity,
      tags: List<String>.from((json['tags'] as List?) ?? const []),
      nutritionalInfo: json['nutritionalInfo'] is Map
          ? Map<String, dynamic>.from(json['nutritionalInfo'])
          : {},
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      discountPercentage: json['discountPercentage'] != null
          ? _toDouble(json['discountPercentage'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendorId': vendorId,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'images': images,
      'isAvailable': isAvailable,
      'stockQuantity': stockQuantity,
      'availability': isAvailable ? 'in_stock' : 'out_of_stock',
      'stock': stockQuantity,
      'tags': tags,
      'nutritionalInfo': nutritionalInfo,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'discountPercentage': discountPercentage,
    };
  }

  double get discountedPrice {
    if (discountPercentage != null && discountPercentage! > 0) {
      return price * (1 - discountPercentage! / 100);
    }
    return price;
  }

  Product copyWith({
    String? id,
    String? vendorId,
    String? name,
    String? description,
    double? price,
    String? category,
    List<String>? images,
    bool? isAvailable,
    int? stockQuantity,
    List<String>? tags,
    Map<String, dynamic>? nutritionalInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? discountPercentage,
  }) {
    return Product(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      images: images ?? this.images,
      isAvailable: isAvailable ?? this.isAvailable,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      tags: tags ?? this.tags,
      nutritionalInfo: nutritionalInfo ?? this.nutritionalInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      discountPercentage: discountPercentage ?? this.discountPercentage,
    );
  }
}

class Order {
  final String id;
  final String orderNumber;
  final String vendorId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final List<OrderItem> items;
  final double totalAmount;
  final double discountAmount;
  final double finalAmount;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final Map<String, dynamic> deliveryAddress;
  final DateTime createdAt;
  final DateTime? estimatedDeliveryTime;
  final DateTime? deliveredAt;
  final String? customerNotes;
  final List<String> orderImages;
  final Map<String, dynamic> metadata;

  Order({
    required this.id,
    required this.orderNumber,
    required this.vendorId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.totalAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.deliveryAddress,
    required this.createdAt,
    this.estimatedDeliveryTime,
    this.deliveredAt,
    this.customerNotes,
    required this.orderImages,
    required this.metadata,
  });

  static String _readString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] is Map
        ? Map<String, dynamic>.from(json['customer'])
        : <String, dynamic>{};
    final deliveryAddress = json['deliveryAddress'] is Map
        ? Map<String, dynamic>.from(json['deliveryAddress'])
        : <String, dynamic>{};
    final pricing = json['pricing'] is Map
        ? Map<String, dynamic>.from(json['pricing'])
        : <String, dynamic>{};
    final rawVendor = json['vendorId'] ?? json['vendor'];
    final rawCustomer = json['customerId'] ?? json['customer'];
    final orderId = _readString(json['id'] ?? json['_id']);
    final orderNumber = _readString(json['orderNumber']);

    return Order(
      id: orderId,
      orderNumber: orderNumber.isNotEmpty ? orderNumber : orderId,
      vendorId: rawVendor is Map
          ? _readString(rawVendor['_id'] ?? rawVendor['id'])
          : _readString(rawVendor),
      customerId: rawCustomer is Map
          ? _readString(rawCustomer['_id'] ?? rawCustomer['id'])
          : _readString(rawCustomer),
      customerName: _readString(
        json['customerName'] ?? customer['name'] ?? deliveryAddress['name'],
      ),
      customerPhone: _readString(
        json['customerPhone'] ?? customer['phone'] ?? deliveryAddress['phone'],
      ),
      items:
          (json['items'] as List<dynamic>?)
              ?.whereType<Map>()
              .map(
                (item) => OrderItem.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList() ??
          [],
      totalAmount: _toDouble(json['totalAmount'] ?? json['subtotal']),
      discountAmount: _toDouble(json['discountAmount'] ?? json['discount']),
      finalAmount: _toDouble(
        json['finalAmount'] ??
            json['totalAmount'] ??
            json['total'] ??
            pricing['finalPayableAmount'],
      ),
      status: _readString(json['status'] ?? json['orderStatus']).isEmpty
          ? 'pending'
          : _readString(json['status'] ?? json['orderStatus']),
      paymentMethod: _readString(
        json['paymentMethod'] ?? json['payment']?['method'],
      ),
      paymentStatus:
          _readString(
            json['paymentStatus'] ?? json['payment']?['status'],
          ).isEmpty
          ? 'pending'
          : _readString(json['paymentStatus'] ?? json['payment']?['status']),
      deliveryAddress: deliveryAddress,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      estimatedDeliveryTime: json['estimatedDeliveryTime'] != null
          ? DateTime.parse(json['estimatedDeliveryTime'])
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'])
          : null,
      customerNotes: json['customerNotes'],
      orderImages: List<String>.from(json['orderImages'] ?? []),
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'vendorId': vendorId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'discountAmount': discountAmount,
      'finalAmount': finalAmount,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'deliveryAddress': deliveryAddress,
      'createdAt': createdAt.toIso8601String(),
      'estimatedDeliveryTime': estimatedDeliveryTime?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'customerNotes': customerNotes,
      'orderImages': orderImages,
      'metadata': metadata,
    };
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final String productImage;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final Map<String, dynamic> customization;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.customization,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] is Map
        ? Map<String, dynamic>.from(json['product'])
        : <String, dynamic>{};
    final productImages = product['images'];
    String productImage = '';
    if (productImages is List && productImages.isNotEmpty) {
      productImage = Product._extractImageString(productImages.first) ?? '';
    }

    return OrderItem(
      productId:
          (json['productId'] ??
                  json['product']?['_id'] ??
                  json['product']?['id'] ??
                  '')
              .toString(),
      productName:
          (json['productName'] ?? json['name'] ?? product['name'] ?? '')
              .toString(),
      productImage: (json['productImage'] ?? productImage).toString(),
      quantity: json['quantity'] is num ? (json['quantity'] as num).toInt() : 0,
      unitPrice: Order._toDouble(
        json['unitPrice'] ?? json['price'] ?? json['linePrice'],
      ),
      totalPrice: Order._toDouble(
        json['totalPrice'] ?? json['subtotal'] ?? json['lineTotal'],
      ),
      customization: json['customization'] is Map
          ? Map<String, dynamic>.from(json['customization'])
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'customization': customization,
    };
  }
}

class VendorLedger {
  final String vendorId;
  final double totalEarnings;
  final double totalCommissionOwed;
  final double pendingAmount;
  final double availableAmount;
  final double paidAmount;
  final double platformReceivable;
  final DateTime? lastSettledAt;

  VendorLedger({
    required this.vendorId,
    required this.totalEarnings,
    required this.totalCommissionOwed,
    required this.pendingAmount,
    required this.availableAmount,
    required this.paidAmount,
    required this.platformReceivable,
    this.lastSettledAt,
  });

  factory VendorLedger.fromJson(Map<String, dynamic> json) {
    return VendorLedger(
      vendorId: (json['vendorId'] ?? json['_id'] ?? '').toString(),
      totalEarnings: Order._toDouble(json['totalEarnings']),
      totalCommissionOwed: Order._toDouble(json['totalCommissionOwed']),
      pendingAmount: Order._toDouble(json['pendingAmount']),
      availableAmount: Order._toDouble(json['availableAmount']),
      paidAmount: Order._toDouble(json['paidAmount']),
      platformReceivable: Order._toDouble(json['platformReceivable']),
      lastSettledAt: json['lastSettledAt'] != null
          ? DateTime.tryParse(json['lastSettledAt'].toString())
          : null,
    );
  }
}

class VendorPayout {
  final String id;
  final String vendorId;
  final double amount;
  final String currency;
  final String status;
  final String? bankReference;
  final String? failureReason;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? failedAt;

  VendorPayout({
    required this.id,
    required this.vendorId,
    required this.amount,
    required this.currency,
    required this.status,
    this.bankReference,
    this.failureReason,
    required this.createdAt,
    this.completedAt,
    this.failedAt,
  });

  factory VendorPayout.fromJson(Map<String, dynamic> json) {
    return VendorPayout(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      vendorId: (json['vendorId'] ?? '').toString(),
      amount: Order._toDouble(json['amount']),
      currency: (json['currency'] ?? 'INR').toString(),
      status: (json['status'] ?? 'initiated').toString(),
      bankReference: json['bankReference']?.toString(),
      failureReason: json['failureReason']?.toString(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
      failedAt: json['failedAt'] != null
          ? DateTime.tryParse(json['failedAt'].toString())
          : null,
    );
  }
}

class VendorAnalytics {
  final String vendorId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double totalRevenue;
  final int totalOrders;
  final int totalCustomers;
  final double averageOrderValue;
  final Map<String, int> salesByCategory;
  final List<Product> topProducts;
  final Map<String, double> revenueByDay;
  final List<String> peakHours;
  final double customerRetentionRate;
  final Map<String, dynamic> growthMetrics;

  VendorAnalytics({
    required this.vendorId,
    required this.periodStart,
    required this.periodEnd,
    required this.totalRevenue,
    required this.totalOrders,
    required this.totalCustomers,
    required this.averageOrderValue,
    required this.salesByCategory,
    required this.topProducts,
    required this.revenueByDay,
    required this.peakHours,
    required this.customerRetentionRate,
    required this.growthMetrics,
  });

  factory VendorAnalytics.fromJson(Map<String, dynamic> json) {
    return VendorAnalytics(
      vendorId: json['vendorId'] ?? '',
      periodStart: DateTime.parse(
        json['periodStart'] ?? DateTime.now().toIso8601String(),
      ),
      periodEnd: DateTime.parse(
        json['periodEnd'] ?? DateTime.now().toIso8601String(),
      ),
      totalRevenue: (json['totalRevenue'] ?? 0.0).toDouble(),
      totalOrders: json['totalOrders'] ?? 0,
      totalCustomers: json['totalCustomers'] ?? 0,
      averageOrderValue: (json['averageOrderValue'] ?? 0.0).toDouble(),
      salesByCategory: Map<String, int>.from(json['salesByCategory'] ?? {}),
      topProducts:
          (json['topProducts'] as List<dynamic>?)
              ?.map((product) => Product.fromJson(product))
              .toList() ??
          [],
      revenueByDay: Map<String, double>.from(json['revenueByDay'] ?? {}),
      peakHours: List<String>.from(json['peakHours'] ?? []),
      customerRetentionRate: (json['customerRetentionRate'] ?? 0.0).toDouble(),
      growthMetrics: json['growthMetrics'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendorId': vendorId,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'totalRevenue': totalRevenue,
      'totalOrders': totalOrders,
      'totalCustomers': totalCustomers,
      'averageOrderValue': averageOrderValue,
      'salesByCategory': salesByCategory,
      'topProducts': topProducts.map((product) => product.toJson()).toList(),
      'revenueByDay': revenueByDay,
      'peakHours': peakHours,
      'customerRetentionRate': customerRetentionRate,
      'growthMetrics': growthMetrics,
    };
  }
}

// Enums for better type safety
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  outForDelivery,
  delivered,
  cancelled,
  refunded,
}

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  refunded,
  partiallyRefunded,
}

enum PaymentMethod { cash, card, upi, wallet, netBanking }

class NotificationSettings {
  final bool orderNotifications;
  final bool paymentNotifications;
  final bool reviewNotifications;
  final bool promotionNotifications;
  final bool systemNotifications;
  final bool emailNotifications;
  final bool smsNotifications;
  final bool pushNotifications;

  NotificationSettings({
    this.orderNotifications = true,
    this.paymentNotifications = true,
    this.reviewNotifications = true,
    this.promotionNotifications = false,
    this.systemNotifications = true,
    this.emailNotifications = true,
    this.smsNotifications = false,
    this.pushNotifications = true,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      orderNotifications:
          json['orderNotifications'] ?? json['orderAlerts'] ?? true,
      paymentNotifications:
          json['paymentNotifications'] ?? json['paymentAlerts'] ?? true,
      reviewNotifications:
          json['reviewNotifications'] ?? json['reviewAlerts'] ?? true,
      promotionNotifications: json['promotionNotifications'] ?? false,
      systemNotifications: json['systemNotifications'] ?? true,
      emailNotifications: json['emailNotifications'] ?? true,
      smsNotifications: json['smsNotifications'] ?? false,
      pushNotifications: json['pushNotifications'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderNotifications': orderNotifications,
      'paymentNotifications': paymentNotifications,
      'reviewNotifications': reviewNotifications,
      'promotionNotifications': promotionNotifications,
      'systemNotifications': systemNotifications,
      'emailNotifications': emailNotifications,
      'smsNotifications': smsNotifications,
      'pushNotifications': pushNotifications,
    };
  }

  NotificationSettings copyWith({
    bool? orderNotifications,
    bool? paymentNotifications,
    bool? reviewNotifications,
    bool? promotionNotifications,
    bool? systemNotifications,
    bool? emailNotifications,
    bool? smsNotifications,
    bool? pushNotifications,
  }) {
    return NotificationSettings(
      orderNotifications: orderNotifications ?? this.orderNotifications,
      paymentNotifications: paymentNotifications ?? this.paymentNotifications,
      reviewNotifications: reviewNotifications ?? this.reviewNotifications,
      promotionNotifications:
          promotionNotifications ?? this.promotionNotifications,
      systemNotifications: systemNotifications ?? this.systemNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
    );
  }
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.refunded:
        return 'Refunded';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.outForDelivery:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.teal;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.refunded:
        return Colors.grey;
    }
  }
}
