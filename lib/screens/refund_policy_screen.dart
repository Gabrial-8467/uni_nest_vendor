import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class RefundPolicyScreen extends StatelessWidget {
  const RefundPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Refund & Return Policy'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'UNI NEST Vendor - Refund & Return Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Last Updated: March 15, 2026',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            _buildSection('No Return and Refund Policy', [
              'UNI NEST Vendor platform does not currently offer a return and refund policy for vendor services.',
              'All transactions made through the platform are considered final and non-refundable.',
              'Vendors are expected to provide the services as described in their listings.',
              'Customers should carefully review all details before making any bookings or purchases.',
            ]),

            _buildSection('Vendor Guidelines', [
              'Vendors must clearly describe their services and any limitations in their listings.',
              'Any special conditions or restrictions should be communicated upfront to customers.',
              'Vendors should address customer concerns professionally and promptly.',
              'In case of disputes, vendors should attempt to resolve issues directly with customers first.',
            ]),

            _buildSection('Customer Responsibilities', [
              'Customers should verify all details before confirming any bookings or transactions.',
              'Read all property descriptions, amenities, and terms carefully.',
              'Contact vendors directly if you have questions about specific services.',
              'Understand that all payments are final once confirmed.',
            ]),

            _buildSection('Exceptional Circumstances', [
              'In exceptional circumstances, UNI NEST may review individual cases on a case-by-case basis.',
              'Such circumstances may include platform errors, fraudulent activities, or other exceptional situations.',
              'Any exceptions to the no-refund policy are at the sole discretion of UNI NEST.',
              'Documentation and evidence may be required to support any refund requests.',
            ]),

            _buildSection('Platform Liability', [
              'UNI NEST acts as an intermediary platform and is not responsible for vendor-customer disputes.',
              'We are not liable for the quality of services provided by individual vendors.',
              'Our role is limited to facilitating connections and processing payments.',
              'We encourage both vendors and customers to communicate clearly to avoid misunderstandings.',
            ]),

            _buildSection('Contact Information', [
              'If you have questions about this policy, please contact our support team.',
              'For vendor-specific concerns, reach out through the Help & Support section.',
              'We are available to assist with platform-related issues and provide guidance.',
              'Regular updates to this policy may occur; check back periodically for any changes.',
            ]),

            const SizedBox(height: 40),

            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  'I Understand',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> points) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6, right: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
