# generate_dummy_data.py
import pandas as pd
import numpy as np
from datetime import datetime, timedelta

np.random.seed(42)
start = datetime(2025, 7, 1)
end = datetime(2025, 10, 31)
dates = pd.date_range(start, end)

menu_items = [
    (101, "Masala Dosa", "Breakfast"),
    (102, "Poori Bhaji", "Breakfast"),
    (201, "Paneer Curry", "Lunch"),
    (202, "Veg Biryani", "Lunch"),
    (301, "Samosa", "Snack"),
]

rows = []
for d in dates:
    for mid, name, cat in menu_items:
        base = 40 if cat == "Breakfast" else 60 if cat == "Lunch" else 70
        noise = np.random.randint(-10, 10)
        confirmed = max(10, base + noise)
        prev_day = confirmed + np.random.randint(-5, 5)
        avg7 = base + np.random.randn() * 5
        rows.append([
            d.date(), mid, name, cat,
            confirmed, 120, confirmed / 120,
            prev_day, avg7, 0, 0, 30 + np.random.randn(), 0
        ])

df = pd.DataFrame(rows, columns=[
    "date", "menu_item_id", "item_name", "item_category",
    "confirmed_count", "total_employees", "confirmed_optin_rate",
    "prev_day_count", "prev_7day_avg", "is_holiday",
    "is_company_event", "temperature", "precipitation"
])

df.to_csv("canteen_history.csv", index=False)
print(f"✅ Dummy dataset created with {len(df)} rows ({df['date'].nunique()} days).")
