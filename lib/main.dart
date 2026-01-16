import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // 日本語対応用に追加推奨
import 'screens/main_screen.dart'; // InputScreenではなくMainScreen

void main() {
  runApp(const QuickKakeiboApp());
}

class QuickKakeiboApp extends StatelessWidget {
  const QuickKakeiboApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'あつめる',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      // カレンダー等を日本語化するためにローカリゼーションを追加
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ja', 'JP')],
      home: const MainScreen(),
    );
  }
}
