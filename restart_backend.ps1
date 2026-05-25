# Restart Backend Server
Write-Host "Restarting backend server..." -ForegroundColor Cyan

# Navigate to backend directory
Set-Location "Ourdeals_Healthcare"

# Kill any existing node processes on port 5000
Write-Host "Stopping existing server..." -ForegroundColor Yellow
$process = Get-NetTCPConnection -LocalPort 5000 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique
if ($process) {
    Stop-Process -Id $process -Force
    Write-Host "Stopped process on port 5000" -ForegroundColor Green
    Start-Sleep -Seconds 2
}

# Start the server
Write-Host "Starting backend server..." -ForegroundColor Cyan
npm start
