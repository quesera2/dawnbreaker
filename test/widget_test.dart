import 'package:flutter_test/flutter_test.dart';

import 'package:dawnbreaker/app/app.dart';

void main() {
  testWidgets('Home screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const App());

    expect(find.text('Dawnbreaker'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });
}