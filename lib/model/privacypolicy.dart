class PrivacyPolicyResponse {
  bool? success;
  Data? data;

  PrivacyPolicyResponse({this.success, this.data});

  PrivacyPolicyResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? sId;
  String? title;
  String? content;
  bool? isPublished;
  Null? createdBy;
  String? publishedAt;
  String? createdAt;
  String? updatedAt;
  String? slug;
  int? iV;

  Data(
      {this.sId,
        this.title,
        this.content,
        this.isPublished,
        this.createdBy,
        this.publishedAt,
        this.createdAt,
        this.updatedAt,
        this.slug,
        this.iV});

  Data.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    title = json['title'];
    content = json['content'];
    isPublished = json['isPublished'];
    createdBy = json['createdBy'];
    publishedAt = json['publishedAt'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    slug = json['slug'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['title'] = this.title;
    data['content'] = this.content;
    data['isPublished'] = this.isPublished;
    data['createdBy'] = this.createdBy;
    data['publishedAt'] = this.publishedAt;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['slug'] = this.slug;
    data['__v'] = this.iV;
    return data;
  }
}