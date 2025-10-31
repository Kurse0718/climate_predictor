import 'package:flutter/material.dart';
import '../utils/glossary_data.dart';

class GlossaryPage extends StatelessWidget {
  const GlossaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = glossaryItems; // from glossary_data.dart
    return Scaffold(
      appBar: AppBar(title: const Text("To Know")),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final g = items[i];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    g.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...g.points.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text("• $p"),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
