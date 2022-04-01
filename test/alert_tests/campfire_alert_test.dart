import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paymint/notifications/campfire_alert.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';

void main() {
  testWidgets("CampfireAlert builds correctly", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CampfireAlert(message: "Hello world!"),
      ),
    );

    expect(find.text("Hello world!"), findsOneWidget);
    expect(find.byType(GradientButton), findsOneWidget);
    expect(find.text("OK"), findsOneWidget);
  });

  testWidgets("CampfireAlert interaction", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CampfireAlert(message: "Hello world!"),
      ),
    );

    await tester.tap(find.byType(GradientButton));
    await tester.pumpAndSettle();

    expect(find.byType(CampfireAlert), findsNothing);
  });
}
