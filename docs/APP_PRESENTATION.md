# UNI NEST Vendor App - Comprehensive Presentation

## Executive Summary

**UNI NEST Vendor** is a comprehensive, cross-platform Flutter application designed specifically for food and restaurant vendors. It provides an end-to-end solution for managing business operations including orders, products, payments, analytics, and customer communications.

---

## App Overview

| Attribute | Details |
|-----------|---------|
| **App Name** | UNI NEST Vendor |
| **Version** | 1.0.0+1 |
| **Platform** | Flutter (Cross-platform) |
| **Target Audience** | Food & Restaurant Vendors |
| **Platforms Supported** | Android, iOS, Web, Windows, macOS, Linux |
| **Minimum SDK** | Android 21 (Android 5.0+) |
| **Flutter SDK** | ^3.11.1 |

---

## Core Features

### 1. Vendor Authentication System
- **Secure Login** with JWT token-based authentication
- **Registration** with business details capture
- **Forgot Password** with secure reset flow
- **Session Management** with automatic timeout
- **Secure Token Storage** using encrypted local storage
- **Session Persistence** - Auto-login with secure token refresh

### 2. Order Management
- **Real-time Order Tracking** - View all orders with live status updates
- **Order Status Updates** - Update order status (confirmed, preparing, ready, out_for_delivery, delivered, cancelled)
- **Order Details View** - Complete order information including:
  - Customer details (name, phone, address)
  - Item breakdown with quantities and prices
  - Payment information (method, status)
  - Delivery OTP verification
  - Order timeline with status history
- **Order Filtering** - Filter by status, date range, payment method
- **Push Notifications** - Instant alerts for new orders

### 3. Product Catalog Management
- **Add Products** - Create new products with:
  - Name, description, pricing
  - Category selection
  - Multiple image uploads with compression
  - Inventory/stock management
  - Availability toggles
  - Dietary information (veg/non-veg)
- **Edit Products** - Modify existing product details
- **Product Status Control** - Enable/disable products instantly
- **Inventory Tracking** - Monitor stock levels
- **Bulk Operations** - Manage multiple products efficiently

### 4. Dashboard & Analytics (In Development)
- **Dashboard Overview** - Real-time business summary with:
  - Active orders count
  - Today's order statistics
  - Available payout balance
  - Quick action shortcuts
- **Revenue Chart Widget** - Visual revenue trends using FL Chart
- **Recent Orders Widget** - Display of today's latest orders
- **Analytics Screen** - *Coming Soon*: Performance reports and revenue insights

### 5. Payment & Payout System
- **Payment Tracking** - Monitor all payment transactions
- **Payout Method Management**:
  - Bank Transfer (Account number, IFSC, Bank name)
  - UPI (UPI ID verification)
- **Payout Requests** - Request fund withdrawals
- **Payment History** - Complete transaction ledger
- **Security Features** - Encrypted payout data storage
- **Settlement Tracking** - Monitor payout status

### 6. Notification System
- **Push Notifications** via Firebase Cloud Messaging (FCM)
- **Notification Types**:
  - New Order Alerts
  - Order Status Updates
  - Payment Confirmations
  - Vendor Status Changes (Approval, Suspension)
  - System Announcements
- **In-app Notification Center** - View all notifications with:
  - Read/unread indicators
  - Timestamp
  - Deep linking to relevant screens
  - Swipe to dismiss
- **Customizable Preferences** - Control notification frequency

### 7. Profile & Business Management
- **Vendor Profile** - Complete business information:
  - Business name and type
  - Contact details (email, phone)
  - Location with GPS coordinates
  - Business hours
  - Profile image
  - Rating display
- **Business Details** - Additional business metadata
- **Account Status** - Real-time account status (active, pending, suspended)
- **Settings Management** - App preferences and configurations

### 8. Security Features
- **Data Protection** - Encrypted local storage using FlutterSecureStorage
- **Secure API Communication** - HTTPS-only API calls
- **JWT Authentication** - Secure token-based session management
- **Session Timeout** - Automatic logout after inactivity
- **Secure Payout Data** - Encrypted sensitive financial information

### 9. Support & Help
- **Help Center** - Comprehensive FAQ and guides
- **Live Chat UI** - Chat interface demo (simulated responses)
- **Terms of Service** - In-app legal documentation
- **Privacy Policy** - Data handling transparency
- **Refund Policy** - Clear return guidelines

### 10. Promotions & Marketing (In Development)
- **Promotions Screen** - UI framework for viewing promotional offers
- **Filter Options** - Filter by active/expired promotions
- **Promotion Types** - Support for discounts, BOGO, credit offers
- **Create/Manage** - *Planned*: Full promotion creation and management

---

## Technical Architecture

### State Management
| Component | Technology | Purpose |
|-------------|------------|---------|
| Primary State | Riverpod | Modern reactive state management |
| Legacy Screens | Provider | Backward compatibility |
| Local Storage | SharedPreferences | Persistent settings |
| Secure Storage | FlutterSecureStorage | Encrypted sensitive data |
| Cache | CacheService | Performance optimization |

### Architecture Pattern
```
┌─────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                    │
│         (Screens + Widgets + UI Components)             │
├─────────────────────────────────────────────────────────┤
│                   BUSINESS LOGIC LAYER                   │
│              (Providers + Services)                     │
├─────────────────────────────────────────────────────────┤
│                     DATA LAYER                         │
│         (Models + API Services + Local Storage)       │
└─────────────────────────────────────────────────────────┘
```

### Key Services
| Service | Responsibility |
|---------|----------------|
| `AuthService` | Authentication, session management |
| `VendorApiService` | Backend API communication |
| `VendorPushNotificationService` | FCM push notifications |
| `CacheService` | Local data caching |
| `ImageUploadService` | Image compression and upload |
| `PermissionService` | Device permission handling |
| `ConnectivityService` | Network state monitoring |
| `UpdateService` | App version checking |
| `LedgerService` | Financial transaction tracking |

---

## Data Models

### Core Models

#### Vendor Model
```dart
class Vendor {
  String id              // Unique identifier
  String name            // Vendor name
  String email           // Contact email
  String phone           // Contact phone
  String businessName    // Business name
  String businessType    // Type of business
  LocationData locationData  // GPS coordinates + address
  double rating          // Customer rating
  bool isActive          // Account status
  DateTime createdAt     // Registration date
  String profileImage    // Profile photo URL
  NotificationSettings notificationSettings
  bool isOpen            // Business open status
}
```

#### Order Model
```dart
class VendorOrder {
  String id              // Order ID
  String orderNumber     // Human-readable order number
  String status          // Order status
  String paymentMethod   // online/cod
  String paymentStatus   // pending/completed/failed
  String fulfillmentType // delivery/pickup
  String customerName    // Customer details
  String customerPhone
  List<VendorOrderItem> items  // Order items
  OrderPricingSnapshot pricing   // Price breakdown
  DateTime createdAt     // Order timestamp
  Map deliveryAddress    // Delivery location
  List<OrderTimelineEvent> timeline  // Status history
  bool deliveryOtpRequired
}
```

#### Product Model
```dart
class VendorProduct {
  String id              // Product ID
  String name            // Product name
  String description     // Product description
  double price           // Selling price
  double? comparePrice   // Original price (for discounts)
  String category        // Product category
  List<String> images    // Product images
  int stock              // Available quantity
  bool isAvailable       // In stock status
  bool isVeg             // Vegetarian flag
  Map<String, dynamic> attributes  // Additional properties
}
```

---

## Screens & Navigation

### Authentication Flow (Standalone Screens)
| Screen | Purpose |
|--------|---------|
| **SplashScreen** | App initialization with logo animation |
| **VendorAuthGateScreen** | Authentication state router |
| **VendorLoginScreen** | Email/password login with secure auth |
| **VendorSignupScreen** | Registration with business details capture |
| **VendorForgotPasswordScreen** | Password recovery flow |

### Main App Structure (VendorShellScreen with 5 Tabs)

| Tab | Widget | Key Features |
|-----|--------|--------------|
| **Dashboard** | `VendorDashboardTab` | Overview, quick stats, recent orders, revenue chart, canteen status toggle |
| **Orders** | `VendorOrdersTab` | Order list with status filtering (6 tabs: New, Preparing, Ready, Out for Delivery, Delivered, Cancelled) |
| **Ledger** | `VendorLedgerTab` | Transaction history, earnings breakdown, cross-settlement details |
| **Payouts** | `VendorPayoutsTab` | Payout balance, request withdrawals, view payout history |
| **Profile** | `VendorProfileTab` | Business details, account settings, help links |

### Standalone Feature Screens (Navigated from tabs)
| Screen | Accessed From | Purpose |
|--------|---------------|---------|
| **OrderDetailsScreen** | Orders Tab | Complete order information with timeline |
| **ProductsScreen** | Dashboard (Quick Action) | Product catalog management |
| **AddProductScreen** | Dashboard / Products | Create new product listings |
| **AnalyticsScreen** | *Navigation* | *Coming Soon* - Performance analytics |
| **PayoutRequestScreen** | Payouts Tab | Request fund withdrawals |
| **AddPayoutMethodScreen** | Payouts Tab | Configure bank/UPI payout methods |
| **PaymentDetailsScreen** | *Navigation* | Payment transaction details |

### Notifications & Support
| Screen | Accessed From | Purpose |
|--------|---------------|---------|
| **VendorNotificationScreen** | App Bar (Notification Bell) | In-app notification center with unread badges |
| **HelpAndSupportScreen** | Profile Tab | Support resources and FAQs |
| **LiveChatScreen** | Help & Support | Chat interface (simulated demo) |

### Legal & Policy
| Screen | Purpose |
|--------|---------|
| **PrivacyPolicyScreen** | Legal documentation |
| **TermsOfServiceScreen** | Terms and conditions |
| **RefundPolicyScreen** | Refund guidelines |

### Marketing
| Screen | Purpose |
|--------|---------|
| **PromotionsScreen** | View promotional offers (UI framework) |

---

## API Integration

### Backend API
- **Base URL**: `https://uninest-backend.onrender.com/api`
- **Authentication**: JWT Bearer tokens
- **Data Format**: JSON

### Key Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/auth/vendor/login` | POST | Vendor authentication |
| `/auth/vendor/register` | POST | Vendor registration |
| `/auth/vendor/forgot-password` | POST | Password reset |
| `/vendor/dashboard` | GET | Dashboard data |
| `/vendor/orders` | GET | Fetch orders |
| `/vendor/orders/:id` | GET | Order details |
| `/vendor/orders/:id/status` | PUT | Update order status |
| `/vendor/products` | GET/POST | Product management |
| `/vendor/products/:id` | PUT/DELETE | Product operations |
| `/vendor/payouts/method` | GET/PUT | Payout configuration |
| `/vendor/payouts/request` | POST | Request payout |
| `/vendor/ledger` | GET | Transaction history |
| `/notifications/register-token` | POST | Register FCM token |

### Notification Types
| Type | Description | Icon |
|------|-------------|------|
| `order` | New orders, updates | Icons.shopping_bag |
| `vendor_approval` | Account approved | Icons.verified_outlined (teal) |
| `vendor_status` | Status changes | Icons.admin_panel_settings (red) |
| `payment` | Payment updates | Icons.payment |
| `system` | System announcements | Icons.notifications |

---

## Security Features

### Data Security
- **AES Encryption** for sensitive local data
- **Secure Key Storage** using Android Keystore / iOS Keychain
- **HTTPS Only** API communication
- **Certificate Pinning** (configurable)

### Authentication Security
- **JWT Tokens** with automatic refresh
- **Session Timeout** after inactivity
- **Secure Token Storage** - Tokens never stored in plain text
- **Biometric Lock** support (optional)

### Input Validation
- **SQL Injection** protection
- **XSS Prevention** in all user inputs
- **Form Validation** with real-time feedback
- **Image Validation** - Size, type, dimension checks

---

## Dependencies & Packages

### Core Dependencies
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter` | SDK | UI Framework |
| `provider` | ^6.1.2 | State Management |
| `flutter_riverpod` | ^2.4.9 | Modern State Management |
| `http` | ^1.6.0 | HTTP requests |
| `dio` | ^5.4.3 | Advanced HTTP client |

### Storage & Security
| Package | Version | Purpose |
|---------|---------|---------|
| `shared_preferences` | ^2.3.2 | Local preferences |
| `flutter_secure_storage` | ^10.0.0 | Encrypted storage |
| `crypto` | ^3.0.3 | Cryptographic functions |

### Firebase & Notifications
| Package | Version | Purpose |
|---------|---------|---------|
| `firebase_core` | ^4.2.1 | Firebase integration |
| `firebase_messaging` | ^16.0.4 | Push notifications |
| `flutter_local_notifications` | ^21.0.0 | Local notifications |

### Media & Files
| Package | Version | Purpose |
|---------|---------|---------|
| `image_picker` | ^1.2.1 | Image selection |
| `cached_network_image` | ^3.3.1 | Image caching |
| `flutter_image_compress` | ^2.4.0 | Image compression |
| `file_picker` | ^11.0.2 | File selection |

### UI Components
| Package | Version | Purpose |
|---------|---------|---------|
| `fl_chart` | ^0.65.0 | Analytics charts |
| `charts_flutter` | ^0.12.0 | Data visualization |
| `cupertino_icons` | ^1.0.8 | iOS-style icons |

### Utilities
| Package | Version | Purpose |
|---------|---------|---------|
| `intl` | ^0.17.0 | Date/number formatting |
| `geolocator` | ^14.0.2 | GPS location |
| `connectivity_plus` | ^7.1.1 | Network monitoring |
| `permission_handler` | ^12.0.1 | Device permissions |
| `url_launcher` | ^6.2.4 | External links |
| `uuid` | ^4.4.0 | Unique identifiers |

---

## Project Structure

```
lib/
├── config/
│   └── vendor_config.dart          # App configuration
├── core/
│   ├── api_client.dart             # HTTP client setup
│   ├── base_repository.dart        # Data repository base
│   ├── connectivity_adapter.dart   # Network adapter
│   ├── error_handler.dart          # Error handling
│   ├── secure_storage_service.dart # Secure storage
│   └── service_locator.dart        # Dependency injection
├── models/
│   ├── auth_models.dart            # Authentication models
│   ├── ledger_models.dart          # Financial models
│   ├── notification_models.dart    # Notification models
│   ├── order_models.dart           # Order data models
│   ├── vendor_models.dart          # Vendor & product models
│   └── vendor_notification.dart    # Vendor notification model
├── providers/
│   ├── analytics_provider.dart     # Analytics state
│   ├── auth_provider.dart          # Authentication state
│   ├── ledger_provider.dart        # Financial state
│   ├── order_provider.dart         # Orders state
│   ├── payout_method_provider.dart # Payout configuration
│   ├── payout_provider.dart        # Payout requests
│   └── vendor_notification_provider.dart # Notifications
├── screens/
│   ├── add_payout_method_screen.dart
│   ├── add_product_screen.dart
│   ├── analytics_screen.dart
│   ├── auth_gate_screen.dart
│   ├── dashboard_screen.dart
│   ├── forgot_password_screen.dart
│   ├── help_and_support_screen.dart
│   ├── ledger_screen.dart
│   ├── live_chat_screen.dart
│   ├── login_screen.dart
│   ├── order_details_screen.dart
│   ├── orders_screen.dart
│   ├── payment_details_screen.dart
│   ├── payout_request_screen.dart
│   ├── payouts_screen.dart
│   ├── privacy_policy_screen.dart
│   ├── products_screen.dart
│   ├── promotions_screen.dart
│   ├── refund_policy_screen.dart
│   ├── signup_screen.dart
│   ├── splash_screen.dart
│   ├── terms_of_service_screen.dart
│   ├── vendor_dashboard_screen.dart
│   ├── vendor_forgot_password_screen.dart
│   ├── vendor_login_screen.dart
│   ├── vendor_notification_screen.dart
│   ├── vendor_profile_screen.dart
│   ├── vendor_shell_screen.dart
│   └── vendor_signup_screen.dart
├── services/
│   ├── auth_service.dart           # Authentication logic
│   ├── cache_service.dart          # Local caching
│   ├── image_upload_service.dart   # Image handling
│   ├── permission_service.dart     # Permissions
│   ├── realtime_notification_service.dart
│   ├── secure_auth_service.dart    # Secure auth
│   ├── update_service.dart         # App updates
│   ├── vendor_api_service.dart     # API calls
│   ├── vendor_notification_service.dart
│   └── vendor_push_notification_service.dart
├── state/
│   └── vendor_provider.dart        # Legacy provider
├── utils/
│   ├── app_assets.dart             # Asset management
│   ├── app_theme.dart              # UI theming
│   ├── connectivity_service.dart   # Network service
│   ├── error_handler.dart          # Error utilities
│   ├── logger.dart                 # Logging
│   ├── payout_security.dart        # Payout encryption
│   ├── performance_optimizer.dart  # Performance
│   ├── product_image_helper.dart   # Image utilities
│   ├── secure_logger.dart          # Secure logging
│   └── security_validator.dart     # Security checks
├── widgets/
│   ├── analytics_card.dart
│   ├── app_flow_test_widget.dart
│   ├── connection_test_widget.dart
│   ├── empty_state.dart
│   ├── order_card.dart
│   ├── order_list_card.dart
│   ├── otp_verify_sheet.dart
│   ├── permission_request_widget.dart
│   ├── quick_stats_widget.dart
│   ├── recent_orders_widget.dart
│   ├── revenue_chart_widget.dart
│   ├── status_chip.dart
│   ├── summary_tile.dart
│   ├── toast_notification_listener.dart
│   └── widgets.dart
├── firebase_options.dart           # Firebase configuration
└── main.dart                       # App entry point
```

---

## Features Checklist

### Implemented Features
| Feature | Status | Notes |
|---------|--------|-------|
| **Vendor Authentication** | ✅ Complete | JWT login, registration, password reset, secure storage |
| **Order Management** | ✅ Complete | Full lifecycle management, status updates, OTP verification |
| **Product Catalog** | ✅ Complete | CRUD operations, image upload with compression |
| **Dashboard** | ✅ Complete | Real-time stats, revenue chart, recent orders, canteen toggle |
| **Push Notifications** | ✅ Complete | FCM integration, in-app notification center |
| **Ledger System** | ✅ Complete | Transaction history, earnings breakdown, cross-settlement |
| **Payout System** | ✅ Complete | Bank/UPI methods, withdrawal requests |
| **Profile Management** | ✅ Complete | Business details, account settings |
| **Help & Support** | ✅ Complete | FAQ, help center UI |
| **Legal Screens** | ✅ Complete | Privacy Policy, Terms, Refund Policy |

### In Development / Pending
| Feature | Status | Notes |
|---------|--------|-------|
| **Analytics Dashboard** | ⏳ Coming Soon | Screen shows placeholder; charts exist in main dashboard |
| **Live Chat** | ⏳ UI Demo | Chat interface implemented with simulated responses |
| **Promotions** | ⏳ UI Framework | Screen structure ready; backend integration pending |

### Security & Performance (All Implemented)
| Feature | Status |
|---------|--------|
| JWT Authentication | ✅ |
| Encrypted Local Storage (FlutterSecureStorage) | ✅ |
| Secure API Communication (HTTPS) | ✅ |
| Image Compression | ✅ |
| Local Caching | ✅ |
| Session Timeout | ✅ |
| Input Validation | ✅ |
| Payout Data Encryption | ✅ |

---

## Development Roadmap

### Phase 1: Core Platform (✅ Completed)
- [x] Vendor authentication system (JWT, secure storage)
- [x] Order management with real-time updates
- [x] Product catalog with image upload
- [x] Dashboard with revenue charts
- [x] Push notifications (FCM)
- [x] Basic profile management

### Phase 2: Financial & Operations (✅ Completed)
- [x] Ledger system with transaction history
- [x] Payout system (Bank/UPI)
- [x] Cross-settlement calculations
- [x] In-app notification center
- [x] Help & support framework
- [x] Legal compliance screens

### Phase 3: Enhanced Features (⏳ In Progress / Planned)
- [ ] **Full Analytics Dashboard** - Replace placeholder with complete analytics
- [ ] **Live Chat Backend** - Connect to real support system
- [ ] **Promotions System** - Complete backend integration for campaigns
- [ ] **Inventory Management** - Stock alerts and forecasting
- [ ] **Multi-language Support** - Localization for regional markets
- [ ] **Dark Mode** - Alternative theme
- [ ] **Offline Mode** - Full offline functionality with sync
- [ ] **Customer Insights** - Order patterns and customer analytics

---

## Support & Documentation

### In-App Documentation
- Help Center with FAQs
- Contextual tooltips
- Onboarding screens

### Technical Documentation
- API Documentation: `PAYOUT_API_DOCUMENTATION.md`
- Push Notification Guide: `vendor-push-notifications.md`
- Notification System: `lib/notification_system_README.md`

### Support Channels
- In-app Live Chat UI (Demo)
- Email Support
- Phone Support (business hours)

---

## Conclusion

UNI NEST Vendor is a functional, feature-rich Flutter application that enables food and restaurant vendors to manage their business operations effectively. The app has completed its core functionality with a robust order management system, product catalog, payment/payout processing, and real-time notifications.

**Current Status:**
- **Core Features**: Fully operational (Authentication, Orders, Products, Dashboard)
- **Financial System**: Complete (Ledger, Payouts, Cross-settlement)
- **Notifications**: Fully implemented (FCM Push + In-app center)
- **In Development**: Full Analytics Dashboard, Live Chat backend, Promotions system

**Key Strengths:**
- Cross-platform support (Android, iOS, Web, Desktop)
- Real-time order tracking with push notifications
- Complete payment & payout system with bank/UPI support
- Secure architecture with encrypted storage
- Modern UI with Riverpod state management
- Professional theming and animations

**Target Ready For:**
- Production deployment for vendor onboarding
- Order processing and fulfillment
- Product catalog management
- Financial tracking and payouts

---

*Document Version: 1.0.0*  
*Last Updated: May 2026*  
*For: UNI NEST Vendor App Presentation*
