import 'package:flutter/material.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const RentGoApp());
}

class RentGoApp extends StatelessWidget {
  const RentGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RentGo',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF2563EB),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2563EB),
          secondary: Color(0xFF38BDF8),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF020617),
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF020617),
          elevation: 4,
          margin: EdgeInsets.symmetric(vertical: 8),
        ),
      ),
      home: const MainScreen(),
    );
  }
}
