// lib/pages/home_page.dart
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

  // UI control
  bool showAI = false; // ALWAYS enabled (Option B)

  // API forecast rows
  List<DailyRow> apiDaily = [];

  // Historical AI rows (predictions.json)
  List<PredRow> aiRows = [];

  // Future AI rows (ai_forecast.json) lookup: date -> XGBoost value
  List<Map<String, dynamic>> aiFuture = [];
  Map<String, double> aiFutureByDate = {};

  // metadata (if you want to display)
  String? aiCity;
  DateTime? lastAiHistoricalDate;

  // debug info
  String? aiLoadError;

  final TextEditingController _searchCtr = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAIJson(); // load assets
    _fetchForecast(); // fetch initial forecast
  }

  // -----------------------
  // Load AI JSON assets
  // -----------------------
  Future<void> _loadAIJson() async {
    // Reset
    aiRows = [];
    aiFuture = [];
    aiFutureByDate = {};
    aiCity = null;
    lastAiHistoricalDate = null;
    aiLoadError = null;

    // 1) load historical predictions.json
    try {
      final raw = await rootBundle.loadString("assets/predictions.json");
      final list = json.decode(raw) as List<dynamic>;
      aiRows = list.map((e) => PredRow.fromJson(e)).toList();
      // make sure sorted by date ascending
      aiRows.sort((a, b) => a.date.compareTo(b.date));
      debugPrint("Loaded historical aiRows: ${aiRows.length}");
      if (aiRows.isNotEmpty) {
        lastAiHistoricalDate = DateTime.parse(aiRows.last.date);
        debugPrint(
          "Last historical AI date: ${lastAiHistoricalDate!.toIso8601String().substring(0, 10)}",
        );
      }
    } catch (e, st) {
      aiLoadError = "Error loading predictions.json: $e";
      debugPrint("$aiLoadError\n$st");
    }

    // 2) load predictions_meta.json (optional metadata)
    try {
      final metaRaw = await rootBundle.loadString(
        "assets/predictions_meta.json",
      );
      final meta = json.decode(metaRaw) as Map<String, dynamic>;
      aiCity = meta["city"]?.toString();
      debugPrint("Loaded predictions_meta: $aiCity");
    } catch (e) {
      debugPrint("No predictions_meta.json or parse error: $e");
    }

    // 3) load ai_forecast.json (future predictions)
    try {
      final rawF = await rootBundle.loadString("assets/ai_forecast.json");
      aiFuture = List<Map<String, dynamic>>.from(json.decode(rawF));
      aiFutureByDate = {
        for (final r in aiFuture)
          r["date"].toString(): (r["XGBoost"] as num).toDouble(),
      };
      debugPrint("Loaded ai_forecast rows: ${aiFuture.length}");
    } catch (e, st) {
      debugPrint("No ai_forecast.json or parse error: $e\n$st");
    }

    // 4) (optional) load ai_forecast_meta.json
    try {
      final metaRaw2 = await rootBundle.loadString(
        "assets/ai_forecast_meta.json",
      );
      final meta2 = json.decode(metaRaw2) as Map<String, dynamic>;
      if (aiCity == null) aiCity = meta2["city"]?.toString();
      debugPrint("Loaded ai_forecast_meta: ${meta2["city"]}");
    } catch (_) {
      // ignore
    }

    setState(() {});
  }

  // -----------------------
  // Fetch Open-Meteo forecast
  // -----------------------
  Future<void> _fetchForecast() async {
    setState(() => loading = true);
    try {
      apiDaily = await OpenMeteoService.fetchForecast(lat, lon);
      debugPrint("Fetched API forecast rows: ${apiDaily.length}");
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Forecast error: $e")));
      debugPrint("Forecast error: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // -----------------------
  // Search / Geocode
  // -----------------------
  Future<void> _searchCity() async {
    final q = _searchCtr.text.trim();
    if (q.isEmpty) return;
    final urlResults = await OpenMeteoService.geocode(q);
    if (!mounted) return;
    if (urlResults.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No matches")));
      return;
    }
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return ListView(
          children: urlResults.map((r) {
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
        );
      },
    );
  }

  // -----------------------
  // Compute model scores (from historical aiRows)
  // -----------------------
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

  // -----------------------
  // UI
  // -----------------------
  @override
  Widget build(BuildContext context) {
    final scores = _computeModelScores();

    return Scaffold(
      appBar: AppBar(
        title: const Text("climate_predictor"),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => Navigator.pushNamed(context, '/glossary'),
          ),
        ],
      ),
      body: Column(
        children: [
          // search
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

          // location + show ai switch (always enabled)
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

          // small info / debug banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                if (aiCity != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "AI file city: $aiCity",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                if (lastAiHistoricalDate != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Historical AI coverage up to: ${lastAiHistoricalDate!.toIso8601String().substring(0, 10)}",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                if (aiLoadError != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "AI load error: $aiLoadError",
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),

          // Model performance card
          if (aiRows.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ModelPerformanceCard(
                scores: scores,
                aiLoadError: aiLoadError,
              ),
            ),

          const SizedBox(height: 4),

          // Forecast list
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: apiDaily.length,
                    itemBuilder: (_, i) {
                      final row = apiDaily[i];

                      // Try future AI forecast first (ai_forecast.json)
                      PredRow? ai;
                      if (showAI) {
                        final xgbFuture = aiFutureByDate[row.date];
                        if (xgbFuture != null) {
                          // build a PredRow for the future day so ForecastCard shows values
                          ai = PredRow(
                            date: row.date,
                            trueVal: 0.0,
                            linear: xgbFuture,
                            randomForest: xgbFuture,
                            xgboost: xgbFuture,
                          );
                        } else if (aiRows.isNotEmpty) {
                          // fallback: historical predictions.json
                          final found = aiRows.firstWhere(
                            (p) => p.date.startsWith(row.date),
                            orElse: () => PredRow.empty(),
                          );
                          if (!found.isEmpty) ai = found;
                        }
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
