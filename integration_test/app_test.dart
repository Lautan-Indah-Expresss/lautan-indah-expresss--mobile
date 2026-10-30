import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Driver App E2E Integration Flow', () {
    testWidgets('1. App launches into splash screen and transitions to driver login screen', (tester) async {
      await tester.pumpWidget(const LieDriverApp());
      await tester.pump();

      // Verify app initialized
      expect(find.byType(MaterialApp), findsOneWidget);

      // Advance through splash screen delay (1400ms + transitions)
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      // Check login screen elements
      expect(find.text('DRIVER'), findsOneWidget);
      expect(find.text('PT LAUTAN INDAH EXPRESS'), findsOneWidget);
      expect(find.text('MASUK KE APLIKASI'), findsOneWidget);
    });

    testWidgets('2. Empty username/password triggers validation message', (tester) async {
      await tester.pumpWidget(const LieDriverApp());
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      // Tap "MASUK KE APLIKASI" with empty fields
      final loginButton = find.text('MASUK KE APLIKASI');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Validation error banner should appear
      expect(find.text('Nama pengguna dan kata sandi wajib diisi.'), findsOneWidget);
    });

    testWidgets('3. Entering credentials and toggling password visibility works smoothly', (tester) async {
      await tester.pumpWidget(const LieDriverApp());
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      // Fill in username
      final usernameField = find.widgetWithText(TextField, 'Masukkan nama pengguna...');
      expect(usernameField, findsOneWidget);
      await tester.enterText(usernameField, 'driver_test');

      // Fill in password
      final passwordField = find.widgetWithText(TextField, 'Masukkan kata sandi...');
      expect(passwordField, findsOneWidget);
      await tester.enterText(passwordField, 'rahasia123');
      await tester.pumpAndSettle();

      expect(find.text('driver_test'), findsOneWidget);

      // Toggle password visibility
      final visibilityToggle = find.byIcon(Icons.visibility);
      if (visibilityToggle.evaluate().isNotEmpty) {
        await tester.tap(visibilityToggle);
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      }
    });
  });
}
