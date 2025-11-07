# predict_next_day.py
import pandas as pd
import numpy as np
import joblib
import os
from datetime import timedelta

MODEL_DIR = "models_per_item"
DATA_CSV = "canteen_history.csv"
TARGET_COL = "confirmed_count"
ID_COL = "menu_item_id"
DATE_COL = "date"

# --- Load data ---
df = pd.read_csv(DATA_CSV)
df[DATE_COL] = pd.to_datetime(df[DATE_COL])

latest_date = df[DATE_COL].max()
next_date = latest_date + timedelta(days=1)
print(f"Generating prediction for next day: {next_date.date()}")

predictions = []

def add_lag_features(group):
    group = group.sort_values(DATE_COL).copy()
    for lag in [1, 2, 3, 7, 14]:
        group[f'lag_{lag}'] = group[TARGET_COL].shift(lag)
    group['roll_3_mean'] = group[TARGET_COL].shift(1).rolling(window=3, min_periods=1).mean()
    group['roll_7_mean'] = group[TARGET_COL].shift(1).rolling(window=7, min_periods=1).mean()
    group['roll_14_mean'] = group[TARGET_COL].shift(1).rolling(window=14, min_periods=1).mean()
    group.fillna(0, inplace=True)
    return group

# --- For each trained model ---
for file in os.listdir(MODEL_DIR):
    if file.startswith("lgb_item_") and file.endswith(".pkl"):
        item_id = int(file.split("_")[-1].split(".")[0])
        bundle = joblib.load(os.path.join(MODEL_DIR, file))
        model = bundle['model']
        features = bundle['features']

        item_df = df[df[ID_COL] == item_id].copy()
        if len(item_df) < 7:
            print(f"Skipping item {item_id}: not enough history.")
            continue

        item_df = add_lag_features(item_df)
        last_row = item_df.iloc[-1:].copy()

        next_row = last_row.copy()
        next_row[DATE_COL] = next_date
        next_row['day_of_week'] = next_date.weekday()
        next_row['month'] = next_date.month
        next_row['year'] = next_date.year
        next_row['dow_sin'] = np.sin(2 * np.pi * next_row['day_of_week'] / 7)
        next_row['dow_cos'] = np.cos(2 * np.pi * next_row['day_of_week'] / 7)

        for lag in [1, 2, 3, 7, 14]:
            if len(item_df) >= lag:
                next_row[f'lag_{lag}'] = item_df[TARGET_COL].iloc[-lag]
            else:
                next_row[f'lag_{lag}'] = 0

        next_row['roll_3_mean'] = item_df[TARGET_COL].tail(3).mean()
        next_row['roll_7_mean'] = item_df[TARGET_COL].tail(7).mean()
        next_row['roll_14_mean'] = item_df[TARGET_COL].tail(14).mean()

        for col in features:
            if col not in next_row.columns:
                next_row[col] = 0

        # ✅ fixed: use next_row, not last_row
        X_pred = next_row[features].fillna(0)
        y_pred = model.predict(X_pred)[0]

        predictions.append({
            'menu_item_id': item_id,
            'predicted_count': round(float(y_pred)),
            'date': next_date.date()
        })

# --- Save predictions ---
if predictions:
    pred_df = pd.DataFrame(predictions)
    pred_path = os.path.join(MODEL_DIR, f"predictions_{next_date.date()}.csv")
    pred_df.to_csv(pred_path, index=False)
    print(f"✅ Predictions saved to {pred_path}")
    print(pred_df)
else:
    print("⚠️ No predictions generated.")
