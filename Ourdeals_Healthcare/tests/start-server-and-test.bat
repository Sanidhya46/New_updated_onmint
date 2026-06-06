@echo off
echo ========================================
echo Starting Backend Server and Running Tests
echo ========================================
echo.

echo Step 1: Starting backend server...
start "Backend Server" cmd /k "npm start"

echo.
echo Waiting 10 seconds for server to start...
timeout /t 10 /nobreak

echo.
echo Step 2: Running API tests...
npm run test:api

echo.
echo ========================================
echo Tests completed!
echo ========================================
pause
