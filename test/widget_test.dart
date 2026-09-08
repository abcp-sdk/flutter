import 'package:flutter_test/flutter_test.dart';

import 'package:agent_app/main.dart';

void main() {
  testWidgets('app launches to settings', (WidgetTester tester) async {
    await tester.pumpWidget(const AgentApp());
    expect(find.text('Settings'), findsOneWidget);
  });
}
