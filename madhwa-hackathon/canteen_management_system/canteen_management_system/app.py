"""
CanteenAI Web UI
Simple Flask-based dashboard for running predictions and viewing insights
"""
from flask import Flask, render_template, jsonify, request, send_file
from canteen_ai import CanteenAI
from data_agent import DataAgent
from predict_agent import PredictAgent
from insight_agent import InsightAgent
import pandas as pd
import json
from datetime import datetime
import os

app = Flask(__name__)

# Initialize CanteenAI
ai = CanteenAI()

@app.route('/')
def index():
    """Main dashboard page"""
    return render_template('index.html')

@app.route('/api/status')
def status():
    """Get system status"""
    try:
        # Check if data is loaded
        data_exists = os.path.exists('canteen_history.csv')
        models_exist = os.path.exists('models_per_item') and len(os.listdir('models_per_item')) > 0
        
        # Get data stats
        if data_exists:
            df = pd.read_csv('canteen_history.csv')
            data_stats = {
                'total_records': len(df),
                'date_range': f"{df['date'].min()} to {df['date'].max()}",
                'menu_items': int(df['menu_item_id'].nunique())
            }
        else:
            data_stats = None
        
        return jsonify({
            'status': 'online',
            'data_loaded': data_exists,
            'models_trained': models_exist,
            'data_stats': data_stats,
            'timestamp': datetime.now().isoformat()
        })
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/api/update-data', methods=['POST'])
def update_data():
    """Update data from Firebase or local CSV"""
    try:
        df = ai.update_data()
        return jsonify({
            'success': True,
            'records': len(df),
            'message': f'Successfully loaded {len(df)} records'
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/train', methods=['POST'])
def train_models():
    """Train ML models"""
    try:
        results = ai.train_model(force=True)
        return jsonify({
            'success': True,
            'models_trained': results.get('models_trained', 0),
            'avg_mae': results.get('avg_mae', 0),
            'avg_confidence': results.get('avg_confidence', 0),
            'message': f"Trained {results.get('models_trained', 0)} models successfully"
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/predict-next-day', methods=['POST'])
def predict_next_day():
    """Generate next-day predictions"""
    try:
        predictions = ai.predict_next_day()
        
        if predictions.empty:
            return jsonify({'success': False, 'message': 'No predictions generated'}), 400
        
        # Convert to dict for JSON
        pred_list = predictions.to_dict('records')
        
        return jsonify({
            'success': True,
            'predictions': pred_list,
            'total_meals': int(predictions['predicted_count'].sum()),
            'avg_confidence': float(predictions['confidence'].mean()),
            'date': str(predictions['date'].iloc[0])
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/predict-weekly', methods=['POST'])
def predict_weekly():
    """Generate weekly predictions"""
    try:
        days = request.json.get('days', 7)
        predictions = ai.predict_next_week(days=days)
        
        if predictions.empty:
            return jsonify({'success': False, 'message': 'No predictions generated'}), 400
        
        # Group by date
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
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/insights')
def get_insights():
    """Get trend insights"""
    try:
        insights = ai.analyze_trends()
        return jsonify({
            'success': True,
            'insights': insights
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/run-pipeline', methods=['POST'])
def run_pipeline():
    """Run full pipeline"""
    try:
        results = ai.run_full_pipeline(retrain=True, forecast_days=7)
        return jsonify({
            'success': True,
            'results': results
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/download-predictions')
def download_predictions():
    """Download latest predictions as CSV"""
    try:
        # Find latest prediction file
        pred_files = [f for f in os.listdir('models_per_item') if f.startswith('predictions_')]
        if not pred_files:
            return jsonify({'success': False, 'message': 'No predictions found'}), 404
        
        latest_file = sorted(pred_files)[-1]
        file_path = os.path.join('models_per_item', latest_file)
        
        return send_file(file_path, as_attachment=True)
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

if __name__ == '__main__':
    print("\n" + "="*60)
    print("🤖 CanteenAI Web UI")
    print("="*60)
    print("\n🌐 Starting server...")
    print("📱 Open your browser and go to: http://localhost:5000")
    print("\n⚠️  Press Ctrl+C to stop the server")
    print("="*60 + "\n")
    
    app.run(debug=True, host='0.0.0.0', port=5000)
