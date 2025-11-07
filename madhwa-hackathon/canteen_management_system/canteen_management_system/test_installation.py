"""
Test Installation Script
Verifies that CanteenAI is properly installed and configured
"""
import sys
import os


def test_imports():
    """Test if all required modules can be imported"""
    print("🔍 Testing imports...")
    
    try:
        import pandas
        print("  ✅ pandas")
    except ImportError:
        print("  ❌ pandas - Run: pip install pandas")
        return False
    
    try:
        import numpy
        print("  ✅ numpy")
    except ImportError:
        print("  ❌ numpy - Run: pip install numpy")
        return False
    
    try:
        import sklearn
        print("  ✅ scikit-learn")
    except ImportError:
        print("  ❌ scikit-learn - Run: pip install scikit-learn")
        return False
    
    try:
        import lightgbm
        print("  ✅ lightgbm")
    except ImportError:
        print("  ❌ lightgbm - Run: pip install lightgbm")
        return False
    
    try:
        import joblib
        print("  ✅ joblib")
    except ImportError:
        print("  ❌ joblib - Run: pip install joblib")
        return False
    
    try:
        import firebase_admin
        print("  ✅ firebase-admin")
    except ImportError:
        print("  ⚠️  firebase-admin (optional) - Run: pip install firebase-admin")
    
    return True


def test_canteen_ai_modules():
    """Test if CanteenAI modules can be imported"""
    print("\n🔍 Testing CanteenAI modules...")
    
    try:
        from firebase_config import FirebaseConfig
        print("  ✅ firebase_config")
    except ImportError as e:
        print(f"  ❌ firebase_config - {e}")
        return False
    
    try:
        from data_agent import DataAgent
        print("  ✅ data_agent")
    except ImportError as e:
        print(f"  ❌ data_agent - {e}")
        return False
    
    try:
        from train_agent import TrainAgent
        print("  ✅ train_agent")
    except ImportError as e:
        print(f"  ❌ train_agent - {e}")
        return False
    
    try:
        from predict_agent import PredictAgent
        print("  ✅ predict_agent")
    except ImportError as e:
        print(f"  ❌ predict_agent - {e}")
        return False
    
    try:
        from insight_agent import InsightAgent
        print("  ✅ insight_agent")
    except ImportError as e:
        print(f"  ❌ insight_agent - {e}")
        return False
    
    try:
        from canteen_ai import CanteenAI
        print("  ✅ canteen_ai")
    except ImportError as e:
        print(f"  ❌ canteen_ai - {e}")
        return False
    
    return True


def test_data_availability():
    """Test if data files are available"""
    print("\n🔍 Testing data availability...")
    
    if os.path.exists("canteen_history.csv"):
        print("  ✅ canteen_history.csv found")
        
        # Check if file has data
        try:
            import pandas as pd
            df = pd.read_csv("canteen_history.csv")
            print(f"     {len(df)} records, {len(df.columns)} columns")
            return True
        except Exception as e:
            print(f"  ⚠️  Error reading CSV: {e}")
            return False
    else:
        print("  ⚠️  canteen_history.csv not found")
        print("     You'll need historical data to train models")
        return False


def test_model_directory():
    """Test if model directory exists"""
    print("\n🔍 Testing model directory...")
    
    if os.path.exists("models_per_item"):
        print("  ✅ models_per_item directory exists")
        
        # Check for trained models
        models = [f for f in os.listdir("models_per_item") if f.endswith(".pkl")]
        if models:
            print(f"     Found {len(models)} trained models")
        else:
            print("     No trained models yet (run training first)")
        return True
    else:
        print("  ⚠️  models_per_item directory not found")
        print("     Will be created automatically on first training")
        return True


def test_basic_functionality():
    """Test basic CanteenAI functionality"""
    print("\n🔍 Testing basic functionality...")
    
    try:
        from canteen_ai import CanteenAI
        from data_agent import DataAgent
        
        # Test DataAgent
        print("  Testing DataAgent...")
        data_agent = DataAgent()
        print("    ✅ DataAgent initialized")
        
        # Test CanteenAI initialization
        print("  Testing CanteenAI...")
        ai = CanteenAI()
        print("    ✅ CanteenAI initialized")
        
        return True
        
    except Exception as e:
        print(f"  ❌ Error: {e}")
        return False


def test_firebase_connection():
    """Test Firebase connection (optional)"""
    print("\n🔍 Testing Firebase connection...")
    
    try:
        from firebase_config import FirebaseConfig
        
        db = FirebaseConfig.get_db()
        
        if db:
            print("  ✅ Firebase connected")
            return True
        else:
            print("  ⚠️  Firebase not configured (optional)")
            print("     Set FIREBASE_CREDENTIALS environment variable to enable")
            return True
            
    except Exception as e:
        print(f"  ⚠️  Firebase not available: {e}")
        print("     This is optional - local CSV mode will work")
        return True


def main():
    """Run all tests"""
    print("=" * 60)
    print("🤖 CanteenAI Installation Test")
    print("=" * 60)
    
    results = []
    
    # Run tests
    results.append(("Dependencies", test_imports()))
    results.append(("CanteenAI Modules", test_canteen_ai_modules()))
    results.append(("Data Availability", test_data_availability()))
    results.append(("Model Directory", test_model_directory()))
    results.append(("Basic Functionality", test_basic_functionality()))
    results.append(("Firebase Connection", test_firebase_connection()))
    
    # Summary
    print("\n" + "=" * 60)
    print("📊 Test Summary")
    print("=" * 60)
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status} - {test_name}")
    
    print("=" * 60)
    print(f"Result: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n🎉 All tests passed! CanteenAI is ready to use.")
        print("\nNext steps:")
        print("  1. Run: python example_usage.py")
        print("  2. Or: python canteen_ai.py --action full")
    else:
        print("\n⚠️  Some tests failed. Please check the errors above.")
        print("   Run: pip install -r requirements.txt")
    
    print("=" * 60)
    
    return passed == total


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
