# CTU Danao Smart Bins - Flutter App

A Flutter mobile application for managing smart trash bins at Cebu Technological University Danao Campus. This app provides real-time monitoring of bin capacity, battery levels, and a points-based reward system.

## Features

### 🔐 Authentication
- User registration and login
- Staff account with special privileges
- Secure password management

### 📊 Dashboard
- Real-time bin capacity monitoring
- Battery level indicators
- Last collection timestamps
- Staff-only bin management controls

### 🗺️ Interactive Map
- Visual representation of bin locations
- Color-coded bin types (Paper, Plastic, Metal, E-Waste)
- Battery status indicators with low battery alerts
- Tap to view detailed bin information

### 🛍️ Points Store
- Earn eco-points for using smart bins
- Redeem points for rewards (coffee, vouchers, etc.)
- Real-time points balance

### 👤 Profile Management
- Update username and password
- Staff controls for system management:
  - Clear all bins
  - Charge all batteries
  - Reset system
  - Generate system reports

## Technical Features

### 🎨 UI/UX
- Dark theme matching the original web design
- Responsive design for mobile devices
- Smooth animations and transitions
- Material Design 3 components

### 💾 Data Management
- Local storage using SharedPreferences
- Persistent user data and bin information
- Real-time data updates

### 🔧 Architecture
- Clean architecture with separation of concerns
- Service-based data management
- Model-driven development
- Provider pattern for state management

## Getting Started

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Default Credentials

**Staff Account:**
- Username: `staff`
- Password: `staff123`

**Regular Users:**
- Create a new account through the registration form

## Project Structure

```
lib/
├── constants/          # App constants and configuration
├── models/            # Data models (User, Bin, StoreItem)
├── screens/           # UI screens
├── services/          # Business logic and data services
├── utils/             # Utility functions and themes
├── widgets/           # Reusable UI components
└── main.dart          # App entry point
```

## Key Components

### Models
- `User`: User account information and points
- `Bin`: Smart bin data with location and status
- `StoreItem`: Rewards available in the points store

### Services
- `AuthService`: Authentication and user management
- `BinService`: Bin data management and operations
- `StoreService`: Points store management
- `StorageService`: Local data persistence

### Screens
- `AuthScreen`: Login and registration
- `MainScreen`: Main navigation container
- `DashboardScreen`: Bin monitoring dashboard
- `MapScreen`: Interactive bin map
- `StoreScreen`: Points redemption store
- `ProfileScreen`: User profile and staff controls

## Features Comparison with Web Version

✅ **Implemented:**
- Complete authentication system
- Dashboard with bin cards
- Interactive map view
- Points store with redemption
- Profile management
- Staff controls
- Dark theme UI
- Local data persistence
- Real-time updates

🔄 **Enhanced:**
- Mobile-optimized UI
- Better navigation with bottom tabs
- Improved animations
- Touch-friendly interactions

## Development Notes

### State Management
The app uses a simple service-based approach for state management. For larger applications, consider implementing Provider or Bloc pattern.

### Data Persistence
Currently uses SharedPreferences for local storage. For production, consider implementing a proper database solution.

### Maps Integration
The current map implementation uses a custom canvas-based approach. For production, integrate with Google Maps or similar mapping services.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Original web application design and functionality
- Flutter team for the excellent framework
- Material Design for UI guidelines