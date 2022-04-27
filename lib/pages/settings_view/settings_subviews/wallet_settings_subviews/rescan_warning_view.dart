import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/notifications/modal_popup_dialog.dart';
import 'package:paymint/notifications/overlay_notification.dart';
import 'package:paymint/pages/settings_view/helpers/builders.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/utilities/address_utils.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/clipboard_interface.dart';
import 'package:paymint/utilities/misc_global_constants.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:paymint/widgets/custom_buttons/simple_button.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:provider/provider.dart';
import 'package:wakelock/wakelock.dart';

class RescanWarningView extends StatelessWidget {
  const RescanWarningView({
    Key key,
    this.clipboard = const ClipboardWrapper(),
  }) : super(key: key);

  final ClipboardInterface clipboard;

  Future<List<String>> _getMnemonic(BuildContext context) async {
    final manager = Provider.of<Manager>(context, listen: false);
    final mnemonic = await manager.mnemonic;
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
                builder: (BuildContext context,
                    AsyncSnapshot<List<String>> snapshot) {
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
                    builder: (_) => _buildConfirmDialog(context),
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
              "Thanks!\nYour wallet will be completely rescanned",
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
                      key: Key("rescanWarningContinueCancelButtonKey"),
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
                      key: Key("rescanWarningContinueRescanButtonKey"),
                      child: FittedBox(
                        child: Text(
                          "RESCAN",
                          style: CFTextStyles.button,
                        ),
                      ),
                      onTap: () async {
                        Wakelock.enable();
                        // show restoring in progress
                        showDialog(
                          context: context,
                          useSafeArea: false,
                          barrierDismissible: false,
                          builder: (context) => WillPopScope(
                            onWillPop: () async {
                              return false;
                            },
                            child: ModalPopupDialog(
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 28,
                                  ),
                                  FittedBox(
                                    child: Text(
                                      "Rescanning wallet",
                                      style: CFTextStyles.pinkHeader.copyWith(
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 12,
                                  ),
                                  FittedBox(
                                    child: Text(
                                      "This may take a while.",
                                      style: GoogleFonts.workSans(
                                        color: CFColors.dusk,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 12,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child: FittedBox(
                                      child: Text(
                                        "Do not close or leave the app until this completes!",
                                        style: GoogleFonts.workSans(
                                          color: CFColors.dusk,
                                          fontWeight: FontWeight.w400,
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 50,
                                  ),
                                  Container(
                                    width: 98,
                                    height: 98,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(49),
                                      border: Border.all(
                                        color: CFColors.dew,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Container(
                                        height: 40,
                                        width: 40,
                                        child: CircularProgressIndicator(
                                          color: CFColors.spark,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 50,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );

                        try {
                          // do rescan
                          await Provider.of<Manager>(context, listen: false)
                              .fullRescan();
                          Navigator.pushReplacementNamed(context, "/mainview");

                          Timer timer = Timer(Duration(milliseconds: 2000), () {
                            Navigator.of(context, rootNavigator: true).pop();
                          });

                          showDialog(
                            context: context,
                            useSafeArea: false,
                            barrierDismissible: false,
                            builder: (_) {
                              return _buildRescanCompleteDialog();
                            },
                          ).then(
                            (_) {
                              Wakelock.disable();
                              timer.cancel();
                              timer = null;
                            },
                          );
                        } catch (e) {
                          Wakelock.disable();
                          // pop waiting dialog
                          Navigator.pop(context);
                          // show restoring wallet failed dialog
                          showDialog(
                            context: context,
                            useSafeArea: false,
                            barrierDismissible: false,
                            builder: (_) => RescanFailedDialog(
                              errorMessage: e.toString(),
                            ),
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
    final _isTinyWidth = SizingUtilities.isTinyWidth(context);
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: SizingUtilities.standardButtonHeight,
            child: SimpleButton(
              key: Key("rescanWarningShowQrCodeButtonKey"),
              onTap: () {
                showDialog(
                  context: context,
                  useSafeArea: false,
                  barrierDismissible: false,
                  builder: (_) {
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
                    width: _isTinyWidth ? 4 : 10,
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
              key: Key("rescanWarningCopySeedButtonKey"),
              onTap: () async {
                final mnemonic = await _getMnemonic(context);
                clipboard.setData(
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
                    width: _isTinyWidth ? 4 : 10,
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
    final int wordsCount =
        min(words.length, CampfireConstants.seedPhraseWordCount);
    List<TableRow> rows = [];

    for (int i = 0; i < wordsCount / 2; i++) {
      final row = TableRow(
        children: [
          TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Material(
              color: CFColors.fog,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(SizingUtilities.checkboxBorderRadius),
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
                            topLeft: Radius.circular(
                                SizingUtilities.checkboxBorderRadius),
                            bottomLeft: Radius.circular(
                                SizingUtilities.checkboxBorderRadius),
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
                borderRadius:
                    BorderRadius.circular(SizingUtilities.checkboxBorderRadius),
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
                            topLeft: Radius.circular(
                                SizingUtilities.checkboxBorderRadius),
                            bottomLeft: Radius.circular(
                                SizingUtilities.checkboxBorderRadius),
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
                borderRadius:
                    BorderRadius.circular(SizingUtilities.circularBorderRadius),
                side: BorderSide(
                  color: CFColors.smoke,
                  width: 1,
                ),
              ),
              child: FutureBuilder(
                future: _getMnemonic(context),
                builder: (BuildContext context,
                    AsyncSnapshot<List<String>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return Center(
                      child: PrettyQr(
                        data: AddressUtils.encodeQRSeedData(snapshot.data),
                        roundEdges: CampfireConstants.roundedQrCode,
                        elementColor: CFColors.midnight,
                        typeNumber: 15,
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
                    width: MediaQuery.of(context).size.width / 2,
                    child: SimpleButton(
                      key: Key("rescanWarningQrCodePopupCancelButtonKey"),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  _buildRescanCompleteDialog() {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: ModalPopupDialog(
        child: Column(
          children: [
            SizedBox(
              height: 28,
            ),
            FittedBox(
              child: Text(
                "Rescan Complete!",
                style: CFTextStyles.pinkHeader.copyWith(
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(
              height: 50,
            ),
            Container(
              width: 98,
              height: 98,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(49),
                border: Border.all(
                  color: CFColors.dew,
                  width: 2,
                ),
              ),
              child: Center(
                child: Container(
                  height: 50,
                  width: 50,
                  child: SvgPicture.asset(
                    "assets/svg/check-circle.svg",
                    color: CFColors.spark,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 50.0,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}

class RescanFailedDialog extends StatelessWidget {
  const RescanFailedDialog({Key key, this.errorMessage}) : super(key: key);

  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final navigator = Navigator.of(context);
        navigator.pop();
        navigator.pop();
        navigator.pop();
        return true;
      },
      child: ModalPopupDialog(
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
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(SizingUtilities.standardPadding),
                child: SizedBox(
                  height: SizingUtilities.standardButtonHeight,
                  width: SizingUtilities.standardFixedButtonWidth,
                  child: GradientButton(
                    key: Key("rescanWarningViewRescanFailedOkButtonKey"),
                    child: FittedBox(
                      child: Text(
                        "OK",
                        style: CFTextStyles.button,
                      ),
                    ),
                    onTap: () {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      navigator.pop();
                      navigator.pop();
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
      ),
    );
  }
}
