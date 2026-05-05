// Basic Flutter widget test for UBSER app.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:abser/main.dart';

void main() {
  testWidgets('UBSER app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: UbserApp(),
      ),
    );

    expect(find.text('UBSER'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
