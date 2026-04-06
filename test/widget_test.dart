import 'package:flutter_test/flutter_test.dart';

import 'package:fifalove_mobile/main.dart';

void main() {
  testWidgets('Renders Turf&Ardor landing screen text', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TurfAndArdorApp());

    // Verify that the LandingScreen renders key text
    expect(find.text('Turf&Ardor'), findsOneWidget);
    expect(find.text('Match Across Borders'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}

