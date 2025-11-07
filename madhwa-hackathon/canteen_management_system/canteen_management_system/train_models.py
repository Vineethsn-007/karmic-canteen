"""
Quick script to train models
Run this once before using the UI
"""
from canteen_ai import CanteenAI

print("\n" + "="*60)
print("🎯 Training CanteenAI Models")
print("="*60)

# Initialize
ai = CanteenAI()

# Update data
print("\n📊 Loading data...")
ai.update_data()

# Train models
print("\n🎯 Training models (this may take 30-60 seconds)...")
results = ai.train_model(force=True)

print("\n" + "="*60)
print("✅ Training Complete!")
print("="*60)
print(f"Models trained: {results.get('models_trained', 0)}")
print(f"Average MAE: {results.get('avg_mae', 0):.2f}")
print(f"Average Confidence: {results.get('avg_confidence', 0)*100:.1f}%")
print("\n✅ You can now use the UI!")
print("Run: python simple_app.py")
print("="*60 + "\n")
