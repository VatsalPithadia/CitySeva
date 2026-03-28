import 'package:flutter_test/flutter_test.dart';
import 'package:cityseva/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CitySeva());
    expect(find.byType(CitySeva), findsOneWidget);
  });
}
