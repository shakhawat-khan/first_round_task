import 'dart:convert';
import 'dart:io';

import 'package:first_round_task/main.dart';
import 'package:first_round_task/src/utils/custom_talker_log.dart';
import 'package:first_round_task/src/utils/log_message.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http_interceptor/http/intercepted_client.dart';

import 'package:path/path.dart' as path;

import 'package:talker_http_logger/talker_http_logger.dart';

class ApiClient {
  ApiClient();
  static const int timeoutRequest = 60;

  final client = InterceptedClient.build(
    interceptors: [TalkerHttpLogger(talker: talker)],
  );

  final Map<String, String> _mainHeaders = {
    'Content-Type': 'application/json',
    'Vary': 'Accept',
  };

  ///get http request supported
  Future<http.Response> getData({
    required String url,
    Uri? uri,
    String? token,
    Map<String, String>? headers,
    int? timeOut,
  }) async {
    if (uri != null) {
      logMessage(title: "parse uri", message: uri);
    } else {
      logMessage(title: "parse url", message: Uri.parse(url));
    }

    http.Response response = await client
        .get(
          uri ?? Uri.parse(url),
          headers:
              headers ??
              (token != null ? currentUserHeader(token) : _mainHeaders),
        )
        .timeout(
          Duration(seconds: timeOut ?? timeoutRequest),
          onTimeout: () {
            return http.Response(
              addedErrorMessage(),
              408,
            ); // Replace 500 with your http code.
          },
        );
    // talker.logTyped(
    //   ShowResponseLog(
    //     'GET: Request URL: ${response.request?.url} \n Response Status: ${response.body}',
    //   ),
    // );
    // talker.log('Response Status: ${response.body}');
    return response;
  }

  static Map<String, String> currentUserHeader(String token) {
    Map<String, String> mainHeaders = {
      'Content-Type': 'application/json',
      'Vary': 'Accept',
      'Authorization': 'Bearer $token',
    };
    return mainHeaders;
  }

  String addedErrorMessage({String message = 'error'}) {
    return '{"error": "$message"}';
  }

  Future<http.Response> postData({
    required String url,
    dynamic body,
    String? token,
    Map<String, String>? headers,
    int? timeOut,
  }) async {
    logMessage(title: 'post token', message: token);

    http.Response response = await client
        .post(
          Uri.parse(url),
          body: jsonEncode(body),
          headers:
              headers ??
              (token != null ? currentUserHeader(token) : _mainHeaders),
        )
        .timeout(
          Duration(seconds: timeOut ?? timeoutRequest),
          onTimeout: () {
            return http.Response(
              addedErrorMessage(),
              408,
            ); // Replace 500 with your http code.
          },
        );
    talker.logTyped(
      ShowResponseLog(
        'POST: Request URL: ${response.request?.url} \n POST BODY:${jsonEncode(body)}  \n Response Status: ${response.body}',
      ),
    );

    // logMessage(
    //     title: 'post response url: ${Uri.parse(url)}', message: response.body);
    return response;
  }

  /// Upload image/file using multipart request
  Future<http.Response> uploadFile({
    required String url,
    required File file,
    required String fieldName,
    Map<String, String>? fields,
    String? token,
    int? timeOut,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse(url));

    // Add authorization header if token is provided
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Add the file to the request
    var fileStream = http.ByteStream(file.openRead());
    var fileLength = await file.length();
    var multipartFile = http.MultipartFile(
      fieldName,
      fileStream,
      fileLength,
      filename: path.basename(file.path),
    );

    request.files.add(multipartFile);

    // Add additional fields if provided
    if (fields != null) {
      request.fields.addAll(fields);
    }

    logMessage(
      title: 'Uploading file',
      message: 'File: ${file.path}, Size: $fileLength bytes',
    );

    // Send the request
    try {
      var streamedResponse = await request.send().timeout(
        Duration(seconds: timeOut ?? timeoutRequest),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      // Convert to Response object
      var response = await http.Response.fromStream(streamedResponse);

      talker.logTyped(
        ShowResponseLog(
          'FILE UPLOAD: Request URL: $url \n File: ${file.path} \n Response Status: ${response.statusCode} \n Response Body: ${response.body}',
        ),
      );

      return response;
    } catch (e) {
      if (e is TimeoutException) {
        return http.Response(
          addedErrorMessage(message: 'Request timed out'),
          408,
        );
      } else {
        logMessage(title: 'File upload error', message: e.toString());
        return http.Response(addedErrorMessage(message: e.toString()), 500);
      }
    }
  }

  /// Upload multiple files using multipart request
  Future<http.Response> uploadMultipleFiles({
    required String url,
    required List<Map<String, dynamic>>
    files, // List of {file: File, fieldName: String}
    Map<String, String>? fields,
    String? token,
    int? timeOut,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse(url));

    // Add authorization header if token is provided
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Add all files to the request
    for (var fileMap in files) {
      File file = fileMap['file'];
      String fieldName = fileMap['fieldName'];

      var fileStream = http.ByteStream(file.openRead());
      var fileLength = await file.length();
      var multipartFile = http.MultipartFile(
        fieldName,
        fileStream,
        fileLength,
        filename: path.basename(file.path),
      );

      request.files.add(multipartFile);
    }

    // Add additional fields if provided
    if (fields != null) {
      request.fields.addAll(fields);
    }

    logMessage(
      title: 'Uploading multiple files',
      message: 'Files count: ${files.length}',
    );

    // Send the request
    try {
      var streamedResponse = await request.send().timeout(
        Duration(seconds: timeOut ?? timeoutRequest),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      // Convert to Response object
      var response = await http.Response.fromStream(streamedResponse);

      talker.logTyped(
        ShowResponseLog(
          'MULTIPLE FILES UPLOAD: Request URL: $url \n Files count: ${files.length} \n Response Status: ${response.statusCode} \n Response Body: ${response.body}',
        ),
      );

      return response;
    } catch (e) {
      if (e is TimeoutException) {
        return http.Response(
          addedErrorMessage(message: 'Request timed out'),
          408,
        );
      } else {
        logMessage(title: 'Multiple files upload error', message: e.toString());
        return http.Response(addedErrorMessage(message: e.toString()), 500);
      }
    }
  }

  /// delete http request supported
  Future<http.Response> deleteData({
    required String url,
    String? token,
    Map<String, String>? headers,
    int? timeOut,
  }) async {
    http.Response response = await http
        .delete(
          Uri.parse(url),
          headers:
              headers ??
              (token != null ? currentUserHeader(token) : _mainHeaders),
        )
        .timeout(
          Duration(seconds: timeOut ?? timeoutRequest),
          onTimeout: () {
            return http.Response(
              addedErrorMessage(),
              408,
            ); // Replace 500 with your http code.
          },
        );
    talker.logTyped(
      ShowResponseLog(
        'DELETE: Request URL: ${response.request?.url} \n Response Status: ${response.body}',
      ),
    );
    return response;
  }

  ///put http request supported
  Future<http.Response> putData({
    required String url,
    dynamic body,
    String? token,
    Map<String, String>? headers,
    int? timeOut,
  }) async {
    http.Response response = await http
        .put(
          Uri.parse(url),
          body: jsonEncode(body),
          headers:
              headers ??
              (token != null ? currentUserHeader(token) : _mainHeaders),
        )
        .timeout(
          Duration(seconds: timeOut ?? timeoutRequest),
          onTimeout: () {
            return http.Response(
              addedErrorMessage(),
              408,
            ); // Replace 500 with your http code.
          },
        );
    // ignore: deprecated_member_use
    talker.logTyped(
      ShowResponseLog(
        'PUT: Request URL: ${response.request?.url} \n Response Status: ${response.body}',
      ),
    );

    return response;
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
