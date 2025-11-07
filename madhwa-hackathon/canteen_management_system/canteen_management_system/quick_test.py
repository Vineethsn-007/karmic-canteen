"""Quick test of CanteenAI predictions"""
from canteen_ai import CanteenAI

print("\n" + "="*60)
print("🔮 CANTEEN AI - QUICK PREDICTION TEST")
print("="*60)

# Initialize
ai = CanteenAI()

# Update data
print("\n1️⃣ Loading data...")
ai.update_data()

# Generate next-day predictions
print("\n2️⃣ Generating next-day predictions...")
predictions = ai.predict_next_day()

print("\n" + "="*60)
print("📊 NEXT DAY PREDICTIONS")
print("="*60)
print(predictions[['date', 'menu_item_id', 'predicted_count', 'confidence', 'lower_bound', 'upper_bound']])

print("\n" + "="*60)
print("📈 SUMMARY")
print("="*60)
print(f"Total predicted meals: {predictions['predicted_count'].sum()}")
print(f"Average confidence: {predictions['confidence'].mean():.1%}")
print(f"Prediction range: {predictions['lower_bound'].sum()}-{predictions['upper_bound'].sum()} meals")

print("\n✅ Test completed successfully!")
