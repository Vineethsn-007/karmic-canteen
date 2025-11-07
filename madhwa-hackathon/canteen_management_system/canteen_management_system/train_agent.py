"""
TrainAgent - Manages ML model lifecycle, training, and evaluation
"""
import pandas as pd
import numpy as np
import joblib
import os
from datetime import datetime
from typing import Dict, List, Tuple, Optional
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from lightgbm import LGBMRegressor, early_stopping, log_evaluation
from firebase_config import FirebaseConfig, FirebaseCollections


class TrainAgent:
    """Agent responsible for model training and lifecycle management"""
    
    def __init__(self, model_dir: str = "models_per_item"):
        self.model_dir = model_dir
        os.makedirs(model_dir, exist_ok=True)
        self.db = FirebaseConfig.get_db()
        self.models = {}
        self.training_history = []
        self.model_version = "v2.1"
    
    def train_model(self, 
                   df: pd.DataFrame,
                   target_col: str = 'confirmed_count',
                   validation_days: int = 28) -> Dict:
        """
        Train models for each menu item
        
        Args:
            df: Feature-engineered DataFrame
            target_col: Target column name
            validation_days: Days to use for validation
        
        Returns:
            Training summary dictionary
        """
        print(f"\n🎯 Training models (validation: {validation_days} days)...")
        
        # Prepare data
        df = df.copy()
        df['date'] = pd.to_datetime(df['date'])
        
        # Define features
        exclude_cols = ['date', 'menu_item_id', target_col, 'item_name', 'doc_id']
        feature_cols = [c for c in df.columns if c not in exclude_cols]
        feature_cols = df[feature_cols].select_dtypes(include=[np.number]).columns.tolist()
        
        print(f"📊 Features: {len(feature_cols)} columns")
        
        # Split by date
        unique_dates = sorted(df['date'].unique())
        cutoff_date = pd.to_datetime(unique_dates[-1]) - pd.Timedelta(days=validation_days)
        
        summary = []
        
        for item_id, group in df.groupby('menu_item_id'):
            g = group.sort_values('date').copy()
            train_df = g[g['date'] <= cutoff_date]
            val_df = g[g['date'] > cutoff_date]
            
            if len(train_df) < 30 or len(val_df) < 5:
                print(f"⏭️ Skipping item {item_id} (insufficient data)")
                continue
            
            X_train = train_df[feature_cols].fillna(0)
            y_train = train_df[target_col].values
            X_val = val_df[feature_cols].fillna(0)
            y_val = val_df[target_col].values
            
            # Train LightGBM model
            model = LGBMRegressor(
                objective="regression",
                n_estimators=1000,
                learning_rate=0.05,
                num_leaves=31,
                max_depth=7,
                min_child_samples=10,
                subsample=0.8,
                colsample_bytree=0.8,
                random_state=42,
                n_jobs=-1,
                verbose=-1
            )
            
            try:
                model.fit(
                    X_train, y_train,
                    eval_set=[(X_val, y_val)],
                    eval_metric="mae",
                    callbacks=[early_stopping(20), log_evaluation(0)]
                )
            except:
                model.fit(X_train, y_train)
            
            # Evaluate
            y_pred = model.predict(X_val)
            mae = mean_absolute_error(y_val, y_pred)
            rmse = np.sqrt(mean_squared_error(y_val, y_pred))
            r2 = r2_score(y_val, y_pred)
            
            # Calculate confidence (inverse of normalized MAE)
            mean_val = y_val.mean() if y_val.mean() > 0 else 1
            confidence = max(0, 1 - (mae / mean_val))
            
            summary.append({
                'menu_item_id': item_id,
                'mae': mae,
                'rmse': rmse,
                'r2_score': r2,
                'confidence': confidence,
                'train_rows': len(train_df),
                'val_rows': len(val_df),
                'trained_at': datetime.now().isoformat(),
                'model_version': self.model_version
            })
            
            print(f"✅ Item {item_id} | MAE: {mae:.2f} | RMSE: {rmse:.2f} | R²: {r2:.3f} | Conf: {confidence:.2%}")
            
            # Save model
            model_path = os.path.join(self.model_dir, f"lgb_item_{item_id}.pkl")
            joblib.dump({
                'model': model,
                'features': feature_cols,
                'metadata': summary[-1]
            }, model_path, compress=3)
            
            self.models[item_id] = model
        
        # Save summary
        if summary:
            summary_df = pd.DataFrame(summary)
            summary_path = os.path.join(self.model_dir, "training_summary.csv")
            summary_df.to_csv(summary_path, index=False)
            print(f"\n📊 Training complete! {len(summary)} models trained.")
            
            # Push to Firebase
            self.push_training_log_to_firebase(summary_df)
            
            return {
                'models_trained': len(summary),
                'avg_mae': summary_df['mae'].mean(),
                'avg_confidence': summary_df['confidence'].mean(),
                'summary': summary
            }
        else:
            print("❌ No models trained")
            return {'models_trained': 0}
    
    def evaluate_model(self, df: pd.DataFrame, target_col: str = 'confirmed_count') -> pd.DataFrame:
        """
        Evaluate model accuracy against actual values
        
        Returns:
            DataFrame with evaluation metrics
        """
        print("\n📈 Evaluating model accuracy...")
        
        results = []
        
        for item_id in df['menu_item_id'].unique():
            model_path = os.path.join(self.model_dir, f"lgb_item_{item_id}.pkl")
            
            if not os.path.exists(model_path):
                continue
            
            bundle = joblib.load(model_path)
            model = bundle['model']
            features = bundle['features']
            
            item_df = df[df['menu_item_id'] == item_id].copy()
            X = item_df[features].fillna(0)
            y_actual = item_df[target_col].values
            y_pred = model.predict(X)
            
            mae = mean_absolute_error(y_actual, y_pred)
            rmse = np.sqrt(mean_squared_error(y_actual, y_pred))
            mape = np.mean(np.abs((y_actual - y_pred) / (y_actual + 1))) * 100
            
            results.append({
                'menu_item_id': item_id,
                'mae': mae,
                'rmse': rmse,
                'mape': mape,
                'samples': len(item_df)
            })
        
        eval_df = pd.DataFrame(results)
        print(f"✅ Evaluated {len(eval_df)} models")
        print(f"   Avg MAE: {eval_df['mae'].mean():.2f}")
        print(f"   Avg MAPE: {eval_df['mape'].mean():.1f}%")
        
        return eval_df
    
    def should_retrain(self, new_records_count: int = 0, days_since_training: int = 0) -> bool:
        """
        Determine if model should be retrained
        
        Args:
            new_records_count: Number of new records since last training
            days_since_training: Days since last training
        
        Returns:
            Boolean indicating if retraining is needed
        """
        # Retrain if 20+ new records or 7+ days
        if new_records_count >= 20:
            print(f"🔄 Retraining triggered: {new_records_count} new records")
            return True
        
        if days_since_training >= 7:
            print(f"🔄 Retraining triggered: {days_since_training} days since last training")
            return True
        
        return False
    
    def push_training_log_to_firebase(self, summary_df: pd.DataFrame):
        """Push training logs to Firebase"""
        if not self.db:
            return
        
        try:
            collection_ref = self.db.collection(FirebaseCollections.TRAINING_LOGS)
            log_data = {
                'timestamp': datetime.now().isoformat(),
                'model_version': self.model_version,
                'models_trained': len(summary_df),
                'avg_mae': float(summary_df['mae'].mean()),
                'avg_confidence': float(summary_df['confidence'].mean()),
                'details': summary_df.to_dict('records')
            }
            collection_ref.add(log_data)
            print("✅ Training log pushed to Firebase")
        except Exception as e:
            print(f"⚠️ Could not push training log: {e}")
    
    def load_model(self, item_id: int) -> Optional[Dict]:
        """Load a trained model for specific item"""
        model_path = os.path.join(self.model_dir, f"lgb_item_{item_id}.pkl")
        if os.path.exists(model_path):
            return joblib.load(model_path)
        return None
    
    def get_feature_importance(self, item_id: int, top_n: int = 10) -> pd.DataFrame:
        """Get feature importance for a specific model"""
        bundle = self.load_model(item_id)
        if not bundle:
            return pd.DataFrame()
        
        model = bundle['model']
        features = bundle['features']
        
        importance_df = pd.DataFrame({
            'feature': features,
            'importance': model.feature_importances_
        }).sort_values('importance', ascending=False).head(top_n)
        
        return importance_df


if __name__ == "__main__":
    # Test training
    from data_agent import DataAgent
    
    data_agent = DataAgent()
    df = data_agent.update_data()
    
    if not df.empty:
        train_agent = TrainAgent()
        results = train_agent.train_model(df)
        print(f"\n🎉 Training Results: {results}")
