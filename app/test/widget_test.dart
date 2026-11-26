import 'package:flutter_test/flutter_test.dart';
import 'package:guinote/main.dart';

void main() {
  testWidgets('la app arranca', (tester) async {
    await tester.pumpWidget(const GuinoteApp());
    expect(find.text('Guiñote'), findsOneWidget);
  });
}
