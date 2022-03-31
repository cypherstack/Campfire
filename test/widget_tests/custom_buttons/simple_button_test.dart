import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paymint/widgets/custom_buttons/simple_button.dart';

void main() {
  testWidgets("SimpleButton builds correctly with provided shadow and color",
      (tester) async {
    final button = SimpleButton(
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
      color: Colors.red,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: button,
      ),
    );

    expect(find.byType(MaterialButton), findsOneWidget);
    expect(find.text("button text"), findsOneWidget);
  });

  testWidgets("disabled SimpleButton builds correctly", (tester) async {
    bool onTapCalled = false;
    final button = SimpleButton(
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

    await tester.tap(find.byType(SimpleButton));
    await tester.pumpAndSettle();

    expect(onTapCalled, false);
  });

  testWidgets("enabled SimpleButton builds correctly", (tester) async {
    bool onTapCalled = false;
    final button = SimpleButton(
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

    await tester.tap(find.byType(SimpleButton));
    await tester.pumpAndSettle();

    expect(onTapCalled, true);
  });
}
