
import 'package:equatable/equatable.dart';

import '../repository/response_status.dart';

enum AppStatus {
  initial,
  loginLoading,
  loginSuccess,
  loginError,

  checkStatusLoading,
  checkStatusSuccess,
  checkStatusError,



  generateStoryLoading,
  generateStorySuccess,
  generateStoryError,


  signupLoading,
  signupSuccess,
  signupError,

  storyHistoryLoading,
  storyHistorySuccess,
  storyHistoryError,



  historyDescriptionLoading,
  historyDescriptionSuccess,
  historyDescriptionError,


  getProfileLoading,
  getProfileSuccess,
  getProfileError,


  getQuizQuesLoading,
  getQuizQuesSuccess,
  getQuizQuesError,


  submitQuizLoading,
  submitQuizError,
  submitQuizSuccess,


  wordMeaningLoading,
  wordMeaningError,
  wordMeaningSuccess,


  bannerListLoading,
  bannerListError,
  bannerListSuccess,




 deleteStoryLoading,
  deleteStoryError,
  deleteStorySuccess,




  quizHistoryLoading,
  quizHistoryError,
  quizHistorySuccess,

  privacyPolicyLoading,
  privacyPolicyError,
  privacyPolicySuccess,

  submitFeedbackLoading,
  submitFeedbackSuccess,
  submitFeedbackError,

}

class AppStates extends Equatable {
  final AppStatus status;
  final ResponseData? responseData;
  final ErrorData? errorData;
  final String? error;


  const AppStates({
    this.status = AppStatus.initial,
    this.responseData,
    this.errorData,
    this.error,
  });

  @override
  List<Object?> get props => [
    status,
    responseData,
    errorData,
    error,
  ];

  AppStates copyWith({
    AppStatus? status,
    ResponseData? responseData,
    ErrorData? errorData,
    String? error,

  }) {
    return AppStates(
      status: status ?? AppStatus.initial,
      responseData: responseData,
      errorData: errorData,
      error: error,

    );
  }
}
