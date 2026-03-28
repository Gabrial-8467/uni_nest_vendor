class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final String status;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? data;
  final bool isActionable;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.status,
    required this.createdAt,
    this.readAt,
    this.data,
    this.isActionable = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'system',
      status: json['status'] ?? 'unread',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      data: json['data'] as Map<String, dynamic>?,
      isActionable: json['isActionable'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'data': data,
      'isActionable': isActionable,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    String? status,
    DateTime? createdAt,
    DateTime? readAt,
    Map<String, dynamic>? data,
    bool? isActionable,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      data: data ?? this.data,
      isActionable: isActionable ?? this.isActionable,
    );
  }

  bool get isRead => status == 'read';
  bool get isUnread => status == 'unread';
  bool get isArchived => status == 'archived';

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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, type: $type, status: $status)';
  }
}

class NotificationSettings {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final bool orderNotifications;
  final bool productNotifications;
  final bool paymentNotifications;
  final bool systemNotifications;
  final bool promotionalNotifications;
  final String quietHoursStart;
  final String quietHoursEnd;
  final bool quietHoursEnabled;

  NotificationSettings({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.smsEnabled = false,
    this.orderNotifications = true,
    this.productNotifications = true,
    this.paymentNotifications = true,
    this.systemNotifications = true,
    this.promotionalNotifications = false,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '08:00',
    this.quietHoursEnabled = false,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      pushEnabled: json['pushEnabled'] ?? true,
      emailEnabled: json['emailEnabled'] ?? true,
      smsEnabled: json['smsEnabled'] ?? false,
      orderNotifications: json['orderNotifications'] ?? true,
      productNotifications: json['productNotifications'] ?? true,
      paymentNotifications: json['paymentNotifications'] ?? true,
      systemNotifications: json['systemNotifications'] ?? true,
      promotionalNotifications: json['promotionalNotifications'] ?? false,
      quietHoursStart: json['quietHoursStart'] ?? '22:00',
      quietHoursEnd: json['quietHoursEnd'] ?? '08:00',
      quietHoursEnabled: json['quietHoursEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushEnabled': pushEnabled,
      'emailEnabled': emailEnabled,
      'smsEnabled': smsEnabled,
      'orderNotifications': orderNotifications,
      'productNotifications': productNotifications,
      'paymentNotifications': paymentNotifications,
      'systemNotifications': systemNotifications,
      'promotionalNotifications': promotionalNotifications,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'quietHoursEnabled': quietHoursEnabled,
    };
  }

  NotificationSettings copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
    bool? orderNotifications,
    bool? productNotifications,
    bool? paymentNotifications,
    bool? systemNotifications,
    bool? promotionalNotifications,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? quietHoursEnabled,
  }) {
    return NotificationSettings(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      orderNotifications: orderNotifications ?? this.orderNotifications,
      productNotifications: productNotifications ?? this.productNotifications,
      paymentNotifications: paymentNotifications ?? this.paymentNotifications,
      systemNotifications: systemNotifications ?? this.systemNotifications,
      promotionalNotifications: promotionalNotifications ?? this.promotionalNotifications,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
    );
  }
}
