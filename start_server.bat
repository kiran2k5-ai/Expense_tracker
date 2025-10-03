@echo off
cd /d "d:\flutter vs code\expense\expense\build\web"
start /min python -m http.server 3000
echo Expense Tracker server started on port 3000
echo Access from mobile: http://10.20.41.40:3000
echo Press any key to stop the server...
pause
taskkill /f /im python.exe