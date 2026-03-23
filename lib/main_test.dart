import 'package:flutter/material.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OLTrap Locator Test',
      home: const TestScreen(),
      debugShowCheckedModeBanner: true,
    );
  }
}

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OLTrap Locator'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bug_report, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'OLTrap Locator',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('App is working!'),
          ],
        ),
      ),
    );
  }
}
