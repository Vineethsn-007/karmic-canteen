"""
CanteenAI Configuration
Centralized configuration for all agents
"""
import os


class Config:
    """Main configuration class"""
    
    # Firebase Configuration
    FIREBASE_CREDENTIALS = os.getenv('FIREBASE_CREDENTIALS', None)
    
    # Data Configuration
    LOCAL_CSV_PATH = "canteen_history.csv"
    PROCESSED_CSV_PATH = "canteen_history_processed.csv"
    
    # Model Configuration
    MODEL_DIR = "models_per_item"
    MODEL_VERSION = "v2.1"
    
    # Training Configuration
    VALIDATION_DAYS = 28
    MIN_TRAINING_SAMPLES = 30
    MIN_VALIDATION_SAMPLES = 5
    
    # LightGBM Hyperparameters
    LGBM_PARAMS = {
        'objective': 'regression',
        'n_estimators': 1000,
        'learning_rate': 0.05,
        'num_leaves': 31,
        'max_depth': 7,
        'min_child_samples': 10,
        'subsample': 0.8,
        'colsample_bytree': 0.8,
        'random_state': 42,
        'n_jobs': -1,
        'verbose': -1
    }
    
    # Feature Engineering
    LAG_PERIODS = [1, 2, 3, 7, 14]
    ROLLING_WINDOWS = [3, 7, 14]
    
    # Retraining Triggers
    RETRAIN_NEW_RECORDS_THRESHOLD = 20
    RETRAIN_DAYS_THRESHOLD = 7
    
    # Prediction Configuration
    DEFAULT_FORECAST_DAYS = 7
    CONFIDENCE_THRESHOLD = 0.80
    
    # Firebase Collections
    COLLECTION_MEAL_DATA = "canteen_meal_data"
    COLLECTION_PREDICTIONS = "canteen_predictions"
    COLLECTION_MODEL_METADATA = "model_metadata"
    COLLECTION_INSIGHTS = "canteen_insights"
    COLLECTION_TRAINING_LOGS = "training_logs"
    
    # Target Column
    TARGET_COLUMN = "confirmed_count"
    ID_COLUMN = "menu_item_id"
    DATE_COLUMN = "date"
    
    # Output Configuration
    INSIGHTS_JSON_PATH = "canteen_insights.json"
    REPORT_OUTPUT_DIR = "reports"
    
    @classmethod
    def get_firebase_credentials(cls):
        """Get Firebase credentials path"""
        return cls.FIREBASE_CREDENTIALS
    
    @classmethod
    def set_firebase_credentials(cls, path: str):
        """Set Firebase credentials path"""
        cls.FIREBASE_CREDENTIALS = path
        os.environ['FIREBASE_CREDENTIALS'] = path
    
    @classmethod
    def get_model_params(cls):
        """Get model hyperparameters"""
        return cls.LGBM_PARAMS.copy()
    
    @classmethod
    def update_model_params(cls, **kwargs):
        """Update model hyperparameters"""
        cls.LGBM_PARAMS.update(kwargs)


# Development/Testing Configuration
class DevConfig(Config):
    """Development configuration with relaxed constraints"""
    MIN_TRAINING_SAMPLES = 10
    MIN_VALIDATION_SAMPLES = 3
    VALIDATION_DAYS = 7
    RETRAIN_DAYS_THRESHOLD = 1


# Production Configuration
class ProdConfig(Config):
    """Production configuration with strict constraints"""
    MIN_TRAINING_SAMPLES = 50
    MIN_VALIDATION_SAMPLES = 10
    VALIDATION_DAYS = 28
    CONFIDENCE_THRESHOLD = 0.85


# Select active configuration
ACTIVE_CONFIG = Config  # Change to DevConfig or ProdConfig as needed


if __name__ == "__main__":
    print("CanteenAI Configuration")
    print("=" * 60)
    print(f"Model Directory: {Config.MODEL_DIR}")
    print(f"Model Version: {Config.MODEL_VERSION}")
    print(f"Validation Days: {Config.VALIDATION_DAYS}")
    print(f"Lag Periods: {Config.LAG_PERIODS}")
    print(f"Rolling Windows: {Config.ROLLING_WINDOWS}")
    print(f"Retrain Threshold: {Config.RETRAIN_NEW_RECORDS_THRESHOLD} records or {Config.RETRAIN_DAYS_THRESHOLD} days")
    print("=" * 60)
