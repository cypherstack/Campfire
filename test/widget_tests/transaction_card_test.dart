import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:paymint/models/models.dart';
import 'package:paymint/pages/transaction_subviews/transaction_details_view.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/services/notes_service.dart';
import 'package:paymint/widgets/transaction_card.dart';
import 'package:provider/provider.dart';

import 'transaction_card_test.mocks.dart';

class MockCallbackFunction extends Mock {
  call();
}

@GenerateMocks([], customMocks: [
  MockSpec<Manager>(returnNullOnMissingStub: true),
  MockSpec<NotesService>(returnNullOnMissingStub: true)
])
void main() {
  MockManager mockManager;
  MockNotesService mockNotesService;

  final mockCallback = MockCallbackFunction();

  setUp(() {
    mockManager = MockManager()..addListener(mockCallback);
    mockNotesService = MockNotesService()..addListener(mockCallback);
    reset(mockCallback);
  });

  testWidgets("Sent confirmed tx displays correctly", (tester) async {
    final tx = Transaction(
      txid: "some txid",
      confirmedStatus: true,
      timestamp: 1648595998,
      txType: "Sent",
      amount: 100000000,
      aliens: [],
      worthNow: "0.01",
      worthAtBlockTimestamp: "0.01",
      fees: 3794,
      inputSize: 1,
      outputSize: 1,
      inputs: [],
      outputs: [],
      address: "",
      height: 450123,
      subType: "mint",
    );

    when(mockNotesService.getNoteFor(txid: "some txid"))
        .thenAnswer((_) async => "some note");

    when(mockManager.coinTicker).thenAnswer((_) => "FIRO");
    when(mockManager.fiatPrice).thenAnswer((_) async => Decimal.ten);
    when(mockManager.fiatCurrency).thenAnswer((_) => "USD");

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<NotesService>(
              create: (context) => mockNotesService,
            ),
            ChangeNotifierProvider<Manager>(
              create: (context) => mockManager,
            ),
          ],
          child: TransactionCard(transaction: tx),
        ),
      ),
    );

    final title = find.text("Sent");
    final price1 = find.text("0.00");
    final amount = find.text("1.00000000 FIRO");

    final icon = find.byIcon(FeatherIcons.arrowUp);

    expect(title, findsOneWidget);
    expect(price1, findsOneWidget);
    expect(amount, findsOneWidget);
    expect(icon, findsOneWidget);

    await tester.pumpAndSettle(Duration(seconds: 2));

    final price2 = find.text("\$10.00");
    expect(price2, findsOneWidget);
  });

  testWidgets("Received unconfirmed tx displays correctly", (tester) async {
    final tx = Transaction(
      txid: "some txid",
      confirmedStatus: false,
      timestamp: 1648595998,
      txType: "Received",
      amount: 100000000,
      aliens: [],
      worthNow: "0.01",
      worthAtBlockTimestamp: "0.01",
      fees: 3794,
      inputSize: 1,
      outputSize: 1,
      inputs: [],
      outputs: [],
      address: "",
      height: null,
      subType: null,
    );

    when(mockNotesService.getNoteFor(txid: "some txid"))
        .thenAnswer((_) async => "some note");

    when(mockManager.coinTicker).thenAnswer((_) => "FIRO");
    when(mockManager.fiatPrice).thenAnswer((_) async => Decimal.ten);
    when(mockManager.fiatCurrency).thenAnswer((_) => "USD");

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<NotesService>(
              create: (context) => mockNotesService,
            ),
            ChangeNotifierProvider<Manager>(
              create: (context) => mockManager,
            ),
          ],
          child: TransactionCard(transaction: tx),
        ),
      ),
    );

    final title = find.text("Receiving");
    final price1 = find.text("0.00");
    final amount = find.text("1.00000000 FIRO");

    final icon = find.byIcon(FeatherIcons.arrowDown);

    expect(title, findsOneWidget);
    expect(price1, findsOneWidget);
    expect(amount, findsOneWidget);
    expect(icon, findsOneWidget);

    await tester.pumpAndSettle(Duration(seconds: 2));

    final price2 = find.text("\$10.00");
    expect(price2, findsOneWidget);
  });

  testWidgets("bad tx displays correctly", (tester) async {
    final tx = Transaction(
      txid: "some txid",
      confirmedStatus: false,
      timestamp: 1648595998,
      txType: "ahhhhhh",
      amount: 100000000,
      aliens: [],
      worthNow: "0.01",
      worthAtBlockTimestamp: "0.01",
      fees: 3794,
      inputSize: 1,
      outputSize: 1,
      inputs: [],
      outputs: [],
      address: "",
      height: null,
      subType: null,
    );

    when(mockNotesService.getNoteFor(txid: "some txid"))
        .thenAnswer((_) async => "some note");

    when(mockManager.coinTicker).thenAnswer((_) => "FIRO");
    when(mockManager.fiatPrice).thenAnswer((_) async => Decimal.ten);
    when(mockManager.fiatCurrency).thenAnswer((_) => "USD");

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<NotesService>(
              create: (context) => mockNotesService,
            ),
            ChangeNotifierProvider<Manager>(
              create: (context) => mockManager,
            ),
          ],
          child: TransactionCard(transaction: tx),
        ),
      ),
    );

    final title = find.text("Unknown");
    final price1 = find.text("0.00");
    final amount = find.text("1.00000000 FIRO");

    final icon = find.byIcon(Icons.warning_rounded);

    expect(title, findsOneWidget);
    expect(price1, findsOneWidget);
    expect(amount, findsOneWidget);
    expect(icon, findsOneWidget);

    await tester.pumpAndSettle(Duration(seconds: 2));

    final price2 = find.text("\$10.00");
    expect(price2, findsOneWidget);
  });

  testWidgets("Tap gesture", (tester) async {
    final tx = Transaction(
      txid: "some txid",
      confirmedStatus: false,
      timestamp: 1648595998,
      txType: "Received",
      amount: 100000000,
      aliens: [],
      worthNow: "0.01",
      worthAtBlockTimestamp: "0.01",
      fees: 3794,
      inputSize: 1,
      outputSize: 1,
      inputs: [],
      outputs: [],
      address: "",
      height: null,
      subType: null,
    );

    when(mockNotesService.getNoteFor(txid: "some txid"))
        .thenAnswer((_) async => "some note");

    when(mockManager.coinTicker).thenAnswer((_) => "FIRO");
    when(mockManager.fiatPrice).thenAnswer((_) async => Decimal.ten);
    when(mockManager.fiatCurrency).thenAnswer((_) => "USD");

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<NotesService>(
              create: (context) => mockNotesService,
            ),
            ChangeNotifierProvider<Manager>(
              create: (context) => mockManager,
            ),
          ],
          child: TransactionCard(transaction: tx),
        ),
      ),
    );

    expect(find.byType(GestureDetector), findsOneWidget);

    await tester.tap(find.byType(GestureDetector));
    await tester.pumpAndSettle(Duration(seconds: 2));

    expect(find.byType(TransactionDetailsView), findsOneWidget);
  });
}
