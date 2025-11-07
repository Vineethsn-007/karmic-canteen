"""Test weekly forecast"""
from canteen_ai import CanteenAI
import pandas as pd

print("\n" + "="*60)
print("📅 CANTEEN AI - WEEKLY FORECAST TEST")
print("="*60)

# Initialize
ai = CanteenAI()
ai.update_data()

# Generate 7-day forecast
print("\n🔮 Generating 7-day forecast...")
weekly = ai.predict_next_week(days=7)

print("\n" + "="*60)
print("📊 7-DAY FORECAST BY DATE")
print("="*60)

# Group by date
daily_summary = weekly.groupby('date').agg({
    'predicted_count': 'sum',
    'confidence': 'mean',
    'lower_bound': 'sum',
    'upper_bound': 'sum'
}).round(2)

print(daily_summary)

print("\n" + "="*60)
print("📈 WEEKLY SUMMARY")
print("="*60)
print(f"Total predictions: {len(weekly)}")
print(f"Total meals (7 days): {weekly['predicted_count'].sum()}")
print(f"Daily average: {weekly['predicted_count'].sum() / 7:.0f} meals")
print(f"Average confidence: {weekly['confidence'].mean():.1%}")

print("\n" + "="*60)
print("🍽️ PREDICTIONS BY MENU ITEM")
print("="*60)
item_summary = weekly.groupby('menu_item_id')['predicted_count'].sum().sort_values(ascending=False)
for item_id, total in item_summary.items():
    print(f"Item {item_id}: {total} meals over 7 days (avg {total/7:.0f}/day)")

print("\n✅ Weekly forecast test completed!")
