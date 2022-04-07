import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:paymint/pages/wallet_view/receive_view.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/utilities/clipboard_interface.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:provider/provider.dart';

import 'receive_view_screen_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<Manager>(returnNullOnMissingStub: true),
])
void main() {
  testWidgets("ReceiveView builds without loading address", (tester) async {
    final manager = MockManager();
    final clipboard = FakeClipboard();

    when(manager.currentReceivingAddress).thenAnswer((_) async => null);

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<Manager>(
              create: (_) => manager,
            ),
          ],
          child: ReceiveView(
            clipboard: clipboard,
          ),
        ),
      ),
    );
    await tester.pump(Duration(seconds: 1));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    expect(find.byType(PrettyQr), findsNothing);
    expect(find.byType(MaterialButton), findsNothing);
    expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsNothing);
    expect(find.text("TAP ADDRESS TO COPY"), findsNothing);
  });

  testWidgets("ReceiveView builds correctly and loads address", (tester) async {
    final manager = MockManager();
    final clipboard = FakeClipboard();

    when(manager.currentReceivingAddress)
        .thenAnswer((_) async => "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg");

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<Manager>(
              create: (_) => manager,
            ),
          ],
          child: ReceiveView(
            clipboard: clipboard,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final qr = find.byType(PrettyQr).evaluate().single.widget as PrettyQr;

    expect(qr.data, "firo:a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg");

    expect(find.byType(MaterialButton), findsOneWidget);

    expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
    expect(find.text("TAP ADDRESS TO COPY"), findsOneWidget);
  });

  testWidgets("tap copy address", (tester) async {
    final manager = MockManager();
    final clipboard = FakeClipboard();

    when(manager.currentReceivingAddress)
        .thenAnswer((_) async => "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg");

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<Manager>(
              create: (_) => manager,
            ),
          ],
          child: ReceiveView(
            clipboard: clipboard,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final qr = find.byType(PrettyQr).evaluate().single.widget as PrettyQr;

    expect(qr.data, "firo:a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg");

    expect(find.byType(MaterialButton), findsOneWidget);

    expect(find.text("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), findsOneWidget);
    expect(find.text("TAP ADDRESS TO COPY"), findsOneWidget);

    await tester.tap(find.byType(MaterialButton));
    await tester.pump(Duration(seconds: 1));
    expect(find.text("Copied to clipboard"), findsOneWidget);

    await tester.pump(Duration(seconds: 2));
    expect(find.text("Copied to clipboard"), findsNothing);

    final clipboardString = await clipboard.getData(Clipboard.kTextPlain);
    expect(clipboardString.text, "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg");
  });
}
