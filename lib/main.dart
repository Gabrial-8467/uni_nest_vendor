// =============================================================================
// UNI NEST Vendor Application
// =============================================================================
//
// Application: UNI NEST Vendor Management System
// Version: 1.0.0
// Platform: Flutter (Cross-platform)
// Target: Food & Restaurant Vendors
//
// Description:
// A comprehensive vendor management application for restaurants and food vendors
// to manage orders, products, payments, and business operations. Features include
// real-time order tracking, inventory management, payment processing, analytics,
// and customer communication tools.
//
// Main Features:
// - Order Management (Real-time tracking, status updates)
// - Product Catalog Management (Add/edit/remove products)
// - Payment Processing (COD, online payments)
// - Analytics & Reporting (Sales insights, performance metrics)
// - Profile Management (Business details, settings)
// - Customer Support (Live chat, help system)
// - Notifications (Order alerts, system updates)
//
// Architecture:
// - State Management: Riverpod (Vendor app) / Provider (Legacy screens)
// - Navigation: Flutter Navigator with named routes
// - Services: Modular service architecture (Auth, Cache, Connectivity, etc.)
// - UI: Material Design 3 with custom theming
// - Storage: Local caching with secure storage
//
// Author: UNI NEST Development Team
// Last Updated: April 2026
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/vendor_config.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/cache_service.dart';
import 'services/permission_service.dart';
import 'services/update_service.dart';
import 'utils/app_theme.dart';
import 'utils/connectivity_service.dart';
import 'utils/logger.dart';
import 'utils/performance_optimizer.dart';
import 'screens/auth_gate_screen.dart';
import 'screens/vendor_signup_screen.dart';
import 'screens/vendor_shell_screen.dart';
import 'screens/vendor_forgot_password_screen.dart';
import 'widgets/permission_request_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await VendorConfig.initialize();
    VendorConfig.debugApiUrl(); // Debug API URL
    await _initializeServices();
  } catch (e) {
    debugPrint('Failed to initialize app: $e');
  }

  runApp(const ProviderScope(child: UNINestVendorApp()));
}

Future<void> _initializeServices() async {
  try {
    await Logger().initialize();
  } catch (e) {
    debugPrint('Logger initialization failed: $e');
  }

  try {
    await ConnectivityService().initialize();
  } catch (e) {
    debugPrint('Connectivity service initialization failed: $e');
  }

  try {
    AuthService().startSessionTimer();
  } catch (e) {
    debugPrint('Auth service initialization failed: $e');
  }

  try {
    await CacheService().initialize();
  } catch (e) {
    debugPrint('Cache service initialization failed: $e');
  }

  try {
    await UpdateService().initialize();
  } catch (e) {
    debugPrint('Update service initialization failed: $e');
  }

  try {
    PerformanceOptimizer().initialize();
  } catch (e) {
    debugPrint('Performance optimizer initialization failed: $e');
  }

  try {
    await PermissionService.initializePermissions();
  } catch (e) {
    debugPrint('Permission service initialization failed: $e');
  }
}

class UNINestVendorApp extends StatelessWidget {
  const UNINestVendorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: PermissionWrapper(
        child: MaterialApp(
          title: VendorConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const SplashScreen(),
          routes: {
            '/auth': (context) => const VendorAuthGateScreen(),
            '/dashboard': (context) => const VendorShellScreen(),
            '/signup': (context) => const VendorSignupScreen(),
            '/forgot-password': (context) => const VendorForgotPasswordScreen(),
          },
        ),
      ),
    );
  }
}
