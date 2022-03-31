import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';

void main() {
  testWidgets("GradientButton builds correctly with provided shadows",
      (tester) async {
    final button = GradientButton(
      onTap: () {},
      child: Text("button text"),
      enabled: true,
      shadows: [
        BoxShadow(
          color: Colors.green,
          spreadRadius: 0.1,
          blurRadius: 1.5,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: button,
      ),
    );

    expect(find.byType(MaterialButton), findsOneWidget);
    expect(find.text("button text"), findsOneWidget);
  });

  testWidgets("disabled GradientButton builds correctly", (tester) async {
    bool onTapCalled = false;
    final button = GradientButton(
      onTap: () => onTapCalled = true,
      child: Text("button text"),
      enabled: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: button,
      ),
    );

    expect(find.byType(MaterialButton), findsNothing);
    expect(find.text("button text"), findsOneWidget);

    await tester.tap(find.byType(GradientButton));
    await tester.pumpAndSettle();

    expect(onTapCalled, false);
  });

  testWidgets("enabled GradientButton builds correctly", (tester) async {
    bool onTapCalled = false;
    final button = GradientButton(
      onTap: () => onTapCalled = true,
      child: Text("button text"),
      enabled: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: button,
      ),
    );

    expect(find.byType(MaterialButton), findsOneWidget);
    expect(find.text("button text"), findsOneWidget);

    await tester.tap(find.byType(GradientButton));
    await tester.pumpAndSettle();

    expect(onTapCalled, true);
  });
}
