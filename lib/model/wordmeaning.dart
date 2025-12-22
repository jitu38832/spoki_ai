class WordMeaningResponse {
  final bool? success;
  final Data? data;

  WordMeaningResponse({
    this.success,
    this.data,
  });

  WordMeaningResponse.fromJson(Map<String, dynamic> json)
      : success = json['success'] as bool?,
        data = (json['data'] as Map<String,dynamic>?) != null ? Data.fromJson(json['data'] as Map<String,dynamic>) : null;

  Map<String, dynamic> toJson() => {
    'success' : success,
    'data' : data?.toJson()
  };
}

class Data {
  final String? word;
  final String? phonetic;
  final List<Meanings>? meanings;

  Data({
    this.word,
    this.phonetic,
    this.meanings,
  });

  Data.fromJson(Map<String, dynamic> json)
      : word = json['word'] as String?,
        phonetic = json['phonetic'] as String?,
        meanings = (json['meanings'] as List?)?.map((dynamic e) => Meanings.fromJson(e as Map<String,dynamic>)).toList();

  Map<String, dynamic> toJson() => {
    'word' : word,
    'phonetic' : phonetic,
    'meanings' : meanings?.map((e) => e.toJson()).toList()
  };
}

class Meanings {
  final String? partOfSpeech;
  final String? definition;
  final dynamic example;

  Meanings({
    this.partOfSpeech,
    this.definition,
    this.example,
  });

  Meanings.fromJson(Map<String, dynamic> json)
      : partOfSpeech = json['partOfSpeech'] as String?,
        definition = json['definition'] as String?,
        example = json['example'];

  Map<String, dynamic> toJson() => {
    'partOfSpeech' : partOfSpeech,
    'definition' : definition,
    'example' : example
  };
}