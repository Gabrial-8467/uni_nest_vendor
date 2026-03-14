import 'package:flutter/material.dart';

// Vendor Models
class Vendor {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String businessName;
  final String businessType;
  final String location;
  final double rating;
  final bool isActive;
  final DateTime createdAt;
  final String? profileImage;
  final Map<String, dynamic> businessDetails;

  Vendor({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.businessName,
    required this.businessType,
    required this.location,
    required this.rating,
    required this.isActive,
    required this.createdAt,
    this.profileImage,
    required this.businessDetails,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      businessName: json['businessName'] ?? '',
      businessType: json['businessType'] ?? '',
      location: json['location'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      isActive: json['isActive'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      profileImage: json['profileImage'],
      businessDetails: json['businessDetails'] ?? {},
    );
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
      'rating': rating,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'profileImage': profileImage,
      'businessDetails': businessDetails,
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
  final bool isFeatured;

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
    this.isFeatured = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      vendorId: json['vendorId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      category: json['category'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      isAvailable: json['isAvailable'] ?? true,
      stockQuantity: json['stockQuantity'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      nutritionalInfo: json['nutritionalInfo'] ?? {},
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      discountPercentage: json['discountPercentage']?.toDouble(),
      isFeatured: json['isFeatured'] ?? false,
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
      'tags': tags,
      'nutritionalInfo': nutritionalInfo,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'discountPercentage': discountPercentage,
      'isFeatured': isFeatured,
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
    bool? isFeatured,
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
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }
}

class Order {
  final String id;
  final String vendorId;
  final String customerId;
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
    required this.vendorId,
    required this.customerId,
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

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      vendorId: json['vendorId'] ?? '',
      customerId: json['customerId'] ?? '',
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromJson(item))
          .toList() ?? [],
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0.0).toDouble(),
      finalAmount: (json['finalAmount'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'pending',
      paymentMethod: json['paymentMethod'] ?? '',
      paymentStatus: json['paymentStatus'] ?? 'pending',
      deliveryAddress: json['deliveryAddress'] ?? {},
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
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
      'vendorId': vendorId,
      'customerId': customerId,
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
    return OrderItem(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      productImage: json['productImage'] ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice: (json['unitPrice'] ?? 0.0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
      customization: json['customization'] ?? {},
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
      periodStart: DateTime.parse(json['periodStart'] ?? DateTime.now().toIso8601String()),
      periodEnd: DateTime.parse(json['periodEnd'] ?? DateTime.now().toIso8601String()),
      totalRevenue: (json['totalRevenue'] ?? 0.0).toDouble(),
      totalOrders: json['totalOrders'] ?? 0,
      totalCustomers: json['totalCustomers'] ?? 0,
      averageOrderValue: (json['averageOrderValue'] ?? 0.0).toDouble(),
      salesByCategory: Map<String, int>.from(json['salesByCategory'] ?? {}),
      topProducts: (json['topProducts'] as List<dynamic>?)
          ?.map((product) => Product.fromJson(product))
          .toList() ?? [],
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
  refunded
}

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  refunded,
  partiallyRefunded
}

enum PaymentMethod {
  cash,
  card,
  upi,
  wallet,
  netBanking
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
