@echo off
echo CTU Danao Smart Bins - Flutter App Runner
echo ==========================================
echo.

echo Checking Flutter installation...
flutter --version
echo.

echo Getting dependencies...
flutter pub get
echo.

echo Analyzing code...
flutter analyze
echo.

echo Available devices:
flutter devices
echo.

echo Choose your preferred platform:
echo 1. Chrome (Web) - Recommended for testing
echo 2. Windows Desktop (requires Developer Mode)
echo 3. Android Emulator (if available)
echo 4. iOS Simulator (if available)
echo.

set /p choice="Enter your choice (1-4): "

if "%choice%"=="1" (
    echo Starting app on Chrome...
    flutter run -d chrome
) else if "%choice%"=="2" (
    echo Starting app on Windows...
    echo Note: If you get a symlink error, enable Developer Mode:
    echo 1. Open Windows Settings
    echo 2. Go to Update & Security ^> For developers
    echo 3. Turn on Developer Mode
    echo 4. Restart your computer
    echo.
    flutter run -d windows
) else if "%choice%"=="3" (
    echo Starting app on Android...
    flutter run -d android
) else if "%choice%"=="4" (
    echo Starting app on iOS...
    flutter run -d ios
) else (
    echo Invalid choice. Starting on Chrome by default...
    flutter run -d chrome
)

pause
