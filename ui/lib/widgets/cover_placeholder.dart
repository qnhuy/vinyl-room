import 'package:flutter/material.dart';

/// Widget ảnh bìa mặc định khi không tải được ảnh hoặc bài hát chưa có ảnh.
class CoverPlaceholder extends StatelessWidget {
  final double size;
  final IconData icon;

  const CoverPlaceholder({
    super.key,
    this.size = 140,
    this.icon = Icons.album,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: Colors.black26,
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.35, color: Colors.white70),
    );
  }
}
