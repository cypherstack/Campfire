import 'dart:io';

import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:paymint/notifications/overlay_notification.dart';
import 'package:paymint/pages/onboarding_view/helpers/builders.dart';
import 'package:paymint/pages/onboarding_view/restore_wallet_view.dart';
import 'package:paymint/services/bitcoin_service.dart';
import 'package:paymint/services/wallets_service.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_pin_put/custom_pin_put.dart';
import 'package:provider/provider.dart';

import 'backup_key_warning_view.dart';
import 'helpers/create_wallet_type.dart';

class CreatePinView extends StatefulWidget {
  const CreatePinView({Key key, @required this.type, @required this.walletName})
      : super(key: key);

  final CreateWalletType type;
  final String walletName;

  @override
  _CreatePinViewState createState() => _CreatePinViewState();
}

class _CreatePinViewState extends State<CreatePinView> {
  BoxDecoration get _pinPutDecoration {
    return BoxDecoration(
      color: CFColors.fog,
      border: Border.all(width: 1, color: CFColors.smoke),
      borderRadius: BorderRadius.circular(6),
    );
  }

  PageController _pageController = PageController(initialPage: 0, keepPage: true);

  // Attributes for Page 1 of the pageview
  final TextEditingController _pinPutController1 = TextEditingController();
  final FocusNode _pinPutFocusNode1 = FocusNode();

  // Attributes for Page 2 of the pageview
  final TextEditingController _pinPutController2 = TextEditingController();
  final FocusNode _pinPutFocusNode2 = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: CFColors.starryNight,
        appBar: buildOnboardingAppBar(context),
        body: PageView(
          controller: _pageController,
          physics: NeverScrollableScrollPhysics(),
          children: [
            // page 1
            buildOnboardingBody(
              context,
              Container(
                height: MediaQuery.of(context).size.height -
                    SizingUtilities.getStatusBarHeight(context) -
                    80, // 80 is height of onboarding appbar
                child: Column(
                  children: [
                    SizedBox(
                      height: 40,
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: FittedBox(
                        child: Text(
                          "Create a PIN",
                          style: CFTextStyles.pinkHeader,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 28,
                    ),
                    Expanded(
                      child: CustomPinPut(
                        fieldsCount: 4,
                        eachFieldHeight: 12,
                        eachFieldWidth: 12,
                        textStyle: GoogleFonts.workSans(
                          fontSize: 1,
                        ),
                        focusNode: _pinPutFocusNode1,
                        controller: _pinPutController1,
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
                        onSubmit: (String pin) {
                          _pageController.nextPage(
                            duration: Duration(milliseconds: 500),
                            curve: Curves.bounceIn,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // page 2
            buildOnboardingBody(
              context,
              Container(
                height: MediaQuery.of(context).size.height -
                    SizingUtilities.getStatusBarHeight(context) -
                    80, // 80 is height of onboarding appbar
                child: Column(
                  children: [
                    SizedBox(
                      height: 40,
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: FittedBox(
                        child: Text(
                          "Confirm PIN",
                          style: CFTextStyles.pinkHeader,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 28,
                    ),
                    Expanded(
                      child: CustomPinPut(
                        fieldsCount: 4,
                        eachFieldHeight: 12,
                        eachFieldWidth: 12,
                        textStyle: GoogleFonts.workSans(
                          fontSize: 1,
                        ),
                        focusNode: _pinPutFocusNode2,
                        controller: _pinPutController2,
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
                          if (_pinPutController1.text == _pinPutController2.text) {
                            // ask if want to use biometrics
                            final bool useBiometrics = await _enableBiometricsDialog();

                            // handle wallet creation/initialization

                            final walletService =
                                Provider.of<WalletsService>(context, listen: false);
                            final store = new FlutterSecureStorage();

                            await walletService.addNewWalletName(widget.walletName);
                            final id = await walletService.getWalletId(widget.walletName);
                            await store.write(key: "${id}_pin", value: pin);

                            if (widget.type == CreateWalletType.NEW) {
                              final bitcoinService =
                                  Provider.of<BitcoinService>(context, listen: false);

                              // need to pop another screen in appbar button if the below is uncommented

                              // TODO replace this with something else
                              showModal(
                                context: context,
                                configuration: FadeScaleTransitionConfiguration(
                                    barrierDismissible: false),
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: CFColors.white,
                                    title: Row(
                                      children: <Widget>[
                                        SpinKitThreeBounce(
                                          color: CFColors.spark,
                                          size: 30,
                                        )
                                        // SizedBox(width: 16),
                                        // Text('Please do not exit',
                                        //     style: TextStyle(color: Colors.white)),
                                      ],
                                    ),
                                    content: Text(
                                      "Generating Backup Key",
                                      style: TextStyle(color: CFColors.spark),
                                    ),
                                  );
                                },
                              );

                              // TODO do this differently - causes short lockup of UI
                              await bitcoinService.initializeWallet(widget.walletName);
                              await bitcoinService.updateBiometricsUsage(useBiometrics);
                              await Future.delayed(Duration(seconds: 3));

                              Navigator.pop(context);
                            }

                            // String message;
                            Widget nextView;

                            switch (widget.type) {
                              // push restore wallet page
                              case CreateWalletType.RESTORE:
                                // message = "PIN code successfully set";
                                nextView =
                                    RestoreWalletFormView(walletName: widget.walletName);

                                break;

                              // push new wallet page
                              case CreateWalletType.NEW:
                                // message = "PIN code successfully set";
                                nextView =
                                    BackupKeyWarningView(walletName: widget.walletName);

                                break;
                            }

                            // OverlayNotification.showSuccess(
                            //   context,
                            //   message,
                            //   Duration(milliseconds: 2000),
                            // );

                            await Future.delayed(Duration(milliseconds: 700));

                            Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (context) {
                                  return nextView;
                                },
                              ),
                            );
                          } else {
                            _pageController.animateTo(
                              0,
                              duration: Duration(milliseconds: 500),
                              curve: Curves.bounceOut,
                            );

                            OverlayNotification.showError(
                              context,
                              "PIN codes do not match. Try again.",
                              Duration(milliseconds: 1500),
                            );

                            _pinPutController1.text = '';
                            _pinPutController2.text = '';
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ));
  }

  Future<bool> _enableBiometricsDialog() async {
    final LocalAuthentication localAuth = LocalAuthentication();

    bool canCheckBiometrics = await localAuth.canCheckBiometrics;

    if (canCheckBiometrics) {
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
            localizedReason: 'Enable fingerprint authentication',
          );

          if (didAuthenticate) {
            return true;
          }
        }
      }
    }
    return false;
  }
}
