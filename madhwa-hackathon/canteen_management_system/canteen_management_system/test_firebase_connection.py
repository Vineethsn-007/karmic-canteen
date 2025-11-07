"""
Test Firebase Connection
Run this after setting up your service account credentials
"""
from firebase_config import FirebaseConfig, FirebaseCollections, FIREBASE_PROJECT_CONFIG
import sys


def test_firebase_connection():
    """Test connection to Firebase"""
    print("\n" + "="*60)
    print("🔥 Firebase Connection Test")
    print("="*60)
    
    print(f"\n📋 Project Configuration:")
    print(f"   Project ID: {FIREBASE_PROJECT_CONFIG['projectId']}")
    print(f"   Auth Domain: {FIREBASE_PROJECT_CONFIG['authDomain']}")
    print(f"   Storage Bucket: {FIREBASE_PROJECT_CONFIG['storageBucket']}")
    
    print("\n🔌 Attempting to connect...")
    
    # Try to initialize
    db = FirebaseConfig.initialize()
    
    if db is None:
        print("\n❌ Connection Failed")
        print("\n📝 To fix this:")
        print("   1. Download service account key from Firebase Console")
        print("   2. Save as 'firebase-credentials.json'")
        print("   3. Set FIREBASE_CREDENTIALS environment variable")
        print("   4. Or run: python test_firebase_connection.py path/to/credentials.json")
        return False
    
    print("✅ Connected to Firebase!")
    
    # Test Firestore access
    print("\n🗄️ Testing Firestore access...")
    try:
        # Try to list collections
        collections = db.collections()
        collection_names = [col.id for col in collections]
        
        if collection_names:
            print(f"✅ Found {len(collection_names)} collections:")
            for name in collection_names:
                print(f"   - {name}")
        else:
            print("ℹ️ No collections yet (this is normal for new projects)")
            print("   Collections will be created when you upload data")
        
        # Test write access (optional)
        print("\n✍️ Testing write access...")
        test_collection = db.collection('_canteen_ai_test')
        test_doc = test_collection.document('test')
        test_doc.set({
            'test': True,
            'timestamp': FirebaseConfig.get_db().SERVER_TIMESTAMP
        })
        print("✅ Write access confirmed")
        
        # Clean up test document
        test_doc.delete()
        print("✅ Test document cleaned up")
        
        print("\n" + "="*60)
        print("🎉 Firebase Connection Successful!")
        print("="*60)
        print("\n✅ You can now:")
        print("   1. Upload data: python -c \"from data_agent import DataAgent; DataAgent().push_to_firebase(...)\"")
        print("   2. Run CanteenAI: python canteen_ai.py")
        print("   3. Sync predictions to cloud automatically")
        
        return True
        
    except Exception as e:
        print(f"\n❌ Firestore access error: {e}")
        print("\n💡 Make sure:")
        print("   1. Firestore is enabled in Firebase Console")
        print("   2. Service account has proper permissions")
        return False


def upload_sample_data():
    """Upload sample data to Firebase"""
    print("\n" + "="*60)
    print("📤 Uploading Sample Data to Firebase")
    print("="*60)
    
    from data_agent import DataAgent
    import pandas as pd
    import os
    
    if not os.path.exists('canteen_history.csv'):
        print("❌ canteen_history.csv not found")
        return False
    
    print("\n📊 Loading local data...")
    df = pd.read_csv('canteen_history.csv')
    print(f"✅ Loaded {len(df)} records")
    
    print("\n☁️ Uploading to Firebase...")
    agent = DataAgent()
    count = agent.push_to_firebase(df)
    
    if count > 0:
        print(f"\n✅ Successfully uploaded {count} records!")
        print(f"   Collection: {FirebaseCollections.MEAL_DATA}")
        print("\n🌐 View in Firebase Console:")
        print(f"   https://console.firebase.google.com/project/{FIREBASE_PROJECT_CONFIG['projectId']}/firestore")
        return True
    else:
        print("\n❌ Upload failed")
        return False


def main():
    """Main test function"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Test Firebase connection')
    parser.add_argument('credentials', nargs='?', help='Path to Firebase credentials JSON')
    parser.add_argument('--upload', action='store_true', help='Upload sample data after testing')
    
    args = parser.parse_args()
    
    # Set credentials if provided
    if args.credentials:
        import os
        os.environ['FIREBASE_CREDENTIALS'] = args.credentials
        print(f"📁 Using credentials: {args.credentials}")
    
    # Test connection
    success = test_firebase_connection()
    
    if not success:
        sys.exit(1)
    
    # Upload data if requested
    if args.upload:
        upload_success = upload_sample_data()
        if not upload_success:
            sys.exit(1)
    
    print("\n✅ All tests passed!")


if __name__ == "__main__":
    main()
