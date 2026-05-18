import 'dart:io';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import 'package:spokiai/model/commonresponse.dart';
import 'package:spokiai/model/generatestory.dart';
import 'package:spokiai/model/getprofile.dart';
import 'package:spokiai/model/googlelogin.dart';
import 'package:spokiai/model/historydescription.dart';
import 'package:spokiai/model/homebanner.dart';
import 'package:spokiai/model/quizhistory.dart';
import 'package:spokiai/model/quizques.dart';
import 'package:spokiai/model/signup.dart';
import 'package:spokiai/model/storyhistory.dart';
import 'package:spokiai/model/submitquiz.dart';
import 'package:spokiai/model/wordmeaning.dart';
import 'package:spokiai/viewmodel/repository/response_status.dart';

import '../../model/applelogin.dart';
import '../../model/checkstatus.dart';
import '../../model/privacypolicy.dart';
import '../../view/utils/preference_manager.dart';
import 'api_service.dart';

class AppRepository {
  String _extractErrorMessage(
    dynamic responseData, {
    required String fallback,
  }) {
    if (responseData is Map) {
      final dynamic messageValue =
          responseData['message'] ?? responseData['error'];
      if (messageValue != null) {
        final text = messageValue.toString().trim();
        if (text.isNotEmpty) return text;
      }
    }
    final text = responseData?.toString().trim();
    if (text != null && text.isNotEmpty && text != 'null') return text;
    return fallback;
  }

  Future<ResponseData> login(String idToken) async {
    try {
      final response = await ApiService()
          .sendRequest
          .post("auth/firebase/login", data: {"idToken": idToken});

      return ResponseData(
          statusCode: response.statusCode,
          response: GoogleLoginResponse.fromJson(response.data));
    } on DioException catch (e) {
      final message = _extractErrorMessage(
        e.response?.data,
        fallback: "Google Sign-In failed. Please try again.",
      );
      throw ErrorData(
        message: message,
        code: e.response?.statusCode,
      );
    } on Exception catch (_) {
      rethrow;
    }
  }

  Future<ResponseData> appleLogin(Map<String, dynamic> appleDetails) async {
    print("Apple details in repo");
    print(appleDetails);
    try {
      final response = await ApiService()
          .sendRequest
          .post("auth/apple-login", data: appleDetails);

      return ResponseData(
          statusCode: response.statusCode,
          response: AppleLoginResponse.fromJson(response.data));
    } on DioException catch (e) {
      final message = _extractErrorMessage(
        e.response?.data,
        fallback: "Apple Sign-In failed. Please try again.",
      );
      throw ErrorData(
        message: message,
        code: e.response?.statusCode,
      );
    } on Exception catch (_) {
      rethrow;
    }
  }

  Future<ResponseData> checkStatus() async {
    try {
      final response = await ApiService().sendRequest.get("users/key");

      return ResponseData(
          statusCode: response.statusCode,
          response: CheckStatusResponse.fromJson(response.data));
    } on DioException catch (e) {
      throw ErrorData(
          message: e.response!.data['error'], code: e.response!.statusCode);
    } on Exception catch (_) {
      rethrow;
    }
  }

  Future<ResponseData> generateStory(
      String token, Map<String, dynamic> storyDetails) async {
    try {
      final response = await ApiService(token: token)
          .sendRequest
          .post("story-writing", data: storyDetails);

      return ResponseData(
          statusCode: response.statusCode,
          response: GenerateStoryResponse.fromJson(response.data));
    } on DioException catch (e) {
      throw ErrorData(
          message: e.response!.data['message'], code: e.response!.statusCode);
    } on Exception catch (_) {
      rethrow;
    }
  }

  Future<ResponseData> signUp(Map<String, dynamic> signUpDetails) async {
    try {
      final response = await ApiService()
          .sendRequest
          .post("auth/login", data: signUpDetails);

      return ResponseData(
          statusCode: response.statusCode,
          response: SignUpResponse.fromJson(response.data));
    } on DioException catch (e) {
      throw ErrorData(
          message: e.response!.data['message'], code: e.response!.statusCode);
    } on Exception catch (_) {
      rethrow;
    }
  }

  Future<ResponseData> privacyPolicy(String type) async {
    try {
      final response =
          await ApiService().sendRequest.get("contents/${type}", data: {});

      return ResponseData(
          statusCode: response.statusCode,
          response: PrivacyPolicyResponse.fromJson(response.data));
    } on DioException catch (e) {
      throw ErrorData(
          message: e.response!.data['error'], code: e.response!.statusCode);
    } on Exception catch (_) {
      rethrow;
    }
  }

  Future<ResponseData> storyHistory(String token) async {
    try {
      final response = await ApiService(token: token)
          .sendRequest
          .get("story-writing/history", data: {});

      return ResponseData(
          statusCode: response.statusCode,
          response: StoryHistoryResponse.fromJson(response.data));
    } on DioException catch (e) {
      throw ErrorData(
          message: e.response!.data['message'], code: e.response!.statusCode);
    } on Exception catch (_) {
      rethrow;
    }
  }

  Future<ResponseData> historyDescription(String token, String id) async {
    try {
      final response = await ApiService(token: token).sendRequest.get(
            "story-writing/history/${id}",
          );

      return ResponseData(
          statusCode: response.statusCode,
          response: HistoryDescriptionResponse.fromJson(response.data));
    } on DioException catch (e) {
      throw ErrorData(
          message: e.response!.data['message'], code: e.response!.statusCode);
    } on Exception catch (_) {
      rethrow;
    }
  }

  Future<ResponseData> getProfile(String token) async {
    try {
      final response = await ApiService(token: token).sendRequest.get(
            "users/me",
          );

      return ResponseData(
          statusCode: response.statusCode,
          response: GetProfileResponse.fromJson(response.data));
    } on DioException catch (e) {
      final message = _extractErrorMessage(
        e.response?.data,
        fallback: "Could not fetch profile details.",
      );
      throw ErrorData(
        message: message,
        code: e.response?.statusCode,
      );
    } on Exception catch (_) {
      rethrow;
    }
  }

  Future<ResponseData> getQuizQues(
      String token, Map<String, dynamic> quizDetails) async {
    try {
      final response = await ApiService(
        token: token,
      ).sendRequest.post("quiz/generate", data: quizDetails);

      return ResponseData(
          statusCode: response.statusCode,
          response: QuizQuesResponse.fromJson(response.data));
    } on DioException catch (e) {
      throw ErrorData(
          message: e.response!.data['message'], code: e.response!.statusCode);
    } on Exception catch (_) {
      rethrow;
    }
  }

  Future<ResponseData> submitQuiz(
      String token, String id, String quizDetails) async {
    try {
      final response = await ApiService(
        token: token,
      ).sendRequest.post("quiz/${id}/submit", data: quizDetails);

      return ResponseData(
          statusCode: response.statusCode,
          response: SubmitQuizResponse.fromJson(response.data));
    } on DioException catch (e) {
      throw ErrorData(
          message: e.response!.data['message'], code: e.response!.statusCode);
    } on Exception catch (_) {
      rethrow;
    }
  }

  /// Same key as [Editprofile] — "Which language do you speak?"
  static const String _kProfileSpokenLanguage = 'profile_spoken_language';

  /// Query `?language=hindi` etc.; defaults to `english` if not set in profile.
  String _dictionaryLanguageQueryParam() {
    final raw = PreferenceManager.getStringValue(key: _kProfileSpokenLanguage)
            ?.trim() ??
        '';
    if (raw.isEmpty) return 'english';
    return raw.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<ResponseData> wordMeaning(String token, String word) async {
    try {
      final encodedWord = Uri.encodeComponent(word);
      final language = _dictionaryLanguageQueryParam();
      final response = await ApiService().sendRequest.get(
        "dictionary/$encodedWord",
        queryParameters: <String, dynamic>{'language': language},
      );

      return ResponseData(
          statusCode: response.statusCode,
          response: WordMeaningResponse.fromJson(response.data));
    } on DioException catch (e) {
      throw ErrorData(
          message: e.response!.data['message'], code: e.response!.statusCode);
    } on Exception catch (_) {
      rethrow;
    }
  }

  Future<ResponseData> bannerList() async {
    try {
      final response = await ApiService().sendRequest.get(
            "banners",
          );

      return ResponseData(
          statusCode: response.statusCode,
          response: HomeBannerResponse.fromJson(response.data));
    } on DioException catch (e) {
      throw ErrorData(
          message: e.response!.data['message'], code: e.response!.statusCode);
    } on Exception catch (_) {
      rethrow;
    }
  }

  Future<ResponseData> deleteStory(String token, String id) async {
    try {
      final response = await ApiService(token: token).sendRequest.delete(
            "story-writing/history/${id}",
          );

      return ResponseData(
          statusCode: response.statusCode,
          response: CommonResponse.fromJson(response.data));
    } on DioException catch (e) {
      throw ErrorData(
          message: e.response!.data['message'], code: e.response!.statusCode);
    } on Exception catch (_) {
      rethrow;
    }
  }

  Future<ResponseData> quizHistory(String token, String id) async {
    try {
      final response = await ApiService(token: token).sendRequest.get(
            "quiz-responses/history/story/${id}",
          );

      return ResponseData(
          statusCode: response.statusCode,
          response: QuizHistoryResponse.fromJson(response.data));
    } on DioException catch (e) {
      throw ErrorData(
          message: e.response!.data['message'], code: e.response!.statusCode);
    } on Exception catch (_) {
      rethrow;
    }
  }

  /// Multipart feedback: [type] `bug` | `suggestion`, optional [screenshotPath].
  Future<ResponseData> submitFeedback({
    required String token,
    required String type,
    required String title,
    required String description,
    String? screenshotPath,
  }) async {
    try {
      final fields = <String, dynamic>{
        'type': type,
        'title': title,
        'description': description,
      };
      if (screenshotPath != null && screenshotPath.isNotEmpty) {
        final file = File(screenshotPath);
        if (await file.exists()) {
          final name = screenshotPath.replaceAll(r'\', '/').split('/').last;
          fields['screenshot'] = await MultipartFile.fromFile(
            screenshotPath,
            filename: name.isEmpty ? 'upload.jpg' : name,
          );
        }
      }
      final formData = FormData.fromMap(fields);
      final response = await ApiService(token: token).sendRequest.post(
            'users/feedback',
            data: formData,
          );

      final raw = response.data;
      Map<String, dynamic> body = {};
      if (raw is Map<String, dynamic>) {
        body = raw;
      } else if (raw is Map) {
        body = Map<String, dynamic>.from(raw);
      }
      return ResponseData(
        statusCode: response.statusCode,
        response: CommonResponse.fromJson(body),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg = 'Could not submit feedback';
      if (data is Map) {
        msg = data['message']?.toString() ??
            data['error']?.toString() ??
            msg;
      }
      throw ErrorData(message: msg, code: e.response?.statusCode);
    } on Exception catch (_) {
      rethrow;
    }
  }

  Future<ResponseData> updateProfile(
      String token, Map<String, dynamic> profileDetails) async {
    developer.log(
      "PATCH users/me called",
      name: "AppRepository",
      error: profileDetails,
    );
    developer.log(
      "PATCH users/me payload json",
      name: "AppRepository",
      error: jsonEncode(profileDetails),
    );
    try {
      final response = await ApiService(token: token).sendRequest.patch(
            "users/me",
            data: profileDetails,
            options: Options(
              contentType: Headers.jsonContentType,
              responseType: ResponseType.json,
              headers: const {
                Headers.acceptHeader: Headers.jsonContentType,
              },
            ),
          );
      developer.log(
        "PATCH users/me success",
        name: "AppRepository",
        error: "status=${response.statusCode}",
      );
      return ResponseData(
        statusCode: response.statusCode,
        response: response.data,
      );
    } on DioException catch (e) {
      final message = _extractErrorMessage(
        e.response?.data,
        fallback: "Could not update profile. Please try again.",
      );
      developer.log(
        "PATCH users/me failed",
        name: "AppRepository",
        error: message,
        stackTrace: e.stackTrace,
      );
      throw ErrorData(
        message: message,
        code: e.response?.statusCode,
      );
    } on Exception catch (_) {
      rethrow;
    }
  }

}
