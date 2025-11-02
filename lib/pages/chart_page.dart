// lib/pages/chart_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/rows.dart';
import '../widgets/forecast_chart.dart';

class ChartPage extends StatelessWidget {
  final List<DailyRow> apiDaily;
  final Map<String, double> aiFutureByDate; // date -> xgb
  final List<PredRow> aiRows; // historical preds (may be empty)

  const ChartPage({
    super.key,
    required this.apiDaily,
    required this.aiFutureByDate,
    required this.aiRows,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');

    final apiDates = apiDaily.map((d) => d.date).toList();
    if (apiDates.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Forecast Comparison")),
        body: const Center(child: Text("No API forecast data available.")),
      );
    }

    // choose window (first 14 API days)
    final maxPoints = 14;
    final window = apiDates.length <= maxPoints
        ? apiDates
        : apiDates.sublist(0, maxPoints);

    // build maps for quick lookup
    final apiMap = {for (var r in apiDaily) r.date: r.apiTmax};
    final histMap = {for (var p in aiRows) p.date: p};

    final List<String> xDates = window;
    final List<double> apiSeries = xDates
        .map((d) => apiMap[d] ?? double.nan)
        .toList();
    final List<double?> aiSeries = xDates.map((d) {
      if (aiFutureByDate.containsKey(d)) return aiFutureByDate[d];
      if (histMap.containsKey(d)) return histMap[d]!.xgboost;
      return null;
    }).toList();

    // compute deltas (AI - API) nullable
    final List<double?> delta = List<double?>.generate(xDates.length, (i) {
      final a = aiSeries[i];
      final p = apiSeries[i];
      if (a == null || p.isNaN) return null;
      return a - p;
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Forecast Comparison (API vs AI)")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Showing ${xDates.length} days · API vs AI (XGBoost)",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Chart widget: line chart + delta bars
            Expanded(
              child: ForecastChart(
                dates: xDates,
                api: apiSeries,
                ai: aiSeries,
                delta: delta,
              ),
            ),
            const SizedBox(height: 8),
            // legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(Colors.blue, "API (Tmax)"),
                const SizedBox(width: 12),
                _legendDot(Colors.redAccent, "AI (XGBoost)"),
                const SizedBox(width: 12),
                _legendDot(Colors.green, "Δ (AI−API negative)"),
                const SizedBox(width: 6),
                _legendDot(Colors.red, "Δ (AI−API positive)"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color c, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
