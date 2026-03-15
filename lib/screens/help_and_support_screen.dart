import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_theme.dart';
import '../widgets/widgets.dart';
import '../screens/live_chat_screen.dart';

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
              _buildHelpItem(
                'How to enable notifications?',
                'Go to Profile > Notification Settings to configure email and push notifications.',
                Icons.notifications_outlined,
                Colors.purple,
              ),
              _buildHelpItem(
                'How to track sales?',
                'View the Dashboard tab to see real-time sales data and analytics.',
                Icons.trending_up,
                Colors.teal,
              ),
              _buildHelpItem(
                'How to handle refunds?',
                'Go to Orders > Select Order > Process Refund to issue customer refunds.',
                Icons.currency_exchange,
                Colors.amber,
              ),
              _buildHelpItem(
                'How to update business hours?',
                'Profile > Business Settings > Operating Hours to set your availability.',
                Icons.schedule,
                Colors.indigo,
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
                  'Send us an email for support inquiries',
                  Icons.email,
                  Colors.blue,
                  'support@uninest.com',
                  () => _launchEmail(
                    'support@uninest.com',
                    subject: 'Support Request - UNI NEST Vendor',
                    body:
                        'Hello UNI NEST Support,\n\nI need help with:\n\n[Please describe your issue here]\n\nThank you,\n[Your Name]\nVendor ID: [Your Vendor ID]',
                  ),
                ),
                _buildContactItem(
                  'Live Chat',
                  'Chat with our support team in real-time',
                  Icons.chat,
                  Colors.teal,
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
                  'Step-by-step video tutorials',
                  'Step-by-step video tutorials',
                  Icons.play_circle,
                  Colors.red,
                  () => _launchUrl('https://tutorials.uninest.com/vendor'),
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
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TermsOfServiceScreen(),
                  ),
                ),
              ),
              _buildResourceItem(
                'Privacy Policy',
                'How we handle your data',
                Icons.security,
                Colors.grey,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyScreen(),
                  ),
                ),
              ),
              _buildResourceItem(
                'Refund Policy',
                'Our refund and return policies',
                Icons.currency_exchange,
                Colors.grey,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RefundPolicyScreen(),
                  ),
                ),
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

  Future<void> _launchEmail(
    String email, {
    String? subject,
    String? body,
  }) async {
    final Map<String, String> queryParams = {};
    if (subject != null) queryParams['subject'] = subject;
    if (body != null) queryParams['body'] = body;

    final String queryString = _encodeQueryParameters(queryParams) ?? '';

    try {
      // Try standard mailto first (this usually opens user's default email app, which is often Gmail)
      final emailUri = Uri(
        scheme: 'mailto',
        path: email,
        query: queryString.isNotEmpty ? queryString : null,
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        return;
      }

      // Try Gmail app using package-specific intent
      final gmailIntent =
          'intent://sendto/$email#Intent;scheme=mailto;package=com.google.android.gm;S.android.intent.action.SEND;end';

      if (await canLaunchUrl(Uri.parse(gmailIntent))) {
        await launchUrl(Uri.parse(gmailIntent));
        return;
      }

      // Fallback: show manual email dialog
      _showEmailFallback(email, subject, body);
    } catch (e) {
      _showEmailFallback(email, subject, body);
    }
  }

  void _showEmailFallback(String email, String? subject, String? body) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email App Not Available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Could not open your email app. You can send us an email manually using the information below:',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Email Address:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SelectableText(email),
                  if (subject != null) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Subject:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SelectableText(subject),
                  ],
                  if (body != null) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Message Template:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SelectableText(body),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _copyToClipboard(email, subject, body);
            },
            child: const Text('Copy Details'),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String email, String? subject, String? body) async {
    final emailContent =
        'To: $email\n'
        'Subject: ${subject ?? "Support Request"}\n\n'
        '${body ?? "Please describe your issue here..."}';

    await Clipboard.setData(ClipboardData(text: emailContent));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email details copied to clipboard!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
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
    // Navigate to the live chat screen
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const LiveChatScreen()));
  }
}
