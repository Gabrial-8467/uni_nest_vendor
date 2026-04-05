import 'package:flutter/foundation.dart';

/// Vendor Notification model that matches backend JSON exactly
@immutable
class VendorNotification {
  const VendorNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.data,
  });

  /// Notification ID from backend
  final String id;

  /// Notification title
  final String title;

  /// Notification message (mapped from backend "message" field)
  final String body;

  /// Notification type: "order" | "payment" | "system" | "promotion" | "vendor_approval" | "vendor_status"
  final String type;

  /// Read status from backend
  final bool isRead;

  /// Creation timestamp (parsed from ISO string)
  final DateTime createdAt;

  /// Optional metadata for additional context
  final Map<String, dynamic>? data;

  /// Creates VendorNotification from backend JSON response
  factory VendorNotification.fromJson(Map<String, dynamic> json) {
    try {
      return VendorNotification(
        id: json['_id'] as String? ?? json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['message'] as String? ?? json['body'] as String? ?? '',
        type: json['type'] as String? ?? 'system',
        isRead: json['isRead'] as bool? ?? false,
        createdAt: _parseDateTime(json['createdAt']),
        data: json['data'] as Map<String, dynamic>?,
      );
    } catch (e) {
      debugPrint('Error parsing VendorNotification: $e');
      // Return safe default on parsing error
      return VendorNotification(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Notification',
        body: json['message']?.toString() ?? json['body']?.toString() ?? '',
        type: json['type']?.toString() ?? 'system',
        isRead: json['isRead'] as bool? ?? false,
        createdAt: _parseDateTime(json['createdAt']),
        data: json['data'] as Map<String, dynamic>?,
      );
    }
  }

  /// Parses DateTime from various possible backend formats
  static DateTime _parseDateTime(dynamic dateTimeValue) {
    if (dateTimeValue == null) return DateTime.now();

    if (dateTimeValue is DateTime) return dateTimeValue;

    if (dateTimeValue is String) {
      try {
        // Try ISO 8601 format first
        return DateTime.parse(dateTimeValue);
      } catch (e) {
        debugPrint('Failed to parse ISO date: $dateTimeValue, error: $e');
        try {
          // Fallback to other common formats
          return DateTime.tryParse(dateTimeValue) ?? DateTime.now();
        } catch (e2) {
          debugPrint(
            'Failed to parse date completely: $dateTimeValue, error: $e2',
          );
          return DateTime.now();
        }
      }
    }

    return DateTime.now();
  }

  /// Converts model back to JSON (if needed for API calls)
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'id': id,
      'title': title,
      'message': body, // Map back to backend field name
      'body': body,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'data': data,
    };
  }

  /// Creates a copy with updated values
  VendorNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return VendorNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }

  /// Gets formatted time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  /// Check if notification is of order type
  bool get isOrder => type == 'order';

  /// Check if notification is of payment type
  bool get isPayment => type == 'payment';

  /// Check if notification is of system type
  bool get isSystem => type == 'system';

  /// Check if notification is of promotion type
  bool get isPromotion => type == 'promotion';

  /// Check if notification is of vendor approval type
  bool get isVendorApproval => type == 'vendor_approval';

  /// Check if notification is of vendor status type
  bool get isVendorStatus => type == 'vendor_status';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VendorNotification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'VendorNotification(id: $id, title: $title, type: $type, isRead: $isRead)';
  }
}
