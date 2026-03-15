import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
              'UNI NEST Vendor - Privacy Policy',
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

            _buildSection('1. Information We Collect', [
              'We collect information you provide directly when using UNI NEST Vendor.',
              'This includes business details, contact information, and usage data.',
              'We only collect data that is necessary to provide and improve our services.',
            ]),

            _buildSection('2. How We Use Your Information', [
              'Your information is used to create and manage your vendor account.',
              'We analyze usage patterns to improve app performance and user experience.',
              'Data is shared with service providers only when necessary for app functionality.',
              'We never sell your personal information to third parties.',
            ]),

            _buildSection('3. Data Protection Measures', [
              'We use industry-standard encryption and security measures.',
              'All data transmissions are secured using HTTPS protocols.',
              'Access to your data is restricted to authorized personnel only.',
              'Regular security audits ensure ongoing protection of your information.',
            ]),

            _buildSection('4. Your Rights and Choices', [
              'You can access, update, or delete your personal information at any time.',
              'You can request a copy of all data we hold about you.',
              'You can opt out of marketing communications while maintaining service access.',
              'You can request deletion of your account and associated data.',
            ]),

            _buildSection('5. Information Sharing', [
              'We may share anonymized data for analytics and service improvement.',
              'We never share personally identifiable information without your consent.',
              'Data sharing is limited to what is necessary for service provision.',
              'We use reputable third-party services with strong privacy protections.',
            ]),

            _buildSection('6. Data Retention', [
              'We retain your data only as long as necessary for service provision.',
              'You can request deletion of your data at any time.',
              'Deleted data is securely removed from our systems within 30 days.',
              'We comply with all applicable data retention regulations.',
            ]),

            _buildSection('7. Children\'s Privacy', [
              'We do not knowingly collect information from children under 13.',
              'Parental consent is required for minor users.',
              'We provide additional protections for children\'s data.',
              'Children\'s data is used only for account management purposes.',
            ]),

            _buildSection('8. Changes to This Policy', [
              'We may update this policy from time to time.',
              'Changes will be communicated through the app and email.',
              'Continued use of the app constitutes acceptance of updated terms.',
              'We will notify users of significant changes at least 30 days in advance.',
            ]),

            _buildSection('9. Contact Information', [
              'For privacy questions or concerns, please contact our privacy team.',
              'You can reach us through the Help & Support section in the app.',
              'We respond to privacy inquiries within 30 business days.',
              'Our privacy contact information is available in the app settings.',
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
