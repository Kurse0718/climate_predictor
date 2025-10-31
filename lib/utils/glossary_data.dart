// lib/utils/glossary_data.dart
class GlossaryItem {
  final String title;
  final List<String> points;
  GlossaryItem(this.title, this.points);
}

final List<GlossaryItem> glossaryItems = [
  GlossaryItem("MAE — Mean Absolute Error", [
    "Average absolute difference between predictions and actual values.",
    "Smaller MAE = more accurate on average.",
  ]),
  GlossaryItem("RMSE — Root Mean Squared Error", [
    "Like MAE but penalizes large mistakes more heavily.",
    "Useful when you care about extremes.",
  ]),
  GlossaryItem("RF — Random Forest", [
    "Ensemble ML model combining many decision trees.",
    "Robust for tabular data; handles non-linear patterns.",
  ]),
  GlossaryItem("XGB / XGBoost — Extreme Gradient Boosting", [
    "High-performance boosting algorithm for tabular data.",
    "Often top choice for structured datasets.",
  ]),
  GlossaryItem("Lin / Linear (Ridge) — Linear Regression (Ridge)", [
    "Fits a linear relationship between inputs and output.",
    "Ridge adds regularization to stabilize coefficients.",
  ]),
  GlossaryItem("Δ (Delta) — Difference", [
    "Here: Δ = XGB − API for temperature.",
    "Green = small, Orange = moderate, Red = big disagreement.",
  ]),
  // Extras — helpful for AI/climate context
  GlossaryItem("API — Application Programming Interface", [
    "A web service you call to get data (Open-Meteo in this app).",
    "Returns JSON: a text format for structured data.",
  ]),
  GlossaryItem("JSON — JavaScript Object Notation", [
    "Human-readable data format for exchanging data between systems.",
  ]),
  GlossaryItem("Forecast Horizon", [
    "How far ahead you’re predicting (e.g., 7 days).",
  ]),
  GlossaryItem("Calibration (Probabilistic Models)", [
    "Adjusting model outputs so predicted probabilities match observed frequencies.",
    "Examples: isotonic regression, temperature scaling.",
  ]),
  GlossaryItem("Quantiles (P10/P50/P90)", [
    "Percentile-based forecasts: 10th, 50th (median), 90th percentiles.",
    "Create uncertainty bands for decision-making.",
  ]),
  GlossaryItem("Reanalysis (e.g., ERA5)", [
    "Blends models and historical observations into a consistent dataset.",
    "Good coverage; used as inputs or ground truth in research.",
  ]),
  GlossaryItem("S2S — Sub-seasonal to Seasonal", [
    "Forecast range ~2 weeks to ~2 months.",
    "Hard regime; hybrid ML+physics is common.",
  ]),
  GlossaryItem("ENSO — El Niño–Southern Oscillation", [
    "Tropical Pacific variability influencing global weather patterns.",
  ]),
  GlossaryItem("MJO — Madden–Julian Oscillation", [
    "30–60 day tropical convection pattern affecting rainfall and monsoon activity.",
  ]),
  GlossaryItem("ACC — Anomaly Correlation Coefficient", [
    "Correlation between predicted and observed anomalies (de-meaned).",
    "Standard skill metric in climate forecasting.",
  ]),
];
