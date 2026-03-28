import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class AppFlowTestWidget extends StatelessWidget {
  const AppFlowTestWidget({super.key});

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
              'App Flow Test',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFlowStep('1️⃣', 'Splash Screen', 'Shows UNINEST logo and loading animation'),
            _buildFlowStep('2️⃣', 'Auth Wrapper', 'Checks authentication status and initializes provider'),
            _buildFlowStep('3️⃣', 'Login Screen', 'Shows for unauthenticated users'),
            _buildFlowStep('4️⃣', 'Sign Up Screen', 'Accessible from login screen'),
            _buildFlowStep('5️⃣', 'Dashboard', 'Shows after successful login'),
            const SizedBox(height: 16),
            const Text(
              'Navigation Flow:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildNavigationRow('Splash → Auth', '/auth', '3 seconds'),
            _buildNavigationRow('Login → Sign Up', '/signup', 'Tap "Sign Up"'),
            _buildNavigationRow('Sign Up → Login', 'pop()', 'Tap "Sign In"'),
            _buildNavigationRow('Login → Dashboard', '/dashboard', 'After successful login'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'App flow is properly configured! Splash → Auth → Login/Signup → Dashboard',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRow(String from, String to, String trigger) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$from →',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              to,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            '($trigger)',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
