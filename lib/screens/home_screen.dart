import 'package:flutter/material.dart';
import 'library_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WatchList')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LibraryScreen()),
            ),
            child: const Text('Моя библиотека'),
          ),
        ],
      ),
    );
  }
}