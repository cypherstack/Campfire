import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:paymint/notifications/campfire_alert.dart';
import 'package:paymint/pages/lockscreen_view.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/services/node_service.dart';
import 'package:paymint/services/wallets_service.dart';
import 'package:paymint/utilities/flutter_secure_storage_interface.dart';
import 'package:paymint/utilities/misc_global_constants.dart';
import 'package:paymint/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:paymint/widgets/custom_pin_put/custom_pin_put.dart';
import 'package:paymint/widgets/custom_pin_put/pin_keyboard.dart';
import 'package:provider/provider.dart';

import 'lockscreen_view_screen_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<WalletsService>(returnNullOnMissingStub: true),
  MockSpec<NodeService>(returnNullOnMissingStub: true),
  MockSpec<Manager>(returnNullOnMissingStub: true),
])
void main() {
  testWidgets("LockscreenView builds correctly", (tester) async {
    final navigator = mockingjay.MockNavigator();
    final walletsService = MockWalletsService();
    final nodeService = MockNodeService();
    final manager = MockManager();
    final secureStore = FakeSecureStorage();

    secureStore.write(key: "walletID", value: "1234");

    when(walletsService.currentWalletName)
        .thenAnswer((_) async => "My Firo Wallet");
    when(walletsService.getWalletId("My Firo Wallet"))
        .thenAnswer((_) async => "walletID");
    when(walletsService.networkName).thenAnswer((_) async => "main");

    when(nodeService.reInit()).thenAnswer((_) async {});

    when(
      nodeService.createNode(
        name: CampfireConstants.defaultNodeName,
        ipAddress: CampfireConstants.defaultIpAddress,
        port: CampfireConstants.defaultPort.toString(),
        useSSL: CampfireConstants.defaultUseSSL,
      ),
    ).thenAnswer((_) => true);

    when(manager.hasWallet).thenAnswer((_) => true);
    when(manager.useBiometrics).thenAnswer((_) async => true);

    await tester.pumpWidget(
      MaterialApp(
        home: mockingjay.MockNavigatorProvider(
          navigator: navigator,
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<WalletsService>(
                create: (_) => walletsService,
              ),
              ChangeNotifierProvider<NodeService>(
                create: (_) => nodeService,
              ),
              ChangeNotifierProvider<Manager>(
                create: (_) => manager,
              ),
            ],
            child: LockscreenView(
              routeOnSuccess: "/mainview",
              secureStore: secureStore,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(AppBarIconButton), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);

    expect(find.text("My Firo Wallet"), findsOneWidget);
    expect(find.text("Enter PIN"), findsOneWidget);

    expect(find.byType(CustomPinPut), findsOneWidget);
  });

  testWidgets("LockscreenView builds without a wallet", (tester) async {
    final navigator = mockingjay.MockNavigator();
    final walletsService = MockWalletsService();
    final nodeService = MockNodeService();
    final manager = MockManager();
    final secureStore = FakeSecureStorage();

    when(walletsService.currentWalletName).thenAnswer((_) async => "");

    when(manager.hasWallet).thenAnswer((_) => true);
    when(manager.useBiometrics).thenAnswer((_) async => false);

    await tester.pumpWidget(
      MaterialApp(
        home: mockingjay.MockNavigatorProvider(
          navigator: navigator,
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<WalletsService>(
                create: (_) => walletsService,
              ),
              ChangeNotifierProvider<NodeService>(
                create: (_) => nodeService,
              ),
              ChangeNotifierProvider<Manager>(
                create: (_) => manager,
              ),
            ],
            child: LockscreenView(
              routeOnSuccess: "/mainview",
              secureStore: secureStore,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byType(AppBarIconButton), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);

    expect(find.text("failed to load wallet"), findsOneWidget);
    expect(find.text("Enter PIN"), findsOneWidget);

    expect(find.byType(CustomPinPut), findsOneWidget);
  });

  testWidgets("enter valid pin", (tester) async {
    final navigator = mockingjay.MockNavigator();
    final walletsService = MockWalletsService();
    final nodeService = MockNodeService();
    final manager = MockManager();
    final secureStore = FakeSecureStorage();

    secureStore.write(key: "walletID_pin", value: "1234");

    when(walletsService.currentWalletName)
        .thenAnswer((_) async => "My Firo Wallet");
    when(walletsService.getWalletId("My Firo Wallet"))
        .thenAnswer((_) async => "walletID");
    when(walletsService.networkName).thenAnswer((_) async => "main");

    when(nodeService.reInit()).thenAnswer((_) async {});

    when(
      nodeService.createNode(
        name: CampfireConstants.defaultNodeName,
        ipAddress: CampfireConstants.defaultIpAddress,
        port: CampfireConstants.defaultPort.toString(),
        useSSL: CampfireConstants.defaultUseSSL,
      ),
    ).thenAnswer((_) => true);

    when(manager.hasWallet).thenAnswer((_) => true);
    when(manager.useBiometrics).thenAnswer((_) async => false);
    when(manager.initializeWallet()).thenAnswer((_) async => true);

    mockingjay
        .when(() => navigator.pushReplacementNamed("/mainview"))
        .thenAnswer((_) async => {});

    await tester.pumpWidget(
      MaterialApp(
        home: mockingjay.MockNavigatorProvider(
          navigator: navigator,
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<WalletsService>(
                create: (_) => walletsService,
              ),
              ChangeNotifierProvider<NodeService>(
                create: (_) => nodeService,
              ),
              ChangeNotifierProvider<Manager>(
                create: (_) => manager,
              ),
            ],
            child: LockscreenView(
              routeOnSuccess: "/mainview",
              secureStore: secureStore,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is NumberKey && widget.number == "1"));
    await tester.pump(Duration(milliseconds: 200));
    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is NumberKey && widget.number == "2"));
    await tester.pump(Duration(milliseconds: 200));
    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is NumberKey && widget.number == "3"));
    await tester.pump(Duration(milliseconds: 200));
    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is NumberKey && widget.number == "4"));
    await tester.pump(Duration(milliseconds: 500));

    expect(find.text("PIN code correct. Unlocking wallet..."), findsOneWidget);

    await tester.pump(Duration(seconds: 2));

    mockingjay
        .verify(() => navigator.pushReplacementNamed("/mainview"))
        .called(1);
  });

  testWidgets("wallet initialization fails", (tester) async {
    final navigator = mockingjay.MockNavigator();
    final walletsService = MockWalletsService();
    final nodeService = MockNodeService();
    final manager = MockManager();
    final secureStore = FakeSecureStorage();

    secureStore.write(key: "walletID_pin", value: "1234");

    when(walletsService.currentWalletName)
        .thenAnswer((_) async => "My Firo Wallet");
    when(walletsService.getWalletId("My Firo Wallet"))
        .thenAnswer((_) async => "walletID");
    when(walletsService.networkName).thenAnswer((_) async => "test");

    when(nodeService.reInit()).thenAnswer((_) async {});

    when(
      nodeService.createNode(
        name: CampfireConstants.defaultNodeNameTestNet,
        ipAddress: CampfireConstants.defaultIpAddressTestNet,
        port: CampfireConstants.defaultPortTestNet.toString(),
        useSSL: CampfireConstants.defaultUseSSLTestNet,
      ),
    ).thenAnswer((_) => true);

    when(manager.hasWallet).thenAnswer((_) => true);
    when(manager.useBiometrics).thenAnswer((_) async => false);
    when(manager.initializeWallet()).thenAnswer((_) async => false);

    mockingjay
        .when(() => navigator.pushReplacementNamed("/mainview"))
        .thenAnswer((_) async => {});

    await tester.pumpWidget(
      MaterialApp(
        home: mockingjay.MockNavigatorProvider(
          navigator: navigator,
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<WalletsService>(
                create: (_) => walletsService,
              ),
              ChangeNotifierProvider<NodeService>(
                create: (_) => nodeService,
              ),
              ChangeNotifierProvider<Manager>(
                create: (_) => manager,
              ),
            ],
            child: LockscreenView(
              routeOnSuccess: "/mainview",
              secureStore: secureStore,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is NumberKey && widget.number == "1"));
    await tester.pump(Duration(milliseconds: 200));
    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is NumberKey && widget.number == "2"));
    await tester.pump(Duration(milliseconds: 200));
    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is NumberKey && widget.number == "3"));
    await tester.pump(Duration(milliseconds: 200));
    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is NumberKey && widget.number == "4"));
    await tester.pump(Duration(milliseconds: 500));

    expect(find.text("PIN code correct. Unlocking wallet..."), findsOneWidget);

    await tester.pump(Duration(seconds: 2));

    expect(find.byType(CampfireAlert), findsOneWidget);
    expect(
        find.text(
            "Failed to connect to network. Check your internet connection and make sure the Electrum X node you are connected to is not having any issues."),
        findsOneWidget);

    await tester.tap(find.byKey(Key("campfireAlertOKButtonKey")));
    await tester.pump(Duration(seconds: 2));
    await tester.pump(Duration(seconds: 2));

    expect(find.byType(CampfireAlert), findsNothing);
    expect(
        find.text(
            "Failed to connect to network. Check your internet connection and make sure the Electrum X node you are connected to is not having any issues."),
        findsNothing);

    mockingjay
        .verify(() => navigator.pushReplacementNamed("/mainview"))
        .called(1);
  });

  testWidgets("enter invalid pin", (tester) async {
    final navigator = mockingjay.MockNavigator();
    final walletsService = MockWalletsService();
    final nodeService = MockNodeService();
    final manager = MockManager();
    final secureStore = FakeSecureStorage();

    secureStore.write(key: "walletID_pin", value: "1234");

    when(walletsService.currentWalletName)
        .thenAnswer((_) async => "My Firo Wallet");
    when(walletsService.getWalletId("My Firo Wallet"))
        .thenAnswer((_) async => "walletID");
    when(walletsService.networkName).thenAnswer((_) async => "main");

    when(nodeService.reInit()).thenAnswer((_) async {});

    when(
      nodeService.createNode(
        name: CampfireConstants.defaultNodeName,
        ipAddress: CampfireConstants.defaultIpAddress,
        port: CampfireConstants.defaultPort.toString(),
        useSSL: CampfireConstants.defaultUseSSL,
      ),
    ).thenAnswer((_) => true);

    when(manager.hasWallet).thenAnswer((_) => true);
    when(manager.useBiometrics).thenAnswer((_) async => false);
    when(manager.initializeWallet()).thenAnswer((_) async => true);

    mockingjay
        .when(() => navigator.pushReplacementNamed("/mainview"))
        .thenAnswer((_) async => {});

    await tester.pumpWidget(
      MaterialApp(
        home: mockingjay.MockNavigatorProvider(
          navigator: navigator,
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<WalletsService>(
                create: (_) => walletsService,
              ),
              ChangeNotifierProvider<NodeService>(
                create: (_) => nodeService,
              ),
              ChangeNotifierProvider<Manager>(
                create: (_) => manager,
              ),
            ],
            child: LockscreenView(
              routeOnSuccess: "/mainview",
              secureStore: secureStore,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is NumberKey && widget.number == "1"));
    await tester.pump(Duration(milliseconds: 200));
    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is NumberKey && widget.number == "1"));
    await tester.pump(Duration(milliseconds: 200));
    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is NumberKey && widget.number == "3"));
    await tester.pump(Duration(milliseconds: 200));
    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is NumberKey && widget.number == "4"));
    await tester.pump(Duration(milliseconds: 500));

    expect(find.text("Incorrect PIN. Please try again"), findsOneWidget);

    await tester.pump(Duration(seconds: 2));

    mockingjay.verifyNever(() => navigator.pushReplacementNamed("/mainview"));
  });

  testWidgets("tap back", (tester) async {
    final navigator = mockingjay.MockNavigator();
    final walletsService = MockWalletsService();
    final nodeService = MockNodeService();
    final manager = MockManager();
    final secureStore = FakeSecureStorage();

    when(walletsService.currentWalletName)
        .thenAnswer((_) async => "My Firo Wallet");

    mockingjay.when(() => navigator.pop()).thenAnswer((_) async => {});

    when(manager.hasWallet).thenAnswer((_) => true);
    when(manager.useBiometrics).thenAnswer((_) async => false);

    await tester.pumpWidget(
      MaterialApp(
        home: mockingjay.MockNavigatorProvider(
          navigator: navigator,
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<WalletsService>(
                create: (_) => walletsService,
              ),
              ChangeNotifierProvider<NodeService>(
                create: (_) => nodeService,
              ),
              ChangeNotifierProvider<Manager>(
                create: (_) => manager,
              ),
            ],
            child: LockscreenView(
              routeOnSuccess: "/mainview",
              secureStore: secureStore,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppBarIconButton));
    await tester.pumpAndSettle();

    mockingjay.verify(() => navigator.pop()).called(1);
  });
}
