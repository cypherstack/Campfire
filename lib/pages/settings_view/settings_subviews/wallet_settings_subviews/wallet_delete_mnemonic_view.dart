import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/notifications/modal_popup_dialog.dart';
import 'package:paymint/notifications/overlay_notification.dart';
import 'package:paymint/pages/onboarding_view/onboarding_view.dart';
import 'package:paymint/pages/settings_view/helpers/builders.dart';
import 'package:paymint/services/bitcoin_service.dart';
import 'package:paymint/services/wallets_service.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/misc_global_constants.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:paymint/widgets/custom_buttons/simple_button.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:provider/provider.dart';

import '../../../wallet_selection_view.dart';

class WalletDeleteMnemonicView extends StatelessWidget {
  const WalletDeleteMnemonicView({Key key}) : super(key: key);

  Future<List<String>> _getMnemonic(BuildContext context) async {
    final bitcoinService = Provider.of<BitcoinService>(context, listen: false);
    final mnemonic = await bitcoinService.getMnemonicList();
    return mnemonic;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CFColors.white,
      appBar: buildSettingsAppBar(context, "Backup Key", backDelayed: false),
      body: Padding(
        padding: EdgeInsets.all(SizingUtilities.standardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 9,
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FittedBox(
                  child: Text(
                    "Please write down your backup key.",
                    style: GoogleFonts.workSans(
                      color: CFColors.dusk,
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: SizingUtilities.standardPadding,
            ),
            Expanded(
              child: FutureBuilder(
                future: _getMnemonic(context),
                builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return _buildKeys(snapshot.data);
                  } else {
                    return Center(
                      child: SpinKitThreeBounce(
                        color: CFColors.spark,
                        size: MediaQuery.of(context).size.width * 0.1,
                      ),
                    );
                  }
                },
              ),
            ),
            _buildButtonRow(context),
            SizedBox(
              height: 12,
            ),
            SizedBox(
              height: 48,
              child: GradientButton(
                onTap: () {
                  showDialog(
                    useSafeArea: false,
                    barrierColor: Colors.transparent,
                    barrierDismissible: false,
                    context: context,
                    builder: (context) => _buildConfirmDialog(context),
                  );
                },
                child: FittedBox(
                  child: Text(
                    "CONTINUE",
                    style: GoogleFonts.workSans(
                        color: CFColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        letterSpacing: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _buildConfirmDialog(BuildContext context) {
    return ModalPopupDialog(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 28,
              left: 24,
              right: 24,
              bottom: 12,
            ),
            child: Text(
              "Thanks!\nYour wallet will be deleted",
              style: GoogleFonts.workSans(
                color: CFColors.dusk,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(SizingUtilities.standardPadding),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: SizingUtilities.standardButtonHeight,
                    child: SimpleButton(
                      child: FittedBox(
                        child: Text(
                          "CANCEL",
                          style: CFTextStyles.button.copyWith(
                            color: CFColors.dusk,
                          ),
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ),
                SizedBox(
                  width: 16,
                ),
                Expanded(
                  child: SizedBox(
                    height: SizingUtilities.standardButtonHeight,
                    child: GradientButton(
                      child: FittedBox(
                        child: Text(
                          "DELETE",
                          style: CFTextStyles.button,
                        ),
                      ),
                      onTap: () async {
                        // TODO possibly show progress of deletion if it takes any significant time
                        final walletsService =
                            Provider.of<WalletsService>(context, listen: false);
                        final walletName = await walletsService.currentWalletName;
                        int result = await walletsService.deleteWallet(walletName);
                        print("delete result: $result");
                        // check if last wallet was deleted
                        if (result == 2) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            CupertinoPageRoute(
                              maintainState: false,
                              builder: (_) => OnboardingView(),
                            ),
                            (_) => false,
                          );
                        } else {
                          Navigator.pushAndRemoveUntil(
                            context,
                            CupertinoPageRoute(
                              builder: (_) => WalletSelectionView(),
                            ),
                            (_) => false,
                          );
                        }
                      },
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  _buildButtonRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: SizingUtilities.standardButtonHeight,
            child: SimpleButton(
              onTap: () {
                showDialog(
                  context: context,
                  useSafeArea: false,
                  barrierDismissible: false,
                  builder: (context) {
                    return _buildQrCodePopup(context);
                  },
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    "assets/svg/qr-code.svg",
                    color: CFColors.dusk,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  FittedBox(
                    child: Text(
                      "QR CODE",
                      style: CFTextStyles.button.copyWith(
                        color: CFColors.dusk,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          width: 16,
        ),
        Expanded(
          child: SizedBox(
            height: 48,
            child: SimpleButton(
              onTap: () async {
                final mnemonic = await _getMnemonic(context);
                Clipboard.setData(
                  ClipboardData(
                    text: mnemonic.join(" "),
                  ),
                );
                OverlayNotification.showInfo(
                  context,
                  "Copied to clipboard",
                  Duration(seconds: 2),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    "assets/svg/copy.svg",
                    color: CFColors.dusk,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    "COPY",
                    style: CFTextStyles.button.copyWith(
                      color: CFColors.dusk,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeys(List<String> words) {
    final int wordsCount = 12;
    List<TableRow> rows = [];

    for (int i = 0; i < wordsCount / 2; i++) {
      final row = TableRow(
        children: [
          TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Material(
              color: CFColors.fog,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SizingUtilities.checkboxBorderRadius),
                side: BorderSide(
                  width: 1,
                  color: CFColors.dew,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Material(
                        color: CFColors.dew,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft:
                                Radius.circular(SizingUtilities.checkboxBorderRadius),
                            bottomLeft:
                                Radius.circular(SizingUtilities.checkboxBorderRadius),
                          ),
                          side: BorderSide(
                            width: 1,
                            color: CFColors.dew,
                          ),
                        ),
                        child: Center(
                          child: FittedBox(
                            child: Text(
                              "${i + 1}",
                              style: GoogleFonts.workSans(
                                color: CFColors.starryNight,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: FittedBox(
                        child: Text(
                          "${words[i]}",
                          style: GoogleFonts.workSans(
                            color: CFColors.starryNight,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          TableCell(
            child: SizedBox(
              width: 20,
            ),
          ),
          TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Material(
              color: CFColors.fog,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SizingUtilities.checkboxBorderRadius),
                side: BorderSide(
                  width: 1,
                  color: CFColors.dew,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Material(
                        color: CFColors.dew,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft:
                                Radius.circular(SizingUtilities.checkboxBorderRadius),
                            bottomLeft:
                                Radius.circular(SizingUtilities.checkboxBorderRadius),
                          ),
                          side: BorderSide(
                            width: 1,
                            color: CFColors.dew,
                          ),
                        ),
                        child: Center(
                          child: FittedBox(
                            child: Text(
                              "${i + (wordsCount ~/ 2) + 1}",
                              style: GoogleFonts.workSans(
                                color: CFColors.starryNight,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: FittedBox(
                        child: Text(
                          "${words[i + wordsCount ~/ 2]}",
                          style: GoogleFonts.workSans(
                            color: CFColors.starryNight,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

      rows.add(row);

      // add space between each row hack
      if (i < (wordsCount / 2) - 1) {
        final spacerRow = TableRow(
          children: [
            SizedBox(
              height: 10,
            ),
            SizedBox(
              height: 10,
            ),
            SizedBox(
              height: 10,
            ),
          ],
        );
        rows.add(spacerRow);
      }
    }

    return SingleChildScrollView(
      child: Table(
        columnWidths: {
          0: FlexColumnWidth(),
          1: IntrinsicColumnWidth(),
          2: FlexColumnWidth(),
        },
        children: rows,
      ),
    );
  }

  _buildQrCodePopup(BuildContext context) {
    final _qrSize = MediaQuery.of(context).size.width * 0.42;
    return ModalPopupDialog(
      child: Column(
        children: [
          SizedBox(
            height: 28,
          ),
          FittedBox(
            child: Text(
              "Backup Key QR Code",
              style: CFTextStyles.pinkHeader.copyWith(
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(
            height: 16,
          ),
          Container(
            height: _qrSize * 1.1,
            width: _qrSize * 1.1,
            color: CFColors.white,
            child: Material(
              color: CFColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SizingUtilities.circularBorderRadius),
                side: BorderSide(
                  color: CFColors.smoke,
                  width: 1,
                ),
              ),
              child: FutureBuilder(
                future: _getMnemonic(context),
                builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return Center(
                      child: PrettyQr(
                        data: snapshot.data.join(' '),
                        roundEdges: CampfireConstants.roundedQrCode,
                        elementColor: CFColors.midnight,
                        typeNumber: 5,
                        size: _qrSize,
                      ),
                    );
                  } else {
                    return Container(
                      height: _qrSize,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
          SizedBox(
            height: 12,
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              // crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: SimpleButton(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: FittedBox(
                        child: Text(
                          "CANCEL",
                          style: CFTextStyles.button.copyWith(
                            color: CFColors.dusk,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 16,
                ),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: GradientButton(
                      onTap: () {
                        // TODO implement save QR Code to file
                        print("SAVE mnemonic key pressed");
                      },
                      child: FittedBox(
                        child: Text(
                          "SAVE",
                          style: CFTextStyles.button,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
