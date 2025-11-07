"""
CanteenAI - Main Orchestrator
Intelligent agent for managing canteen meal demand forecasting
"""
import pandas as pd
from datetime import datetime, timedelta
from typing import Dict, Optional
import argparse

from firebase_config import FirebaseConfig
from data_agent import DataAgent
from train_agent import TrainAgent
from predict_agent import PredictAgent
from insight_agent import InsightAgent


class CanteenAI:
    """
    Main CanteenAI orchestrator that coordinates all agents
    
    Usage:
        ai = CanteenAI()
        ai.run_full_pipeline()
    """
    
    def __init__(self, firebase_credentials: Optional[str] = None):
        """
        Initialize CanteenAI
        
        Args:
            firebase_credentials: Path to Firebase credentials JSON
        """
        print("\n" + "=" * 60)
        print("🤖 CANTEEN AI - Intelligent Meal Demand Forecasting")
        print("=" * 60)
        
        # Initialize Firebase
        if firebase_credentials:
            FirebaseConfig.initialize(firebase_credentials)
        else:
            FirebaseConfig.initialize()
        
        # Initialize agents
        self.data_agent = DataAgent()
        self.train_agent = TrainAgent()
        self.predict_agent = PredictAgent()
        self.insight_agent = InsightAgent()
        
        self.last_training_date = None
        self.data_cache = None
        
        print("✅ CanteenAI initialized successfully")
    
    def update_data(self, days_back: Optional[int] = None) -> pd.DataFrame:
        """
        Fetch and update data from Firebase
        
        Args:
            days_back: Number of days to fetch (None = all data)
        
        Returns:
            Updated DataFrame
        """
        print("\n📥 STEP 1: Updating data from Firebase...")
        self.data_cache = self.data_agent.update_data()
        return self.data_cache
    
    def train_model(self, force: bool = False) -> Dict:
        """
        Train or retrain models
        
        Args:
            force: Force retraining even if not needed
        
        Returns:
            Training results dictionary
        """
        print("\n🎯 STEP 2: Training models...")
        
        if self.data_cache is None or self.data_cache.empty:
            print("❌ No data available for training")
            return {'error': 'no_data'}
        
        # Check if retraining is needed
        if not force:
            days_since = 0
            if self.last_training_date:
                days_since = (datetime.now() - self.last_training_date).days
            
            if not self.train_agent.should_retrain(days_since_training=days_since):
                print("ℹ️ Retraining not needed yet")
                return {'status': 'skipped', 'reason': 'not_needed'}
        
        # Train models
        results = self.train_agent.train_model(self.data_cache)
        self.last_training_date = datetime.now()
        
        return results
    
    def predict_next_day(self) -> pd.DataFrame:
        """
        Generate predictions for next day
        
        Returns:
            DataFrame with predictions
        """
        print("\n🔮 STEP 3: Generating next-day predictions...")
        
        if self.data_cache is None or self.data_cache.empty:
            print("❌ No data available for predictions")
            return pd.DataFrame()
        
        predictions = self.predict_agent.predict_next_day(self.data_cache)
        return predictions
    
    def predict_next_week(self, days: int = 7) -> pd.DataFrame:
        """
        Generate predictions for next N days
        
        Args:
            days: Number of days to predict
        
        Returns:
            DataFrame with weekly predictions
        """
        print(f"\n📅 Generating {days}-day forecast...")
        
        if self.data_cache is None or self.data_cache.empty:
            print("❌ No data available for predictions")
            return pd.DataFrame()
        
        predictions = self.predict_agent.predict_weekly(self.data_cache, days=days)
        return predictions
    
    def analyze_trends(self) -> Dict:
        """
        Generate insights and trend analysis
        
        Returns:
            Dictionary with insights
        """
        print("\n📊 STEP 4: Analyzing trends...")
        
        if self.data_cache is None or self.data_cache.empty:
            print("❌ No data available for analysis")
            return {}
        
        insights = self.insight_agent.analyze_trends(self.data_cache)
        return insights
    
    def evaluate_model(self) -> pd.DataFrame:
        """
        Evaluate model accuracy
        
        Returns:
            DataFrame with evaluation metrics
        """
        print("\n📈 Evaluating model accuracy...")
        
        if self.data_cache is None or self.data_cache.empty:
            print("❌ No data available for evaluation")
            return pd.DataFrame()
        
        eval_results = self.train_agent.evaluate_model(self.data_cache)
        return eval_results
    
    def push_prediction_to_firebase(self, predictions: pd.DataFrame) -> int:
        """
        Upload predictions to Firebase
        
        Args:
            predictions: DataFrame with predictions
        
        Returns:
            Number of records pushed
        """
        print("\n☁️ Pushing predictions to Firebase...")
        return self.predict_agent.push_predictions_to_firebase(predictions)
    
    def run_full_pipeline(self, retrain: bool = True, forecast_days: int = 7) -> Dict:
        """
        Run the complete CanteenAI pipeline
        
        Args:
            retrain: Whether to retrain models
            forecast_days: Number of days to forecast
        
        Returns:
            Dictionary with all results
        """
        print("\n" + "=" * 60)
        print("🚀 RUNNING FULL CANTEEN AI PIPELINE")
        print("=" * 60)
        
        results = {
            'timestamp': datetime.now().isoformat(),
            'status': 'success'
        }
        
        try:
            # Step 1: Update data
            df = self.update_data()
            results['data_records'] = len(df)
            
            if df.empty:
                results['status'] = 'failed'
                results['error'] = 'no_data'
                return results
            
            # Step 2: Train models
            if retrain:
                training_results = self.train_model(force=True)
                results['training'] = training_results
            
            # Step 3: Generate predictions
            next_day_pred = self.predict_next_day()
            results['next_day_predictions'] = len(next_day_pred)
            
            if forecast_days > 1:
                weekly_pred = self.predict_next_week(days=forecast_days)
                results['weekly_predictions'] = len(weekly_pred)
            
            # Step 4: Analyze trends
            insights = self.analyze_trends()
            results['insights'] = insights.get('summary', [])
            
            # Step 5: Evaluate models
            eval_results = self.evaluate_model()
            if not eval_results.empty:
                results['model_accuracy'] = {
                    'avg_mae': float(eval_results['mae'].mean()),
                    'avg_mape': float(eval_results['mape'].mean())
                }
            
            print("\n" + "=" * 60)
            print("✅ PIPELINE COMPLETED SUCCESSFULLY")
            print("=" * 60)
            print(f"📊 Data records: {results['data_records']}")
            print(f"🎯 Models trained: {results.get('training', {}).get('models_trained', 0)}")
            print(f"🔮 Predictions generated: {results['next_day_predictions']}")
            print("\n💡 Key Insights:")
            for insight in results.get('insights', []):
                print(f"   {insight}")
            print("=" * 60)
            
            return results
            
        except Exception as e:
            print(f"\n❌ Pipeline failed: {e}")
            results['status'] = 'failed'
            results['error'] = str(e)
            return results
    
    def generate_report(self, output_format: str = 'text') -> str:
        """
        Generate comprehensive report
        
        Args:
            output_format: 'text' or 'json'
        
        Returns:
            Report string
        """
        if self.data_cache is None or self.data_cache.empty:
            self.update_data()
        
        return self.insight_agent.generate_report(self.data_cache, output_format)


def main():
    """Command-line interface for CanteenAI"""
    parser = argparse.ArgumentParser(description='CanteenAI - Intelligent Meal Demand Forecasting')
    parser.add_argument('--action', type=str, default='full',
                       choices=['full', 'update', 'train', 'predict', 'analyze', 'report'],
                       help='Action to perform')
    parser.add_argument('--days', type=int, default=7,
                       help='Number of days to forecast')
    parser.add_argument('--credentials', type=str, default=None,
                       help='Path to Firebase credentials JSON')
    parser.add_argument('--no-retrain', action='store_true',
                       help='Skip model retraining')
    
    args = parser.parse_args()
    
    # Initialize CanteenAI
    ai = CanteenAI(firebase_credentials=args.credentials)
    
    # Execute requested action
    if args.action == 'full':
        results = ai.run_full_pipeline(retrain=not args.no_retrain, forecast_days=args.days)
        
    elif args.action == 'update':
        df = ai.update_data()
        print(f"✅ Updated {len(df)} records")
        
    elif args.action == 'train':
        results = ai.train_model(force=True)
        print(f"✅ Trained {results.get('models_trained', 0)} models")
        
    elif args.action == 'predict':
        if args.days == 1:
            predictions = ai.predict_next_day()
        else:
            predictions = ai.predict_next_week(days=args.days)
        print(f"✅ Generated {len(predictions)} predictions")
        print(predictions)
        
    elif args.action == 'analyze':
        insights = ai.analyze_trends()
        print("\n💡 Key Insights:")
        for insight in insights.get('summary', []):
            print(f"   {insight}")
        
    elif args.action == 'report':
        report = ai.generate_report(output_format='text')
        print(report)


if __name__ == "__main__":
    # Example usage without command line
    print("\n🤖 Starting CanteenAI...")
    
    # Initialize
    ai = CanteenAI()
    
    # Run full pipeline
    results = ai.run_full_pipeline(retrain=True, forecast_days=7)
    
    # Generate report
    print("\n📄 Generating detailed report...")
    report = ai.generate_report(output_format='text')
    print(report)
