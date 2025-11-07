@echo off
echo ========================================
echo  Starting CanteenAI ML Server
echo ========================================
echo.
echo Installing flask-cors if needed...
pip install flask-cors
echo.
echo Starting server...
python app_with_cors.py
pause
