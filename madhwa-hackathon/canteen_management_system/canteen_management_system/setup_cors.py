"""
Quick setup script to add CORS support to the Flask app
Run this once to install flask-cors: pip install flask-cors
"""
import subprocess
import sys

def install_flask_cors():
    """Install flask-cors package"""
    try:
        print("Installing flask-cors...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "flask-cors"])
        print("✓ flask-cors installed successfully!")
        return True
    except subprocess.CalledProcessError as e:
        print(f"✗ Error installing flask-cors: {e}")
        return False

if __name__ == "__main__":
    install_flask_cors()
