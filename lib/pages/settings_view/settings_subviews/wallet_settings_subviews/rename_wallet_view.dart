import 'package:flutter/material.dart';
import 'package:paymint/notifications/campfire_alert.dart';
import 'package:paymint/pages/settings_view/helpers/builders.dart';
import 'package:paymint/services/wallets_service.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/logger.dart';
import 'package:paymint/utilities/shared_utilities.dart';
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

  bool _saveButtonEnabled = false;

  @override
  void initState() {
    _controller.text = widget.oldWalletName;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CFColors.white,
      appBar: buildSettingsAppBar(context, "Rename wallet"),
      body: Padding(
        padding: const EdgeInsets.all(SizingUtilities.standardPadding),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              onChanged: (newValue) {
                setState(() {
                  _saveButtonEnabled = newValue.trim().isNotEmpty;
                });
              },
            ),
            Spacer(),
            SizedBox(
              width: MediaQuery.of(context).size.width -
                  (SizingUtilities.standardPadding * 2),
              height: SizingUtilities.standardButtonHeight,
              child: GradientButton(
                enabled: _saveButtonEnabled,
                child: FittedBox(
                  child: Text(
                    "SAVE",
                    style: CFTextStyles.button,
                  ),
                ),
                onTap: () async {
                  final walletsService =
                      Provider.of<WalletsService>(context, listen: false);
                  final name = _controller.text.trim();
                  if (!Utilities.isAscii(name)) {
                    Logger.print(
                        "rename wallet failed due to non ascii characters");
                    showDialog(
                      context: context,
                      useSafeArea: false,
                      barrierDismissible: false,
                      builder: (ctx) => CampfireAlert(
                        message: "Non ASCII characters are not allowed!",
                      ),
                    );
                  } else if (await walletsService.renameWallet(toName: name)) {
                    Navigator.pop(context);
                    Logger.print("renamed wallet");
                  } else {
                    Logger.print("rename wallet failed");
                    showDialog(
                      context: context,
                      useSafeArea: false,
                      barrierDismissible: false,
                      builder: (ctx) => CampfireAlert(
                        message: "A wallet with name \"$name\" already exists!",
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
