import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:paymint/models/lelantus_fee_data.dart';
import 'package:paymint/pages/main_view.dart';
import 'package:paymint/pages/wallet_view/receive_view.dart';
import 'package:paymint/pages/wallet_view/send_view.dart';
import 'package:paymint/pages/wallet_view/wallet_view.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/services/event_bus/events/node_connection_status_changed_event.dart';
import 'package:paymint/services/event_bus/global_event_bus.dart';
import 'package:paymint/services/locale_service.dart';
import 'package:paymint/services/notes_service.dart';
import 'package:paymint/services/wallets_service.dart';
import 'package:provider/provider.dart';

import '../sample_data/transaction_data_samples.dart';
import 'main_view_screen_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<WalletsService>(returnNullOnMissingStub: true),
  MockSpec<Manager>(returnNullOnMissingStub: true),
  MockSpec<NotesService>(returnNullOnMissingStub: true),
  MockSpec<LocaleService>(returnNullOnMissingStub: true),
])
void main() {
  testWidgets("MainView screen test", (tester) async {
    final walletsService = MockWalletsService();
    final manager = MockManager();
    final notesService = MockNotesService();
    final localeService = MockLocaleService();

    when(localeService.locale).thenAnswer((_) => "en_US");

    when(walletsService.currentWalletName)
        .thenAnswer((_) async => "My Firo Wallet");

    when(manager.fiatPrice).thenAnswer((_) async => Decimal.ten);
    when(manager.refresh()).thenAnswer((_) async {});
    when(manager.exitCurrentWallet()).thenAnswer((_) async {});

    when(manager.balance).thenAnswer((_) async => Decimal.one);
    when(manager.totalBalance).thenAnswer((_) async => Decimal.ten);
    when(manager.fiatBalance).thenAnswer((_) async => Decimal.ten);
    when(manager.fiatTotalBalance)
        .thenAnswer((_) async => Decimal.fromInt(100));

    when(manager.coinTicker).thenAnswer((_) => "FIRO");
    when(manager.fiatCurrency).thenAnswer((_) => "USD");

    when(manager.maxFee).thenAnswer((_) async => LelantusFeeData(0, 100, []));
    when(manager.balanceMinusMaxFee).thenAnswer((_) async => Decimal.one);

    when(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
        .thenAnswer((_) => true);

    when(manager.transactionData)
        .thenAnswer((_) async => transactionDataFromJsonChunks);

    when(manager.currentReceivingAddress)
        .thenAnswer((_) async => "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg");

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<WalletsService>(
              create: (_) => walletsService,
            ),
            ChangeNotifierProvider<Manager>(
              create: (_) => manager,
            ),
            ChangeNotifierProvider<NotesService>(
              create: (_) => notesService,
            ),
            ChangeNotifierProvider<LocaleService>(
              create: (_) => localeService,
            ),
          ],
          child: MainView(
            disableRefreshOnInit: false,
            args: {
              "addressBookEntry": {
                "address": "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg",
                "name": "john doe",
              }
            },
          ),
        ),
      ),
    );

    await tester.pump(Duration(seconds: 3));

    expect(find.byKey(Key("mainViewRefreshButton")), findsOneWidget);
    expect(find.byKey(Key("mainViewSettingsButton")), findsOneWidget);
    expect(find.text("My Firo Wallet"), findsOneWidget);
    expect(find.text("1.00000000 FIRO"), findsNWidgets(2));
    expect(find.text("10.00000000 USD"), findsOneWidget);
    expect(find.text("TRANSACTIONS"), findsOneWidget);
    expect(find.text("Wallet"), findsOneWidget);
    expect(find.text("Send"), findsOneWidget);
    expect(find.text("Receive"), findsOneWidget);

    expect(find.byType(WalletView), findsOneWidget);
    expect(find.byType(SendView), findsOneWidget);
    expect(find.byType(ReceiveView), findsOneWidget);

    expect(find.byType(BottomNavigationBar), findsOneWidget);

    verify(notesService.addListener(any)).called(1);

    verify(walletsService.addListener(any)).called(1);
    verify(walletsService.currentWalletName).called(1);

    verify(manager.addListener(any)).called(1);
    verify(manager.fiatPrice).called(8);
    verify(manager.refresh()).called(1);
    verify(manager.balance).called(1);
    verify(manager.balanceMinusMaxFee).called(1);
    verify(manager.fiatBalance).called(1);
    verify(manager.maxFee).called(1);
    verify(manager.coinTicker).called(16);
    verify(manager.fiatCurrency).called(3);
    verify(manager.transactionData).called(1);
    verify(manager.currentReceivingAddress).called(2);
    verify(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
        .called(1);

    verify(localeService.addListener(any)).called(1);
    verify(localeService.locale).called(14);

    verifyNoMoreInteractions(localeService);
    verifyNoMoreInteractions(walletsService);
    verifyNoMoreInteractions(manager);
    verifyNoMoreInteractions(notesService);
  });

  testWidgets("tap refresh", (tester) async {
    final walletsService = MockWalletsService();
    final manager = MockManager();
    final notesService = MockNotesService();
    final localeService = MockLocaleService();

    when(localeService.locale).thenAnswer((_) => "en_US");

    when(walletsService.currentWalletName)
        .thenAnswer((_) async => "My Firo Wallet");
    when(walletsService.refreshWallets()).thenAnswer((_) async {});

    when(manager.fiatPrice).thenAnswer((_) async => Decimal.ten);
    when(manager.refresh()).thenAnswer((_) async {
      GlobalEventBus.instance
          .fire(NodeConnectionStatusChangedEvent(NodeConnectionStatus.loading));
      await Future.delayed(Duration(seconds: 3));
      GlobalEventBus.instance
          .fire(NodeConnectionStatusChangedEvent(NodeConnectionStatus.synced));
    });
    when(manager.exitCurrentWallet()).thenAnswer((_) async {});

    when(manager.balance).thenAnswer((_) async => Decimal.one);
    when(manager.totalBalance).thenAnswer((_) async => Decimal.ten);
    when(manager.fiatBalance).thenAnswer((_) async => Decimal.ten);
    when(manager.fiatTotalBalance)
        .thenAnswer((_) async => Decimal.fromInt(100));

    when(manager.coinTicker).thenAnswer((_) => "FIRO");
    when(manager.fiatCurrency).thenAnswer((_) => "USD");

    when(manager.maxFee).thenAnswer((_) async => LelantusFeeData(0, 100, []));
    when(manager.balanceMinusMaxFee).thenAnswer((_) async => Decimal.one);

    when(manager.transactionData)
        .thenAnswer((_) async => transactionDataFromJsonChunks);

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<WalletsService>(
              create: (_) => walletsService,
            ),
            ChangeNotifierProvider<Manager>(
              create: (_) => manager,
            ),
            ChangeNotifierProvider<NotesService>(
              create: (_) => notesService,
            ),
            ChangeNotifierProvider<LocaleService>(
              create: (_) => localeService,
            ),
          ],
          child: MainView(
            disableRefreshOnInit: true,
          ),
        ),
      ),
    );

    await tester.pump(Duration(seconds: 2));

    verify(notesService.addListener(any)).called(1);

    verify(walletsService.addListener(any)).called(1);
    verify(walletsService.currentWalletName).called(1);

    verify(manager.addListener(any)).called(1);
    verify(manager.fiatPrice).called(8);
    // verify(manager.refresh()).called(1);
    verify(manager.balance).called(1);
    verify(manager.balanceMinusMaxFee).called(1);
    verify(manager.fiatBalance).called(1);
    verify(manager.maxFee).called(1);
    verify(manager.coinTicker).called(16);
    verify(manager.fiatCurrency).called(3);
    verify(manager.transactionData).called(1);
    verify(manager.currentReceivingAddress).called(2);
    // verify(manager.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"))
    //     .called(1);

    verify(localeService.addListener(any)).called(1);
    verify(localeService.locale).called(14);

    verifyNoMoreInteractions(localeService);
    verifyNoMoreInteractions(walletsService);
    verifyNoMoreInteractions(manager);
    verifyNoMoreInteractions(notesService);
  });

  // testWidgets("MainView builds correctly without args", (tester) async {
  //   final walletsService = MockWalletsService();
  //   final manager = MockManager();
  //   final notesService = MockNotesService();
  //   when(walletsService.currentWalletName)
  //       .thenAnswer((_) async => "My Firo wallet");
  //   when(walletsService.refreshWallets()).thenAnswer((_) async {});
  //
  //   when(manager.fiatPrice).thenAnswer((_) async => Decimal.ten);
  //   when(manager.refresh()).thenAnswer((_) async {});
  //   when(manager.exitCurrentWallet()).thenAnswer((_) async {});
  //
  //   when(manager.balance).thenAnswer((_) async => Decimal.one);
  //   when(manager.totalBalance).thenAnswer((_) async => Decimal.ten);
  //   when(manager.fiatBalance).thenAnswer((_) async => Decimal.ten);
  //   when(manager.fiatTotalBalance)
  //       .thenAnswer((_) async => Decimal.fromInt(100));
  //
  //   when(manager.coinTicker).thenAnswer((_) => "FIRO");
  //   when(manager.fiatCurrency).thenAnswer((_) => "USD");
  //
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: MultiProvider(
  //         providers: [
  //           ChangeNotifierProvider<WalletsService>(
  //             create: (_) => walletsService,
  //           ),
  //           ChangeNotifierProvider<Manager>(
  //             create: (_) => manager,
  //           ),
  //           ChangeNotifierProvider<NotesService>(
  //             create: (_) => notesService,
  //           ),
  //         ],
  //         child: MainView(),
  //       ),
  //     ),
  //   );
  //
  //   expect(find.byType(CircularProgressIndicator), findsNWidgets(3));
  //
  //   expect(find.byKey(Key("mainViewRefreshButton")), findsOneWidget);
  //   expect(find.byKey(Key("mainViewSettingsButton")), findsOneWidget);
  //
  //   await tester.pumpAndSettle();
  //
  // verifyNoMoreInteractions(localeService);
  // verifyNoMoreInteractions(manager);
  // verifyNoMoreInteractions(notesService);
  // });
}
