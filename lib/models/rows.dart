class DailyRow {
  final String date; // "YYYY-MM-DD"
  final double apiTmax;
  final double apiPrecip;
  DailyRow({
    required this.date,
    required this.apiTmax,
    required this.apiPrecip,
  });
}

class PredRow {
  final String date; // "YYYY-MM-DD"
  final double trueVal;
  final double linear;
  final double randomForest;
  final double xgboost;
  PredRow({
    required this.date,
    required this.trueVal,
    required this.linear,
    required this.randomForest,
    required this.xgboost,
  });
  factory PredRow.fromJson(Map<String, dynamic> j) => PredRow(
    date: j["date"].toString(),
    trueVal: (j["True"] as num).toDouble(),
    linear: (j["Linear"] as num).toDouble(),
    randomForest: (j["RandomForest"] as num).toDouble(),
    xgboost: (j["XGBoost"] as num).toDouble(),
  );
  static PredRow empty() =>
      PredRow(date: "", trueVal: 0, linear: 0, randomForest: 0, xgboost: 0);
  bool get isEmpty => date.isEmpty;
}

class ModelScores {
  final double maeLinear, maeRF, maeXGB;
  final double rmseLinear, rmseRF, rmseXGB;
  ModelScores({
    required this.maeLinear,
    required this.maeRF,
    required this.maeXGB,
    required this.rmseLinear,
    required this.rmseRF,
    required this.rmseXGB,
  });
  factory ModelScores.empty() => ModelScores(
    maeLinear: 0,
    maeRF: 0,
    maeXGB: 0,
    rmseLinear: 0,
    rmseRF: 0,
    rmseXGB: 0,
  );
}
