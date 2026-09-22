import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Quản lý cấu hình toàn bộ ứng dụng Vinyl Room
class AppConfig {
  /// Base URL mặc định của Backend API
  static const String defaultApiUrl = 'http://localhost:3000';

  /// Khởi tạo cấu hình (tải file .env nếu có)
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('[AppConfig] Không tìm thấy file .env, sử dụng cấu hình mặc định: $defaultApiUrl');
    }
  }

  /// Base URL của Backend API. Ưu tiên đọc từ file .env (BASE_API_URL), fallback về mặc định
  static String get apiBaseUrl {
    if (dotenv.isInitialized) {
      final envUrl = dotenv.env['BASE_API_URL'];
      if (envUrl != null && envUrl.trim().isNotEmpty) {
        return envUrl.trim();
      }
    }
    return defaultApiUrl;
  }

  /// Alias tương thích ngược
  static String get apiUrl => apiBaseUrl;
}

/// Alias ApiConfig để tương thích ngược với các service cũ
class ApiConfig {
  static String get baseUrl => AppConfig.apiBaseUrl;
}

// Alias Config cho tương thích ngược
typedef Config = AppConfig;
