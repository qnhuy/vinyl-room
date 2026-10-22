import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/config.dart';
import '../services/session.dart';

enum HttpMethod { get, post, put, patch, delete }

/// Utility gọi API chung cho toàn bộ dự án
class Http {
  static const Duration _timeout = Duration(seconds: 15);

  static Uri _buildUrl(String endpoint, [Map<String, dynamic>? queryParameters]) {
    // Nếu endpoint đã là URL đầy đủ thì parse trực tiếp
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      final uri = Uri.parse(endpoint);
      if (queryParameters != null && queryParameters.isNotEmpty) {
        final stringParams = queryParameters.map(
          (key, value) => MapEntry(key, value?.toString() ?? ''),
        );
        return uri.replace(queryParameters: {
          ...uri.queryParameters,
          ...stringParams,
        });
      }
      return uri;
    }

    String baseUrl = AppConfig.apiBaseUrl;
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final fullUrl = '$baseUrl$path';

    final uri = Uri.parse(fullUrl);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final stringParams = queryParameters.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      );
      return uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...stringParams,
      });
    }
    return uri;
  }

  static Map<String, String> get _defaultHeaders => {
        'content-type': 'application/json',
        'accept': 'application/json',
        'x-user-id': '${Session.userId}',
      };

  static Future<http.Response> _createRequest(
    HttpMethod method,
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    final url = _buildUrl(endpoint, queryParams);
    final mergedHeaders = {..._defaultHeaders, ...?headers};

    final request = http.Request(method.name.toUpperCase(), url);
    request.headers.addAll(mergedHeaders);

    if (body != null) {
      if (body is String) {
        request.body = body;
      } else {
        request.body = jsonEncode(body);
      }
    }

    try {
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      return response;
    } on TimeoutException {
      debugPrint('[Http Timeout] ${method.name.toUpperCase()} $url');
      return http.Response(
        jsonEncode({'success': false, 'message': 'Hết thời gian kết nối máy chủ.'}),
        408,
        headers: _defaultHeaders,
      );
    } catch (e) {
      debugPrint('[Http Error] ${method.name.toUpperCase()} $url: $e');
      return http.Response(
        jsonEncode({'success': false, 'message': 'Không thể kết nối đến máy chủ.'}),
        500,
        headers: _defaultHeaders,
      );
    }
  }

  static Future<http.Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    return await _createRequest(
      HttpMethod.get,
      endpoint,
      queryParams: queryParams,
      headers: headers,
    );
  }

  static Future<http.Response> post(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    return await _createRequest(
      HttpMethod.post,
      endpoint,
      body: body,
      queryParams: queryParams,
      headers: headers,
    );
  }

  static Future<http.Response> put(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    return await _createRequest(
      HttpMethod.put,
      endpoint,
      body: body,
      queryParams: queryParams,
      headers: headers,
    );
  }

  static Future<http.Response> patch(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    return await _createRequest(
      HttpMethod.patch,
      endpoint,
      body: body,
      queryParams: queryParams,
      headers: headers,
    );
  }

  static Future<http.Response> delete(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    return await _createRequest(
      HttpMethod.delete,
      endpoint,
      body: body,
      queryParams: queryParams,
      headers: headers,
    );
  }
}
