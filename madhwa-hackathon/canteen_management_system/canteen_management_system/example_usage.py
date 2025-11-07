"""
Example Usage of CanteenAI
Demonstrates various ways to use the system
"""
from canteen_ai import CanteenAI
import pandas as pd


def example_1_full_pipeline():
    """Example 1: Run complete pipeline"""
    print("\n" + "="*60)
    print("EXAMPLE 1: Full Pipeline")
    print("="*60)
    
    ai = CanteenAI()
    results = ai.run_full_pipeline(retrain=True, forecast_days=7)
    
    print(f"\nResults: {results}")


def example_2_step_by_step():
    """Example 2: Step-by-step execution"""
    print("\n" + "="*60)
    print("EXAMPLE 2: Step-by-Step Execution")
    print("="*60)
    
    ai = CanteenAI()
    
    # Step 1: Update data
    print("\n1️⃣ Updating data...")
    df = ai.update_data()
    print(f"   Loaded {len(df)} records")
    
    # Step 2: Train models
    print("\n2️⃣ Training models...")
    training_results = ai.train_model(force=True)
    print(f"   Trained {training_results.get('models_trained', 0)} models")
    
    # Step 3: Generate predictions
    print("\n3️⃣ Generating predictions...")
    predictions = ai.predict_next_day()
    print(f"   Generated {len(predictions)} predictions")
    print(predictions.head())
    
    # Step 4: Analyze trends
    print("\n4️⃣ Analyzing trends...")
    insights = ai.analyze_trends()
    print("   Key insights:")
    for insight in insights.get('summary', []):
        print(f"   - {insight}")


def example_3_weekly_forecast():
    """Example 3: Generate weekly forecast"""
    print("\n" + "="*60)
    print("EXAMPLE 3: Weekly Forecast")
    print("="*60)
    
    ai = CanteenAI()
    ai.update_data()
    
    # Generate 7-day forecast
    weekly_predictions = ai.predict_next_week(days=7)
    
    print(f"\n📅 7-Day Forecast ({len(weekly_predictions)} predictions):")
    print(weekly_predictions[['date', 'menu_item_id', 'predicted_count', 'confidence']])
    
    # Group by date
    daily_totals = weekly_predictions.groupby('date')['predicted_count'].sum()
    print("\n📊 Daily Totals:")
    print(daily_totals)


def example_4_insights_report():
    """Example 4: Generate insights report"""
    print("\n" + "="*60)
    print("EXAMPLE 4: Insights Report")
    print("="*60)
    
    ai = CanteenAI()
    ai.update_data()
    
    # Generate text report
    report = ai.generate_report(output_format='text')
    print(report)


def example_5_model_evaluation():
    """Example 5: Evaluate model accuracy"""
    print("\n" + "="*60)
    print("EXAMPLE 5: Model Evaluation")
    print("="*60)
    
    ai = CanteenAI()
    ai.update_data()
    
    # Evaluate models
    eval_results = ai.evaluate_model()
    
    print("\n📈 Model Accuracy:")
    print(eval_results)
    print(f"\nAverage MAE: {eval_results['mae'].mean():.2f}")
    print(f"Average MAPE: {eval_results['mape'].mean():.1f}%")


def example_6_custom_workflow():
    """Example 6: Custom workflow with individual agents"""
    print("\n" + "="*60)
    print("EXAMPLE 6: Custom Workflow")
    print("="*60)
    
    from data_agent import DataAgent
    from train_agent import TrainAgent
    from predict_agent import PredictAgent
    
    # Use agents individually
    data_agent = DataAgent()
    train_agent = TrainAgent()
    predict_agent = PredictAgent()
    
    # Fetch last 90 days
    df = data_agent.fetch_from_firebase(days_back=90)
    print(f"✅ Fetched {len(df)} records")
    
    # Prepare features
    df_features = data_agent.prepare_features(df)
    print(f"✅ Prepared features: {df_features.shape}")
    
    # Train with custom validation period
    results = train_agent.train_model(df_features, validation_days=14)
    print(f"✅ Trained {results['models_trained']} models")
    
    # Generate predictions
    predictions = predict_agent.predict_next_day(df_features)
    print(f"✅ Generated {len(predictions)} predictions")


if __name__ == "__main__":
    print("\n🤖 CanteenAI Usage Examples")
    print("="*60)
    
    # Run examples (comment out ones you don't want to run)
    
    # Full pipeline - recommended for first run
    example_1_full_pipeline()
    
    # Uncomment to run other examples:
    # example_2_step_by_step()
    # example_3_weekly_forecast()
    # example_4_insights_report()
    # example_5_model_evaluation()
    # example_6_custom_workflow()
    
    print("\n✅ Examples completed!")
