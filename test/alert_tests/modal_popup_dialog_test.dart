import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paymint/notifications/modal_popup_dialog.dart';

void main() {
  testWidgets("ModalPopupDialog builds correctly", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ModalPopupDialog(
          child: Text("Hello world!"),
        ),
      ),
    );

    expect(find.byType(Material), findsOneWidget);
    expect(find.byType(Spacer), findsOneWidget);
    expect(find.byType(Padding), findsOneWidget);
    expect(find.text("Hello world!"), findsOneWidget);
  });
}
