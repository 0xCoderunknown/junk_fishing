import 'package:flutter_test/flutter_test.dart';
import 'package:junk_fishing/main.dart';

void main() {
  testWidgets('Junk Fishing app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const JunkFishingApp());

    // Verify app builds
    expect(find.byType(JunkFishingApp), findsOneWidget);
  });
}
