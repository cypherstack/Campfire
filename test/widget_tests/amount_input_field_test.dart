import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/widgets/amount_input_field.dart';
import 'package:provider/provider.dart';

import 'amount_input_field_test.mocks.dart';

class MockCallbackFunction extends Mock {
  call();
}

@GenerateMocks([], customMocks: [
  MockSpec<Manager>(returnNullOnMissingStub: true),
])
void main() {
  MockManager mockManager;
  final mockCallback = MockCallbackFunction();

  setUp(() {
    mockManager = MockManager()..addListener(mockCallback);
    reset(mockCallback);
  });

  testWidgets("AmountInputField Builds correctly", (tester) async {
    final totalChanged = () {};
    final amountChanged = () {};
    final cryptoAmountController = TextEditingController();
    final fiatAmountController = TextEditingController();
    final controller = AmountInputFieldController(
      amountChanged: amountChanged,
      totalChanged: totalChanged,
    );

    when(mockManager.coinTicker).thenAnswer((_) => "FIRO");
    when(mockManager.fiatPrice).thenAnswer((_) async => Decimal.ten);
    when(mockManager.fiatCurrency).thenAnswer((_) => "USD");

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<Manager>(
                create: (context) => mockManager,
              ),
            ],
            child: AmountInputField(
              cryptoAmountController: cryptoAmountController,
              fiatAmountController: fiatAmountController,
              controller: controller,
              locale: "en_US",
            ),
          ),
        ),
      ),
    );

    expect(find.text("FIRO"), findsOneWidget);
    expect(find.text("0.00"), findsNWidgets(2));
    expect(find.text("USD"), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets(
      "AmountInputField enter crypto amount with period decimal separator",
      (tester) async {
    final totalChanged = () {};
    final amountChanged = () {};
    final cryptoAmountController = TextEditingController();
    final fiatAmountController = TextEditingController();
    final controller = AmountInputFieldController(
      amountChanged: amountChanged,
      totalChanged: totalChanged,
    );

    when(mockManager.coinTicker).thenAnswer((_) => "FIRO");
    when(mockManager.fiatPrice).thenAnswer((_) async => Decimal.ten);
    when(mockManager.fiatCurrency).thenAnswer((_) => "USD");

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<Manager>(
                create: (context) => mockManager,
              ),
            ],
            child: AmountInputField(
              cryptoAmountController: cryptoAmountController,
              fiatAmountController: fiatAmountController,
              controller: controller,
              locale: "en_US",
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle(Duration(seconds: 1));

    await tester.enterText(
      find.byWidgetPredicate((widget) =>
          widget is TextField && widget.controller == cryptoAmountController),
      "1",
    );

    await tester.pumpAndSettle(Duration(seconds: 1));

    expect(cryptoAmountController.text, "1");
    expect(find.text("1"), findsOneWidget);

    expect(fiatAmountController.text, "10.00");
    expect(find.text("10.00"), findsOneWidget);
  });

  testWidgets(
      "AmountInputField enter crypto amount with comma decimal separator",
      (tester) async {
    final totalChanged = () {};
    final amountChanged = () {};
    final cryptoAmountController = TextEditingController();
    final fiatAmountController = TextEditingController();
    final controller = AmountInputFieldController(
      amountChanged: amountChanged,
      totalChanged: totalChanged,
    );

    when(mockManager.coinTicker).thenAnswer((_) => "FIRO");
    when(mockManager.fiatPrice).thenAnswer((_) async => Decimal.ten);
    when(mockManager.fiatCurrency).thenAnswer((_) => "USD");

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<Manager>(
                create: (context) => mockManager,
              ),
            ],
            child: AmountInputField(
              cryptoAmountController: cryptoAmountController,
              fiatAmountController: fiatAmountController,
              controller: controller,
              locale: "de_DE",
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle(Duration(seconds: 1));

    await tester.enterText(
      find.byWidgetPredicate((widget) =>
          widget is TextField && widget.controller == cryptoAmountController),
      "1,0",
    );

    await tester.pumpAndSettle(Duration(seconds: 1));

    expect(cryptoAmountController.text, "1,0");
    expect(find.text("1,0"), findsOneWidget);

    expect(fiatAmountController.text, "10,00");
    expect(find.text("10,00"), findsOneWidget);
  });

  testWidgets(
      "AmountInputField enter fiat amount with period decimal separator",
      (tester) async {
    final totalChanged = () {};
    final amountChanged = () {};
    final cryptoAmountController = TextEditingController();
    final fiatAmountController = TextEditingController();
    final controller = AmountInputFieldController(
      amountChanged: amountChanged,
      totalChanged: totalChanged,
    );

    when(mockManager.coinTicker).thenAnswer((_) => "FIRO");
    when(mockManager.fiatPrice).thenAnswer((_) async => Decimal.ten);
    when(mockManager.fiatCurrency).thenAnswer((_) => "USD");

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<Manager>(
                create: (context) => mockManager,
              ),
            ],
            child: AmountInputField(
              cryptoAmountController: cryptoAmountController,
              fiatAmountController: fiatAmountController,
              controller: controller,
              locale: "en_US",
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle(Duration(seconds: 1));

    await tester.enterText(
      find.byWidgetPredicate((widget) =>
          widget is TextField && widget.controller == fiatAmountController),
      "1",
    );

    await tester.pumpAndSettle(Duration(seconds: 1));

    expect(cryptoAmountController.text, "0.10000000");
    expect(find.text("0.10000000"), findsOneWidget);

    expect(fiatAmountController.text, "1");
    expect(find.text("1"), findsOneWidget);
  });

  testWidgets("AmountInputField enter fiat amount with comma decimal separator",
      (tester) async {
    final totalChanged = () {};
    final amountChanged = () {};
    final cryptoAmountController = TextEditingController();
    final fiatAmountController = TextEditingController();
    final controller = AmountInputFieldController(
      amountChanged: amountChanged,
      totalChanged: totalChanged,
    );

    when(mockManager.coinTicker).thenAnswer((_) => "FIRO");
    when(mockManager.fiatPrice).thenAnswer((_) async => Decimal.ten);
    when(mockManager.fiatCurrency).thenAnswer((_) => "USD");

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<Manager>(
                create: (context) => mockManager,
              ),
            ],
            child: AmountInputField(
              cryptoAmountController: cryptoAmountController,
              fiatAmountController: fiatAmountController,
              controller: controller,
              locale: "de_DE",
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle(Duration(seconds: 1));

    await tester.enterText(
      find.byWidgetPredicate((widget) =>
          widget is TextField && widget.controller == fiatAmountController),
      "1,",
    );

    await tester.pumpAndSettle(Duration(seconds: 1));

    expect(cryptoAmountController.text, "0,10000000");
    expect(find.text("0,10000000"), findsOneWidget);

    expect(fiatAmountController.text, "1,");
    expect(find.text("1,"), findsOneWidget);
  });

  testWidgets("AmountInputField enter fiat amount when price is negative",
      (tester) async {
    final totalChanged = () {};
    final amountChanged = () {};
    final cryptoAmountController = TextEditingController();
    final fiatAmountController = TextEditingController();
    final controller = AmountInputFieldController(
      amountChanged: amountChanged,
      totalChanged: totalChanged,
    );

    when(mockManager.coinTicker).thenAnswer((_) => "FIRO");
    when(mockManager.fiatPrice).thenAnswer((_) async => Decimal.parse("-10"));
    when(mockManager.fiatCurrency).thenAnswer((_) => "USD");

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<Manager>(
                create: (context) => mockManager,
              ),
            ],
            child: AmountInputField(
              cryptoAmountController: cryptoAmountController,
              fiatAmountController: fiatAmountController,
              controller: controller,
              locale: "de_DE",
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle(Duration(seconds: 1));

    await tester.enterText(
      find.byWidgetPredicate((widget) =>
          widget is TextField && widget.controller == fiatAmountController),
      "1,",
    );

    await tester.pumpAndSettle(Duration(seconds: 1));

    expect(cryptoAmountController.text, "0,00000000");
    expect(find.text("0,00000000"), findsOneWidget);

    expect(fiatAmountController.text, "1,");
    expect(find.text("1,"), findsOneWidget);
  });

  testWidgets("AmountInputField clear crypto amount", (tester) async {
    final totalChanged = () {};
    final amountChanged = () {};
    final cryptoAmountController = TextEditingController();
    final fiatAmountController = TextEditingController();
    final controller = AmountInputFieldController(
      amountChanged: amountChanged,
      totalChanged: totalChanged,
    );

    controller.cryptoAmount = Decimal.one;
    controller.cryptoTotal = Decimal.one + Decimal.one;

    cryptoAmountController.text = "1";
    fiatAmountController.text = "10,00";

    when(mockManager.coinTicker).thenAnswer((_) => "FIRO");
    when(mockManager.fiatPrice).thenAnswer((_) async => Decimal.parse("-1"));
    when(mockManager.fiatCurrency).thenAnswer((_) => "USD");

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<Manager>(
                create: (context) => mockManager,
              ),
            ],
            child: AmountInputField(
              cryptoAmountController: cryptoAmountController,
              fiatAmountController: fiatAmountController,
              controller: controller,
              locale: "de_DE",
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle(Duration(seconds: 1));

    await tester.enterText(
      find.byWidgetPredicate((widget) =>
          widget is TextField && widget.controller == cryptoAmountController),
      "",
    );

    await tester.pumpAndSettle(Duration(seconds: 1));

    expect(cryptoAmountController.text, "");
    expect(fiatAmountController.text, "");

    expect(find.text("0,00"), findsOneWidget);

    expect(controller.cryptoTotal, Decimal.zero);
    expect(controller.cryptoAmount, Decimal.zero);
  });

  testWidgets("AmountInputField clear fiat amount", (tester) async {
    final totalChanged = () {};
    final amountChanged = () {};
    final cryptoAmountController = TextEditingController();
    final fiatAmountController = TextEditingController();
    final controller = AmountInputFieldController(
      amountChanged: amountChanged,
      totalChanged: totalChanged,
    );

    controller.cryptoAmount = Decimal.one;
    controller.cryptoTotal = Decimal.one + Decimal.one;

    cryptoAmountController.text = "1";
    fiatAmountController.text = "10,00";

    when(mockManager.coinTicker).thenAnswer((_) => "FIRO");
    when(mockManager.fiatPrice).thenAnswer((_) async => Decimal.ten);
    when(mockManager.fiatCurrency).thenAnswer((_) => "USD");

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<Manager>(
                create: (context) => mockManager,
              ),
            ],
            child: AmountInputField(
              cryptoAmountController: cryptoAmountController,
              fiatAmountController: fiatAmountController,
              controller: controller,
              locale: "en_US",
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle(Duration(seconds: 1));

    await tester.enterText(
      find.byWidgetPredicate((widget) =>
          widget is TextField && widget.controller == fiatAmountController),
      "",
    );

    await tester.pumpAndSettle(Duration(seconds: 1));

    await tester.pumpAndSettle(Duration(seconds: 1));

    expect(cryptoAmountController.text, "");
    expect(fiatAmountController.text, "");

    expect(find.text("0.00"), findsNWidgets(2));

    expect(controller.cryptoTotal, Decimal.zero);
    expect(controller.cryptoAmount, Decimal.zero);
  });

  test("extra AmountInputFieldController coverage", () {
    final controller = AmountInputFieldController();

    controller.cryptoAmount = Decimal.one;
    controller.cryptoTotal = Decimal.one;

    expect(controller.cryptoAmount, Decimal.one);
    expect(controller.cryptoTotal, Decimal.one);

    controller.clearAmounts();

    expect(controller.cryptoAmount, Decimal.zero);
    expect(controller.cryptoTotal, Decimal.zero);
  });
}
