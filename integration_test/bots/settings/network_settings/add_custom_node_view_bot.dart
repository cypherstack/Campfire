import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paymint/pages/settings_view/settings_subviews/network_settings_subviews/add_custom_node_view.dart';
import 'package:paymint/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:paymint/widgets/custom_buttons/simple_button.dart';

class AddCustomNodeViewBot {
  final WidgetTester tester;

  const AddCustomNodeViewBot(this.tester);

  Future<void> ensureVisible() async {
    await tester.ensureVisible(find.byType(AddCustomNodeView));
  }

  Future<void> tapBack() async {
    await tester.tap(find.byType(AppBarIconButton));
    await tester.pumpAndSettle();
  }

  Future<void> enterNodeName(String name) async {
    await tester.enterText(
        find.byKey(Key("addCustomNodeNodeNameFieldKey")), name);
    await tester.pumpAndSettle();
  }

  Future<void> enterNodeAddress(String address) async {
    await tester.enterText(
        find.byKey(Key("addCustomNodeNodeAddressFieldKey")), address);
    await tester.pumpAndSettle();
  }

  Future<void> enterNodePort(String port) async {
    await tester.enterText(
        find.byKey(Key("addCustomNodeNodePortFieldKey")), port);
    await tester.pumpAndSettle();
  }

  Future<void> tapSSLCheckbox() async {
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
  }

  Future<void> tapTestConnection() async {
    await tester.tap(find.byType(SimpleButton));
    await tester.pump(Duration(milliseconds: 500));
  }

  Future<void> tapSave() async {
    await tester.tap(find.byType(GradientButton));
    await tester.pumpAndSettle();
  }
}
