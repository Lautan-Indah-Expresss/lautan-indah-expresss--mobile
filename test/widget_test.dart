import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('Driver logistics app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LieDriverApp(initialLoggedIn: false));
    expect(find.text('LIE Driver'), findsOneWidget);
  });
}
