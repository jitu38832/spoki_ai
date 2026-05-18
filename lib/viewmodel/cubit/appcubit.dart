import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/app_repository.dart';
import '../repository/response_status.dart';
import 'app_state.dart';

class AppCubit extends Cubit<AppStates> {
  final AppRepository repository;

  AppCubit(this.repository) : super(const AppStates());

  Future<void> login(String idToken) async {
    emit(state.copyWith(status: AppStatus.loginLoading));
    try {
      ResponseData response = await repository.login(idToken);
      emit(state.copyWith(
          status: AppStatus.loginSuccess, responseData: response));
    } on ErrorData catch (errorData) {
      emit(state.copyWith(
          status: AppStatus.loginError, errorData: errorData, error: null));
    } catch (e) {
      emit(state.copyWith(
          status: AppStatus.loginError, error: e.toString(), errorData: null));
    }
  }

  Future<void> appleLogin(Map<String, dynamic> appleDetails) async {
    emit(state.copyWith(status: AppStatus.appleLoginLoading));
    try {
      ResponseData response = await repository.appleLogin(appleDetails);
      emit(state.copyWith(
          status: AppStatus.appleLoginSuccess, responseData: response));
    } on ErrorData catch (errorData) {
      emit(state.copyWith(
          status: AppStatus.appleLoginError, errorData: errorData, error: null));
    } catch (e) {
      emit(state.copyWith(
          status: AppStatus.appleLoginError, error: e.toString(), errorData: null));
    }
  }


  Future<void> checkStatus() async {
    emit(state.copyWith(status: AppStatus.checkStatusLoading));
    try {
      ResponseData response = await repository.checkStatus();
      emit(state.copyWith(
          status: AppStatus.checkStatusSuccess, responseData: response));
    } on ErrorData catch (errorData) {
      emit(state.copyWith(
          status: AppStatus.checkStatusError,
          errorData: errorData,
          error: null));
    } catch (e) {
      emit(state.copyWith(
          status: AppStatus.checkStatusError,
          error: e.toString(),
          errorData: null));
    }
  }

  Future<void> signUp(Map<String, dynamic> signUpDetails) async {
    emit(state.copyWith(status: AppStatus.signupLoading));
    try {
      ResponseData response = await repository.signUp(signUpDetails);
      emit(state.copyWith(
          status: AppStatus.signupSuccess, responseData: response));
    } on ErrorData catch (errorData) {
      emit(state.copyWith(
          status: AppStatus.signupError, errorData: errorData, error: null));
    } catch (e) {
      emit(state.copyWith(
          status: AppStatus.signupError, error: e.toString(), errorData: null));
    }
  }

  Future<void> generateStory(
      String token, Map<String, dynamic> storyDetails) async {
    emit(state.copyWith(status: AppStatus.generateStoryLoading));
    try {
      ResponseData response =
          await repository.generateStory(token, storyDetails);
      emit(state.copyWith(
          status: AppStatus.generateStorySuccess, responseData: response));
    } on ErrorData catch (errorData) {
      emit(state.copyWith(
          status: AppStatus.generateStoryError,
          errorData: errorData,
          error: null));
    } catch (e) {
      emit(state.copyWith(
          status: AppStatus.generateStoryError,
          error: e.toString(),
          errorData: null));
    }
  }

  Future<void> privacyPolicy(String type) async {
    emit(state.copyWith(status: AppStatus.privacyPolicyLoading));
    try {
      ResponseData response = await repository.privacyPolicy(type);
      emit(state.copyWith(
          status: AppStatus.privacyPolicySuccess, responseData: response));
    } on ErrorData catch (errorStatus) {
      emit(
        state.copyWith(
          status: AppStatus.privacyPolicyError,
          error: errorStatus.toString(),
        ),
      );
    } catch (e) {
      emit(state.copyWith(
          status: AppStatus.privacyPolicyError,
          error: e.toString(),
          errorData: null));
    }
  }

  Future<void> storyHistory(String token) async {
    emit(state.copyWith(status: AppStatus.storyHistoryLoading));
    try {
      ResponseData response = await repository.storyHistory(token);
      emit(state.copyWith(
          status: AppStatus.storyHistorySuccess, responseData: response));
    } on ErrorData catch (errorData) {
      emit(state.copyWith(
          status: AppStatus.storyHistoryError,
          errorData: errorData,
          error: null));
    } catch (e) {
      emit(state.copyWith(
          status: AppStatus.storyHistoryError,
          error: e.toString(),
          errorData: null));
    }
  }

  Future<void> historyDescription(String token, String id) async {
    emit(state.copyWith(status: AppStatus.historyDescriptionLoading));
    try {
      ResponseData response = await repository.historyDescription(token, id);
      emit(state.copyWith(
          status: AppStatus.historyDescriptionSuccess, responseData: response));
    } on ErrorData catch (errorData) {
      emit(state.copyWith(
          status: AppStatus.historyDescriptionError,
          errorData: errorData,
          error: null));
    } catch (e) {
      emit(state.copyWith(
          status: AppStatus.historyDescriptionError,
          error: e.toString(),
          errorData: null));
    }
  }

  Future<void> getProfile(String token) async {
    emit(state.copyWith(status: AppStatus.getProfileLoading));
    try {
      ResponseData response = await repository.getProfile(token);
      emit(state.copyWith(
          status: AppStatus.getProfileSuccess, responseData: response));
    } on ErrorData catch (errorData) {
      emit(state.copyWith(
          status: AppStatus.getProfileError,
          errorData: errorData,
          error: null));
    } catch (e) {
      emit(state.copyWith(
          status: AppStatus.getProfileError,
          error: e.toString(),
          errorData: null));
    }
  }

  Future<void> getQuizQues(
      String token, Map<String, dynamic> quizDetails) async {
    emit(state.copyWith(status: AppStatus.getQuizQuesLoading));
    try {
      ResponseData response = await repository.getQuizQues(token, quizDetails);
      emit(state.copyWith(
          status: AppStatus.getQuizQuesSuccess, responseData: response));
    } on ErrorData catch (errorData) {
      emit(state.copyWith(
          status: AppStatus.getQuizQuesError,
          errorData: errorData,
          error: null));
    } catch (e) {
      emit(state.copyWith(
          status: AppStatus.getQuizQuesError,
          error: e.toString(),
          errorData: null));
    }
  }

  Future<void> submitQuiz(String token, String id, String quizDetails) async {
    emit(state.copyWith(status: AppStatus.submitQuizLoading));
    try {
      ResponseData response =
          await repository.submitQuiz(token, id, quizDetails);
      emit(state.copyWith(
          status: AppStatus.submitQuizSuccess, responseData: response));
    } on ErrorData catch (errorData) {
      emit(state.copyWith(
          status: AppStatus.submitQuizError,
          errorData: errorData,
          error: null));
    } catch (e) {
      emit(state.copyWith(
          status: AppStatus.submitQuizError,
          error: e.toString(),
          errorData: null));
    }
  }

  Future<void> wordMeaning(String token, String word) async {
    emit(state.copyWith(status: AppStatus.wordMeaningLoading));
    try {
      ResponseData response = await repository.wordMeaning(token, word);
      emit(state.copyWith(
          status: AppStatus.wordMeaningSuccess, responseData: response));
    } on ErrorData catch (errorData) {
      emit(state.copyWith(
          status: AppStatus.wordMeaningError,
          errorData: errorData,
          error: null));
    } catch (e) {
      emit(state.copyWith(
          status: AppStatus.wordMeaningError,
          error: e.toString(),
          errorData: null));
    }
  }

  Future<void> bannerList() async {
    emit(state.copyWith(status: AppStatus.bannerListLoading));
    try {
      ResponseData response = await repository.bannerList();
      emit(state.copyWith(
          status: AppStatus.bannerListSuccess, responseData: response));
    } on ErrorData catch (errorData) {
      emit(state.copyWith(
          status: AppStatus.bannerListError,
          errorData: errorData,
          error: null));
    } catch (e) {
      emit(state.copyWith(
          status: AppStatus.bannerListError,
          error: e.toString(),
          errorData: null));
    }
  }

  Future<void> deleteStory(String token, String id) async {
    emit(state.copyWith(status: AppStatus.deleteStoryLoading));
    try {
      ResponseData response = await repository.deleteStory(token, id);
      emit(state.copyWith(
          status: AppStatus.deleteStorySuccess, responseData: response));
    } on ErrorData catch (errorData) {
      emit(state.copyWith(
          status: AppStatus.deleteStoryError,
          errorData: errorData,
          error: null));
    } catch (e) {
      emit(state.copyWith(
          status: AppStatus.deleteStoryError,
          error: e.toString(),
          errorData: null));
    }
  }

  Future<void> quizHistory(String token, String id) async {
    emit(state.copyWith(status: AppStatus.quizHistoryLoading));
    try {
      ResponseData response = await repository.quizHistory(token, id);
      emit(state.copyWith(
          status: AppStatus.quizHistorySuccess, responseData: response));
    } on ErrorData catch (errorData) {
      emit(state.copyWith(
          status: AppStatus.quizHistoryError,
          errorData: errorData,
          error: null));
    } catch (e) {
      emit(state.copyWith(
          status: AppStatus.quizHistoryError,
          error: e.toString(),
          errorData: null));
    }
  }

  /// [type] must be `bug` or `suggestion` (server contract).
  Future<void> submitFeedback({
    required String token,
    required String type,
    required String title,
    required String description,
    String? screenshotPath,
  }) async {
    emit(state.copyWith(status: AppStatus.submitFeedbackLoading));
    try {
      final response = await repository.submitFeedback(
        token: token,
        type: type,
        title: title,
        description: description,
        screenshotPath: screenshotPath,
      );
      emit(state.copyWith(
        status: AppStatus.submitFeedbackSuccess,
        responseData: response,
      ));
    } on ErrorData catch (errorData) {
      emit(state.copyWith(
        status: AppStatus.submitFeedbackError,
        errorData: errorData,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AppStatus.submitFeedbackError,
        error: e.toString(),
        errorData: null,
      ));
    }
  }

  Future<void> updateProfile({
    required String token,
    required Map<String, dynamic> profileDetails,
  }) async {
    emit(state.copyWith(status: AppStatus.updateProfileLoading));
    try {
      final response = await repository.updateProfile(token, profileDetails);
      emit(state.copyWith(
        status: AppStatus.updateProfileSuccess,
        responseData: response,
      ));
    } on ErrorData catch (errorData) {
      emit(state.copyWith(
        status: AppStatus.updateProfileError,
        errorData: errorData,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AppStatus.updateProfileError,
        error: e.toString(),
        errorData: null,
      ));
    }
  }

  void resetToInitial() {
    emit(const AppStates());
  }
}
