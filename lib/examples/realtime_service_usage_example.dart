import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/realtime_notification_service.dart';

/// Example of how to use RealtimeNotificationService with Riverpod
class RealtimeServiceExample extends ConsumerStatefulWidget {
  const RealtimeServiceExample({super.key});

  @override
  ConsumerState<RealtimeServiceExample> createState() => _RealtimeServiceExampleState();
}

class _RealtimeServiceExampleState extends ConsumerState<RealtimeServiceExample> {
  @override
  void initState() {
    super.initState();
    // Set the ref for the service to access providers
    RealtimeNotificationService.setRef(ref);
    // Initialize the service
    RealtimeNotificationService.initialize();
  }

  @override
  void dispose() {
    // Clean up the service
    RealtimeNotificationService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Realtime Service Example'),
      ),
      body: const Center(
        child: Text('Realtime notification service is running'),
      ),
    );
  }
}
