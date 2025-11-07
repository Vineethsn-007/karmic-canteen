"""
CanteenAI - Simple UI
Just Next Day Prediction and Weekly Forecast
"""
from flask import Flask, render_template, jsonify
from canteen_ai import CanteenAI
import pandas as pd

app = Flask(__name__)
ai = CanteenAI()

# Load data on startup
print("Loading data...")
ai.update_data()
print("Data loaded successfully!")

@app.route('/')
def index():
    return render_template('simple.html')

@app.route('/api/predict-next-day', methods=['POST'])
def predict_next_day():
    try:
        # Ensure data is loaded
        if ai.data_cache is None or ai.data_cache.empty:
            ai.update_data()
        
        predictions = ai.predict_next_day()
        
        if predictions.empty:
            return jsonify({'success': False, 'message': 'No predictions generated. Please train models first.'}), 400
        
        pred_list = predictions.to_dict('records')
        
        return jsonify({
            'success': True,
            'predictions': pred_list,
            'total_meals': int(predictions['predicted_count'].sum()),
            'avg_confidence': float(predictions['confidence'].mean()),
            'date': str(predictions['date'].iloc[0])
        })
    except Exception as e:
        return jsonify({'success': False, 'message': f'Error: {str(e)}'}), 500

@app.route('/api/predict-weekly', methods=['POST'])
def predict_weekly():
    try:
        # Ensure data is loaded
        if ai.data_cache is None or ai.data_cache.empty:
            ai.update_data()
        
        predictions = ai.predict_next_week(days=7)
        
        if predictions.empty:
            return jsonify({'success': False, 'message': 'No predictions generated. Please train models first.'}), 400
        
        daily_summary = predictions.groupby('date').agg({
            'predicted_count': 'sum',
            'confidence': 'mean'
        }).reset_index()
        
        return jsonify({
            'success': True,
            'daily_summary': daily_summary.to_dict('records'),
            'total_predictions': len(predictions),
            'total_meals': int(predictions['predicted_count'].sum()),
            'avg_confidence': float(predictions['confidence'].mean())
        })
    except Exception as e:
        return jsonify({'success': False, 'message': f'Error: {str(e)}'}), 500

if __name__ == '__main__':
    print("\n🤖 CanteenAI - Simple UI")
    print("🌐 Open: http://localhost:5000\n")
    app.run(debug=True, host='0.0.0.0', port=5000)
