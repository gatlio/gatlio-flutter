import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: const [
          ListTile(title: Text('Plan'), trailing: Text('Growth')),
          ListTile(title: Text('Renewal'), trailing: Text('Jul 1, 2026')),
          ListTile(title: Text('Account'), trailing: Text('demo@arcta.io')),
        ],
      ),
    );
  }
}
