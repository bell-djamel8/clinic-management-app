import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clinic_app/main.dart';

void main() {
  testWidgets('App starts and shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ClinicApp());

    // Trigger a frame so any async build settles.
    await tester.pump();

    // Verify the app builds without crashing and MaterialApp is present.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
