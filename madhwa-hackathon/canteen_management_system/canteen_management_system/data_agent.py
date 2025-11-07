"""
DataAgent - Handles Firebase data ingestion, validation, and synchronization
"""
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
from firebase_config import FirebaseConfig, FirebaseCollections
import os


class DataAgent:
    """Agent responsible for data management and Firebase synchronization"""
    
    def __init__(self, local_csv: str = "canteen_history.csv"):
        self.local_csv = local_csv
        self.db = FirebaseConfig.get_db()
        self.data_cache = None
        self.last_sync = None
    
    def fetch_from_firebase(self, days_back: Optional[int] = None) -> pd.DataFrame:
        """Fetch meal data from Firebase Firestore"""
        if not self.db:
            print("⚠️ Firebase not connected. Loading from local CSV...")
            return self.load_local_data()
        
        try:
            collection_ref = self.db.collection(FirebaseCollections.MEAL_DATA)
            query = collection_ref
            
            if days_back:
                cutoff_date = datetime.now() - timedelta(days=days_back)
                query = query.where('date', '>=', cutoff_date.strftime('%Y-%m-%d'))
            
            docs = query.stream()
            records = [doc.to_dict() for doc in docs]
            
            if not records:
                return self.load_local_data()
            
            df = pd.DataFrame(records)
            print(f"✅ Fetched {len(df)} records from Firebase")
            self.data_cache = df
            self.last_sync = datetime.now()
            self.save_to_local(df)
            return df
            
        except Exception as e:
            print(f"❌ Error fetching from Firebase: {e}")
            return self.load_local_data()
    
    def load_local_data(self) -> pd.DataFrame:
        """Load data from local CSV file"""
        if not os.path.exists(self.local_csv):
            return pd.DataFrame()
        df = pd.read_csv(self.local_csv)
        print(f"✅ Loaded {len(df)} records from local CSV")
        return df
    
    def save_to_local(self, df: pd.DataFrame, path: Optional[str] = None):
        """Save DataFrame to local CSV"""
        save_path = path or self.local_csv
        df.to_csv(save_path, index=False)
        print(f"💾 Saved {len(df)} records to {save_path}")
    
    def push_to_firebase(self, df: pd.DataFrame, collection: str = None) -> int:
        """Push data to Firebase Firestore"""
        if not self.db:
            return 0
        
        collection = collection or FirebaseCollections.MEAL_DATA
        collection_ref = self.db.collection(collection)
        pushed_count = 0
        batch = self.db.batch()
        
        try:
            for idx, row in df.iterrows():
                data = {k: (None if pd.isna(v) else v) for k, v in row.to_dict().items()}
                data['updated_at'] = datetime.now().isoformat()
                doc_id = f"{data.get('date', '')}_{data.get('menu_item_id', idx)}"
                batch.set(collection_ref.document(doc_id), data, merge=True)
                pushed_count += 1
                
                if pushed_count % 500 == 0:
                    batch.commit()
                    batch = self.db.batch()
            
            if pushed_count % 500 != 0:
                batch.commit()
            
            print(f"✅ Pushed {pushed_count} records to Firebase")
            return pushed_count
        except Exception as e:
            print(f"❌ Error: {e}")
            return pushed_count
    
    def validate_data(self, df: pd.DataFrame) -> Tuple[pd.DataFrame, List[str]]:
        """Validate and clean data"""
        warnings = []
        df_clean = df.copy()
        
        required_cols = ['date', 'total_employees', 'confirmed_count']
        missing = [c for c in required_cols if c not in df_clean.columns]
        if missing:
            warnings.append(f"Missing columns: {missing}")
            return df_clean, warnings
        
        df_clean['date'] = pd.to_datetime(df_clean['date'])
        
        if 'opt_in_rate' not in df_clean.columns:
            df_clean['opt_in_rate'] = df_clean['confirmed_count'] / df_clean['total_employees']
            df_clean['opt_in_rate'] = df_clean['opt_in_rate'].clip(0, 1)
        
        return df_clean, warnings
    
    def prepare_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """Prepare features for model training"""
        df_feat = df.copy()
        df_feat['date'] = pd.to_datetime(df_feat['date'])
        df_feat = df_feat.sort_values(['menu_item_id', 'date']).reset_index(drop=True)
        
        df_feat['day_of_week'] = df_feat['date'].dt.weekday
        df_feat['month'] = df_feat['date'].dt.month
        df_feat['year'] = df_feat['date'].dt.year
        df_feat['dow_sin'] = np.sin(2 * np.pi * df_feat['day_of_week'] / 7)
        df_feat['dow_cos'] = np.cos(2 * np.pi * df_feat['day_of_week'] / 7)
        
        target_col = 'confirmed_count'
        df_feat = df_feat.set_index('date')
        out_frames = []
        
        for item_id, group in df_feat.groupby('menu_item_id'):
            g = group.sort_index().copy()
            for lag in [1, 2, 3, 7, 14]:
                g[f'lag_{lag}'] = g[target_col].shift(lag)
            for window in [3, 7, 14]:
                g[f'roll_{window}_mean'] = g[target_col].shift(1).rolling(window, min_periods=1).mean()
            g = g.fillna(0)
            out_frames.append(g)
        
        df_feat = pd.concat(out_frames).reset_index()
        return df_feat
    
    def update_data(self) -> pd.DataFrame:
        """Update data from Firebase and prepare features"""
        print("\n🔄 Updating data...")
        df_raw = self.fetch_from_firebase()
        if df_raw.empty:
            return pd.DataFrame()
        df_clean, warnings = self.validate_data(df_raw)
        df_features = self.prepare_features(df_clean)
        self.save_to_local(df_features, "canteen_history_processed.csv")
        return df_features
