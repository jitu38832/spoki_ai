class QuizHistoryResponse {
  final bool? success;
  final Data? data;

  QuizHistoryResponse({
    this.success,
    this.data,
  });

  QuizHistoryResponse.fromJson(Map<String, dynamic> json)
      : success = json['success'] as bool?,
        data = (json['data'] as Map<String,dynamic>?) != null ? Data.fromJson(json['data'] as Map<String,dynamic>) : null;

  Map<String, dynamic> toJson() => {
    'success' : success,
    'data' : data?.toJson()
  };
}

class Data {
  final Metadata? metadata;
  final InputParams? inputParams;
  final Score? score;
  final String? id;
  final String? user;
  final Story? story;
  final List<QuestionsHistory>? questions;
  final String? createdAt;
  final String? updatedAt;
  final int? v;

  Data({
    this.metadata,
    this.inputParams,
    this.score,
    this.id,
    this.user,
    this.story,
    this.questions,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  Data.fromJson(Map<String, dynamic> json)
      : metadata = (json['metadata'] as Map<String,dynamic>?) != null ? Metadata.fromJson(json['metadata'] as Map<String,dynamic>) : null,
        inputParams = (json['inputParams'] as Map<String,dynamic>?) != null ? InputParams.fromJson(json['inputParams'] as Map<String,dynamic>) : null,
        score = (json['score'] as Map<String,dynamic>?) != null ? Score.fromJson(json['score'] as Map<String,dynamic>) : null,
        id = json['_id'] as String?,
        user = json['user'] as String?,
        story = (json['story'] as Map<String,dynamic>?) != null ? Story.fromJson(json['story'] as Map<String,dynamic>) : null,
        questions = (json['questions'] as List?)?.map((dynamic e) => QuestionsHistory.fromJson(e as Map<String,dynamic>)).toList(),
        createdAt = json['createdAt'] as String?,
        updatedAt = json['updatedAt'] as String?,
        v = json['__v'] as int?;

  Map<String, dynamic> toJson() => {
    'metadata' : metadata?.toJson(),
    'inputParams' : inputParams?.toJson(),
    'score' : score?.toJson(),
    '_id' : id,
    'user' : user,
    'story' : story?.toJson(),
    'questions' : questions?.map((e) => e.toJson()).toList(),
    'createdAt' : createdAt,
    'updatedAt' : updatedAt,
    '__v' : v
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

class Score {
  final int? totalQuestions;
  final int? correctAnswers;
  final int? percentage;
  final String? message;
  final String? submittedAt;
  final List<UserAnswers>? userAnswers;

  Score({
    this.totalQuestions,
    this.correctAnswers,
    this.percentage,
    this.message,
    this.submittedAt,
    this.userAnswers,
  });

  Score.fromJson(Map<String, dynamic> json)
      : totalQuestions = json['totalQuestions'] as int?,
        correctAnswers = json['correctAnswers'] as int?,
        percentage = json['percentage'] as int?,
        message = json['message'] as String?,
        submittedAt = json['submittedAt'] as String?,
        userAnswers = (json['userAnswers'] as List?)?.map((dynamic e) => UserAnswers.fromJson(e as Map<String,dynamic>)).toList();

  Map<String, dynamic> toJson() => {
    'totalQuestions' : totalQuestions,
    'correctAnswers' : correctAnswers,
    'percentage' : percentage,
    'message' : message,
    'submittedAt' : submittedAt,
    'userAnswers' : userAnswers?.map((e) => e.toJson()).toList()
  };
}

class UserAnswers {
  final int? questionIndex;
  final String? userAnswer;
  final bool? isCorrect;
  final String? id;

  UserAnswers({
    this.questionIndex,
    this.userAnswer,
    this.isCorrect,
    this.id,
  });

  UserAnswers.fromJson(Map<String, dynamic> json)
      : questionIndex = json['questionIndex'] as int?,
        userAnswer = json['userAnswer'] as String?,
        isCorrect = json['isCorrect'] as bool?,
        id = json['_id'] as String?;

  Map<String, dynamic> toJson() => {
    'questionIndex' : questionIndex,
    'userAnswer' : userAnswer,
    'isCorrect' : isCorrect,
    '_id' : id
  };
}

class Story {
  final Metadata? metadata;
  final String? id;

  Story({
    this.metadata,
    this.id,
  });

  Story.fromJson(Map<String, dynamic> json)
      : metadata = (json['metadata'] as Map<String,dynamic>?) != null ? Metadata.fromJson(json['metadata'] as Map<String,dynamic>) : null,
        id = json['_id'] as String?;

  Map<String, dynamic> toJson() => {
    'metadata' : metadata?.toJson(),
    '_id' : id
  };
}
class QuestionsHistory {
  final String? question;
  final List<String>? options;
  final String? correctAnswer;
  final String? type;
  final List<Explanations>? explanations;
  final String? id;

  QuestionsHistory({
    this.question,
    this.options,
    this.correctAnswer,
    this.type,
    this.explanations,
    this.id,
  });

  QuestionsHistory.fromJson(Map<String, dynamic> json)
      : question = json['question'] as String?,
        options = (json['options'] as List?)?.map((dynamic e) => e as String).toList(),
        correctAnswer = json['correctAnswer'] as String?,
        type = json['type'] as String?,
        explanations = (json['explanations'] as List?)?.map((dynamic e) => Explanations.fromJson(e as Map<String,dynamic>)).toList(),
        id = json['_id'] as String?;

  Map<String, dynamic> toJson() => {
    'question' : question,
    'options' : options,
    'correctAnswer' : correctAnswer,
    'type' : type,
    'explanations' : explanations?.map((e) => e.toJson()).toList(),
    '_id' : id
  };
}

  class Explanations {
  final String? option;
  final String? explanation;
  final bool? isCorrect;
  final String? id;

  Explanations({
    this.option,
    this.explanation,
    this.isCorrect,
    this.id,
  });

  Explanations.fromJson(Map<String, dynamic> json)
      : option = json['option'] as String?,
        explanation = json['explanation'] as String?,
        isCorrect = json['isCorrect'] as bool?,
        id = json['_id'] as String?;

  Map<String, dynamic> toJson() => {
    'option' : option,
    'explanation' : explanation,
    'isCorrect' : isCorrect,
    '_id' : id
  };
}