import 'dart:io';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import 'package:spokiai/model/chat_freemium_quota.dart';
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
import 'package:spokiai/model/story_freemium_quota.dart';
import 'package:spokiai/model/submitquiz.dart';
import 'package:spokiai/payment/active_subscription_summary.dart';

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

  /// Records a StoreKit / Play Billing subscription with the backend after a
  /// successful purchase or restore (`POST subscriptions/iap/register`).
  Future<ResponseData> registerIapSubscription(
    String token,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await ApiService(token: token).sendRequest.post(
            'subscriptions/iap/register',
            data: body,
            options: Options(
              contentType: Headers.jsonContentType,
              responseType: ResponseType.json,
            ),
          );

      final raw = response.data;
      Map<String, dynamic> map = {};
      if (raw is Map<String, dynamic>) {
        map = raw;
      } else if (raw is Map) {
        map = Map<String, dynamic>.from(raw);
      }

      return ResponseData(
        statusCode: response.statusCode,
        response: CommonResponse.fromJson(map),
      );
    } on DioException catch (e) {
      final message = _extractErrorMessage(
        e.response?.data,
        fallback: 'Could not register subscription with the server.',
      );
      throw ErrorData(
        message: message,
        code: e.response?.statusCode,
      );
    } on Exception catch (_) {
      rethrow;
    }
  }

  /// QA only: `POST subscriptions/qa/test-grant` — server grants Premium for allow-listed emails only.
  Future<ResponseData> grantQaSubscriptionBypass(String token) async {
    try {
      final response = await ApiService(token: token).sendRequest.post(
            'subscriptions/qa/test-grant',
            data: const <String, dynamic>{},
            options: Options(
              contentType: Headers.jsonContentType,
              responseType: ResponseType.json,
            ),
          );

      final raw = response.data;
      Map<String, dynamic> map = {};
      if (raw is Map<String, dynamic>) {
        map = raw;
      } else if (raw is Map) {
        map = Map<String, dynamic>.from(raw);
      }

      return ResponseData(
        statusCode: response.statusCode,
        response: CommonResponse.fromJson(map),
      );
    } on DioException catch (e) {
      final raw = e.response?.data;
      final code = e.response?.statusCode;
      if (raw is Map<String, dynamic> || raw is Map) {
        final map = raw is Map<String, dynamic>
            ? raw
            : Map<String, dynamic>.from((raw as Map).map((k, v) => MapEntry('$k', v)));
        return ResponseData(
          statusCode: code,
          response: CommonResponse.fromJson(map),
        );
      }
      throw ErrorData(
        message: _extractErrorMessage(
          raw,
          fallback: 'Could not activate test subscription.',
        ),
        code: code,
      );
    } on Exception catch (_) {
      rethrow;
    }
  }

  /// `GET subscriptions/me` — active or latest subscription for the signed-in user.
  Future<ActiveSubscriptionSummary?> getMySubscription(String token) async {
    try {
      final response =
          await ApiService(token: token).sendRequest.get('subscriptions/me');
      final raw = response.data;
      if (raw is! Map<String, dynamic> && raw is! Map) {
        return null;
      }
      final map = raw is Map<String, dynamic>
          ? raw
          : Map<String, dynamic>.from((raw as Map).map((k, v) => MapEntry('$k', v)));

      final data = map['data'];
      if (data == null) return null;
      return ActiveSubscriptionSummary.fromJson(data);
    } on DioException {
      return null;
    } on Exception catch (_) {
      return null;
    }
  }

  /// Current chat freemium usage for signed-in account (see docs/chat_freemium_api.md).
  Future<ChatFreemiumQuota> getChatFreemiumQuota(String token) async {
    try {
      final response =
          await ApiService(token: token).sendRequest.get('users/me/chat-freemium');
      final raw = response.data;
      final Map<String, dynamic> map;
      if (raw is Map<String, dynamic>) {
        map = raw;
      } else if (raw is Map) {
        map = Map<String, dynamic>.from(raw.map((k, v) => MapEntry('$k', v)));
      } else {
        throw ErrorData(
          message: 'Invalid chat quota response from server.',
          code: response.statusCode,
        );
      }
      return ChatFreemiumQuota.fromBackendJson(map);
    } on ErrorData {
      rethrow;
    } on DioException catch (e) {
      final message = _extractErrorMessage(
        e.response?.data,
        fallback: 'Could not load chat limits.',
      );
      throw ErrorData(
        message: message,
        code: e.response?.statusCode,
      );
    }
  }

  /// Atomically consumes one unit for [feature] if allowed.
  Future<ChatFreemiumConsumeResult> consumeChatFreemium(
    String token,
    ChatFreemiumConsumeFeatureApi feature,
  ) async {
    try {
      final response = await ApiService(token: token).sendRequest.post(
            'users/me/chat-freemium/consume',
            data: <String, dynamic>{'feature': feature.wireValue},
            options: Options(
              contentType: Headers.jsonContentType,
              responseType: ResponseType.json,
            ),
          );
      final raw = response.data;
      final map = raw is Map<String, dynamic>
          ? raw
          : (raw is Map
              ? Map<String, dynamic>.from(raw.map((k, v) => MapEntry('$k', v)))
              : <String, dynamic>{});
      return ChatFreemiumConsumeResult.fromHttp(
        map,
        httpStatusCode: response.statusCode,
      );
    } on DioException catch (e) {
      final raw = e.response?.data;
      final code = e.response?.statusCode;
      if (raw is Map<String, dynamic> || raw is Map) {
        final map = raw is Map<String, dynamic>
            ? raw
            : Map<String, dynamic>.from((raw as Map).map((k, v) => MapEntry('$k', v)));
        return ChatFreemiumConsumeResult.fromHttp(map, httpStatusCode: code);
      }
      return ChatFreemiumConsumeResult(
        allowed: false,
        success: false,
        message: _extractErrorMessage(
          raw,
          fallback: 'Could not verify chat limits. Try again.',
        ),
        quota: null,
      );
    }
  }

  Future<StoryFreemiumQuota> getStoryFreemiumQuota(String token) async {
    try {
      final response = await ApiService(token: token)
          .sendRequest
          .get('users/me/story-freemium');
      final raw = response.data;
      final Map<String, dynamic> map;
      if (raw is Map<String, dynamic>) {
        map = raw;
      } else if (raw is Map) {
        map = Map<String, dynamic>.from(raw.map((k, v) => MapEntry('$k', v)));
      } else {
        throw ErrorData(
          message: 'Invalid story quota response from server.',
          code: response.statusCode,
        );
      }
      return StoryFreemiumQuota.fromBackendJson(map);
    } on ErrorData {
      rethrow;
    } on DioException catch (e) {
      throw ErrorData(
        message: _extractErrorMessage(
          e.response?.data,
          fallback: 'Could not load story limits.',
        ),
        code: e.response?.statusCode,
      );
    }
  }

  Future<StoryFreemiumConsumeResult> consumeStoryFreemium(
    String token, {
    required String feature,
    String? storyId,
    String? playbackKey,
  }) async {
    final body = <String, dynamic>{
      'feature': feature,
      if (storyId != null && storyId.isNotEmpty) 'story_id': storyId,
      if (playbackKey != null && playbackKey.isNotEmpty)
        'playback_key': playbackKey,
    };
    try {
      final response = await ApiService(token: token).sendRequest.post(
            'users/me/story-freemium/consume',
            data: body,
            options: Options(
              contentType: Headers.jsonContentType,
              responseType: ResponseType.json,
            ),
          );
      final raw = response.data;
      final map = raw is Map<String, dynamic>
          ? raw
          : (raw is Map
              ? Map<String, dynamic>.from(raw.map((k, v) => MapEntry('$k', v)))
              : <String, dynamic>{});
      return StoryFreemiumConsumeResult.fromHttp(
        map,
        httpStatusCode: response.statusCode,
      );
    } on DioException catch (e) {
      final raw = e.response?.data;
      final code = e.response?.statusCode;
      if (raw is Map<String, dynamic> || raw is Map) {
        final map = raw is Map<String, dynamic>
            ? raw
            : Map<String, dynamic>.from((raw as Map).map((k, v) => MapEntry('$k', v)));
        return StoryFreemiumConsumeResult.fromHttp(map, httpStatusCode: code);
      }
      return StoryFreemiumConsumeResult(
        allowed: false,
        success: false,
        message: _extractErrorMessage(
          raw,
          fallback: 'Could not verify story limits. Try again.',
        ),
        quota: null,
      );
    }
  }

}
