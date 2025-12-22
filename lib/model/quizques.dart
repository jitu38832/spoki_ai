class QuizQuesResponse {
  final bool? success;
  final String? message;
  final Data? data;

  QuizQuesResponse({
    this.success,
    this.message,
    this.data,
  });

  QuizQuesResponse.fromJson(Map<String, dynamic> json)
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
  final List<Questions>? questions;
  final Metadata? metadata;
  final InputParams? inputParams;
  final String? id;
  final Story? story;

  Data({
    this.questions,
    this.metadata,
    this.inputParams,
    this.id,
    this.story,
  });

  Data.fromJson(Map<String, dynamic> json)
      : questions = (json['questions'] as List?)?.map((dynamic e) => Questions.fromJson(e as Map<String,dynamic>)).toList(),
        metadata = (json['metadata'] as Map<String,dynamic>?) != null ? Metadata.fromJson(json['metadata'] as Map<String,dynamic>) : null,
        inputParams = (json['inputParams'] as Map<String,dynamic>?) != null ? InputParams.fromJson(json['inputParams'] as Map<String,dynamic>) : null,
        id = json['id'] as String?,
        story = (json['story'] as Map<String,dynamic>?) != null ? Story.fromJson(json['story'] as Map<String,dynamic>) : null;

  Map<String, dynamic> toJson() => {
    'questions' : questions?.map((e) => e.toJson()).toList(),
    'metadata' : metadata?.toJson(),
    'inputParams' : inputParams?.toJson(),
    'id' : id,
    'story' : story?.toJson()
  };
}

class Questions {
  final String? question;
  final List<String>? options;
  final String? correctAnswer;
  final List<Explanations>? explanations;

  Questions({
    this.question,
    this.options,
    this.correctAnswer,
    this.explanations,
  });

  Questions.fromJson(Map<String, dynamic> json)
      : question = json['question'] as String?,
        options = (json['options'] as List?)?.map((dynamic e) => e as String).toList(),
        correctAnswer = json['correctAnswer'] as String?,
        explanations = (json['explanations'] as List?)?.map((dynamic e) => Explanations.fromJson(e as Map<String,dynamic>)).toList();

  Map<String, dynamic> toJson() => {
    'question' : question,
    'options' : options,
    'correctAnswer' : correctAnswer,
    'explanations' : explanations?.map((e) => e.toJson()).toList()
  };
}

class Explanations {
  final String? option;
  final String? explanation;
  final bool? isCorrect;

  Explanations({
    this.option,
    this.explanation,
    this.isCorrect,
  });

  Explanations.fromJson(Map<String, dynamic> json)
      : option = json['option'] as String?,
        explanation = json['explanation'] as String?,
        isCorrect = json['isCorrect'] as bool?;

  Map<String, dynamic> toJson() => {
    'option' : option,
    'explanation' : explanation,
    'isCorrect' : isCorrect
  };
}

class Metadata {
  final String? title;
  final String? difficulty;
  final int? numberOfQuestions;

  Metadata({
    this.title,
    this.difficulty,
    this.numberOfQuestions,
  });

  Metadata.fromJson(Map<String, dynamic> json)
      : title = json['title'] as String?,
        difficulty = json['difficulty'] as String?,
        numberOfQuestions = json['numberOfQuestions'] as int?;

  Map<String, dynamic> toJson() => {
    'title' : title,
    'difficulty' : difficulty,
    'numberOfQuestions' : numberOfQuestions
  };
}

class InputParams {
  final String? storyId;
  final String? difficulty;
  final int? numberOfQuestions;

  InputParams({
    this.storyId,
    this.difficulty,
    this.numberOfQuestions,
  });

  InputParams.fromJson(Map<String, dynamic> json)
      : storyId = json['storyId'] as String?,
        difficulty = json['difficulty'] as String?,
        numberOfQuestions = json['numberOfQuestions'] as int?;

  Map<String, dynamic> toJson() => {
    'storyId' : storyId,
    'difficulty' : difficulty,
    'numberOfQuestions' : numberOfQuestions
  };
}

class Story {
  final String? id;
  final String? title;

  Story({
    this.id,
    this.title,
  });

  Story.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String?,
        title = json['title'] as String?;

  Map<String, dynamic> toJson() => {
    'id' : id,
    'title' : title
  };
}