"""
Firebase Configuration Module
Handles Firebase Firestore connection and authentication
"""
import firebase_admin
from firebase_admin import credentials, firestore
import os
import json
from typing import Optional
from datetime import datetime


# Your Firebase Project Configuration
FIREBASE_PROJECT_CONFIG = {
    "apiKey": "AIzaSyBeSp-YLbbPnEUrEdzro-4PS2TCg4JBQxg",
    "authDomain": "madhwa-hackathon.firebaseapp.com",
    "projectId": "madhwa-hackathon",
    "storageBucket": "madhwa-hackathon.firebasestorage.app",
    "messagingSenderId": "136044007781",
    "appId": "1:136044007781:web:e5ad8af1ae652ae31c518c",
    "measurementId": "G-SBR5LXLPHL"
}


class FirebaseConfig:
    """Manages Firebase connection and configuration"""
    
    _db = None
    _initialized = False
    
    @classmethod
    def initialize(cls, credentials_path: Optional[str] = None, use_project_config: bool = True) -> firestore.Client:
        """
        Initialize Firebase connection
        
        Args:
            credentials_path: Path to Firebase service account JSON file
                            If None, looks for FIREBASE_CREDENTIALS env var
            use_project_config: Use the embedded project config
        
        Returns:
            Firestore client instance
        """
        if cls._initialized:
            return cls._db
        
        try:
            # Try to get credentials from environment or parameter
            if credentials_path is None:
                credentials_path = os.getenv('FIREBASE_CREDENTIALS')
            
            if credentials_path and os.path.exists(credentials_path):
                cred = credentials.Certificate(credentials_path)
                firebase_admin.initialize_app(cred)
                print(f"✅ Firebase initialized with credentials from: {credentials_path}")
            elif use_project_config:
                # Initialize with project ID from config
                firebase_admin.initialize_app(options={
                    'projectId': FIREBASE_PROJECT_CONFIG['projectId']
                })
                print(f"✅ Firebase initialized for project: {FIREBASE_PROJECT_CONFIG['projectId']}")
            else:
                # Try default credentials (for Cloud environments)
                firebase_admin.initialize_app()
                print("✅ Firebase initialized with default credentials")
            
            cls._db = firestore.client()
            cls._initialized = True
            return cls._db
            
        except Exception as e:
            print(f"⚠️ Firebase initialization failed: {e}")
            print("💡 To use Firebase, you need a service account key:")
            print("   1. Go to Firebase Console > Project Settings > Service Accounts")
            print("   2. Click 'Generate New Private Key'")
            print("   3. Save the JSON file and set FIREBASE_CREDENTIALS environment variable")
            return None
    
    @classmethod
    def get_db(cls) -> Optional[firestore.Client]:
        """Get Firestore client instance"""
        if not cls._initialized:
            return cls.initialize()
        return cls._db
    
    @classmethod
    def is_connected(cls) -> bool:
        """Check if Firebase is connected"""
        return cls._initialized and cls._db is not None


class FirebaseCollections:
    """Collection names for Firestore"""
    MEAL_DATA = "canteen_meal_data"
    PREDICTIONS = "canteen_predictions"
    MODEL_METADATA = "model_metadata"
    INSIGHTS = "canteen_insights"
    TRAINING_LOGS = "training_logs"


def create_sample_credentials_template():
    """Create a template for Firebase credentials"""
    template = {
        "type": "service_account",
        "project_id": "your-project-id",
        "private_key_id": "your-private-key-id",
        "private_key": "-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY\n-----END PRIVATE KEY-----\n",
        "client_email": "your-service-account@your-project.iam.gserviceaccount.com",
        "client_id": "your-client-id",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/your-service-account%40your-project.iam.gserviceaccount.com"
    }
    
    template_path = "firebase_credentials_template.json"
    with open(template_path, 'w') as f:
        json.dump(template, f, indent=2)
    
    print(f"📄 Created Firebase credentials template: {template_path}")
    print("   Replace placeholder values with your actual Firebase credentials")
    return template_path


if __name__ == "__main__":
    # Test Firebase connection
    print("Testing Firebase connection...")
    db = FirebaseConfig.initialize()
    
    if db:
        print("✅ Firebase connection successful!")
    else:
        print("⚠️ Firebase not connected. Creating credentials template...")
        create_sample_credentials_template()
