import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/notifications/modal_popup_dialog.dart';
import 'package:paymint/notifications/overlay_notification.dart';
import 'package:paymint/pages/onboarding_view/helpers/builders.dart';
import 'package:paymint/pages/onboarding_view/verify_backup_key_view.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/utilities/address_utils.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/misc_global_constants.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:paymint/widgets/custom_buttons/simple_button.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:provider/provider.dart';

class BackupKeyView extends StatefulWidget {
  const BackupKeyView({Key key}) : super(key: key);

  @override
  _BackupKeyViewState createState() => _BackupKeyViewState();
}

class _BackupKeyViewState extends State<BackupKeyView> {
  Future<List<String>> _getMnemonic(BuildContext context) async {
    final manager = Provider.of<Manager>(context, listen: false);
    final mnemonic = await manager.mnemonic;
    return mnemonic;
  }

  Widget _buildKeys(List<String> words) {
    List<TableRow> rows = [];

    for (int i = 0; i < CampfireConstants.seedPhraseWordCount / 2; i++) {
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
                          key: Key("mnemonic_word_text_$i"),
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
                              "${i + (CampfireConstants.seedPhraseWordCount ~/ 2) + 1}",
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
                          "${words[i + CampfireConstants.seedPhraseWordCount ~/ 2]}",
                          key: Key(
                              "mnemonic_word_text_${i + CampfireConstants.seedPhraseWordCount ~/ 2}"),
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
      if (i < (CampfireConstants.seedPhraseWordCount / 2) - 1) {
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
                      key: Key("backUpKeyViewQrCodeCancelButtonKey"),
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: FittedBox(
                        child: Text(
                          "CANCEL",
                          style: GoogleFonts.workSans(
                            color: CFColors.dusk,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // SizedBox(
                //   width: 16,
                // ),
                // Expanded(
                //   child: SizedBox(
                //     height: 48,
                //     child: GradientButton(
                //       onTap: () {
                //         // TODO implement save QR Code to file
                //         print("SAVE mnemonic key pressed");
                //       },
                //       child: FittedBox(
                //         child: Text(
                //           "SAVE",
                //           style: GoogleFonts.workSans(
                //             color: CFColors.white,
                //             fontWeight: FontWeight.w600,
                //             fontSize: 16,
                //             letterSpacing: 0.5,
                //           ),
                //         ),
                //       ),
                //     ),
                //   ),
                // )
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTiny = SizingUtilities.isTinyWidth(context);

    return Scaffold(
      backgroundColor: CFColors.starryNight,
      appBar: buildOnboardingAppBar(
        context,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, "/mainview");
              },
              child: Text(
                "SKIP",
                style: CFTextStyles.button,
              ),
            ),
          ),
        ],
      ),
      body: buildOnboardingBody(
        context,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 40,
            ),
            Center(
              child: FittedBox(
                child: Text(
                  "Backup Key",
                  style: CFTextStyles.pinkHeader,
                ),
              ),
            ),
            SizedBox(
              height: 12,
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 24,
                  left: 20,
                  right: 20,
                  bottom: 8,
                ),
                child: FutureBuilder(
                  future: _getMnemonic(context),
                  builder: (BuildContext context,
                      AsyncSnapshot<List<String>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return _buildKeys(snapshot.data);
                    } else {
                      return Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: SimpleButton(
                        key: const Key("backupKeyQrCodeButtonKey"),
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
                              width: isTiny ? 5 : 10,
                            ),
                            FittedBox(
                              child: Text(
                                "QR CODE",
                                style: GoogleFonts.workSans(
                                  color: CFColors.dusk,
                                  fontWeight: FontWeight.w600,
                                  fontSize: isTiny ? 14 : 16,
                                  letterSpacing: 0.5,
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
                        key: const Key("backupKeyViewCopyButtonKey"),
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
                              width: isTiny ? 5 : 10,
                            ),
                            Text(
                              "COPY",
                              style: GoogleFonts.workSans(
                                color: CFColors.dusk,
                                fontWeight: FontWeight.w600,
                                fontSize: isTiny ? 14 : 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: 20,
              ),
              child: SizedBox(
                height: 48,
                child: GradientButton(
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => VerifyBackupKeyView(),
                      ),
                    );
                  },
                  child: FittedBox(
                    child: Text(
                      "VERIFY",
                      style: GoogleFonts.workSans(
                        color: CFColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
