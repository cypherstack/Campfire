import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockingjay/mockingjay.dart';
import 'package:mockito/annotations.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/widgets/address_book_card.dart';
import 'package:provider/provider.dart';

import 'address_book_card_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<Manager>(returnNullOnMissingStub: true),
])
void main() {
  testWidgets("AddressBookCard builds correctly", (tester) async {
    final card = AddressBookCard(
      name: "billy",
      address: "some address",
    );

    await tester.pumpWidget(
      MaterialApp(
        home: card,
      ),
    );

    expect(find.text("billy"), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.byType(SubButton), findsNothing);
  });

  testWidgets("AddressBookCard tapped", (tester) async {
    final card = AddressBookCard(
      name: "billy",
      address: "some address",
    );

    await tester.pumpWidget(
      MaterialApp(
        home: card,
      ),
    );

    // tap to expand
    await tester.tap(find.byType(MaterialButton));
    await tester.pumpAndSettle();

    expect(find.text("billy"), findsOneWidget);
    expect(find.text("SEND FIRO"), findsOneWidget);
    expect(find.text("COPY"), findsOneWidget);
    expect(find.text("DETAILS"), findsOneWidget);

    expect(find.byType(SvgPicture), findsNWidgets(4));
    expect(find.byType(SubButton), findsNWidgets(3));

    // tap again to close
    await tester.tap(find.byWidgetPredicate((widget) =>
        widget is MaterialButton && widget.padding == EdgeInsets.zero));
    await tester.pumpAndSettle();

    expect(find.text("billy"), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.byType(SubButton), findsNothing);
  });

  testWidgets("AddressBookCard send tapped", (tester) async {
    final navigator = MockNavigator();
    when(() => navigator.pushAndRemoveUntil(
        any(), ModalRoute.withName("/mainview"))).thenAnswer((_) async {});

    final card = AddressBookCard(
      name: "billy",
      address: "some address",
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MockNavigatorProvider(
          navigator: navigator,
          child: card,
        ),
      ),
    );

    // tap to expand
    await tester.tap(find.byType(MaterialButton));
    await tester.pumpAndSettle();

    expect(find.text("billy"), findsOneWidget);
    expect(find.text("SEND FIRO"), findsOneWidget);
    expect(find.text("COPY"), findsOneWidget);
    expect(find.text("DETAILS"), findsOneWidget);

    expect(find.byType(SvgPicture), findsNWidgets(4));
    expect(find.byType(SubButton), findsNWidgets(3));

    // tap again to close
    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is SubButton && widget.label == "SEND FIRO"));
    await tester.pumpAndSettle(Duration(milliseconds: 300));

    verify(
      () => navigator.pushAndRemoveUntil(any(), any()),
    ).called(1);
  });

  testWidgets("AddressBookCard copy tapped", (tester) async {
    final mockManager = MockManager();
    final card = AddressBookCard(
      name: "billy",
      address: "some address",
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<Manager>(
              create: (context) => mockManager,
            ),
          ],
          child: card,
        ),
      ),
    );

    // tap to expand
    await tester.tap(find.byType(MaterialButton));
    await tester.pumpAndSettle();

    expect(find.text("billy"), findsOneWidget);
    expect(find.text("SEND FIRO"), findsOneWidget);
    expect(find.text("COPY"), findsOneWidget);
    expect(find.text("DETAILS"), findsOneWidget);

    expect(find.byType(SvgPicture), findsNWidgets(4));
    expect(find.byType(SubButton), findsNWidgets(3));

    // tap again to close
    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is SubButton && widget.label == "COPY"));
    await tester.pumpAndSettle(Duration(milliseconds: 300));

    expect(find.text("Address copied to clipboard"), findsOneWidget);
    await tester.pumpAndSettle(Duration(seconds: 2));
  });

  testWidgets("AddressBookCard details tapped", (tester) async {
    final navigator = MockNavigator();
    when(() => navigator.push(any())).thenAnswer((_) async {});

    final card = AddressBookCard(
      name: "billy",
      address: "some address",
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MockNavigatorProvider(
          navigator: navigator,
          child: card,
        ),
      ),
    );

    // tap to expand
    await tester.tap(find.byType(MaterialButton));
    await tester.pumpAndSettle();

    expect(find.text("billy"), findsOneWidget);
    expect(find.text("SEND FIRO"), findsOneWidget);
    expect(find.text("COPY"), findsOneWidget);
    expect(find.text("DETAILS"), findsOneWidget);

    expect(find.byType(SvgPicture), findsNWidgets(4));
    expect(find.byType(SubButton), findsNWidgets(3));

    // tap again to close
    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is SubButton && widget.label == "DETAILS"));
    await tester.pumpAndSettle(Duration(milliseconds: 300));

    verify(
      () => navigator.push(any(that: isRoute<void>())),
    ).called(1);
  });
}
