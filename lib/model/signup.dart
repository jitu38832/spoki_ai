class SignUpResponse {
  final SignUpUser user;
  final String accessToken;

  SignUpResponse({
    required this.user,
    required this.accessToken,
  });

  factory SignUpResponse.fromJson(Map<String, dynamic> json) {
    return SignUpResponse(
      user: SignUpUser.fromJson(json['user']),
      accessToken: json['accessToken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'accessToken': accessToken,
    };
  }
}
class SignUpUser {
  final String id;
  final String name;
  final String email;
  final String firebaseId;

  SignUpUser({
    required this.id,
    required this.name,
    required this.email,
    required this.firebaseId,
  });

  factory SignUpUser.fromJson(Map<String, dynamic> json) {
    return SignUpUser(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      firebaseId: json['firebaseId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'firebaseId': firebaseId,
    };
  }
}

