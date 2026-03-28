import 'package:flutter/material.dart';
import '../config/vendor_config.dart';
import '../config/api_endpoints.dart';

class ConnectionTestWidget extends StatelessWidget {
  const ConnectionTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Backend Connection Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildConfigRow('Base URL', VendorConfig.apiBaseUrl),
            _buildConfigRow(
              'Environment',
              VendorConfig.isDebugMode ? 'Development' : 'Production',
            ),
            _buildConfigRow(
              'HTTPS Enforced',
              VendorConfig.enforceHttps.toString(),
            ),
            _buildConfigRow(
              'Timeout',
              '${VendorConfig.connectionTimeout.inSeconds}s',
            ),
            _buildConfigRow('Max Retries', VendorConfig.maxRetries.toString()),
            const SizedBox(height: 16),
            const Text(
              'API Endpoints:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildEndpointRow(
              'Login',
              '${ApiEndpoints.baseUrl}${ApiEndpoints.login}',
            ),
            _buildEndpointRow(
              'Profile',
              '${ApiEndpoints.baseUrl}${ApiEndpoints.profile}',
            ),
            _buildEndpointRow(
              'Products',
              '${ApiEndpoints.baseUrl}${ApiEndpoints.products}',
            ),
            _buildEndpointRow(
              'Orders',
              '${ApiEndpoints.baseUrl}${ApiEndpoints.orders}',
            ),
            _buildEndpointRow(
              'Analytics',
              '${ApiEndpoints.baseUrl}${ApiEndpoints.analytics}',
            ),
            _buildEndpointRow(
              'Notifications',
              '${ApiEndpoints.baseUrl}${ApiEndpoints.notifications}',
            ),
            _buildEndpointRow(
              'Reviews',
              '${ApiEndpoints.baseUrl}${ApiEndpoints.reviews}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndpointRow(String label, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              url,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.blue,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
