import 'package:flutter/material.dart';
import '../services/music_service.dart';

/// Provider thông báo sự kiện thay đổi dữ liệu (yêu thích, playlist, lịch sử) toàn ứng dụng.
class MusicProvider extends ChangeNotifier {
  MusicProvider() {
    MusicService.changeNotifier.addListener(_onServiceDataChanged);
  }

  void _onServiceDataChanged() {
    notifyListeners();
  }

  void notifyDataChanged() {
    MusicService.notifyChange();
  }

  @override
  void dispose() {
    MusicService.changeNotifier.removeListener(_onServiceDataChanged);
    super.dispose();
  }
}
