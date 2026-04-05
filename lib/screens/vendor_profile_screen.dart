import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/app_theme.dart';
import '../screens/analytics_screen.dart';
import '../core/vendor_formatters.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';

class VendorProfileTab extends ConsumerStatefulWidget {
  const VendorProfileTab({super.key});

  @override
  ConsumerState<VendorProfileTab> createState() => _VendorProfileTabState();
}

class _VendorProfileTabState extends ConsumerState<VendorProfileTab>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _cardAnimation;

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _headerAnimation = CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutQuart,
    );
    _cardAnimation = CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutCubic,
    );

    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _cardAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profile = authState.session?.profile;
    final orderState = ref.watch(orderProvider);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildProfileHeader(profile, orderState),
          const SizedBox(height: 24),
          _buildBusinessDetails(profile),
          const SizedBox(height: 24),
          _buildContactInfo(profile),
          const SizedBox(height: 24),
          _buildQuickActions(authState),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(dynamic profile, OrderState orderState) {
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _headerAnimation.value) * 30),
          child: Opacity(
            opacity: _headerAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppTheme.primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Hero(
                        tag: 'profile-avatar',
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 38,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            backgroundImage: profile?.avatarUrl != null
                                ? NetworkImage(profile!.avatarUrl!)
                                : null,
                            child: profile?.avatarUrl == null
                                ? Text(
                                    _initials(profile?.name ?? 'Vendor'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 28,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile?.businessName ?? 'Vendor Business',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                profile?.businessType == null
                                    ? profile?.name ?? 'Vendor'
                                    : humanizeEnum(profile!.businessType!),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildStatCard(
                        'Active',
                        '${orderState.orders.where((o) => ['pending', 'confirmed', 'preparing', 'ready', 'out_for_delivery'].contains(o.status)).length}',
                        Colors.green,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        'Pending',
                        '${orderState.orders.where((o) => ['pending', 'confirmed'].contains(o.status)).length}',
                        Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        'Total',
                        '${orderState.orders.length}',
                        Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessDetails(dynamic profile) {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _cardAnimation.value) * 20),
          child: Opacity(
            opacity: _cardAnimation.value,
            child: _modernCard(
              title: 'Business Information',
              icon: Icons.store_outlined,
              iconColor: const Color(0xFF6366F1),
              child: Column(
                children: [
                  _buildInfoTile(
                    icon: Icons.person_outline,
                    label: 'Owner Name',
                    value: profile?.name ?? 'Not specified',
                    color: const Color(0xFF6366F1),
                  ),
                  _buildDivider(),
                  _buildInfoTile(
                    icon: Icons.business_outlined,
                    label: 'Business Name',
                    value: profile?.businessName ?? 'Not specified',
                    color: const Color(0xFF8B5CF6),
                  ),
                  _buildDivider(),
                  _buildInfoTile(
                    icon: Icons.category_outlined,
                    label: 'Business Type',
                    value: profile?.businessType == null
                        ? 'Not specified'
                        : humanizeEnum(profile!.businessType!),
                    color: const Color(0xFFEC4899),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactInfo(dynamic profile) {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _cardAnimation.value) * 20),
          child: Opacity(
            opacity: _cardAnimation.value,
            child: _modernCard(
              title: 'Contact Information',
              icon: Icons.contact_phone_outlined,
              iconColor: const Color(0xFF10B981),
              child: Column(
                children: [
                  _buildInfoTile(
                    icon: Icons.email_outlined,
                    label: 'Email Address',
                    value: profile?.email ?? 'Not specified',
                    color: const Color(0xFF3B82F6),
                  ),
                  _buildDivider(),
                  _buildInfoTile(
                    icon: Icons.phone_outlined,
                    label: 'Phone Number',
                    value: profile?.phone ?? 'Not specified',
                    color: const Color(0xFF10B981),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(dynamic authState) {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _cardAnimation.value) * 20),
          child: Opacity(
            opacity: _cardAnimation.value,
            child: _modernCard(
              title: 'Quick Actions',
              icon: Icons.flash_on_outlined,
              iconColor: const Color(0xFFF59E0B),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildActionTile(
                      icon: Icons.edit_outlined,
                      title: 'Edit Profile',
                      subtitle: 'Update your business information',
                      color: const Color(0xFF8B5CF6),
                      onTap: () => _showEditProfileDialog(),
                    ),
                    const SizedBox(height: 12),
                    _buildActionTile(
                      icon: Icons.analytics_outlined,
                      title: 'Analytics',
                      subtitle: 'View performance analytics',
                      color: const Color(0xFF10B981),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AnalyticsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildActionTile(
                      icon: Icons.logout,
                      title: 'Logout',
                      subtitle: 'Sign out from your account',
                      color: const Color(0xFFEF4444),
                      onTap: () => _handleLogout(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _modernCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isMultiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: isMultiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(height: 1, thickness: 1, color: Colors.grey[200]),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/auth', (route) => false);
      }
    }
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

  void _showEditProfileDialog() {
    final authState = ref.read(authProvider);
    final profile = authState.session?.profile;

    if (profile == null) return;

    // Create text controllers with current values
    final nameController = TextEditingController(text: profile.name);
    final businessNameController = TextEditingController(
      text: profile.businessName,
    );
    final phoneController = TextEditingController(text: profile.phone);

    // Business type options
    final businessTypes = [
      'Restaurant',
      'Cafe',
      'Bakery',
      'Fast Food',
      'Food Truck',
      'Cloud Kitchen',
      'Catering',
      'Other',
    ];

    String selectedBusinessType = profile.businessType ?? 'Restaurant';
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.edit_outlined, color: AppTheme.primary),
              const SizedBox(width: 12),
              const Text('Edit Profile'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Personal Information Section
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Name Field
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Phone Field
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter your phone number',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Business Information Section
                const Text(
                  'Business Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Business Name Field
                TextField(
                  controller: businessNameController,
                  decoration: InputDecoration(
                    labelText: 'Business Name',
                    hintText: 'Enter your business name',
                    prefixIcon: const Icon(Icons.business_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Business Type Dropdown
                DropdownButtonFormField<String>(
                  initialValue: selectedBusinessType,
                  decoration: InputDecoration(
                    labelText: 'Business Type',
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primary),
                    ),
                  ),
                  items: businessTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() {
                        selectedBusinessType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      // Store context before async operations
                      final dialogContext = context;

                      // Validate inputs
                      if (nameController.text.trim().isEmpty ||
                          businessNameController.text.trim().isEmpty ||
                          phoneController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in all required fields'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() {
                        isLoading = true;
                      });

                      try {
                        // Prepare update data
                        final updateData = {
                          'name': nameController.text.trim(),
                          'businessName': businessNameController.text.trim(),
                          'phone': phoneController.text.trim(),
                          'businessType': selectedBusinessType,
                        };

                        // Update profile via auth provider
                        if (!mounted) return;

                        final success = await ref
                            .read(authProvider.notifier)
                            .updateProfile(updateData);

                        if (!mounted) return;

                        if (success && mounted) {
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                          if (mounted && dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 12),
                                    Text('Profile updated successfully!'),
                                  ],
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } else if (mounted && dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Failed to update profile. Please try again.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted && dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            isLoading = false;
                          });
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Update Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
