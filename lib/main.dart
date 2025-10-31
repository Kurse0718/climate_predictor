import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/glossary_page.dart';

void main() => runApp(const ClimatePredictor());

class ClimatePredictor extends StatelessWidget {
  const ClimatePredictor({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'climate_predictor',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.light,
      ),
      routes: {
        '/': (_) => const HomePage(),
        '/glossary': (_) => const GlossaryPage(),
      },
    );
  }
}
