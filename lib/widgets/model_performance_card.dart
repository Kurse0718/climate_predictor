import 'package:flutter/material.dart';
import '../models/rows.dart';

class ModelPerformanceCard extends StatelessWidget {
  final ModelScores scores;
  final String? aiLoadError;
  const ModelPerformanceCard({
    super.key,
    required this.scores,
    this.aiLoadError,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Model Performance (historical)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                _chip(
                  context,
                  "Linear",
                  "MAE ${scores.maeLinear.toStringAsFixed(2)} | RMSE ${scores.rmseLinear.toStringAsFixed(2)}",
                ),
                _chip(
                  context,
                  "RF",
                  "MAE ${scores.maeRF.toStringAsFixed(2)} | RMSE ${scores.rmseRF.toStringAsFixed(2)}",
                ),
                _chip(
                  context,
                  "XGB",
                  "MAE ${scores.maeXGB.toStringAsFixed(2)} | RMSE ${scores.rmseXGB.toStringAsFixed(2)}",
                ),
              ],
            ),
            if (aiLoadError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  aiLoadError!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext ctx, String label, String value) {
    return Chip(
      label: Text("$label  •  $value"),
      side: BorderSide(color: Theme.of(ctx).colorScheme.outlineVariant),
    );
  }
}
