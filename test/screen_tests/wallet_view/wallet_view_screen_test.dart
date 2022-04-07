import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:paymint/pages/transaction_subviews/transaction_search_view.dart';
import 'package:paymint/pages/wallet_view/wallet_view.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/services/event_bus/events/node_connection_status_changed_event.dart';
import 'package:paymint/services/event_bus/global_event_bus.dart';
import 'package:paymint/services/notes_service.dart';
import 'package:paymint/widgets/custom_buttons/draggable_switch_button.dart';
import 'package:paymint/widgets/gradient_card.dart';
import 'package:paymint/widgets/transaction_card.dart';
import 'package:provider/provider.dart';

import '../../sample_data/transaction_data_samples.dart';
import 'wallet_view_screen_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<Manager>(returnNullOnMissingStub: true),
  MockSpec<NotesService>(returnNullOnMissingStub: true),
])
void main() {
  testWidgets("WalletView builds correctly with no transactions",
      (tester) async {
    final manager = MockManager();

    when(manager.coinTicker).thenAnswer((_) => "FIRO");
    when(manager.fiatCurrency).thenAnswer((_) => "USD");

    when(manager.balance).thenAnswer((_) async => Decimal.one);
    when(manager.totalBalance).thenAnswer((_) async => Decimal.ten);
    when(manager.fiatBalance).thenAnswer((_) async => Decimal.ten);
    when(manager.fiatTotalBalance)
        .thenAnswer((_) async => Decimal.fromInt(100));

    when(manager.refresh()).thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<Manager>(
                create: (_) => manager,
              ),
            ],
            child: WalletView(),
          ),
        ),
      ),
    );

    expect(find.text("... FIRO"), findsOneWidget);
    expect(find.text("... USD"), findsOneWidget);

    expect(find.text("AVAILABLE"), findsOneWidget);
    expect(find.text("FULL"), findsOneWidget);

    expect(find.byType(SvgPicture), findsNWidgets(2));
    expect(find.byType(GradientCard), findsOneWidget);
    expect(find.byType(DraggableSwitchButton), findsOneWidget);

    expect(find.text("TRANSACTIONS"), findsOneWidget);
    expect(find.text("NO TRANSACTIONS YET"), findsOneWidget);

    expect(find.byIcon(FeatherIcons.search), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text("1.00000000 FIRO"), findsOneWidget);
    expect(find.text("10.00000000 USD"), findsOneWidget);
    expect(find.text("NO TRANSACTIONS YET"), findsOneWidget);
    expect(find.byType(SvgPicture), findsNWidgets(2));
  });

  testWidgets("WalletView builds correctly with transaction history",
      (tester) async {
    final navigator = mockingjay.MockNavigator();
    final manager = MockManager();
    final notesService = MockNotesService();

    when(manager.coinTicker).thenAnswer((_) => "FIRO");
    when(manager.fiatCurrency).thenAnswer((_) => "USD");

    when(manager.balance).thenAnswer((_) async => Decimal.one);
    when(manager.totalBalance).thenAnswer((_) async => Decimal.ten);
    when(manager.fiatBalance).thenAnswer((_) async => Decimal.ten);
    when(manager.fiatTotalBalance)
        .thenAnswer((_) async => Decimal.fromInt(100));

    when(manager.refresh()).thenAnswer((_) async {});

    when(manager.transactionData)
        .thenAnswer((_) async => transactionDataFromJsonChunks);

    await tester.pumpWidget(
      MaterialApp(
        home: mockingjay.MockNavigatorProvider(
          navigator: navigator,
          child: Material(
            child: MultiProvider(
              providers: [
                ChangeNotifierProvider<Manager>(
                  create: (_) => manager,
                ),
                ChangeNotifierProvider<NotesService>(
                  create: (_) => notesService,
                ),
              ],
              child: WalletView(),
            ),
          ),
        ),
      ),
    );

    expect(find.text("... FIRO"), findsOneWidget);
    expect(find.text("... USD"), findsOneWidget);

    expect(find.text("AVAILABLE"), findsOneWidget);
    expect(find.text("FULL"), findsOneWidget);

    expect(find.byType(SvgPicture), findsNWidgets(2));
    expect(find.byType(GradientCard), findsOneWidget);
    expect(find.byType(DraggableSwitchButton), findsOneWidget);

    expect(find.text("TRANSACTIONS"), findsOneWidget);
    expect(find.text("NO TRANSACTIONS YET"), findsOneWidget);

    expect(find.byIcon(FeatherIcons.search), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text("1.00000000 FIRO"), findsOneWidget);
    expect(find.text("10.00000000 USD"), findsOneWidget);
    expect(find.text("NO TRANSACTIONS YET"), findsNothing);
    expect(find.byType(SvgPicture), findsNWidgets(1));
    expect(find.byType(TransactionCard), findsNWidgets(6));
  });

  testWidgets("tap tx search", (tester) async {
    final navigator = mockingjay.MockNavigator();
    final manager = MockManager();
    final notesService = MockNotesService();

    when(manager.coinTicker).thenAnswer((_) => "FIRO");
    when(manager.fiatCurrency).thenAnswer((_) => "USD");

    when(manager.balance).thenAnswer((_) async => Decimal.one);
    when(manager.totalBalance).thenAnswer((_) async => Decimal.ten);
    when(manager.fiatBalance).thenAnswer((_) async => Decimal.ten);
    when(manager.fiatTotalBalance)
        .thenAnswer((_) async => Decimal.fromInt(100));

    when(manager.refresh()).thenAnswer((_) async {});

    when(manager.transactionData)
        .thenAnswer((_) async => transactionDataFromJsonChunks);

    await tester.pumpWidget(
      MaterialApp(
        home: mockingjay.MockNavigatorProvider(
          navigator: navigator,
          child: Material(
            child: MultiProvider(
              providers: [
                ChangeNotifierProvider<Manager>(
                  create: (_) => manager,
                ),
                ChangeNotifierProvider<NotesService>(
                  create: (_) => notesService,
                ),
              ],
              child: WalletView(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(find.byType(TransactionSearchView), findsOneWidget);
  });

  testWidgets("scroll transactions", (tester) async {
    final navigator = mockingjay.MockNavigator();
    final manager = MockManager();
    final notesService = MockNotesService();

    when(manager.coinTicker).thenAnswer((_) => "FIRO");
    when(manager.fiatCurrency).thenAnswer((_) => "USD");

    when(manager.balance).thenAnswer((_) async => Decimal.one);
    when(manager.totalBalance).thenAnswer((_) async => Decimal.ten);
    when(manager.fiatBalance).thenAnswer((_) async => Decimal.ten);
    when(manager.fiatTotalBalance)
        .thenAnswer((_) async => Decimal.fromInt(100));

    when(manager.refresh()).thenAnswer((_) async {});

    when(manager.transactionData)
        .thenAnswer((_) async => transactionDataFromJsonChunks);

    await tester.pumpWidget(
      MaterialApp(
        home: mockingjay.MockNavigatorProvider(
          navigator: navigator,
          child: Material(
            child: MultiProvider(
              providers: [
                ChangeNotifierProvider<Manager>(
                  create: (_) => manager,
                ),
                ChangeNotifierProvider<NotesService>(
                  create: (_) => notesService,
                ),
              ],
              child: WalletView(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.fling(find.byType(ListView), Offset(0, -500), 10000);
    await tester.pumpAndSettle();
    await tester.fling(find.byType(ListView), Offset(0, 500), 10000);
    await tester.pumpAndSettle();
  });

  testWidgets("node events", (tester) async {
    final navigator = mockingjay.MockNavigator();
    final manager = MockManager();
    final notesService = MockNotesService();

    when(manager.coinTicker).thenAnswer((_) => "FIRO");
    when(manager.fiatCurrency).thenAnswer((_) => "USD");

    when(manager.balance).thenAnswer((_) async => Decimal.one);
    when(manager.totalBalance).thenAnswer((_) async => Decimal.ten);
    when(manager.fiatBalance).thenAnswer((_) async => Decimal.ten);
    when(manager.fiatTotalBalance)
        .thenAnswer((_) async => Decimal.fromInt(100));

    when(manager.refresh()).thenAnswer((_) async {});

    when(manager.transactionData)
        .thenAnswer((_) async => transactionDataFromJsonChunks);

    await tester.pumpWidget(
      MaterialApp(
        home: mockingjay.MockNavigatorProvider(
          navigator: navigator,
          child: Material(
            child: MultiProvider(
              providers: [
                ChangeNotifierProvider<Manager>(
                  create: (_) => manager,
                ),
                ChangeNotifierProvider<NotesService>(
                  create: (_) => notesService,
                ),
              ],
              child: WalletView(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SpinKitThreeBounce), findsNothing);

    GlobalEventBus.instance
        .fire(NodeConnectionStatusChangedEvent(NodeConnectionStatus.loading));
    await tester.pump(Duration(seconds: 1));

    expect(find.byType(SpinKitThreeBounce), findsOneWidget);

    GlobalEventBus.instance
        .fire(NodeConnectionStatusChangedEvent(NodeConnectionStatus.synced));
    await tester.pump();

    expect(find.byType(SpinKitThreeBounce), findsNothing);
  });

  testWidgets("select full/available balances", (tester) async {
    final navigator = mockingjay.MockNavigator();
    final manager = MockManager();
    final notesService = MockNotesService();

    when(manager.coinTicker).thenAnswer((_) => "FIRO");
    when(manager.fiatCurrency).thenAnswer((_) => "USD");

    when(manager.balance).thenAnswer((_) async => Decimal.one);
    when(manager.totalBalance).thenAnswer((_) async => Decimal.ten);
    when(manager.fiatBalance).thenAnswer((_) async => Decimal.ten);
    when(manager.fiatTotalBalance)
        .thenAnswer((_) async => Decimal.fromInt(100));

    when(manager.refresh()).thenAnswer((_) async {});

    when(manager.transactionData)
        .thenAnswer((_) async => transactionDataFromJsonChunks);

    await tester.pumpWidget(
      MaterialApp(
        home: mockingjay.MockNavigatorProvider(
          navigator: navigator,
          child: Material(
            child: MultiProvider(
              providers: [
                ChangeNotifierProvider<Manager>(
                  create: (_) => manager,
                ),
                ChangeNotifierProvider<NotesService>(
                  create: (_) => notesService,
                ),
              ],
              child: WalletView(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("1.00000000 FIRO"), findsOneWidget);
    expect(find.text("10.00000000 USD"), findsOneWidget);

    await tester.tap(find.byType(DraggableSwitchButton));
    await tester.pumpAndSettle();

    expect(find.text("10.00000000 FIRO"), findsOneWidget);
    expect(find.text("100.00000000 USD"), findsOneWidget);

    await tester.tap(find.byType(DraggableSwitchButton));
    await tester.pumpAndSettle();

    expect(find.text("1.00000000 FIRO"), findsOneWidget);
    expect(find.text("10.00000000 USD"), findsOneWidget);
  });
}
