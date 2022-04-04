import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paymint/pages/main_view.dart';

class MainViewBot {
  final WidgetTester tester;

  const MainViewBot(this.tester);

  Future<void> ensureVisible() async {
    await tester.ensureVisible(find.byType(MainView));
  }

  Future<void> tapRefresh() async {
    await tester.tap(find.byKey(Key("mainViewRefreshButton")));
    await tester.pumpAndSettle();
  }

  Future<void> tapSettings() async {
    await tester.tap(find.byKey(Key("mainViewSettingsButton")));
    await tester.pumpAndSettle();
  }

  Future<void> tapSend() async {
    await tester.tap(find.bySemanticsLabel("sendBottomNavigationBarItem logo"));
    await tester.pumpAndSettle();
  }

  Future<void> tapWallet() async {
    await tester
        .tap(find.bySemanticsLabel("walletBottomNavigationBarItem logo"));
    await tester.pumpAndSettle();
  }

  Future<void> tapReceive() async {
    await tester
        .tap(find.bySemanticsLabel("receiveBottomNavigationBarItem logo"));
    await tester.pumpAndSettle();
  }
}
