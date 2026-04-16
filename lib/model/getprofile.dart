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
  final String? gender;
  final int? age;
  final String? englishLevel;
  final String? spokenLanguage;

  Data({
    this.name,
    this.email,
    this.firebaseId,
    this.provider,
    this.isAdmin,
    this.gender,
    this.age,
    this.englishLevel,
    this.spokenLanguage,
  });

  Data.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String?,
        email = json['email'] as String?,
        firebaseId = json['firebaseId'] as String?,
        provider = json['provider'] as String?,
        isAdmin = json['isAdmin'] as bool?,
        gender = json['gender'] as String?,
        age = _parseAge(json['age']),
        englishLevel = json['englishLevel'] as String? ??
            json['english_level'] as String?,
        spokenLanguage = json['spokenLanguage'] as String? ??
            json['spoken_language'] as String? ??
            json['language'] as String?;

  static int? _parseAge(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'firebaseId': firebaseId,
        'provider': provider,
        'isAdmin': isAdmin,
        'gender': gender,
        'age': age,
        'englishLevel': englishLevel,
        'spokenLanguage': spokenLanguage,
      };
}

/// True when `users/me` [data] is missing or core fields are blank.
///
/// [name] and [email] are always required. Gender, age, English level, and
/// spoken language are required only if the API already sends **any** of those
/// fields (so older backends that omit them still count as complete).
bool profileNeedsCompletion(Data? data) {
  if (data == null) return true;
  bool blank(String? v) => v == null || v.trim().isEmpty;
  if (blank(data.name) || blank(data.email)) return true;

  final hasAnyExtended = !blank(data.gender) ||
      data.age != null ||
      !blank(data.englishLevel) ||
      !blank(data.spokenLanguage);

  if (hasAnyExtended) {
    if (blank(data.gender) ||
        data.age == null ||
        data.age! < 1 ||
        blank(data.englishLevel) ||
        blank(data.spokenLanguage)) {
      return true;
    }
  }
  return false;
}