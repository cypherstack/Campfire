import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:paymint/notifications/overlay_notification.dart';
import 'package:paymint/services/bitcoin_service.dart';
import 'package:paymint/services/wallets_service.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/widgets/custom_pin_put/custom_pin_put.dart';
import 'package:provider/provider.dart';

class ConfirmSendView extends StatefulWidget {
  const ConfirmSendView({
    Key key,
    @required this.address,
    @required this.note,
    @required this.amount,
    @required this.fee,
  }) : super(key: key);

  final String address;
  final String note;
  final double amount;
  final double fee;

  @override
  _ConfirmSendViewState createState() => _ConfirmSendViewState();
}

class _ConfirmSendViewState extends State<ConfirmSendView> {
  _checkUseBiometrics() async {
    final bitcoinService = Provider.of<BitcoinService>(context, listen: false);
    final bool useBiometrics = await bitcoinService.useBiometrics;
    final LocalAuthentication localAuth = LocalAuthentication();

    bool canCheckBiometrics = await localAuth.canCheckBiometrics;

    // If useBiometrics is enabled, then show fingerprint auth screen
    if (useBiometrics != null && useBiometrics && canCheckBiometrics) {
      List<BiometricType> availableSystems = await localAuth.getAvailableBiometrics();

      //TODO implement iOS biometrics
      if (Platform.isIOS) {
        if (availableSystems.contains(BiometricType.face)) {
          // Write iOS specific code when required
        } else if (availableSystems.contains(BiometricType.fingerprint)) {
          // Write iOS specific code when required
        }
      } else if (Platform.isAndroid) {
        if (availableSystems.contains(BiometricType.fingerprint)) {
          bool didAuthenticate = await localAuth.authenticateWithBiometrics(
            localizedReason: 'Please authenticate to unlock wallet',
          );

          if (didAuthenticate) Navigator.pushReplacementNamed(context, '/mainview');
        }
      }
    }
  }

  @override
  void initState() {
    _checkUseBiometrics();
    super.initState();
  }

  BoxDecoration get _pinPutDecoration {
    return BoxDecoration(
      color: CFColors.fog,
      border: Border.all(width: 1, color: CFColors.smoke),
      borderRadius: BorderRadius.circular(6),
    );
  }

  final _pinTextController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    // final WalletsService walletsService = Provider.of<WalletsService>(context);

    return Container(
      height: MediaQuery.of(context).size.height,
      color: CFColors.midnight.withOpacity(0.8),
      child: Column(
        children: [
          // Spacer(),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          ),
          Material(
            color: CFColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(SizingUtilities.circularBorderRadius * 2),
                topRight: Radius.circular(SizingUtilities.circularBorderRadius * 2),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 43,
                ),
                Center(
                  child: FittedBox(
                    child: Text(
                      "Confirm transaction",
                      style: GoogleFonts.workSans(
                        color: CFColors.spark,
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                Center(
                  child: FittedBox(
                    child: Text(
                      "Enter PIN",
                      style: GoogleFonts.workSans(
                        color: CFColors.dusk,
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        letterSpacing: 0.25,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 28,
                ),
                CustomPinPut(
                  fieldsCount: 4,
                  eachFieldHeight: 12,
                  eachFieldWidth: 12,
                  textStyle: GoogleFonts.workSans(
                    fontSize: 1,
                  ),
                  focusNode: _pinFocusNode,
                  controller: _pinTextController,
                  useNativeKeyboard: false,
                  inputDecoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    fillColor: CFColors.white,
                    counterText: "",
                  ),
                  submittedFieldDecoration: _pinPutDecoration.copyWith(
                    color: CFColors.smoke,
                  ),
                  selectedFieldDecoration: _pinPutDecoration,
                  followingFieldDecoration: _pinPutDecoration,
                  onSubmit: (String pin) async {
                    final BitcoinService bitcoinService =
                        Provider.of<BitcoinService>(context, listen: false);
                    final walletsService =
                        Provider.of<WalletsService>(context, listen: false);

                    final store = new FlutterSecureStorage();

                    final walletName = await bitcoinService.currentWalletName;
                    final id = await walletsService.getWalletId(walletName);
                    final storedPin = await store.read(key: '${id}_pin');

                    if (storedPin == pin) {
                      final rawAmount = (widget.amount * 100000000).toInt();

                      print("rawAmount: $rawAmount");
                      print("widget.fee: ${widget.fee}");
                      print("widget.address: ${widget.address}");

                      // The following call throws an invalid argument exception
                      // on invalid address instead of returning an error int
                      // TODO: validate address
                      dynamic txHexOrError = await bitcoinService.coinSelection(
                        rawAmount,
                        widget.fee,
                        widget.address,
                      );
                      print("txHexOrError $txHexOrError");

                      if (txHexOrError is int) {
                        // Here, we assume that transaction crafting returned an error
                        if (txHexOrError == 1) {
                          //TODO: handle send transaction errors
                          print("Insufficient balance!");
                          // Navigator.pop(context);
                          // showModal(
                          //   context: context,
                          //   configuration: FadeScaleTransitionConfiguration(),
                          //   builder: (BuildContext context) {
                          //     return notEnoughBalanceDialog(context);
                          //   },
                          // );
                        } else if (txHexOrError == 2) {
                          print("Insufficient funds to pay for tx fee");
                          // Navigator.pop(context);
                          // showModal(
                          //   context: context,
                          //   configuration: FadeScaleTransitionConfiguration(),
                          //   builder: (BuildContext context) {
                          //     return notEnoughForFeesDialog(context);
                          //   },
                          // );
                        }
                      } else {
                        print(txHexOrError.toString());

                        await bitcoinService
                            .submitHexToNetwork(txHexOrError['hex'])
                            .then((booleanResponse) async {
                          if (booleanResponse == true) {
                            OverlayNotification.showSuccess(
                              context,
                              "Transaction sent",
                              Duration(milliseconds: 2700),
                            );
                            await Future.delayed(Duration(milliseconds: 700))
                                .then((value) {
                              bitcoinService.refreshWalletData();
                              Navigator.pop(context);
                            });
                          } else {
                            OverlayNotification.showError(
                              context,
                              "Transaction failed. See logs.",
                              Duration(milliseconds: 1500),
                            );
                            await Future.delayed(Duration(milliseconds: 700))
                                .then((value) {
                              Navigator.pop(context);
                            });
                          }
                        });
                      }

                      // Navigator.pop(context);
                    } else {
                      OverlayNotification.showError(
                        context,
                        "Incorrect PIN. Transaction cancelled.",
                        Duration(milliseconds: 1500),
                      );

                      await Future.delayed(Duration(milliseconds: 500));
                      _pinTextController.text = '';
                    }
                  },
                ),
                SizedBox(
                  height: 74,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
