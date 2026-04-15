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
  });

  final String id;
  final String name;
  final String email;
  final String businessName;
  final String phone;
  final String? businessType;
  final String? avatarUrl;
  final String? description;

  factory VendorProfile.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : <String, dynamic>{};
    final contactInfo = json['contactInfo'] is Map<String, dynamic>
        ? json['contactInfo'] as Map<String, dynamic>
        : <String, dynamic>{};
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
    );
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
  };
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
