"""
InsightAgent - Generates trend analysis and insights
"""
import pandas as pd
import numpy as np
from datetime import datetime
from typing import Dict, List, Optional
from firebase_config import FirebaseConfig, FirebaseCollections
import json


class InsightAgent:
    """Agent responsible for generating insights and trend reports"""
    
    def __init__(self):
        self.db = FirebaseConfig.get_db()
    
    def analyze_trends(self, df: pd.DataFrame) -> Dict:
        """
        Analyze meal demand trends
        
        Args:
            df: Historical data
        
        Returns:
            Dictionary with insights
        """
        print("\n📊 Analyzing trends...")
        
        df = df.copy()
        df['date'] = pd.to_datetime(df['date'])
        
        insights = {
            'generated_at': datetime.now().isoformat(),
            'data_period': {
                'start': str(df['date'].min().date()),
                'end': str(df['date'].max().date()),
                'days': (df['date'].max() - df['date'].min()).days
            }
        }
        
        # Day of week analysis
        insights['day_of_week'] = self._analyze_day_of_week(df)
        
        # Weather impact
        if 'temperature' in df.columns and 'precipitation' in df.columns:
            insights['weather_impact'] = self._analyze_weather_impact(df)
        
        # Holiday impact
        if 'is_holiday' in df.columns:
            insights['holiday_impact'] = self._analyze_holiday_impact(df)
        
        # Item popularity
        insights['item_popularity'] = self._analyze_item_popularity(df)
        
        # Trends over time
        insights['temporal_trends'] = self._analyze_temporal_trends(df)
        
        # Generate summary
        insights['summary'] = self._generate_summary(insights)
        
        # Save insights
        self._save_insights(insights)
        
        return insights
    
    def _analyze_day_of_week(self, df: pd.DataFrame) -> Dict:
        """Analyze patterns by day of week"""
        df['day_of_week'] = df['date'].dt.weekday
        df['day_name'] = df['date'].dt.day_name()
        
        dow_stats = df.groupby('day_name', observed=False).agg({
            'confirmed_count': ['mean', 'std', 'count'],
            'opt_in_rate': 'mean' if 'opt_in_rate' in df.columns else 'confirmed_count'
        }).round(2)
        
        # Order by weekday
        day_order = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
        dow_stats = dow_stats.reindex([d for d in day_order if d in dow_stats.index])
        
        # Convert to simple dict structure
        avg_by_day = {}
        for day in dow_stats.index:
            avg_by_day[day] = float(dow_stats.loc[day, ('confirmed_count', 'mean')])
        
        return {
            'best_day': dow_stats[('confirmed_count', 'mean')].idxmax(),
            'worst_day': dow_stats[('confirmed_count', 'mean')].idxmin(),
            'avg_by_day': avg_by_day
        }
    
    def _analyze_weather_impact(self, df: pd.DataFrame) -> Dict:
        """Analyze weather impact on meal demand"""
        # Temperature bins
        df['temp_bin'] = pd.cut(df['temperature'], bins=3, labels=['Cool', 'Moderate', 'Hot'])
        temp_impact = df.groupby('temp_bin')['confirmed_count'].mean().to_dict()
        
        # Precipitation impact
        df['rainy'] = df['precipitation'] > 0.5
        rainy_impact = df.groupby('rainy')['confirmed_count'].mean().to_dict()
        
        if True in rainy_impact and False in rainy_impact:
            rain_effect = ((rainy_impact[True] - rainy_impact[False]) / rainy_impact[False] * 100)
        else:
            rain_effect = 0
        
        return {
            'temperature_impact': temp_impact,
            'rainy_day_effect': f"{rain_effect:+.1f}%",
            'avg_meals_rainy': round(rainy_impact.get(True, 0), 1),
            'avg_meals_clear': round(rainy_impact.get(False, 0), 1)
        }
    
    def _analyze_holiday_impact(self, df: pd.DataFrame) -> Dict:
        """Analyze holiday impact on meal demand"""
        holiday_stats = df.groupby('is_holiday')['confirmed_count'].agg(['mean', 'count']).to_dict()
        
        if True in holiday_stats['mean'] and False in holiday_stats['mean']:
            holiday_effect = ((holiday_stats['mean'][True] - holiday_stats['mean'][False]) / 
                            holiday_stats['mean'][False] * 100)
        else:
            holiday_effect = 0
        
        return {
            'holiday_effect': f"{holiday_effect:+.1f}%",
            'avg_meals_holiday': round(holiday_stats['mean'].get(True, 0), 1),
            'avg_meals_regular': round(holiday_stats['mean'].get(False, 0), 1)
        }
    
    def _analyze_item_popularity(self, df: pd.DataFrame) -> Dict:
        """Analyze menu item popularity"""
        if 'menu_item_id' not in df.columns:
            return {}
        
        item_stats = df.groupby('menu_item_id').agg({
            'confirmed_count': ['mean', 'sum', 'count'],
            'item_name': 'first' if 'item_name' in df.columns else 'menu_item_id'
        }).round(2)
        
        top_items = item_stats.nlargest(5, ('confirmed_count', 'mean'))
        
        # Convert to simple dict
        top_items_dict = {}
        for idx, row in top_items.iterrows():
            top_items_dict[str(idx)] = {
                'avg_count': float(row[('confirmed_count', 'mean')]),
                'total_count': float(row[('confirmed_count', 'sum')])
            }
        
        return {
            'top_5_items': top_items_dict,
            'total_items': len(item_stats)
        }
    
    def _analyze_temporal_trends(self, df: pd.DataFrame) -> Dict:
        """Analyze trends over time"""
        df = df.sort_values('date')
        
        # Monthly trends
        df['month'] = df['date'].dt.to_period('M')
        monthly = df.groupby('month')['confirmed_count'].mean().to_dict()
        monthly = {str(k): round(v, 2) for k, v in monthly.items()}
        
        # Weekly moving average
        weekly_avg = df.set_index('date')['confirmed_count'].rolling(7).mean()
        
        # Trend direction (last 30 days vs previous 30 days)
        if len(df) >= 60:
            recent_avg = df.tail(30)['confirmed_count'].mean()
            previous_avg = df.iloc[-60:-30]['confirmed_count'].mean()
            trend = "increasing" if recent_avg > previous_avg else "decreasing"
            trend_pct = ((recent_avg - previous_avg) / previous_avg * 100)
        else:
            trend = "insufficient_data"
            trend_pct = 0
        
        return {
            'monthly_averages': monthly,
            'trend_direction': trend,
            'trend_change': f"{trend_pct:+.1f}%",
            'recent_30d_avg': round(df.tail(30)['confirmed_count'].mean(), 2)
        }
    
    def _generate_summary(self, insights: Dict) -> List[str]:
        """Generate human-readable summary"""
        summary = []
        
        # Day of week insights
        if 'day_of_week' in insights:
            dow = insights['day_of_week']
            best_day = dow.get('best_day', 'N/A')
            worst_day = dow.get('worst_day', 'N/A')
            summary.append(f"📅 {best_day}s have highest demand, {worst_day}s have lowest")
        
        # Weather insights
        if 'weather_impact' in insights:
            weather = insights['weather_impact']
            rain_effect = weather.get('rainy_day_effect', '0%')
            summary.append(f"🌧️ Rainy days change meal counts by {rain_effect}")
        
        # Holiday insights
        if 'holiday_impact' in insights:
            holiday = insights['holiday_impact']
            holiday_effect = holiday.get('holiday_effect', '0%')
            summary.append(f"🎉 Holidays change meal counts by {holiday_effect}")
        
        # Trend insights
        if 'temporal_trends' in insights:
            trends = insights['temporal_trends']
            direction = trends.get('trend_direction', 'stable')
            change = trends.get('trend_change', '0%')
            summary.append(f"📈 Demand is {direction} ({change} over last 30 days)")
        
        return summary
    
    def _save_insights(self, insights: Dict):
        """Save insights to file and Firebase"""
        # Save to JSON file
        with open('canteen_insights.json', 'w') as f:
            json.dump(insights, f, indent=2, default=str)
        print("💾 Insights saved to canteen_insights.json")
        
        # Push to Firebase
        if self.db:
            try:
                collection_ref = self.db.collection(FirebaseCollections.INSIGHTS)
                collection_ref.add(insights)
                print("✅ Insights pushed to Firebase")
            except Exception as e:
                print(f"⚠️ Could not push insights to Firebase: {e}")
    
    def generate_report(self, df: pd.DataFrame, output_format: str = 'text') -> str:
        """
        Generate a comprehensive report
        
        Args:
            df: Historical data
            output_format: 'text', 'json', or 'csv'
        
        Returns:
            Report string
        """
        insights = self.analyze_trends(df)
        
        if output_format == 'json':
            return json.dumps(insights, indent=2, default=str)
        
        elif output_format == 'text':
            report = []
            report.append("=" * 60)
            report.append("CANTEEN MEAL DEMAND INSIGHTS REPORT")
            report.append("=" * 60)
            report.append(f"\nGenerated: {insights['generated_at']}")
            report.append(f"Data Period: {insights['data_period']['start']} to {insights['data_period']['end']}")
            report.append(f"Total Days: {insights['data_period']['days']}")
            
            report.append("\n" + "=" * 60)
            report.append("KEY INSIGHTS")
            report.append("=" * 60)
            for item in insights.get('summary', []):
                report.append(f"  {item}")
            
            report.append("\n" + "=" * 60)
            report.append("DAY OF WEEK ANALYSIS")
            report.append("=" * 60)
            dow = insights.get('day_of_week', {})
            for day, avg in dow.get('avg_by_day', {}).items():
                report.append(f"  {day}: {avg:.1f} meals average")
            
            report.append("\n" + "=" * 60)
            
            return "\n".join(report)
        
        return str(insights)
    
    def export_insights_csv(self, insights: Dict, filename: str = 'insights_export.csv'):
        """Export insights to CSV format"""
        # Convert insights to flat structure for CSV
        rows = []
        
        if 'day_of_week' in insights:
            for day, avg in insights['day_of_week'].get('avg_by_day', {}).items():
                rows.append({'metric': 'day_of_week', 'category': day, 'value': avg})
        
        if rows:
            df = pd.DataFrame(rows)
            df.to_csv(filename, index=False)
            print(f"📊 Insights exported to {filename}")


if __name__ == "__main__":
    # Test insights generation
    from data_agent import DataAgent
    
    data_agent = DataAgent()
    df = data_agent.load_local_data()
    
    if not df.empty:
        insight_agent = InsightAgent()
        insights = insight_agent.analyze_trends(df)
        
        print("\n" + "=" * 60)
        print("INSIGHTS SUMMARY")
        print("=" * 60)
        for item in insights.get('summary', []):
            print(f"  {item}")
        
        # Generate text report
        report = insight_agent.generate_report(df, output_format='text')
        print("\n" + report)
