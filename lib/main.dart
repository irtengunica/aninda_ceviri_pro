// lib/main.dart

import 'package:flutter/material.dart';
import 'screens/translation_screen.dart';

void main() {
  // Uygulamanın çalışmadan önce Flutter binding'lerinin hazır olduğundan emin ol.
  // Gelecekte eklenecek paketler için (örn: Firebase) bu önemlidir.
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anında Çeviri Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        // Uygulama genelinde kartların daha estetik görünmesi için
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const TranslationScreen(),
    );
  }
}
