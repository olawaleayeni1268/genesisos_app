@echo off
setlocal
echo === Cleaning & fetching deps ===
flutter clean
flutter pub get

echo === Building release APK with dart-define ===
flutter build apk --release ^
  --build-name=1.0.202 --build-number=202 ^
  --dart-define=SUPABASE_URL=https://pmxriyrzlkscisvgcjow.supabase.co ^
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBteHJpeXJ6bGtzY2lzdmdjam93Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3MjQ0OTcsImV4cCI6MjA2OTMwMDQ5N30.qfNPGiFJQN-wi5oKVYzMjEdFbrDcD7RRP0-_merMuFM

if errorlevel 1 (
  echo *** BUILD FAILED ***
  pause
  exit /b 1
)

echo === Build OK ===
echo APK: build\app\outputs\flutter-apk\app-release.apk
explorer build\app\outputs\flutter-apk
pause
