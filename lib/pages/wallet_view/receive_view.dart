import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/notifications/overlay_notification.dart';
import 'package:paymint/services/bitcoin_service.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:provider/provider.dart';

class ReceiveView extends StatefulWidget {
  ReceiveView({Key key}) : super(key: key);

  @override
  _ReceiveViewState createState() => _ReceiveViewState();
}

class _ReceiveViewState extends State<ReceiveView> {
  @override
  Widget build(BuildContext context) {
    final BitcoinService bitcoinService = Provider.of<BitcoinService>(context);
    bool roundQr = true;
    final qrSize = MediaQuery.of(context).size.width / 2;

    return SafeArea(
      child: Scaffold(
        backgroundColor: CFColors.white,
        body: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              height: 32,
            ),
            FutureBuilder(
              future: bitcoinService.currentReceivingAddress,
              builder:
                  (BuildContext context, AsyncSnapshot<String> currentAddress) {
                if (currentAddress.connectionState == ConnectionState.done) {
                  return Center(
                    child: PrettyQr(
                      data: currentAddress.data,
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
              future: bitcoinService.currentReceivingAddress,
              builder: (BuildContext context, AsyncSnapshot<String> address) {
                if (address.connectionState == ConnectionState.done) {
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
                                Clipboard.setData(
                                    new ClipboardData(text: address.data));
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
                  // return ListTile(
                  //   title: Text(
                  //     'Address:',
                  //     style: TextStyle(color: Colors.black),
                  //   ),
                  //   trailing: Text(
                  //     condenseAdress(address.data),
                  //     style: TextStyle(color: Colors.black),
                  //   ),
                  //   onTap: () {},
                  // );
                } else {
                  return Container();
                }
              },
            ),
            // FutureBuilder(
            //   future: bitcoinService.currentReceivingAddress,
            //   builder: (BuildContext context, AsyncSnapshot snapshot) {
            //     if (snapshot.connectionState == ConnectionState.done) {
            //       return ListTile(
            //         title: Text(
            //           'Copy address to clipboard',
            //           style: TextStyle(color: Colors.cyanAccent),
            //         ),
            //         onTap: () {
            //           Clipboard.setData(new ClipboardData(text: snapshot.data));
            //           Toast.show(
            //             'Address copied to clipboard',
            //             context,
            //             duration: Toast.LENGTH_LONG,
            //             gravity: Toast.BOTTOM,
            //           );
            //         },
            //       );
            //     } else {
            //       return ListTile(
            //         title: Text(
            //           'Copy address to clipboard',
            //           style: TextStyle(color: Colors.cyanAccent),
            //         ),
            //       );
            //     }
            //   },
            // ),
            // FutureBuilder(
            //   future: bitcoinService.currentReceivingAddress,
            //   builder: (BuildContext context, AsyncSnapshot snapshot) {
            //     if (snapshot.connectionState == ConnectionState.done) {
            //       return ListTile(
            //         title: Text(
            //           'Share address',
            //           style: TextStyle(color: Colors.cyanAccent),
            //         ),
            //         onTap: () {
            //           Share.share(snapshot.data);
            //         },
            //       );
            //     } else {
            //       return ListTile(
            //         title: Text(
            //           'Share address',
            //           style: TextStyle(color: Colors.cyanAccent),
            //         ),
            //       );
            //     }
            //   },
            // ),
            // ListTile(
            //   title: Text(
            //     'View previous addresses',
            //     style: TextStyle(color: Colors.cyanAccent),
            //   ),
            //   trailing: Icon(
            //     Icons.chevron_right,
            //     color: Colors.cyanAccent,
            //   ),
            //   onTap: () {
            //     Navigator.pushNamed(context, '/receivingaddressbook');
            //   },
            // ),
            // SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// Receive View helper functions

String condenseAdress(String address) {
  return address.substring(0, 5) +
      '...' +
      address.substring(address.length - 5);
}
