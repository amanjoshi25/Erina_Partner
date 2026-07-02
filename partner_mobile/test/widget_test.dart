// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:partner_mobile/main.dart';

void main() {
  testWidgets('Partner home renders balance test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ErinaPartnerApp());

    // Verify that our partner home tab loads and displays the total balance.
    expect(find.text('₹18,450'), findsOneWidget);
    expect(find.text('48 Drivers'), findsOneWidget);
  });
}
