import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/notifications/overlay_notification.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/clipboard_interface.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
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
  bool roundQr = true;
  ClipboardInterface clipboard;

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

    return Container(
      color: CFColors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FutureBuilder(
            future: manager.currentReceivingAddress,
            builder:
                (BuildContext context, AsyncSnapshot<String> currentAddress) {
              if (currentAddress.connectionState == ConnectionState.done &&
                  currentAddress.data != null) {
                return Center(
                  child: PrettyQr(
                    data: "firo:" + currentAddress.data,
                    roundEdges: roundQr,
                    elementColor: CFColors.starryNight,
                    typeNumber: 4,
                    size: qrSize,
                  ),
                );
              } else {
                return Container(
                    height: qrSize,
                    child: Center(child: CircularProgressIndicator()));
              }
            },
          ),
          SizedBox(
            height: 40,
          ),
          FutureBuilder(
            future: manager.currentReceivingAddress,
            builder: (BuildContext context, AsyncSnapshot<String> address) {
              if (address.connectionState == ConnectionState.done &&
                  address.data != null) {
                return Container(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: CFColors.fog,
                            borderRadius: BorderRadius.circular(
                                SizingUtilities.circularBorderRadius),
                            boxShadow: [
                              CFColors.standardBoxShadow,
                            ],
                          ),
                          child: MaterialButton(
                            padding: EdgeInsets.all(18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  SizingUtilities.circularBorderRadius),
                            ),
                            onPressed: () {
                              clipboard
                                  .setData(ClipboardData(text: address.data));
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
                  ),
                );
              } else {
                return Container();
              }
            },
          ),
        ],
      ),
    );
  }
}
