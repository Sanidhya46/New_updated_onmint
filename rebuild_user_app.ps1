# Force complete rebuild of user_app to clear browser cache
Write-Host "=== FORCE REBUILD USER APP ===" -ForegroundColor Cyan

Set-Location "New_Onmint/user_app"

Write-Host "`n1. Cleaning Flutter..." -ForegroundColor Yellow
flutter clean

Write-Host "`n2. Getting dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host "`n3. Running build_runner to regenerate code..." -ForegroundColor Yellow
flutter pub run build_runner build --delete-conflicting-outputs

Write-Host "`n4. Starting app with --no-cache-sksl-warmup..." -ForegroundColor Yellow
Write-Host "This will force a complete rebuild and clear browser cache" -ForegroundColor Green
flutter run -d chrome --web-renderer html --no-cache-sksl-warmup

Set-Location ../..
