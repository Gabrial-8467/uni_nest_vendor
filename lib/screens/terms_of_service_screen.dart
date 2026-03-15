import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Terms of Service',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 4,
        shadowColor: Colors.black26,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'UNI NEST Vendor - Terms of Service',
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

            _buildSection('1. Acceptance of Terms', [
              'By accessing and using the UNI NEST Vendor application, you accept and agree to be bound by these Terms of Service.',
              'If you do not agree to these terms, you may not access or use the application.',
            ]),

            _buildSection('2. Description of Service', [
              'UNI NEST Vendor is a platform that connects vendors with customers for accommodation services.',
              'Our service includes product listings, order management, customer communication, and payment processing.',
              'We provide tools to help vendors manage their business efficiently and grow their customer base.',
            ]),

            _buildSection('3. Vendor Responsibilities', [
              'Vendors must provide accurate and complete information about their properties and services.',
              'All listings must be truthful and not misleading in any way.',
              'Vendors are responsible for maintaining accurate availability and responding to customer inquiries promptly.',
              'You must comply with all applicable laws and regulations regarding your business operations.',
            ]),

            _buildSection('4. Prohibited Activities', [
              'Vendors may not use the platform for illegal activities or to promote illegal services.',
              'False or misleading information about properties is strictly prohibited.',
              'Discrimination based on race, color, religion, national origin, sex, disability, or age is forbidden.',
              'Any form of fraud, including fake reviews or artificial inflation of ratings, is prohibited.',
            ]),

            _buildSection('5. Payment and Fees', [
              'UNI NEST charges a commission fee on successful transactions.',
              'The fee structure is clearly outlined in your vendor dashboard.',
              'Additional fees may apply for premium features or promotional services.',
              'Vendors are responsible for any taxes applicable to their earnings.',
            ]),

            _buildSection('6. Intellectual Property', [
              'Vendors retain ownership of their original content and intellectual property.',
              'By using our platform, you grant us a license to use your content for service promotion.',
              'You must have the right to use all images, descriptions, and content you upload.',
              'We reserve the right to remove content that violates these terms.',
            ]),

            _buildSection('7. Privacy and Data Protection', [
              'We collect and use your information in accordance with our Privacy Policy.',
              'Your personal information is protected by industry-standard security measures.',
              'We may share anonymous data for analytics and service improvement purposes.',
              'You can review and update your privacy settings at any time.',
            ]),

            _buildSection('8. Termination', [
              'Either party may terminate this agreement at any time with or without cause.',
              'Upon termination, you must cease using the platform and remove your listings.',
              'We will provide access to your data for a reasonable period after termination.',
              'Outstanding fees and obligations must be settled before account closure.',
            ]),

            _buildSection('9. Limitation of Liability', [
              'UNI NEST is not responsible for the conduct of vendors or customers.',
              'We are not liable for any indirect, incidental, or consequential damages.',
              'Our liability is limited to the amount paid for our services, if any.',
              'We do not guarantee the accuracy or reliability of user-generated content.',
            ]),

            _buildSection('10. Contact and Support', [
              'For questions about these Terms of Service, please contact our support team.',
              'You can reach us through the Help & Support section in the app.',
              'We reserve the right to update these terms at any time.',
              'Continued use of the platform constitutes acceptance of any updated terms.',
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
                  'I Understand and Agree',
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
