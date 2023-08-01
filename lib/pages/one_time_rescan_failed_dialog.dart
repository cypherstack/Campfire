import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/notifications/modal_popup_dialog.dart';
import 'package:paymint/pages/lockscreen_view.dart';
import 'package:paymint/pages/settings_view/settings_subviews/wallet_settings_view.dart';
import 'package:paymint/services/wallets_service.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:paymint/widgets/custom_buttons/simple_button.dart';
import 'package:provider/provider.dart';

class OneTimeRescanFailedDialog extends StatelessWidget {
  const OneTimeRescanFailedDialog({Key key, this.errorMessage})
      : super(key: key);

  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    return ModalPopupDialog(
      child: Column(
        children: [
          SizedBox(
            height: 28,
          ),
          FittedBox(
            child: Text(
              "Rescan wallet failed.",
              style: CFTextStyles.pinkHeader.copyWith(
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(
            height: 12,
          ),
          Center(
            child: Text(
              errorMessage == null ? "" : errorMessage,
              style: GoogleFonts.workSans(
                color: CFColors.dusk,
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ),
          SizedBox(
            height: 50,
          ),
          SizedBox(
            height: SizingUtilities.standardButtonHeight,
            width: SizingUtilities.standardFixedButtonWidth,
            child: SimpleButton(
              child: FittedBox(
                child: Text(
                  "Cancel",
                  style: CFTextStyles.button.copyWith(color: CFColors.dusk),
                ),
              ),
              onTap: () {
                Navigator.of(context).pop("cancel");
              },
            ),
          ),
          SizedBox(
            height: SizingUtilities.standardPadding,
          ),
          SizedBox(
            height: SizingUtilities.standardButtonHeight,
            width: SizingUtilities.standardFixedButtonWidth,
            child: SimpleButton(
              child: FittedBox(
                child: Text(
                  "Show mnemonic",
                  style: CFTextStyles.button.copyWith(color: CFColors.dusk),
                ),
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => LockscreenView(
                      routeOnSuccess: '/settings/walletbackup',
                      biometricsAuthenticationTitle: "Show backup key",
                      biometricsCancelButtonString: "CANCEL",
                      biometricsLocalizedReason:
                          "Unlock using fingerprint to show backup key",
                    ),
                    settings:
                        RouteSettings(name: "/settings/walletbackupoption"),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            height: SizingUtilities.standardPadding,
          ),
          SizedBox(
            height: SizingUtilities.standardButtonHeight,
            width: SizingUtilities.standardFixedButtonWidth,
            child: SimpleButton(
              child: FittedBox(
                child: Text(
                  "Delete wallet",
                  style: CFTextStyles.button.copyWith(color: CFColors.dusk),
                ),
              ),
              onTap: () async {
                final walletName =
                    await Provider.of<WalletsService>(context, listen: false)
                        .currentWalletName;

                await showDialog(
                  useSafeArea: false,
                  barrierColor: Colors.transparent,
                  barrierDismissible: false,
                  context: context,
                  builder: (_) => ConfirmationDialog(
                    message: "Do you want to delete $walletName Wallet?",
                    cancelButtonText: "CANCEL",
                    confirmButtonText: "DELETE",
                    onCancel: () {
                      Navigator.pop(context);
                    },
                    onConfirm: () async {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => LockscreenView(
                            routeOnSuccess: '/settings/deletewalletwarningview',
                            biometricsAuthenticationTitle: "Confirm delete",
                            biometricsCancelButtonString: "CANCEL",
                            biometricsLocalizedReason:
                                "Continue wallet deletion process via fingerprint authentication",
                          ),
                          settings: RouteSettings(
                              name: "/settings/deletewalletlockscreen"),
                        ),
                      );
                    },
                  ),
                );

                // Navigator.of(context).pop("retry");
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(SizingUtilities.standardPadding),
              child: SizedBox(
                height: SizingUtilities.standardButtonHeight,
                width: SizingUtilities.standardFixedButtonWidth,
                child: GradientButton(
                  child: FittedBox(
                    child: Text(
                      "Retry",
                      style: CFTextStyles.button,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop("retry");
                  },
                ),
              ),
            ),
          ),
          SizedBox(
            height: SizingUtilities.standardPadding,
          ),
        ],
      ),
    );
  }
}
