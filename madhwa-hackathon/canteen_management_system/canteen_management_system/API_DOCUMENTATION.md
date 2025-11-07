# CanteenAI API Documentation

## Main Orchestrator: `CanteenAI`

### Initialization
```python
from canteen_ai import CanteenAI

ai = CanteenAI(firebase_credentials="path/to/credentials.json")
```

### Methods

#### `update_data(days_back=None)`
Fetch and update data from Firebase.
- **Args**: `days_back` (int, optional) - Number of days to fetch
- **Returns**: pandas DataFrame

#### `train_model(force=False)`
Train or retrain models.
- **Args**: `force` (bool) - Force retraining
- **Returns**: Dict with training results

#### `predict_next_day()`
Generate predictions for next day.
- **Returns**: DataFrame with predictions

#### `predict_next_week(days=7)`
Generate multi-day forecast.
- **Args**: `days` (int) - Number of days to predict
- **Returns**: DataFrame with predictions

#### `analyze_trends()`
Generate insights and trend analysis.
- **Returns**: Dict with insights

#### `run_full_pipeline(retrain=True, forecast_days=7)`
Run complete pipeline.
- **Args**: 
  - `retrain` (bool) - Whether to retrain models
  - `forecast_days` (int) - Days to forecast
- **Returns**: Dict with all results

---

## DataAgent

### Methods

#### `fetch_from_firebase(days_back=None)`
Fetch data from Firebase Firestore.

#### `load_local_data()`
Load data from local CSV.

#### `push_to_firebase(df, collection=None)`
Push data to Firebase.

#### `validate_data(df)`
Validate and clean data.
- **Returns**: Tuple (cleaned_df, warnings)

#### `prepare_features(df)`
Engineer features for ML.
- **Returns**: DataFrame with features

#### `update_data()`
Main method to update and prepare data.

---

## TrainAgent

### Methods

#### `train_model(df, target_col='confirmed_count', validation_days=28)`
Train models for each menu item.
- **Returns**: Dict with training summary

#### `evaluate_model(df, target_col='confirmed_count')`
Evaluate model accuracy.
- **Returns**: DataFrame with metrics

#### `should_retrain(new_records_count=0, days_since_training=0)`
Check if retraining is needed.
- **Returns**: Boolean

#### `load_model(item_id)`
Load trained model for specific item.
- **Returns**: Dict with model and metadata

#### `get_feature_importance(item_id, top_n=10)`
Get feature importance for model.
- **Returns**: DataFrame

---

## PredictAgent

### Methods

#### `predict_next_day(df, target_date=None)`
Predict for next day.
- **Returns**: DataFrame with predictions

#### `predict_weekly(df, days=7)`
Generate multi-day predictions.
- **Returns**: DataFrame

#### `push_predictions_to_firebase(pred_df)`
Upload predictions to Firebase.
- **Returns**: Number of records pushed

#### `get_predictions_for_date(date)`
Retrieve predictions from Firebase.
- **Returns**: DataFrame

#### `compare_predictions_vs_actuals(df_actual, date)`
Compare predictions against actuals.
- **Returns**: DataFrame with comparison

---

## InsightAgent

### Methods

#### `analyze_trends(df)`
Analyze meal demand trends.
- **Returns**: Dict with insights

#### `generate_report(df, output_format='text')`
Generate comprehensive report.
- **Args**: `output_format` - 'text', 'json', or 'csv'
- **Returns**: Report string

#### `export_insights_csv(insights, filename='insights_export.csv')`
Export insights to CSV.

---

## Command Line Usage

```bash
# Full pipeline
python canteen_ai.py --action full --days 7

# Update data only
python canteen_ai.py --action update

# Train models
python canteen_ai.py --action train

# Generate predictions
python canteen_ai.py --action predict --days 7

# Analyze trends
python canteen_ai.py --action analyze

# Generate report
python canteen_ai.py --action report

# Skip retraining
python canteen_ai.py --action full --no-retrain

# Custom Firebase credentials
python canteen_ai.py --credentials path/to/creds.json
```

---

## Data Format

### Input Data (Firebase/CSV)
```json
{
  "date": "2025-11-03",
  "menu_item_id": 101,
  "item_name": "Masala Dosa",
  "total_employees": 142,
  "confirmed_count": 85,
  "is_holiday": false,
  "temperature": 27.8,
  "precipitation": 0.1
}
```

### Prediction Output
```json
{
  "date": "2025-11-04",
  "menu_item_id": 101,
  "predicted_count": 88,
  "predicted_opt_in_rate": 0.62,
  "confidence": 0.92,
  "lower_bound": 80,
  "upper_bound": 96,
  "model_version": "v2.1",
  "predicted_at": "2025-11-03T14:30:00"
}
```

---

## Firebase Collections

- **canteen_meal_data**: Historical meal data
- **canteen_predictions**: Forecast outputs
- **model_metadata**: Model information
- **canteen_insights**: Trend analysis
- **training_logs**: Training history
