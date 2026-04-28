class PayoutMethod {
  PayoutMethod({
    required this.type,
    required this.accountHolderName,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.upiId,
    this.isVerified = false,
  });

  final String type; // 'bank_transfer', 'upi'
  final String accountHolderName;
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? upiId;
  final bool isVerified;

  bool get isBankTransfer => type == 'bank_transfer';
  bool get isUpi => type == 'upi';

  String get maskedAccountNumber {
    if (accountNumber == null || accountNumber!.length < 4) {
      return accountNumber ?? '';
    }
    final last4 = accountNumber!.substring(accountNumber!.length - 4);
    return '**** **** $last4';
  }

  String get displayLabel {
    if (isUpi && upiId != null) return upiId!;
    if (bankName != null) return bankName!;
    return 'Bank Account';
  }

  factory PayoutMethod.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] ?? 'bank_transfer').toString();
    return PayoutMethod(
      type: type,
      accountHolderName:
          (json['accountHolderName'] ?? json['accountHolder'] ?? '').toString(),
      bankName: json['bankName']?.toString(),
      accountNumber:
          json['accountNumber']?.toString() ?? json['account']?.toString(),
      ifscCode: json['ifscCode']?.toString() ?? json['ifsc']?.toString(),
      upiId: json['upiId']?.toString() ?? json['upi']?.toString(),
      isVerified: json['isVerified'] == true || json['verified'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'accountHolderName': accountHolderName,
    'bankName': bankName,
    'accountNumber': accountNumber,
    'ifscCode': ifscCode,
    'upiId': upiId,
    'isVerified': isVerified,
  };
}

class VendorProfile {
  VendorProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.businessName,
    required this.phone,
    this.businessType,
    this.avatarUrl,
    this.description,
    this.isOpen = true,
    this.payoutMethod,
  });

  final String id;
  final String name;
  final String email;
  final String businessName;
  final String phone;
  final String? businessType;
  final String? avatarUrl;
  final String? description;
  // Nullable to avoid hot-restart/runtime layout issues when this field is newly
  // introduced (old in-memory instances can surface it as null).
  final bool? isOpen;
  final PayoutMethod? payoutMethod;

  bool get isOpenValue => isOpen ?? true;

  factory VendorProfile.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : <String, dynamic>{};
    final contactInfo = json['contactInfo'] is Map<String, dynamic>
        ? json['contactInfo'] as Map<String, dynamic>
        : <String, dynamic>{};
    final businessDetails = json['businessDetails'] is Map<String, dynamic>
        ? json['businessDetails'] as Map<String, dynamic>
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
    return VendorProfile(
      id: (json['_id'] ?? json['id'] ?? user['_id'] ?? '').toString(),
      name: (json['name'] ?? user['name'] ?? '').toString(),
      email: (json['email'] ?? contactInfo['email'] ?? user['email'] ?? '')
          .toString(),
      businessName: (json['businessName'] ?? '').toString(),
      phone: (json['phone'] ?? contactInfo['phone'] ?? user['phone'] ?? '')
          .toString(),
      businessType: (json['businessType'] ?? '').toString().trim().isEmpty
          ? null
          : (json['businessType'] ?? '').toString(),
      avatarUrl:
          (user['avatar'] ?? json['avatar'] ?? json['profileImage'] ?? '')
              .toString()
              .trim()
              .isEmpty
          ? null
          : (user['avatar'] ?? json['avatar'] ?? json['profileImage'])
                .toString(),
      description: (json['description'] ?? '').toString().trim().isEmpty
          ? null
          : (json['description'] ?? '').toString(),
      isOpen: _toBool(rawOpenStatus, defaultValue: true),
      payoutMethod: json['payoutMethod'] is Map<String, dynamic>
          ? PayoutMethod.fromJson(
              Map<String, dynamic>.from(json['payoutMethod']),
            )
          : json['bankDetails'] is Map<String, dynamic>
          ? PayoutMethod.fromJson({
              ...Map<String, dynamic>.from(json['bankDetails']),
              'type': 'bank_transfer',
            })
          : null,
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'businessName': businessName,
    'phone': phone,
    'businessType': businessType,
    'avatarUrl': avatarUrl,
    'description': description,
    'isOpen': isOpenValue,
    'isAcceptingOrders': isOpenValue,
    'payoutMethod': payoutMethod?.toJson(),
  };

  VendorProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? businessName,
    String? phone,
    String? businessType,
    String? avatarUrl,
    String? description,
    bool? isOpen,
    PayoutMethod? payoutMethod,
  }) {
    return VendorProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      businessName: businessName ?? this.businessName,
      phone: phone ?? this.phone,
      businessType: businessType ?? this.businessType,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      description: description ?? this.description,
      isOpen: isOpen ?? isOpenValue,
      payoutMethod: payoutMethod ?? this.payoutMethod,
    );
  }
}

class AuthSession {
  AuthSession({
    required this.accessToken,
    required this.profile,
    this.refreshToken,
  });

  final String accessToken;
  final String? refreshToken;
  final VendorProfile profile;

  factory AuthSession.fromLoginResponse(Map<String, dynamic> response) {
    final data = response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : <String, dynamic>{};
    final tokens = data['tokens'] is Map<String, dynamic>
        ? data['tokens'] as Map<String, dynamic>
        : <String, dynamic>{};
    final user = data['user'] is Map<String, dynamic>
        ? data['user'] as Map<String, dynamic>
        : <String, dynamic>{};
    final vendor = response['vendor'] is Map<String, dynamic>
        ? response['vendor'] as Map<String, dynamic>
        : data['vendor'] is Map<String, dynamic>
        ? data['vendor'] as Map<String, dynamic>
        : <String, dynamic>{};

    final accessToken =
        (tokens['token'] ??
                tokens['accessToken'] ??
                data['token'] ??
                data['accessToken'] ??
                data['access_token'] ??
                response['token'] ??
                response['accessToken'] ??
                response['access_token'] ??
                '')
            .toString();
    if (accessToken.isEmpty) {
      throw const FormatException('Missing access token in login response');
    }

    return AuthSession(
      accessToken: accessToken,
      refreshToken:
          (tokens['refreshToken'] ??
                  tokens['refresh_token'] ??
                  data['refreshToken'] ??
                  data['refresh_token'] ??
                  response['refreshToken'] ??
                  response['refresh_token'])
              ?.toString(),
      profile: VendorProfile.fromJson({
        ...vendor,
        if (user.isNotEmpty) 'user': user,
      }),
    );
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: (json['accessToken'] ?? '').toString(),
      refreshToken: json['refreshToken']?.toString(),
      profile: VendorProfile.fromJson(
        Map<String, dynamic>.from(json['profile'] ?? const {}),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'profile': profile.toJson(),
  };
}
