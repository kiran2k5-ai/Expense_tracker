@echo off
echo Starting Expense Tracker Web Server...
cd /d "d:\flutter vs code\expense\expense\build\web"

REM Start server in background
powershell -WindowStyle Hidden -Command "python -m http.server 3000"

echo.
echo ================================
echo  EXPENSE TRACKER SERVER RUNNING
echo ================================
echo.
echo Mobile Access: http://10.20.41.40:3000
echo.
echo To stop server: Press Ctrl+C
echo To restart: Run this file again
echo.
pause