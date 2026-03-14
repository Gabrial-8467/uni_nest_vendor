import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uni_nest_vendor/main.dart';

void main() {
  testWidgets('UNINestVendorApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const UNINestVendorApp());

    // Verify that the app builds successfully
    expect(find.byType(MaterialApp), findsOneWidget);

    // Verify that we can find the login screen (initial screen)
    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.text('UNI NEST Vendor'), findsOneWidget);
  });
}
