# Setup Guide - CTU Danao Smart Bins Flutter App

## Quick Start

### Option 1: Run on Web (Recommended for Testing)
```bash
flutter run -d chrome
```

### Option 2: Use the Batch Script
Double-click `run_app.bat` and follow the prompts.

## Platform-Specific Setup

### 🌐 Web (Chrome) - Easiest Option
- **Requirements**: Chrome browser
- **Command**: `flutter run -d chrome`
- **Pros**: No additional setup required
- **Cons**: Some mobile features may not work perfectly

### 🖥️ Windows Desktop
- **Requirements**: Windows 10/11 with Developer Mode
- **Setup Steps**:
  1. Open Windows Settings (Win + I)
  2. Go to "Update & Security" → "For developers"
  3. Turn on "Developer Mode"
  4. Restart your computer
  5. Run: `flutter run -d windows`

### 📱 Android
- **Requirements**: Android Studio with emulator or physical device
- **Setup Steps**:
  1. Install Android Studio
  2. Set up Android SDK
  3. Create/start an Android emulator
  4. Run: `flutter run -d android`

### 🍎 iOS (macOS only)
- **Requirements**: macOS with Xcode
- **Setup Steps**:
  1. Install Xcode from App Store
  2. Install iOS Simulator
  3. Run: `flutter run -d ios`

## Troubleshooting

### Windows Symlink Error
If you get: "Building with plugins requires symlink support"

**Solution 1: Enable Developer Mode**
1. Open Windows Settings (Win + I)
2. Navigate to "Update & Security" → "For developers"
3. Turn on "Developer Mode"
4. Restart your computer

**Solution 2: Run as Administrator**
1. Right-click Command Prompt/PowerShell
2. Select "Run as administrator"
3. Navigate to project directory
4. Run `flutter run -d windows`

**Solution 3: Use Web Instead**
```bash
flutter run -d chrome
```

### Flutter Not Found
If `flutter` command is not recognized:
1. Add Flutter to your PATH environment variable
2. Or use the full path to flutter.exe
3. Restart your terminal/IDE

### Dependencies Issues
```bash
flutter clean
flutter pub get
flutter run
```

## Testing the App

### Default Login Credentials
- **Staff Account**: 
  - Username: `staff`
  - Password: `staff123`
- **Regular Users**: Create new account through registration

### Key Features to Test
1. **Authentication**: Login/Register functionality
2. **Dashboard**: View bin cards with real-time data
3. **Map**: Interactive bin locations
4. **Store**: Points redemption system
5. **Profile**: User settings and staff controls

### Staff Features
- Clear individual bins
- Charge batteries
- Add points to users
- Clear all bins
- Charge all batteries
- Reset system
- Generate reports

## Development Tips

### Hot Reload
- Press `r` in terminal to hot reload
- Press `R` to hot restart
- Press `q` to quit

### Debug Mode
- Use `flutter run --debug` for debugging
- Check console for error messages
- Use Flutter Inspector in VS Code/Android Studio

### Performance
- Use `flutter run --release` for production builds
- Profile with `flutter run --profile`

## File Structure
```
lib/
├── constants/     # App configuration
├── models/        # Data models
├── screens/       # UI screens
├── services/      # Business logic
├── utils/         # Utilities and themes
├── widgets/       # Reusable components
└── main.dart      # App entry point
```

## Need Help?

1. Check Flutter documentation: https://flutter.dev/docs
2. Run `flutter doctor` to check your setup
3. Check the console output for specific error messages
4. Ensure all dependencies are installed: `flutter pub get`
