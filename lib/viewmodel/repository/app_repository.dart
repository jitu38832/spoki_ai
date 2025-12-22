import 'dart:developer';

import 'package:dio/dio.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:spokiai/model/commonresponse.dart';
import 'package:spokiai/model/generatestory.dart';
import 'package:spokiai/model/getprofile.dart';
import 'package:spokiai/model/googlelogin.dart';
import 'package:spokiai/model/historydescription.dart';
import 'package:spokiai/model/homebanner.dart';
import 'package:spokiai/model/quizhistory.dart';
import 'package:spokiai/model/quizques.dart';
import 'package:spokiai/model/storyhistory.dart';
import 'package:spokiai/model/submitquiz.dart';
import 'package:spokiai/model/wordmeaning.dart';
import 'package:spokiai/viewmodel/repository/response_status.dart';


import 'api_service.dart';

class AppRepository {
  Future<ResponseData> login(String idToken) async {
    try {
      final response = await ApiService()
          .sendRequest
          .post("auth/firebase/login", data: {
            "idToken":idToken
      });

      return ResponseData(
          statusCode: response.statusCode,
          response: GoogleLoginResponse.fromJson(response.data));
    } on DioException catch (e) {
      throw ErrorData(
          message: e.response!.data['error'], code: e.response!.statusCode);
    } on Exception catch (_) {
      rethrow;
    }
  }

  Future<ResponseData> generateStory(String token, Map<String, dynamic> storyDetails) async {
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

  Future<ResponseData> privacyPolicy(String type) async {
    try {
      final response = await ApiService()
          .sendRequest
          .get("contents/type/${type}", data: {
      });

      return ResponseData(
          statusCode: response.statusCode,
          response: GoogleLoginResponse.fromJson(response.data));
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
          .get("story-writing/history", data: {
      });

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
      final response = await ApiService(token: token)
          .sendRequest
          .get("story-writing/history/${id}",);

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
      final response = await ApiService(token: token)
          .sendRequest
          .get("users/me",);

      return ResponseData(
          statusCode: response.statusCode,
          response: GetProfileResponse.fromJson(response.data));
    } on DioException catch (e) {
      throw ErrorData(
          message: e.response!.data['message'], code: e.response!.statusCode);
    } on Exception catch (_) {
      rethrow;
    }
  }

  Future<ResponseData> getQuizQues(String token, Map<String, dynamic> quizDetails) async {
    try {
      final response = await ApiService(token: token, )
          .sendRequest
          .post("quiz/generate",data: quizDetails);

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

  Future<ResponseData> submitQuiz(String token,String id, String quizDetails) async {
    try {
      final response = await ApiService(token: token, )
          .sendRequest
          .post("quiz/${id}/submit",data: quizDetails);

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

  Future<ResponseData> wordMeaning(String token,String word) async {
    try {
      final response = await ApiService()
          .sendRequest
          .get("dictionary/${word}",);

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
      final response = await ApiService()
          .sendRequest
          .get("banners",);

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
      final response = await ApiService(token: token)
          .sendRequest
          .delete("story-writing/history/${id}",);

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
      final response = await ApiService(token: token)
          .sendRequest
          .get("quiz-responses/history/story/${id}",);

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


}
