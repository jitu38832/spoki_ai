class GenerateStoryResponse {
  final bool? success;
  final String? message;
  final Data? data;

  GenerateStoryResponse({
    this.success,
    this.message,
    this.data,
  });

  GenerateStoryResponse.fromJson(Map<String, dynamic> json)
      : success = json['success'] as bool?,
        message = json['message'] as String?,
        data = (json['data'] as Map<String,dynamic>?) != null ? Data.fromJson(json['data'] as Map<String,dynamic>) : null;

  Map<String, dynamic> toJson() => {
    'success' : success,
    'message' : message,
    'data' : data?.toJson()
  };
}

class Data {
  final String? story;
  final Metadata? metadata;
  final InputParams? inputParams;
  final String? id;

  Data({
    this.story,
    this.metadata,
    this.inputParams,
    this.id,
  });

  Data.fromJson(Map<String, dynamic> json)
      : story = json['story'] as String?,
        metadata = (json['metadata'] as Map<String,dynamic>?) != null ? Metadata.fromJson(json['metadata'] as Map<String,dynamic>) : null,
        inputParams = (json['inputParams'] as Map<String,dynamic>?) != null ? InputParams.fromJson(json['inputParams'] as Map<String,dynamic>) : null,
        id = json['id'] as String?;

  Map<String, dynamic> toJson() => {
    'story' : story,
    'metadata' : metadata?.toJson(),
    'inputParams' : inputParams?.toJson(),
    'id' : id
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