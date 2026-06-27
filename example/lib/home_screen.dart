import 'package:flutter/material.dart';
import 'package:gatlio_flutter/gatlio_flutter.dart';
import 'arcta_content.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arcta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: GatlioSandbox(
        onLockout: () => debugPrint('lockout'),
        onWarning: () => debugPrint('warning'),
        onActive: () => debugPrint('active'),
        child: const ArctaContent(),
      ),
    );
  }
}
