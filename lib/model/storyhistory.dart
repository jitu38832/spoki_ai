class StoryHistoryResponse {
  final bool? success;
  final List<StoryList>? data;

  StoryHistoryResponse({
    this.success,
    this.data,
  });

  StoryHistoryResponse.fromJson(Map<String, dynamic> json)
      : success = json['success'] as bool?,
        data = (json['data'] as List?)?.map((dynamic e) => StoryList.fromJson(e as Map<String,dynamic>)).toList();

  Map<String, dynamic> toJson() => {
    'success' : success,
    'data' : data?.map((e) => e.toJson()).toList()
  };
}

class StoryList {
  final Metadata? metadata;
  final InputParams? inputParams;
  final String? id;
  final String? user;
  final String? story;
  final String? createdAt;
  final String? updatedAt;
  final int? v;

  StoryList({
    this.metadata,
    this.inputParams,
    this.id,
    this.user,
    this.story,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  StoryList.fromJson(Map<String, dynamic> json)
      : metadata = (json['metadata'] as Map<String,dynamic>?) != null ? Metadata.fromJson(json['metadata'] as Map<String,dynamic>) : null,
        inputParams = (json['inputParams'] as Map<String,dynamic>?) != null ? InputParams.fromJson(json['inputParams'] as Map<String,dynamic>) : null,
        id = json['_id'] as String?,
        user = json['user'] as String?,
        story = json['story'] as String?,
        createdAt = json['createdAt'] as String?,
        updatedAt = json['updatedAt'] as String?,
        v = json['__v'] as int?;

  Map<String, dynamic> toJson() => {
    'metadata' : metadata?.toJson(),
    'inputParams' : inputParams?.toJson(),
    '_id' : id,
    'user' : user,
    'story' : story,
    'createdAt' : createdAt,
    'updatedAt' : updatedAt,
    '__v' : v
  };
}

class Metadata {
  final String? title;
  final int? wordCount;
  final String? genre;
  final String? style;
  final String? learningLevel;
  final List<String>? themes;
  final List<String>? characters;

  Metadata({
    this.title,
    this.wordCount,
    this.genre,
    this.style,
    this.learningLevel,
    this.themes,
    this.characters,
  });

  Metadata.fromJson(Map<String, dynamic> json)
      : title = json['title'] as String?,
        wordCount = json['wordCount'] as int?,
        genre = json['genre'] as String?,
        style = json['style'] as String?,
        learningLevel = json['learningLevel'] as String?,
        themes = (json['themes'] as List?)?.map((dynamic e) => e as String).toList(),
        characters = (json['characters'] as List?)?.map((dynamic e) => e as String).toList();

  Map<String, dynamic> toJson() => {
    'title' : title,
    'wordCount' : wordCount,
    'genre' : genre,
    'style' : style,
    'learningLevel' : learningLevel,
    'themes' : themes,
    'characters' : characters
  };
}

class InputParams {
  final String? stroyDescription;
  final String? storyLength;
  final String? genre;
  final String? style;
  final String? learningLevel;

  InputParams({
    this.stroyDescription,
    this.storyLength,
    this.genre,
    this.style,
    this.learningLevel,
  });

  InputParams.fromJson(Map<String, dynamic> json)
      : stroyDescription = json['stroyDescription'] as String?,
        storyLength = json['storyLength'] as String?,
        genre = json['genre'] as String?,
        style = json['style'] as String?,
        learningLevel = json['learningLevel'] as String?;

  Map<String, dynamic> toJson() => {
    'stroyDescription' : stroyDescription,
    'storyLength' : storyLength,
    'genre' : genre,
    'style' : style,
    'learningLevel' : learningLevel
  };
}