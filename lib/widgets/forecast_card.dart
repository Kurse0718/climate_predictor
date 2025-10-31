import 'package:flutter/material.dart';
import '../models/rows.dart';

class ForecastCard extends StatelessWidget {
  final DailyRow row;
  final PredRow? ai;
  const ForecastCard({super.key, required this.row, this.ai});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        title: Text(row.date),
        subtitle: ai == null
            ? Text(
                "API Tmax: ${row.apiTmax.toStringAsFixed(1)}°C • Precip: ${row.apiPrecip.toStringAsFixed(1)} mm",
              )
            : Text(
                "API: ${row.apiTmax.toStringAsFixed(1)}°C • P: ${row.apiPrecip.toStringAsFixed(1)} mm\n"
                "AI — Lin: ${ai!.linear.toStringAsFixed(1)} | RF: ${ai!.randomForest.toStringAsFixed(1)} | XGB: ${ai!.xgboost.toStringAsFixed(1)}",
              ),
        trailing: ai == null
            ? null
            : _deltaBadge(ai!.xgboost - row.apiTmax, context),
      ),
    );
  }

  Widget _deltaBadge(double d, BuildContext context) {
    final sign = d >= 0 ? "+" : "";
    Color bg, fg;
    if (d.abs() < 1.0) {
      bg = Colors.green.withOpacity(0.15);
      fg = Colors.green.shade900;
    } else if (d.abs() < 3.0) {
      bg = Colors.orange.withOpacity(0.15);
      fg = Colors.orange.shade900;
    } else {
      bg = Colors.red.withOpacity(0.15);
      fg = Colors.red.shade900;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        "Δ ${sign}${d.toStringAsFixed(1)}°",
        style: TextStyle(color: fg),
      ),
    );
  }
}
