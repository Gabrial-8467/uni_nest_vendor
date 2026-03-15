import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_theme.dart';

class HelpAndSupportScreen extends StatefulWidget {
  const HelpAndSupportScreen({super.key});

  @override
  State<HelpAndSupportScreen> createState() => _HelpAndSupportScreenState();
}

class _HelpAndSupportScreenState extends State<HelpAndSupportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        title: const Text(
          'Help & Support',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3436),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Help Section
            _buildSectionCard('Quick Help', 'Common questions and quick solutions', [
              _buildHelpItem(
                'How to update my profile?',
                'Go to Profile tab and tap the edit button to update your business information.',
                Icons.person_outline,
                Colors.blue,
              ),
              _buildHelpItem(
                'How to add new products?',
                'Navigate to Products tab and tap the "+" button to add new items to your catalog.',
                Icons.add_shopping_cart,
                Colors.green,
              ),
              _buildHelpItem(
                'How to view orders?',
                'Check the Orders tab to see all customer orders and their status.',
                Icons.receipt_long,
                Colors.orange,
              ),
              _buildHelpItem(
                'How to change password?',
                'Go to Profile > Account Actions > Change Password to update your security credentials.',
                Icons.lock_outline,
                Colors.red,
              ),
            ]),

            const SizedBox(height: 20),

            // Contact Support Section
            _buildSectionCard(
              'Contact Support',
              'Get in touch with our support team',
              [
                _buildContactItem(
                  'Phone Support',
                  'Call us for immediate assistance',
                  Icons.phone,
                  Colors.green,
                  '+1-800-UNI-NEST',
                  () => _launchPhone('+18002346378'),
                ),
                _buildContactItem(
                  'Email Support',
                  'Send us an email for detailed inquiries',
                  Icons.email,
                  Colors.blue,
                  'support@uninest.com',
                  () => _launchEmail('support@uninest.com'),
                ),
                _buildContactItem(
                  'Live Chat',
                  'Chat with our support team in real-time',
                  Icons.chat,
                  Colors.purple,
                  'Start Chat',
                  () => _launchChat(),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Resources Section
            _buildSectionCard(
              'Resources',
              'Helpful resources and documentation',
              [
                _buildResourceItem(
                  'User Guide',
                  'Complete guide to using UNI NEST Vendor',
                  Icons.menu_book,
                  Colors.indigo,
                  () => _launchUrl('https://docs.uninest.com/vendor-guide'),
                ),
                _buildResourceItem(
                  'Video Tutorials',
                  'Step-by-step video tutorials',
                  Icons.play_circle,
                  Colors.red,
                  () => _launchUrl('https://tutorials.uninest.com/vendor'),
                ),
                _buildResourceItem(
                  'FAQs',
                  'Frequently asked questions',
                  Icons.help_outline,
                  Colors.orange,
                  () => _launchUrl('https://faq.uninest.com/vendor'),
                ),
                _buildResourceItem(
                  'API Documentation',
                  'Technical documentation for developers',
                  Icons.code,
                  Colors.teal,
                  () => _launchUrl('https://api.uninest.com/docs'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Legal Section
            _buildSectionCard('Legal', 'Terms, privacy, and policies', [
              _buildResourceItem(
                'Terms of Service',
                'Our terms and conditions',
                Icons.description,
                Colors.grey,
                () => _launchUrl('https://uninest.com/terms'),
              ),
              _buildResourceItem(
                'Privacy Policy',
                'How we handle your data',
                Icons.security,
                Colors.grey,
                () => _launchUrl('https://uninest.com/privacy'),
              ),
              _buildResourceItem(
                'Refund Policy',
                'Our refund and return policies',
                Icons.currency_exchange,
                Colors.grey,
                () => _launchUrl('https://uninest.com/refunds'),
              ),
            ]),

            const SizedBox(height: 30),

            // App Info
            Center(
              child: Column(
                children: [
                  Text(
                    'UNI NEST Vendor',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '© 2024 UNI NEST. All rights reserved.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    String title,
    String subtitle,
    List<Widget> children,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000), // Black with 5% opacity
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3436),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    String title,
    String description,
    IconData icon,
    Color color,
    String value,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceItem(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Show a message that the URL couldn't be launched
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not launch link. Please check your browser settings.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchChat() async {
    // Open the chat support page
    await _launchUrl('https://uninest.com/support/chat');
  }
}
