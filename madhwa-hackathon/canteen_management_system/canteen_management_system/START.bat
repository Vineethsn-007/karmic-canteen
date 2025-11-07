@echo off
cls
echo ============================================================
echo    CanteenAI - Prediction Dashboard
echo ============================================================
echo.
echo Starting server...
echo.
echo Open your browser: http://localhost:5000
echo.
echo Press Ctrl+C to stop
echo ============================================================
echo.
start http://localhost:5000
python simple_app.py
