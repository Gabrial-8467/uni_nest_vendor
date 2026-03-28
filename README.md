# UNI NEST Vendor

**Version 1.0.0+1**

A comprehensive Flutter application for vendors to manage their business operations, orders, products, and privacy settings. Built with modern architecture and enhanced security features.

## Features

### Core Functionality
- **Vendor Authentication**: Secure login, registration, and password management
- **Product Management**: Create, update, and manage product inventory
- **Order Management**: Track and process customer orders in real-time
- **Analytics Dashboard**: Comprehensive business analytics and revenue tracking
- **Profile Management**: Complete vendor profile with business information

### Advanced Features
- **Privacy Settings**: Granular control over data sharing and profile visibility
- **Notification System**: Customizable notifications for orders, payments, and updates
- **Multi-platform Support**: Runs on Android, iOS, Web, Windows, macOS, and Linux
- **Secure Storage**: Encrypted local storage for sensitive data
- **File Management**: Image and file upload capabilities
- **Advanced Analytics**: Interactive charts and business metrics
- **Environment Configuration**: Secure environment variable management

## Project Structure

```
lib/
├── config/                 # Configuration files
├── models/                 # Data models and entities
│   └── vendor_models.dart  # Vendor, Product, Order, PrivacySettings models
├── screens/                # UI screens and pages
│   ├── analytics_screen.dart
│   ├── login_screen.dart
│   ├── profile_screen.dart
│   └── ...
├── services/               # API and external services
├── state/                  # State management (Provider pattern)
│   └── vendor_provider.dart
├── utils/                  # Utility functions and helpers
└── widgets/                # Reusable UI components
    ├── privacy_settings_dialog.dart
    ├── order_card.dart
    ├── analytics_card.dart
    └── widgets.dart         # Export file for easy imports
```

## Key Components

### Privacy Settings
The app includes comprehensive privacy controls allowing vendors to manage:
- **Profile Visibility**: Control what information is publicly visible
- **Customer Interactions**: Manage reviews, messages, and business hours
- **Data & Analytics**: Control analytics tracking and revenue display
- **Data Sharing**: Manage data sharing with partners and marketing preferences

### State Management
Uses the Provider pattern for efficient state management:
- `VendorProvider`: Manages vendor authentication, data, and business operations
- Real-time updates across the application
- Persistent storage using SharedPreferences

### Models
Comprehensive data models with proper JSON serialization:
- `Vendor`: Complete vendor profile with privacy and notification settings
- `Product`: Product management with inventory and pricing
- `Order`: Order tracking with status management
- `PrivacySettings`: Granular privacy controls
- `NotificationSettings`: Customizable notification preferences

## Getting Started

### Prerequisites
- Flutter SDK (version 3.11.1 or higher)
- Dart SDK
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd uni_nest_vendor
```

2. Install dependencies:
```bash
flutter pub get
```

3. Set up environment variables:
```bash
# Create a .env file in the root directory
# Add your API keys and configuration variables
```

4. Run the application:
```bash
flutter run
```

### Development

For development with hot reload:
```bash
flutter run --hot
```

To run on specific platforms:
```bash
flutter run -d chrome      # Web
flutter run -d android     # Android
flutter run -d ios         # iOS
```

## Architecture

The application follows a clean architecture pattern:
- **Presentation Layer**: Screens and widgets
- **Business Logic Layer**: Providers and services
- **Data Layer**: Models and API services

## Dependencies

Key dependencies include:
- `provider`: State management
- `shared_preferences`: Local storage
- `flutter_secure_storage`: Secure local storage
- `http`: API communications
- `dio`: HTTP client with interceptors
- `fl_chart`: Charts and analytics
- `image_picker`: Image handling
- `cached_network_image`: Network image caching
- `flutter_local_notifications`: Local notifications
- `flutter_dotenv`: Environment configuration
- `url_launcher`: URL launching
- `file_picker`: File handling
- `permission_handler`: Permissions management
- `crypto`: Cryptographic functions
- `uuid`: UUID generation
- `intl`: Internationalization and date formatting

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Privacy & Security

This application takes privacy seriously:
- Local data storage with encryption
- Granular privacy controls for vendors
- Secure API communications
- No unnecessary data collection

## Support

For support and questions:
- Check the documentation
- Review the code comments
- Contact the development team

## License

This project is licensed under the MIT License - see the LICENSE file for details.
