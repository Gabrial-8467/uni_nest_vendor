import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/app_theme.dart';
import '../providers/auth_provider.dart';
import 'vendor_login_screen.dart';
import 'vendor_shell_screen.dart';

class VendorAuthGateScreen extends ConsumerStatefulWidget {
  const VendorAuthGateScreen({super.key});

  @override
  ConsumerState<VendorAuthGateScreen> createState() =>
      _VendorAuthGateScreenState();
}

class _VendorAuthGateScreenState extends ConsumerState<VendorAuthGateScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authProvider.notifier).bootstrap());
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    // Only show full-screen loading during initial bootstrap (app startup)
    // NOT during login operations - login screen handles its own button loading
    if (!authState.didBootstrap) {
      return const Scaffold(
        backgroundColor: AppTheme.primary,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (!authState.isAuthenticated) {
      return const VendorLoginScreen();
    }

    return const VendorShellScreen();
  }
}
