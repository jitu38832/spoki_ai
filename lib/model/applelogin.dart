class AppleLoginResponse {
  final bool success;
  final String message;
  final String token;
  final AppleUser user;

  AppleLoginResponse({
    required this.success,
    required this.message,
    required this.token,
    required this.user,
  });

  factory AppleLoginResponse.fromJson(Map<String, dynamic> json) {
    return AppleLoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      token: json['token'] ?? '',
      user: AppleUser.fromJson(json['user'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'token': token,
      'user': user.toJson(),
    };
  }
}

class AppleUser {
  final String id;
  final String name;
  final String email;
  final String provider;
  final String appleId;
  final bool isAdmin;
  final int status;
  final List<dynamic> spokenLanguages;
  final String firebaseId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int v;

  AppleUser({
    required this.id,
    required this.name,
    required this.email,
    required this.provider,
    required this.appleId,
    required this.isAdmin,
    required this.status,
    required this.spokenLanguages,
    required this.firebaseId,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory AppleUser.fromJson(Map<String, dynamic> json) {
    return AppleUser(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      provider: json['provider'] ?? '',
      appleId: json['appleId'] ?? '',
      isAdmin: json['isAdmin'] ?? false,
      status: json['status'] ?? 0,
      spokenLanguages: json['spokenLanguages'] ?? [],
      firebaseId: json['firebaseId'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      v: json['__v'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'provider': provider,
      'appleId': appleId,
      'isAdmin': isAdmin,
      'status': status,
      'spokenLanguages': spokenLanguages,
      'firebaseId': firebaseId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      '__v': v,
    };
  }
}