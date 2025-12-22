class HomeBannerResponse {
  final bool? success;
  final List<BannerList>? data;

  HomeBannerResponse({
    this.success,
    this.data,
  });

  HomeBannerResponse.fromJson(Map<String, dynamic> json)
      : success = json['success'] as bool?,
        data = (json['data'] as List?)?.map((dynamic e) => BannerList.fromJson(e as Map<String,dynamic>)).toList();

  Map<String, dynamic> toJson() => {
    'success' : success,
    'data' : data?.map((e) => e.toJson()).toList()
  };
}

class BannerList {
  final String? id;
  final String? bannerImage;
  final String? title;
  final String? description;
  final String? type;
  final bool? isActive;
  final int? displayOrder;
  final String? createdAt;
  final String? updatedAt;
  final int? v;

  BannerList({
    this.id,
    this.bannerImage,
    this.title,
    this.description,
    this.type,
    this.isActive,
    this.displayOrder,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  BannerList.fromJson(Map<String, dynamic> json)
      : id = json['_id'] as String?,
        bannerImage = json['banner_image'] as String?,
        title = json['title'] as String?,
        description = json['description'] as String?,
        type = json['type'] as String?,
        isActive = json['isActive'] as bool?,
        displayOrder = json['displayOrder'] as int?,
        createdAt = json['createdAt'] as String?,
        updatedAt = json['updatedAt'] as String?,
        v = json['__v'] as int?;

  Map<String, dynamic> toJson() => {
    '_id' : id,
    'banner_image' : bannerImage,
    'title' : title,
    'description' : description,
    'type' : type,
    'isActive' : isActive,
    'displayOrder' : displayOrder,
    'createdAt' : createdAt,
    'updatedAt' : updatedAt,
    '__v' : v
  };
}