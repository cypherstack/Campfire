import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paymint/pages/settings_view/settings_subviews/wallet_settings_subviews/delete_wallet_warning_view.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:paymint/widgets/custom_buttons/simple_button.dart';

class DeleteWalletWarningViewBot {
  final WidgetTester tester;

  const DeleteWalletWarningViewBot(this.tester);

  Future<void> ensureVisible() async {
    await tester.ensureVisible(find.byType(DeleteWalletWarningView));
  }

  Future<void> tapBack() async {
    await tester.tap(find.byKey(Key("settingsAppBarBackButton")));
    await tester.pumpAndSettle();
  }

  Future<void> tapCancelAndGoBack() async {
    await tester.tap(find.byType(SimpleButton));
    await tester.pumpAndSettle();
  }

  Future<void> tapViewBackupKey() async {
    await tester.tap(find.byType(GradientButton));
    await tester.pumpAndSettle();
  }
}
