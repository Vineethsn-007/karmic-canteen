# ...existing code...
import pandas as pd
import numpy as np
import os
from sklearn.model_selection import RandomizedSearchCV
from sklearn.metrics import mean_absolute_error, mean_squared_error
import lightgbm as lgb
import joblib
from datetime import datetime
from lightgbm import LGBMRegressor, early_stopping, log_evaluation


# -----------------------
# Configuration
# -----------------------
DATA_CSV = "canteen_history.csv"   # path to your prepared dataset
MODEL_DIR = "models_per_item"
os.makedirs(MODEL_DIR, exist_ok=True)

TARGET_COL = "confirmed_count"
ID_COL = "menu_item_id"
DATE_COL = "date"

# -----------------------
# Helpers: feature engineering
# -----------------------
def prepare_features(df):
    # Ensure date is datetime and sorted
    df = df.copy()
    df[DATE_COL] = pd.to_datetime(df[DATE_COL])
    df = df.sort_values([ID_COL, DATE_COL]).reset_index(drop=True)

    # Basic features
    df['day_of_week'] = df[DATE_COL].dt.weekday               # 0=Mon
    df['month'] = df[DATE_COL].dt.month
    df['year'] = df[DATE_COL].dt.year

    # Cyclical encoding for day_of_week
    df['dow_sin'] = np.sin(2 * np.pi * df['day_of_week'] / 7)
    df['dow_cos'] = np.cos(2 * np.pi * df['day_of_week'] / 7)

    # Lag features and rolling means per item
    df = df.set_index(DATE_COL)
    lag_features = [1, 2, 3, 7, 14]
    out_frames = []
    for item_id, group in df.groupby(ID_COL):
        g = group.sort_index().copy()
        # create lags
        for l in lag_features:
            g[f'lag_{l}'] = g[TARGET_COL].shift(l)
        # rolling windows (shift by 1 to avoid leaking today's value)
        g['roll_3_mean'] = g[TARGET_COL].shift(1).rolling(window=3, min_periods=1).mean()
        g['roll_7_mean'] = g[TARGET_COL].shift(1).rolling(window=7, min_periods=1).mean()
        g['roll_14_mean'] = g[TARGET_COL].shift(1).rolling(window=14, min_periods=1).mean()
        # fill missing lags with zeros (or another strategy)
        g.fillna(0, inplace=True)
        out_frames.append(g)
    df2 = pd.concat(out_frames).reset_index()
    return df2

def safe_datetime_series(series):
    try:
        return pd.to_datetime(series)
    except Exception:
        return pd.to_datetime(series, errors='coerce')

# -----------------------
# Main execution
# -----------------------
if __name__ == "__main__":
    # Load data
    if not os.path.exists(DATA_CSV):
        raise FileNotFoundError(f"Data file not found: {DATA_CSV}")

    df = pd.read_csv(DATA_CSV)
    print(f"Loaded {len(df)} rows from {DATA_CSV}")

    # minimal validation
    if DATE_COL not in df.columns or TARGET_COL not in df.columns or ID_COL not in df.columns:
        raise ValueError(f"CSV must contain columns: {DATE_COL}, {TARGET_COL}, {ID_COL}")

    df_feat = prepare_features(df)
    if df_feat.empty:
        print("No feature rows after preparation. Exiting.")
        exit(0)

    # Choose features to use (drop identifiers and target)
    exclude = [DATE_COL, ID_COL, TARGET_COL, 'item_name'] if 'item_name' in df_feat.columns else [DATE_COL, ID_COL, TARGET_COL]
    feature_cols = [c for c in df_feat.columns if c not in exclude]

    # ensure features are numeric where expected
    # drop non-numeric features from feature_cols
    numeric_cols = df_feat[feature_cols].select_dtypes(include=[np.number]).columns.tolist()
    dropped = set(feature_cols) - set(numeric_cols)
    if dropped:
        print("Dropping non-numeric features:", dropped)
    feature_cols = numeric_cols

    print("Features used:", feature_cols)

    # -----------------------
    # Train per-item models
    # -----------------------
    VALIDATION_DAYS = 28  # last 28 days for validation
    unique_dates = sorted(df_feat[DATE_COL].unique())
    if not unique_dates:
        print("No dates found in data. Exiting.")
        exit(0)
    cutoff_date = pd.to_datetime(unique_dates[-1]) - pd.Timedelta(days=VALIDATION_DAYS)

    summary = []
    for item_id, group in df_feat.groupby(ID_COL):
        g = group.sort_values(DATE_COL).copy()
        # split train/val by date (time-aware)
        train_df = g[g[DATE_COL] <= cutoff_date]
        val_df = g[g[DATE_COL] > cutoff_date]

        if len(train_df) < 30 or len(val_df) < 5:
            # skip items with too little history
            print(f"Skipping item {item_id} (not enough history).")
            continue

        X_train = train_df[feature_cols].fillna(0)
        y_train = train_df[TARGET_COL].values
        X_val = val_df[feature_cols].fillna(0)
        y_val = val_df[TARGET_COL].values

        # Basic LightGBM model
        model = LGBMRegressor(
            objective="regression",
            n_estimators=1000,
            learning_rate=0.05,
            num_leaves=31,
            random_state=42,
            n_jobs=4,
            verbose=-1
        )

        # Fit with early stopping; some versions accept early_stopping_rounds, otherwise use callback
        try:
            model.fit(
                X_train, y_train,
                eval_set=[(X_val, y_val)],
                eval_metric="mae",
                callbacks=[early_stopping(20), log_evaluation(0)]
            )
        except TypeError:
            # fallback to callback API
            model.fit(
                X_train, y_train,
                eval_set=[(X_val, y_val)],
                eval_metric="l1",
                callbacks=[lgb.early_stopping(stopping_rounds=50)],
                verbose=False
            )

        # Predict & evaluate
        y_pred = model.predict(X_val)
        mae = mean_absolute_error(y_val, y_pred)
        rmse = np.sqrt(mean_squared_error(y_val, y_pred))
        summary.append({'menu_item_id': item_id, 'mae': mae, 'rmse': rmse, 'train_rows': len(train_df), 'val_rows': len(val_df)})
        print(f"Item {item_id} | MAE: {mae:.3f} | RMSE: {rmse:.3f} | train {len(train_df)} val {len(val_df)}")

        # Save model
        model_path = os.path.join(MODEL_DIR, f"lgb_item_{item_id}.pkl")
        joblib.dump({'model': model, 'features': feature_cols}, model_path, compress=3)

    # Save summary
    if summary:
        summary_df = pd.DataFrame(summary)
        summary_df.to_csv(os.path.join(MODEL_DIR, "training_summary.csv"), index=False)
        print("Training summary saved.")
    else:
        print("No models were trained. No summary to save.")

    # -----------------------
    # Optional: hyperparameter tuning (example for one popular item)
    # -----------------------
    try:
        top_item_series = df_feat.groupby(ID_COL)[TARGET_COL].mean().sort_values(ascending=False)
        if top_item_series.empty:
            print("Skipping tuning: no items found.")
        else:
            top_item = top_item_series.index[0]
            print("Top item for optional tuning:", top_item)
            grp = df_feat[df_feat[ID_COL] == top_item].sort_values(DATE_COL)
            train_grp = grp[grp[DATE_COL] <= cutoff_date]
            if len(train_grp) < 50:
                print("Skipping tuning: not enough training rows for top item.")
            else:
                X = train_grp[feature_cols].fillna(0)
                y = train_grp[TARGET_COL].values

                param_dist = {
                    'num_leaves': [15, 31, 63, 127],
                    'learning_rate': [0.01, 0.03, 0.05, 0.1],
                    'n_estimators': [200, 500, 1000],
                    'min_child_samples': [5, 10, 20, 50],
                    'subsample': [0.6, 0.8, 1.0]
                }

                lgb_base = LGBMRegressor(objective="regression", random_state=42, n_jobs=4)
                search = RandomizedSearchCV(
                    lgb_base, param_distributions=param_dist, n_iter=20, cv=3,
                    scoring='neg_mean_absolute_error', verbose=1, random_state=42, n_jobs=1
                )
                try:
                    search.fit(X, y)
                    print("Best params:", search.best_params_)
                    joblib.dump(search.best_estimator_, os.path.join(MODEL_DIR, f"lgb_tuned_item_{top_item}.pkl"), compress=3)
                except Exception as e:
                    print("Tuning skipped or failed:", e)
    except Exception as e:
        print("Tuning section skipped due to error:", e)
# ...existing code...
