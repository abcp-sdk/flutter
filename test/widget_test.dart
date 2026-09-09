import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agent_app/main.dart';

void main() {
  testWidgets('app launches to setup', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'token': ''});
    await tester.pumpWidget(const EasyLabApp());
    await tester.pump();
    expect(find.text('网关地址'), findsOneWidget);
  });
}
