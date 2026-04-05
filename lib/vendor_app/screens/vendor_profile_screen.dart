import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/app_theme.dart';
import '../core/vendor_formatters.dart';
import '../providers/auth_provider.dart';

// =============================================================================
// VENDOR PROFILE TAB
// =============================================================================
//
// Purpose: Display vendor profile information in the new Riverpod architecture
// Features:
// - Profile information display
// - Avatar management
// - Business details overview
// - Account statistics
// - Profile refresh functionality
//
// Sections:
// 1. Profile Header - Avatar and basic information
// 2. Business Details - Business name, type, and contact info
// 3. Account Statistics - Performance metrics and summary
// 4. Profile Actions - Edit and logout options
// =============================================================================

class VendorProfileTab extends ConsumerWidget {
  const VendorProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profile = authState.session?.profile;

    return RefreshIndicator(
      onRefresh: () => ref.read(authProvider.notifier).refreshProfile(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFF97316)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  backgroundImage: profile?.avatarUrl != null
                      ? NetworkImage(profile!.avatarUrl!)
                      : null,
                  child: profile?.avatarUrl == null
                      ? Text(
                          _initials(profile?.name ?? 'Vendor'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.businessName ?? 'Vendor Business',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile?.businessType == null
                            ? profile?.name ?? ''
                            : '${profile!.name} • ${humanizeEnum(profile.businessType!)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ProfileSection(
            title: 'Business details',
            children: [
              _InfoRow(label: 'Owner name', value: profile?.name ?? '-'),
              _InfoRow(
                label: 'Business name',
                value: profile?.businessName ?? '-',
              ),
              _InfoRow(
                label: 'Business type',
                value: profile?.businessType == null
                    ? '-'
                    : humanizeEnum(profile!.businessType!),
              ),
              _InfoRow(
                label: 'Description',
                value:
                    profile?.description ??
                    'No business description added yet.',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ProfileSection(
            title: 'Contact',
            children: [
              _InfoRow(label: 'Email', value: profile?.email ?? '-'),
              _InfoRow(label: 'Phone', value: profile?.phone ?? '-'),
            ],
          ),
          const SizedBox(height: 16),
          _ProfileSection(
            title: 'Account actions',
            children: [
              _ActionTile(
                icon: Icons.refresh_outlined,
                color: AppTheme.info,
                title: 'Refresh profile',
                subtitle: 'Sync the latest vendor profile from server.',
                onTap: () async {
                  // Clear any existing errors first
                  ref.read(authProvider.notifier).clearError();

                  // Show loading indicator
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Refreshing profile...'),
                          ],
                        ),
                        duration: Duration(seconds: 10),
                      ),
                    );
                  }

                  try {
                    await ref.read(authProvider.notifier).refreshProfile();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 12),
                              const Text('Profile refreshed successfully!'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.white),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _getFriendlyErrorMessage(e.toString()),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.red,
                          action: SnackBarAction(
                            label: 'Retry',
                            textColor: Colors.white,
                            onPressed: () async {
                              await ref
                                  .read(authProvider.notifier)
                                  .refreshProfile();
                            },
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
              _ActionTile(
                icon: Icons.sync_problem_outlined,
                color: Colors.orange,
                title: 'Connection troubleshoot',
                subtitle: 'Fix connection issues and sync problems.',
                onTap: () async {
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Connection Troubleshoot'),
                        content: const Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Try these steps to fix connection issues:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 12),
                            Text('1. Check your internet connection'),
                            Text('2. Wait a few seconds and try again'),
                            Text('3. Restart the app if problems persist'),
                            Text('4. Contact support if issue continues'),
                            SizedBox(height: 12),
                            Text(
                              'Common issues:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('• Slow or unstable internet'),
                            Text('• Server temporarily unavailable'),
                            Text('• Session expired'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await ref
                                  .read(authProvider.notifier)
                                  .refreshProfile();
                            },
                            child: const Text('Test Connection'),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
              _ActionTile(
                icon: Icons.logout,
                color: AppTheme.error,
                title: 'Logout',
                subtitle: 'Clear vendor session on this device.',
                onTap: () async {
                  if (context.mounted) {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.error,
                            ),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/auth', (route) => false);
                      }
                    }
                  }
                },
              ),
            ],
          ),
          if (authState.errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Connection Error',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getFriendlyErrorMessage(authState.errorMessage!),
                    style: TextStyle(color: Colors.red[600], fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () =>
                        ref.read(authProvider.notifier).refreshProfile(),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _initials(String value) {
    final parts = value
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  static String _getFriendlyErrorMessage(String error) {
    final lowerError = error.toLowerCase();

    if (lowerError.contains('network') || lowerError.contains('connection')) {
      return 'Unable to connect to server. Please check your internet connection and try again.';
    } else if (lowerError.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (lowerError.contains('unauthorized') ||
        lowerError.contains('401')) {
      return 'Session expired. Please log in again.';
    } else if (lowerError.contains('forbidden') || lowerError.contains('403')) {
      return 'Access denied. Please check your permissions.';
    } else if (lowerError.contains('not found') || lowerError.contains('404')) {
      return 'Profile not found. Please contact support.';
    } else if (lowerError.contains('server error') ||
        lowerError.contains('500')) {
      return 'Server is temporarily unavailable. Please try again in a few minutes.';
    } else {
      return 'An unexpected error occurred. Please try again or contact support if the problem persists.';
    }
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
