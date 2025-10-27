import 'dart:convert';
import 'package:first_round_task/src/module/home_page/model/home_page_model.dart';
import 'package:first_round_task/src/services/api_services.dart';
import 'package:first_round_task/src/services/api_urls.dart';
import 'package:first_round_task/src/utils/log_message.dart';



class ApiException implements Exception {
  final int code;
  final String message;

  ApiException(this.code, this.message);

  @override
  String toString() => 'ApiException($code): $message';
}

class HomePageApi {
  /// Fetch paginated quotes
  /// Throws ApiException on error
  static Future<QuoteModel> getDashboardData({
    required int limit,
    required int skip,
  }) async {
    try {
      final response = await ApiClient().getData(
        url: '${ApiUrls.quotes}?limit=$limit&skip=$skip',
      );

      logMessage(title: 'Quotes Response', message: response.body);

      switch (response.statusCode) {
        case 200:
          final data = jsonDecode(response.body);
          return QuoteModel.fromJson(data);

        case 403:
          throw ApiException(403, "Unauthorized");

        case 404:
          throw ApiException(404, "Quotes not found");

        case 500:
          throw ApiException(500, "Server error");

        case 408:
          throw ApiException(408, "Request timed out");

        default:
          throw ApiException(
            response.statusCode ?? 0,
            "Unexpected error occurred",
          );
      }
    } catch (e, stacktrace) {
      logMessage(title: 'HomePage API Error', message: '$e\n$stacktrace');
      if (e is ApiException) {
        rethrow;
      } else {
        throw ApiException(0, "Something went wrong: $e");
      }
    }
  }
}

/// try this for mock response

// class MockHomePageApi {
//   /// Always throws 403 for testing
//   static Future<QuoteModel> getDashboardData({
//     required int limit,
//     required int skip,
//   }) async {
//     await Future.delayed(const Duration(seconds: 1)); // simulate network delay
//     throw ApiException(500, "Unauthorized (mock)");
//   }
// }
