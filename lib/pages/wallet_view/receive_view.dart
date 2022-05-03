import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:devicelocale/devicelocale.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/notifications/modal_popup_dialog.dart';
import 'package:paymint/notifications/overlay_notification.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/utilities/address_utils.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/clipboard_interface.dart';
import 'package:paymint/utilities/misc_global_constants.dart';
import 'package:paymint/utilities/shared_utilities.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:paymint/widgets/custom_buttons/simple_button.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:provider/provider.dart';

class ReceiveView extends StatefulWidget {
  const ReceiveView({Key key, this.clipboard = const ClipboardWrapper()})
      : super(key: key);

  final ClipboardInterface clipboard;

  @override
  _ReceiveViewState createState() => _ReceiveViewState();
}

class _ReceiveViewState extends State<ReceiveView> {
  ClipboardInterface clipboard;

  TextEditingController cryptoAmountController = TextEditingController();
  TextEditingController noteTextController = TextEditingController();
  bool _showMoreOptions = false;
  String _locale = "en_US"; // default

  @override
  initState() {
    clipboard = widget.clipboard;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<Manager>(context);
    final size = MediaQuery.of(context).size;
    final minSize = min(size.width, size.height);
    final qrSize = minSize / 2;

    return SafeArea(
      child: Container(
        color: CFColors.white,
        child: LayoutBuilder(
          builder: (context, constraint) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  top: 8,
                  left: 4,
                  right: 4,
                  bottom: 16,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    // subtract top and bottom padding set in parent
                    minHeight: constraint.maxHeight - 8 - 16,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FutureBuilder(
                          future: manager.currentReceivingAddress,
                          builder: (BuildContext context,
                              AsyncSnapshot<String> currentAddress) {
                            if (currentAddress.connectionState ==
                                    ConnectionState.done &&
                                currentAddress.data != null) {
                              return Center(
                                child: PrettyQr(
                                  data: "firo:" + currentAddress.data,
                                  roundEdges: CampfireConstants.roundedQrCode,
                                  elementColor: CFColors.starryNight,
                                  typeNumber: 4,
                                  size: qrSize,
                                ),
                              );
                            } else {
                              return Container(
                                height: qrSize,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                          },
                        ),
                        SizedBox(
                          height: 40,
                        ),
                        FutureBuilder(
                          future: manager.currentReceivingAddress,
                          builder: (BuildContext context,
                              AsyncSnapshot<String> address) {
                            if (address.connectionState ==
                                    ConnectionState.done &&
                                address.data != null) {
                              return Container(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: CFColors.fog,
                                        borderRadius: BorderRadius.circular(
                                            SizingUtilities
                                                .circularBorderRadius),
                                        boxShadow: [
                                          CFColors.standardBoxShadow,
                                        ],
                                      ),
                                      child: MaterialButton(
                                        key: Key(
                                            "receiveViewAddressCopyButtonKey"),
                                        padding: EdgeInsets.all(16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              SizingUtilities
                                                  .circularBorderRadius),
                                        ),
                                        onPressed: () {
                                          clipboard.setData(ClipboardData(
                                              text: address.data));
                                          OverlayNotification.showInfo(
                                            context,
                                            "Copied to clipboard",
                                            Duration(seconds: 2),
                                          );
                                        },
                                        child: Center(
                                          child: Text(
                                            address.data,
                                            style: GoogleFonts.workSans(
                                              color: CFColors.midnight,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              letterSpacing: 0.25,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 12,
                                    ),
                                    Text(
                                      "TAP ADDRESS TO COPY",
                                      style: GoogleFonts.workSans(
                                        color: CFColors.dew,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.25,
                                      ),
                                    )
                                  ],
                                ),
                              );
                            } else {
                              return Container();
                            }
                          },
                        ),
                        SizedBox(
                          height: 24,
                        ),
                        SizedBox(
                          height: SizingUtilities.standardButtonHeight,
                          width: double.infinity,
                          child: SimpleButton(
                            key: Key("receiveViewMoreOptionsButtonKey"),
                            color: _showMoreOptions
                                ? CFColors.mist
                                : CFColors.white,
                            onTap: () async {
                              _locale =
                                  (await Devicelocale.currentLocale) ?? _locale;
                              setState(() {
                                _showMoreOptions = !_showMoreOptions;
                              });
                            },
                            // child: _buildOptionsButtonText(),
                            child: Text(
                              "MORE OPTIONS",
                              // style: moreOptionsStyle,
                              style: CFTextStyles.button.copyWith(
                                color: _showMoreOptions
                                    ? CFColors.dusk.withOpacity(0.5)
                                    : CFColors.dusk,
                              ),
                            ),
                          ),
                        ),
                        if (_showMoreOptions)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 16,
                              bottom: 8,
                            ),
                            child: Text(
                              "Amount (optional)",
                              style: CFTextStyles.label,
                            ),
                          ),
                        if (_showMoreOptions)
                          TextField(
                            key: Key("receiveViewCryptoFieldKey"),
                            style: GoogleFonts.workSans(
                              color: CFColors.dusk,
                            ),
                            controller: cryptoAmountController,
                            keyboardType: TextInputType.numberWithOptions(
                                signed: false, decimal: true),
                            inputFormatters: [
                              // regex to validate a crypto amount with 8 decimal places
                              TextInputFormatter.withFunction((oldValue,
                                      newValue) =>
                                  RegExp(r'^([0-9]*[,.]?[0-9]{0,8}|[,.][0-9]{0,8})$')
                                          .hasMatch(newValue.text)
                                      ? newValue
                                      : oldValue),
                              LengthLimitingTextInputFormatter(18),
                            ],
                            decoration: InputDecoration(
                              fillColor: CFColors.fog,
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.only(
                                left: 16,
                                top: 14,
                                bottom: 12,
                                right: 16,
                              ),
                              // ticker suffix
                              suffixIcon: UnconstrainedBox(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: Text(
                                    Provider.of<Manager>(context, listen: false)
                                        .coinTicker,
                                    style: CFTextStyles.textFieldSuffix,
                                  ),
                                ),
                              ),
                              hintText: Utilities.localizedStringAsFixed(
                                value: Decimal.zero,
                                locale: _locale,
                                decimalPlaces: 2,
                              ),
                              hintStyle: CFTextStyles.textFieldHint,
                            ),
                          ),
                        if (_showMoreOptions)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 12,
                              bottom: 8,
                            ),
                            child: Text(
                              "Note (optional)",
                              style: CFTextStyles.label,
                            ),
                          ),
                        if (_showMoreOptions)
                          TextField(
                            key: Key("receiveViewNoteFieldKey"),
                            style: GoogleFonts.workSans(
                              color: CFColors.dusk,
                            ),
                            controller: noteTextController,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(100),
                            ],
                            decoration: InputDecoration(
                              fillColor: CFColors.fog,
                              border: OutlineInputBorder(),
                              hintText: "Type something...",
                              hintStyle: CFTextStyles.textFieldHint,
                            ),
                          ),
                        if (_showMoreOptions) Spacer(),
                        if (_showMoreOptions)
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: SizedBox(
                              height: SizingUtilities.standardButtonHeight,
                              child: GradientButton(
                                onTap: () async {
                                  final amountString =
                                      cryptoAmountController.text;
                                  final noteString = noteTextController.text;
                                  final currentAddress =
                                      await manager.currentReceivingAddress;
                                  final ticker = manager.coinTicker;

                                  Map<String, String> params = {};

                                  if (amountString.isNotEmpty) {
                                    // check for comma decimal separator
                                    if (amountString.contains(",")) {
                                      params["amount"] =
                                          amountString.replaceFirst(",", ".");
                                    } else {
                                      params["amount"] = amountString;
                                    }
                                  }

                                  if (noteString.isNotEmpty) {
                                    params["message"] = noteString;
                                  }

                                  final uriString =
                                      AddressUtils.buildFiroUriString(
                                    currentAddress,
                                    params,
                                  );

                                  showDialog(
                                    useSafeArea: false,
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (_) => ModalPopupDialog(
                                      child: SingleChildScrollView(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 32,
                                          horizontal: 24,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Scan this QR Code",
                                              style: CFTextStyles.pinkHeader
                                                  .copyWith(fontSize: 16),
                                            ),
                                            SizedBox(
                                              height: 12,
                                              width: double.infinity,
                                            ),
                                            Text(
                                              "Receive $amountString $ticker",
                                              style: GoogleFonts.workSans(
                                                color: CFColors.dusk,
                                                fontWeight: FontWeight.w400,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              "for \"$noteString\"",
                                              style: GoogleFonts.workSans(
                                                color: CFColors.dusk,
                                                fontWeight: FontWeight.w400,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 16),
                                              child: Container(
                                                height: qrSize * 0.99,
                                                width: qrSize * 0.99,
                                                color: CFColors.white,
                                                child: Material(
                                                  color: CFColors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius
                                                        .circular(SizingUtilities
                                                            .circularBorderRadius),
                                                    side: BorderSide(
                                                      color: CFColors.smoke,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: PrettyQr(
                                                      key: Key(
                                                          "receiveViewGeneratedQrCodeKey"),
                                                      data: uriString,
                                                      roundEdges:
                                                          CampfireConstants
                                                              .roundedQrCode,
                                                      elementColor:
                                                          CFColors.starryNight,
                                                      typeNumber: 9,
                                                      size: qrSize * 0.9,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              height: SizingUtilities
                                                  .standardButtonHeight,
                                              width: 128,
                                              child: SimpleButton(
                                                key: Key(
                                                    "receiveViewGeneratedQrPopupOkButtonKey"),
                                                child: FittedBox(
                                                  child: Text(
                                                    "OK",
                                                    style: CFTextStyles.button
                                                        .copyWith(
                                                      color: CFColors.dusk,
                                                    ),
                                                  ),
                                                ),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  "GENERATE QR CODE",
                                  style: CFTextStyles.button,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
