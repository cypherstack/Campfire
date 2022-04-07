import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:paymint/pages/wallet_selection_view.dart';
import 'package:paymint/services/node_service.dart';
import 'package:paymint/services/wallets_service.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:paymint/widgets/custom_buttons/simple_button.dart';
import 'package:provider/provider.dart';

import 'wallet_selection_view_screen_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<WalletsService>(returnNullOnMissingStub: true),
  MockSpec<NodeService>(returnNullOnMissingStub: true),
])
void main() {
  testWidgets("WalletSelectionView builds with no wallets found",
      (tester) async {
    final navigator = mockingjay.MockNavigator();
    final walletsService = MockWalletsService();
    final nodeService = MockNodeService();

    when(walletsService.walletNames).thenAnswer((_) async => {});

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
            ],
            child: WalletSelectionView(),
          ),
        ),
      ),
    );

    final imageFinder = find.byType(Image);
    expect(imageFinder, findsOneWidget);

    final imageSource =
        ((imageFinder.evaluate().single.widget as Image).image as AssetImage)
            .assetName;
    expect(imageSource, "assets/images/splash.png");

    expect(find.text("Welcome"), findsOneWidget);
    expect(find.text("Choose your wallet"), findsOneWidget);

    expect(find.text("CREATE NEW WALLET"), findsOneWidget);
    expect(find.text("RESTORE WALLET"), findsOneWidget);

    expect(find.byType(SpinKitThreeBounce), findsOneWidget);
    expect(find.byType(GradientButton), findsOneWidget);
    expect(find.byType(SimpleButton), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text("An Error occurred. No wallets found..."), findsOneWidget);
  });

  testWidgets("WalletSelectionView builds with two wallets found",
      (tester) async {
    final navigator = mockingjay.MockNavigator();
    final walletsService = MockWalletsService();
    final nodeService = MockNodeService();

    when(walletsService.walletNames).thenAnswer((_) async => {
          "Wallet A": "aID",
          "Wallet B": "bID",
        });

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
            ],
            child: WalletSelectionView(),
          ),
        ),
      ),
    );

    final imageFinder = find.byType(Image);
    expect(imageFinder, findsOneWidget);

    final imageSource =
        ((imageFinder.evaluate().single.widget as Image).image as AssetImage)
            .assetName;
    expect(imageSource, "assets/images/splash.png");

    expect(find.text("Welcome"), findsOneWidget);
    expect(find.text("Choose your wallet"), findsOneWidget);

    expect(find.text("CREATE NEW WALLET"), findsOneWidget);
    expect(find.text("RESTORE WALLET"), findsOneWidget);

    expect(find.byType(SpinKitThreeBounce), findsOneWidget);
    expect(find.byType(GradientButton), findsOneWidget);
    expect(find.byType(SimpleButton), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text("An Error occurred. No wallets found..."), findsNothing);

    expect(find.text("Wallet A"), findsOneWidget);
    expect(find.text("Wallet B", skipOffstage: false), findsOneWidget);

    expect(find.byType(MaterialButton, skipOffstage: false), findsNWidgets(4));
    expect(find.byType(SvgPicture, skipOffstage: false), findsNWidgets(2));
  });

  testWidgets("tap create", (tester) async {
    final navigator = mockingjay.MockNavigator();
    final walletsService = MockWalletsService();
    final nodeService = MockNodeService();

    when(walletsService.walletNames).thenAnswer((_) async => {});

    mockingjay
        .when(() => navigator.push(mockingjay.any()))
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
            ],
            child: WalletSelectionView(),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(GradientButton));
    await tester.pumpAndSettle();

    mockingjay.verify(() => navigator.push(mockingjay.any())).called(1);
  });

  testWidgets("tap restore", (tester) async {
    final navigator = mockingjay.MockNavigator();
    final walletsService = MockWalletsService();
    final nodeService = MockNodeService();

    when(walletsService.walletNames).thenAnswer((_) async => {});

    mockingjay
        .when(() => navigator.push(mockingjay.any()))
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
            ],
            child: WalletSelectionView(),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(SimpleButton));
    await tester.pumpAndSettle();

    mockingjay.verify(() => navigator.push(mockingjay.any())).called(1);
  });

  testWidgets("tap wallet", (tester) async {
    final navigator = mockingjay.MockNavigator();
    final walletsService = MockWalletsService();
    final nodeService = MockNodeService();

    when(walletsService.walletNames)
        .thenAnswer((_) async => {"My Firo Wallet": "walletID"});
    when(walletsService.setCurrentWalletName("My Firo Wallet"))
        .thenAnswer((_) async {});
    when(nodeService.reInit()).thenAnswer((_) async {});

    mockingjay
        .when(() => navigator.push(mockingjay.any()))
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
            ],
            child: WalletSelectionView(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key("walletSelectionViewWalletButtonKey_0")));

    verify(walletsService.setCurrentWalletName("My Firo Wallet")).called(1);
    verify(walletsService.walletNames).called(1);
    verify(nodeService.reInit()).called(1);

    mockingjay.verify(() => navigator.push(mockingjay.any())).called(1);
  });
}
