import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paymint/widgets/custom_buttons/draggable_switch_button.dart';

void main() {
  testWidgets("DraggableSwitchButton tapped", (tester) async {
    bool isButtonOn = false;
    final button = DraggableSwitchButton(
      onItem: Text("yes"),
      offItem: Text("no"),
      onValueChanged: (newValue) => isButtonOn = newValue,
      enabled: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: button,
      ),
    );

    await tester.tap(find.byType(DraggableSwitchButton));
    await tester.pumpAndSettle();

    expect(isButtonOn, true);
  });

  testWidgets("DraggableSwitchButton dragged off", (tester) async {
    bool isButtonOn = true;
    final button = DraggableSwitchButton(
      onItem: Text("yes"),
      offItem: Text("no"),
      onValueChanged: (newValue) => isButtonOn = newValue,
      enabled: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Container(
          width: 200,
          height: 60,
          child: button,
        ),
      ),
    );

    await tester.drag(
        find.byWidgetPredicate(
            (widget) => widget is GestureDetector && widget.child is Padding),
        const Offset(800, 0));
    await tester.pumpAndSettle();

    expect(isButtonOn, false);
  });

  testWidgets("DraggableSwitchButton dragged on", (tester) async {
    bool isButtonOn = false;
    final button = DraggableSwitchButton(
      onItem: Text("yes"),
      offItem: Text("no"),
      onValueChanged: (newValue) => isButtonOn = newValue,
      enabled: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Container(
          width: 200,
          height: 60,
          child: button,
        ),
      ),
    );

    await tester.drag(
        find.byWidgetPredicate(
            (widget) => widget is GestureDetector && widget.child is Padding),
        const Offset(-800, 0));
    await tester.pumpAndSettle();

    expect(isButtonOn, true);
  });
}
