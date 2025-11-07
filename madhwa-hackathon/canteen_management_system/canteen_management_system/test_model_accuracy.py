import pandas as pd
import numpy as np
import joblib
import os
from sklearn.metrics import mean_absolute_error, mean_squared_error

MODEL_DIR = "models_per_item"
DATA_CSV = "canteen_history.csv"
TARGET_COL = "confirmed_count"
ID_COL = "menu_item_id"
DATE_COL = "date"

df = pd.read_csv(DATA_CSV)
df[DATE_COL] = pd.to_datetime(df[DATE_COL])

results = []

for file in os.listdir(MODEL_DIR):
    if file.startswith("lgb_item_") and file.endswith(".pkl"):
        item_id = int(file.split("_")[-1].split(".")[0])
        bundle = joblib.load(os.path.join(MODEL_DIR, file))
        model = bundle['model']
        features = bundle['features']

        item_df = df[df[ID_COL] == item_id].copy()
        if len(item_df) < 50:
            continue

        # chronological split (last 28 days as test)
        cutoff = item_df[DATE_COL].max() - pd.Timedelta(days=28)
        train_df = item_df[item_df[DATE_COL] <= cutoff]
        test_df = item_df[item_df[DATE_COL] > cutoff]
        if len(test_df) < 5:
            continue

        X_test = test_df[features].fillna(0)
        y_test = test_df[TARGET_COL].values
        y_pred = model.predict(X_test)

        mae = mean_absolute_error(y_test, y_pred)
        rmse = np.sqrt(mean_squared_error(y_test, y_pred))
        results.append({'menu_item_id': item_id, 'MAE': mae, 'RMSE': rmse, 'TestRows': len(test_df)})

if results:
    res_df = pd.DataFrame(results)
    print(res_df)
    res_df.to_csv(os.path.join(MODEL_DIR, "model_test_results.csv"), index=False)
    print("\n✅ Test results saved to model_test_results.csv")
else:
    print("⚠️ No models tested (not enough data).")
