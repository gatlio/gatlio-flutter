import 'package:flutter/material.dart';
import 'login_screen.dart';

void main() => runApp(const ArctaApp());

class ArctaApp extends StatelessWidget {
  const ArctaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arcta',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1A1A2E),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
