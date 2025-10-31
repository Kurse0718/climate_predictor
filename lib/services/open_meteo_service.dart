import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/rows.dart';

class OpenMeteoService {
  static Future<List<DailyRow>> fetchForecast(double lat, double lon) async {
    final url = Uri.parse(
      "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&daily=temperature_2m_max,precipitation_sum&timezone=auto",
    );
    final r = await http.get(url);
    if (r.statusCode != 200) {
      throw Exception("Forecast error: ${r.statusCode}");
    }
    final js = json.decode(r.body);
    final times = List<String>.from(js["daily"]["time"]);
    final tmax = List<double>.from(
      js["daily"]["temperature_2m_max"].map((v) => (v as num).toDouble()),
    );
    final prcp = List<double>.from(
      js["daily"]["precipitation_sum"].map((v) => (v as num).toDouble()),
    );
    return List.generate(
      times.length,
      (i) => DailyRow(date: times[i], apiTmax: tmax[i], apiPrecip: prcp[i]),
    );
  }

  static Future<List<Map<String, dynamic>>> geocode(String query) async {
    final url = Uri.parse(
      "https://geocoding-api.open-meteo.com/v1/search?name=$query&count=5&language=en&format=json",
    );
    final r = await http.get(url);
    if (r.statusCode != 200) throw Exception("Search failed: ${r.statusCode}");
    final js = json.decode(r.body);
    final results = (js["results"] as List<dynamic>? ?? []);
    return results.cast<Map<String, dynamic>>();
  }
}
