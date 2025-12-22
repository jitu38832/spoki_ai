class GetProfileResponse {
  final bool? success;
  final Data? data;

  GetProfileResponse({
    this.success,
    this.data,
  });

  GetProfileResponse.fromJson(Map<String, dynamic> json)
      : success = json['success'] as bool?,
        data = (json['data'] as Map<String,dynamic>?) != null ? Data.fromJson(json['data'] as Map<String,dynamic>) : null;

  Map<String, dynamic> toJson() => {
    'success' : success,
    'data' : data?.toJson()
  };
}

class Data {
  final String? name;
  final String? email;
  final String? firebaseId;
  final String? provider;
  final bool? isAdmin;

  Data({
    this.name,
    this.email,
    this.firebaseId,
    this.provider,
    this.isAdmin,
  });

  Data.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String?,
        email = json['email'] as String?,
        firebaseId = json['firebaseId'] as String?,
        provider = json['provider'] as String?,
        isAdmin = json['isAdmin'] as bool?;

  Map<String, dynamic> toJson() => {
    'name' : name,
    'email' : email,
    'firebaseId' : firebaseId,
    'provider' : provider,
    'isAdmin' : isAdmin
  };
}