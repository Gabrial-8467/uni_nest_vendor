import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/vendor_provider.dart';

class VendorDrawer extends StatelessWidget {
  const VendorDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VendorProvider>(
      builder: (context, vendorProvider, child) {
        return Drawer(
          backgroundColor: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Header
              UserAccountsDrawerHeader(
                accountName: Text(
                  vendorProvider.currentVendor?.businessName ?? 'Vendor',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                accountEmail: Text(
                  vendorProvider.currentVendor?.email ?? 'vendor@example.com',
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: const Color(0xFFFF6B6B),
                  child: Text(
                    vendorProvider.currentVendor?.businessName.isNotEmpty == true
                        ? vendorProvider.currentVendor!.businessName[0].toUpperCase()
                        : 'V',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
                  ),
                ),
              ),
              
              // Menu Items
              ListTile(
                leading: const Icon(Icons.dashboard_outlined, color: Color(0xFFFF6B6B)),
                title: const Text('Dashboard'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined, color: Colors.blue),
                title: const Text('Orders'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to orders
                },
              ),
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined, color: Colors.green),
                title: const Text('Products'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to products
                },
              ),
              ListTile(
                leading: const Icon(Icons.analytics_outlined, color: Colors.orange),
                title: const Text('Analytics'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to analytics
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person_outline, color: Colors.purple),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to profile
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined, color: Colors.grey),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to settings
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout'),
                onTap: () async {
                  Navigator.pop(context);
                  await vendorProvider.logout();
                  // Navigate to login screen
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
