import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('Driver logistics app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LieDriverApp());
    expect(find.byType(MaterialApp), findsOneWidget);

    // Advance past splash controller & navigation delay
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 500));
  });
}
