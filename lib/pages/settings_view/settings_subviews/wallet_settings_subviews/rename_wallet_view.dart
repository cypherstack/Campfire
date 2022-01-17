import 'package:flutter/material.dart';
import 'package:paymint/pages/settings_view/helpers/builders.dart';
import 'package:paymint/services/wallets_service.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:provider/provider.dart';

class RenameWalletView extends StatefulWidget {
  const RenameWalletView({Key key, @required this.oldWalletName})
      : super(key: key);

  final String oldWalletName;
  @override
  _RenameWalletViewState createState() => _RenameWalletViewState();
}

class _RenameWalletViewState extends State<RenameWalletView> {
  final _controller = TextEditingController();

  @override
  void initState() {
    _controller.text = widget.oldWalletName;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final walletsService = Provider.of<WalletsService>(context, listen: false);
    return Scaffold(
      backgroundColor: CFColors.white,
      appBar: buildSettingsAppBar(context, "Rename wallet"),
      body: Padding(
        padding: const EdgeInsets.all(SizingUtilities.standardPadding),
        child: Column(
          children: [
            TextField(
              controller: _controller,
            ),
            Spacer(),
            SizedBox(
              height: SizingUtilities.standardButtonHeight,
              child: GradientButton(
                child: FittedBox(
                  child: Text(
                    "SAVE",
                    style: CFTextStyles.button,
                  ),
                ),
                onTap: () async {
                  print("SAVE");
                  await walletsService.renameWallet(toName: _controller.text);
                  Navigator.pop(context);
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
