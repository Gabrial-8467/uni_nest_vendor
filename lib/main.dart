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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize secure configuration
  await VendorConfig.initialize();

  runApp(const UNINestVendorApp());
}

class UNINestVendorApp extends StatelessWidget {
  const UNINestVendorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => VendorProvider(),
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
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VendorProvider>(
      builder: (context, vendorProvider, child) {
        // Initialize provider if not already done
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!vendorProvider.isAuthenticated) {
            vendorProvider.initialize();
          }
        });

        if (vendorProvider.isAuthenticated) {
          return const VendorDashboardScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
