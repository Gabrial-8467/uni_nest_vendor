import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/vendor_config.dart';
import 'state/vendor_provider.dart';
import 'screens/vendor_dashboard_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'utils/app_theme.dart';
import 'utils/connectivity_service.dart';
import 'utils/logger.dart';
import 'utils/performance_optimizer.dart';
import 'services/auth_service.dart';
import 'services/cache_service.dart';
import 'services/update_service.dart';
import 'services/permission_service.dart';
import 'widgets/permission_request_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize secure configuration
    await VendorConfig.initialize();

    // Check production readiness
    if (!VendorConfig.isProductionReady) {
      debugPrint('WARNING: App is not production ready!');
    }

    // Initialize core services
    await _initializeServices();

    runApp(const UNINestVendorApp());
  } catch (e) {
    debugPrint('Failed to initialize app: $e');
    // Fallback initialization
    runApp(const UNINestVendorApp());
  }
}

Future<void> _initializeServices() async {
  try {
    // Initialize logger first
    await Logger().initialize();
  } catch (e) {
    debugPrint('Logger initialization failed: $e');
  }

  try {
    // Initialize connectivity service
    await ConnectivityService().initialize();
  } catch (e) {
    debugPrint('Connectivity service initialization failed: $e');
  }

  try {
    // Initialize authentication service
    AuthService().startSessionTimer();
  } catch (e) {
    debugPrint('Auth service initialization failed: $e');
  }

  try {
    // Initialize cache service
    await CacheService().initialize();
  } catch (e) {
    debugPrint('Cache service initialization failed: $e');
  }

  try {
    // Initialize update service
    await UpdateService().initialize();
  } catch (e) {
    debugPrint('Update service initialization failed: $e');
  }

  try {
    // Initialize performance optimizer
    PerformanceOptimizer().initialize();
  } catch (e) {
    debugPrint('Performance optimizer initialization failed: $e');
  }

  try {
    // Initialize permission service
    await PermissionService.initializePermissions();
  } catch (e) {
    debugPrint('Permission service initialization failed: $e');
  }

  debugPrint('Services initialization completed');
}

class UNINestVendorApp extends StatelessWidget {
  const UNINestVendorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => VendorProvider(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: PermissionWrapper(
          child: MaterialApp(
            title: VendorConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: const SplashScreen(),
            routes: {
              '/auth': (context) => const AuthWrapper(),
              '/dashboard': (context) => const VendorDashboardScreen(),
              '/orders': (context) => const OrdersScreen(),
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignupScreen(),
              '/forgot-password': (context) => const ForgotPasswordScreen(),
            },
          ),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final vendorProvider = Provider.of<VendorProvider>(
        context,
        listen: false,
      );
      await vendorProvider.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing app: $e');
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFFFF6B6B),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return Consumer<VendorProvider>(
      builder: (context, vendorProvider, child) {
        if (vendorProvider.isAuthenticated) {
          return const VendorDashboardScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
