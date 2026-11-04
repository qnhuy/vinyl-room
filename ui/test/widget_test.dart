import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:music_player/main.dart';
import 'package:music_player/providers/auth_provider.dart';
import 'package:music_player/providers/music_provider.dart';
import 'package:music_player/providers/player_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PlayerProvider>.value(
            value: PlayerProvider.instance,
          ),
          ChangeNotifierProvider<AuthProvider>.value(
            value: AuthProvider.instance,
          ),
          ChangeNotifierProvider<MusicProvider>(
            create: (_) => MusicProvider(),
          ),
        ],
        child: const MusicApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
