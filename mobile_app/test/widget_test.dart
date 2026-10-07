import 'package:flutter_test/flutter_test.dart';
import 'package:sms_spam_detector_app/main.dart';

void main() {
  testWidgets('App loads home screen test', (WidgetTester tester) async {
    await tester.pumpWidget(const SMSSpamDetectorApp());
    await tester.pumpAndSettle();
    expect(find.text('SMS Shield AI'), findsOneWidget);
  });
}
