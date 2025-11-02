// lib/widgets/forecast_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ForecastChart extends StatelessWidget {
  final List<String> dates; // YYYY-MM-DD
  final List<double> api; // API Tmax
  final List<double?> ai; // AI XGBoost (nullable)
  final List<double?> delta; // AI - API (nullable)

  const ForecastChart({
    super.key,
    required this.dates,
    required this.api,
    required this.ai,
    required this.delta,
  });

  String _labelAt(int i) {
    if (i < 0 || i >= dates.length) return '';
    final s = dates[i];
    if (s.length >= 10) return s.substring(5); // MM-DD
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final spotsApi = <FlSpot>[];
    final spotsAi = <FlSpot>[];
    final barGroups = <BarChartGroupData>[];

    for (int i = 0; i < dates.length; i++) {
      final x = i.toDouble();
      final yApi = api[i];
      if (yApi.isFinite) spotsApi.add(FlSpot(x, yApi));
      final yAi = ai[i];
      if (yAi != null && yAi.isFinite) spotsAi.add(FlSpot(x, yAi));

      final d = delta[i];
      if (d == null || d.isNaN) {
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(toY: 0, width: 8, color: Colors.transparent),
            ],
          ),
        );
      } else {
        final color = d >= 0 ? Colors.red : Colors.green;
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [BarChartRodData(toY: d, width: 8, color: color)],
          ),
        );
      }
    }

    // compute y-range for lines
    double minY = double.infinity, maxY = -double.infinity;
    for (final s in [...spotsApi, ...spotsAi]) {
      if (s.y < minY) minY = s.y;
      if (s.y > maxY) maxY = s.y;
    }
    if (minY == double.infinity) minY = 0;
    if (maxY == -double.infinity) maxY = 1;
    final pad = (maxY - minY) * 0.12;
    minY = minY - pad;
    maxY = maxY + pad;

    final maxX = (dates.length - 1).toDouble();

    return Column(
      children: [
        // Line chart
        Expanded(
          flex: 3,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: maxX,
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= dates.length)
                        return const SizedBox.shrink();
                      final step = dates.length <= 7
                          ? 1
                          : (dates.length <= 14 ? 2 : 3);
                      if (idx % step != 0) return const SizedBox.shrink();
                      return Text(
                        _labelAt(idx),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  // avoid setting tooltipBgColor (varies across versions)
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((t) {
                      final label = t.barIndex == 0 ? 'API' : 'AI';
                      return LineTooltipItem(
                        '$label: ${t.y.toStringAsFixed(1)}°C\n${dates[t.x.toInt()]}',
                        const TextStyle(color: Colors.white),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spotsApi,
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 2,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.08),
                  ),
                ),
                LineChartBarData(
                  spots: spotsAi,
                  isCurved: true,
                  color: Colors.redAccent,
                  barWidth: 2,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.redAccent.withOpacity(0.06),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Delta bar chart
        SizedBox(
          height: 110,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceBetween,
              barGroups: barGroups,
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: false,
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= dates.length)
                        return const SizedBox.shrink();
                      final step = dates.length <= 7
                          ? 1
                          : (dates.length <= 14 ? 2 : 3);
                      if (idx % step != 0) return const SizedBox.shrink();
                      return Text(
                        _labelAt(idx),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  // avoid named tooltipBgColor to remain compatible
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final idx = group.x.toInt();
                    return BarTooltipItem(
                      '${dates[idx]}\nΔ: ${rod.toY.toStringAsFixed(2)}',
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
