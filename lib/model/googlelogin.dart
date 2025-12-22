class GoogleLoginResponse {
  final bool? success;
  final Data? data;

  GoogleLoginResponse({
    this.success,
    this.data,
  });

  GoogleLoginResponse.fromJson(Map<String, dynamic> json)
      : success = json['success'] as bool?,
        data = (json['data'] as Map<String,dynamic>?) != null ? Data.fromJson(json['data'] as Map<String,dynamic>) : null;

  Map<String, dynamic> toJson() => {
    'success' : success,
    'data' : data?.toJson()
  };
}

class Data {
  final User? user;
  final Tokens? tokens;

  Data({
    this.user,
    this.tokens,
  });

  Data.fromJson(Map<String, dynamic> json)
      : user = (json['user'] as Map<String,dynamic>?) != null ? User.fromJson(json['user'] as Map<String,dynamic>) : null,
        tokens = (json['tokens'] as Map<String,dynamic>?) != null ? Tokens.fromJson(json['tokens'] as Map<String,dynamic>) : null;

  Map<String, dynamic> toJson() => {
    'user' : user?.toJson(),
    'tokens' : tokens?.toJson()
  };
}

class User {
  final String? id;
  final String? name;
  final String? email;
  final String? firebaseId;
  final String? provider;
  final bool? isAdmin;

  User({
    this.id,
    this.name,
    this.email,
    this.firebaseId,
    this.provider,
    this.isAdmin,
  });

  User.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String?,
        name = json['name'] as String?,
        email = json['email'] as String?,
        firebaseId = json['firebaseId'] as String?,
        provider = json['provider'] as String?,
        isAdmin = json['isAdmin'] as bool?;

  Map<String, dynamic> toJson() => {
    'id' : id,
    'name' : name,
    'email' : email,
    'firebaseId' : firebaseId,
    'provider' : provider,
    'isAdmin' : isAdmin
  };
}

class Tokens {
  final Access? access;

  Tokens({
    this.access,
  });

  Tokens.fromJson(Map<String, dynamic> json)
      : access = (json['access'] as Map<String,dynamic>?) != null ? Access.fromJson(json['access'] as Map<String,dynamic>) : null;

  Map<String, dynamic> toJson() => {
    'access' : access?.toJson()
  };
}

class Access {
  final String? token;
  final String? expires;

  Access({
    this.token,
    this.expires,
  });

  Access.fromJson(Map<String, dynamic> json)
      : token = json['token'] as String?,
        expires = json['expires'] as String?;

  Map<String, dynamic> toJson() => {
    'token' : token,
    'expires' : expires
  };
}