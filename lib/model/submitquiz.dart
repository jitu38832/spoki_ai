class SubmitQuizResponse {
  final bool? success;
  final String? message;
  final Data? data;

  SubmitQuizResponse({
    this.success,
    this.message,
    this.data,
  });

  SubmitQuizResponse.fromJson(Map<String, dynamic> json)
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
  final String? quizId;
  final Score? score;
  final List<UserAnswers>? userAnswers;

  Data({
    this.quizId,
    this.score,
    this.userAnswers,
  });

  Data.fromJson(Map<String, dynamic> json)
      : quizId = json['quizId'] as String?,
        score = (json['score'] as Map<String,dynamic>?) != null ? Score.fromJson(json['score'] as Map<String,dynamic>) : null,
        userAnswers = (json['userAnswers'] as List?)?.map((dynamic e) => UserAnswers.fromJson(e as Map<String,dynamic>)).toList();

  Map<String, dynamic> toJson() => {
    'quizId' : quizId,
    'score' : score?.toJson(),
    'userAnswers' : userAnswers?.map((e) => e.toJson()).toList()
  };
}

class Score {
  final int? totalQuestions;
  final int? correctAnswers;
  final int? percentage;
  final String? message;
  final String? submittedAt;

  Score({
    this.totalQuestions,
    this.correctAnswers,
    this.percentage,
    this.message,
    this.submittedAt,
  });

  Score.fromJson(Map<String, dynamic> json)
      : totalQuestions = json['totalQuestions'] as int?,
        correctAnswers = json['correctAnswers'] as int?,
        percentage = json['percentage'] as int?,
        message = json['message'] as String?,
        submittedAt = json['submittedAt'] as String?;

  Map<String, dynamic> toJson() => {
    'totalQuestions' : totalQuestions,
    'correctAnswers' : correctAnswers,
    'percentage' : percentage,
    'message' : message,
    'submittedAt' : submittedAt
  };
}

class UserAnswers {
  final int? questionIndex;
  final String? userAnswer;
  final bool? isCorrect;

  UserAnswers({
    this.questionIndex,
    this.userAnswer,
    this.isCorrect,
  });

  UserAnswers.fromJson(Map<String, dynamic> json)
      : questionIndex = json['questionIndex'] as int?,
        userAnswer = json['userAnswer'] as String?,
        isCorrect = json['isCorrect'] as bool?;

  Map<String, dynamic> toJson() => {
    'questionIndex' : questionIndex,
    'userAnswer' : userAnswer,
    'isCorrect' : isCorrect
  };
}