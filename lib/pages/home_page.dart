import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/rows.dart';
import '../services/open_meteo_service.dart';
import '../widgets/forecast_card.dart';
import '../widgets/model_performance_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Default: JFK (good coverage)
  double lat = 40.6413, lon = -73.7781;
  String placeLabel = "New York (JFK)";
  bool loading = false;
  bool showAI = false;

  List<DailyRow> apiDaily = [];
  List<PredRow> aiRows = [];
  String? aiLoadError;

  final TextEditingController _searchCtr = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAIJson();
    _fetchForecast();
  }

  Future<void> _loadAIJson() async {
    try {
      final raw = await rootBundle.loadString("assets/predictions.json");
      final list = json.decode(raw) as List<dynamic>;
      aiRows = list.map((e) => PredRow.fromJson(e)).toList();
      setState(() {});
    } catch (e) {
      aiLoadError = "AI predictions not found (assets/predictions.json)";
      setState(() {});
    }
  }

  Future<void> _fetchForecast() async {
    setState(() => loading = true);
    try {
      apiDaily = await OpenMeteoService.fetchForecast(lat, lon);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _searchCity() async {
    final q = _searchCtr.text.trim();
    if (q.isEmpty) return;
    try {
      final results = await OpenMeteoService.geocode(q);
      if (!mounted) return;
      if (results.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No matches")));
        return;
      }
      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (_) => ListView(
          children: results.map((r) {
            final name = r["name"];
            final country = r["country"];
            final admin1 = r["admin1"];
            final dLat = (r["latitude"] as num).toDouble();
            final dLon = (r["longitude"] as num).toDouble();
            final label = [
              name,
              admin1,
              country,
            ].whereType<String>().join(", ");
            return ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(label),
              subtitle: Text("lat $dLat, lon $dLon"),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  lat = dLat;
                  lon = dLon;
                  placeLabel = label;
                });
                _fetchForecast();
              },
            );
          }).toList(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
    }
  }

  ModelScores _computeModelScores() {
    if (aiRows.isEmpty) return ModelScores.empty();
    double maeLin = 0, maeRF = 0, maeX = 0;
    double rmseLin = 0, rmseRF = 0, rmseX = 0;
    final n = aiRows.length.toDouble();
    for (final r in aiRows) {
      final dL = r.linear - r.trueVal;
      final dR = r.randomForest - r.trueVal;
      final dX = r.xgboost - r.trueVal;
      maeLin += dL.abs();
      maeRF += dR.abs();
      maeX += dX.abs();
      rmseLin += dL * dL;
      rmseRF += dR * dR;
      rmseX += dX * dX;
    }
    double sqrt(double x) {
      if (x <= 0) return 0;
      double r = x;
      for (int i = 0; i < 10; i++) {
        r = 0.5 * (r + x / r);
      }
      return r;
    }

    return ModelScores(
      maeLinear: maeLin / n,
      maeRF: maeRF / n,
      maeXGB: maeX / n,
      rmseLinear: sqrt(rmseLin / n),
      rmseRF: sqrt(rmseRF / n),
      rmseXGB: sqrt(rmseX / n),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scores = _computeModelScores();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Climate Predictor"),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => Navigator.pushNamed(context, '/glossary'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtr,
                    decoration: InputDecoration(
                      hintText: "Search city (e.g., London, Delhi)",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _searchCity(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _searchCity, child: const Text("Find")),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    placeLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Switch.adaptive(
                  value: showAI,
                  onChanged: (v) => setState(() => showAI = v),
                ),
                const SizedBox(width: 8),
                const Text("Show AI"),
              ],
            ),
          ),
          if (aiRows.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ModelPerformanceCard(
                scores: scores,
                aiLoadError: aiLoadError,
              ),
            ),
          const SizedBox(height: 4),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: apiDaily.length,
                    itemBuilder: (_, i) {
                      final row = apiDaily[i];
                      PredRow? ai;
                      if (showAI && aiRows.isNotEmpty) {
                        ai = aiRows.firstWhere(
                          (p) => p.date.startsWith(row.date),
                          orElse: () => PredRow.empty(),
                        );
                        if (ai!.isEmpty) ai = null;
                      }
                      return ForecastCard(row: row, ai: ai);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _fetchForecast,
        icon: const Icon(Icons.refresh),
        label: const Text("Refresh"),
      ),
    );
  }
}
