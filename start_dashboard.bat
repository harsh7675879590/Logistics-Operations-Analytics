@echo off
title Logistics Operations Analytics Dashboard
echo ========================================================
echo   Starting Logistics Operations Analytics Dashboard...
echo ========================================================
echo.
echo 1. Launching dashboard in browser: http://localhost:8000/dashboard/
start http://localhost:8000/dashboard/
echo.
echo 2. Running local web server on port 8000...
echo.
echo [INFO] Keep this window open while using the dashboard.
echo [INFO] Press Ctrl+C to stop the server when done.
echo ========================================================
python -m http.server 8000
