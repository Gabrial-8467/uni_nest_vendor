import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key, this.showPageHeader = true});

  final bool showPageHeader;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: showPageHeader
          ? AppBar(
              backgroundColor: AppTheme.surface,
              elevation: 0,
              foregroundColor: AppTheme.textPrimary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text(
                'Analytics',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
              ),
              centerTitle: true,
            )
          : null,
      body: const SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: _AnalyticsComingSoonCard(),
          ),
        ),
      ),
    );
  }
}

class _AnalyticsComingSoonCard extends StatelessWidget {
  const _AnalyticsComingSoonCard();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: AppTheme.primary,
              size: 42,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Analytics Coming Soon',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Performance reports, revenue trends, product insights, and export tools are being prepared for vendors.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
