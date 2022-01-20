import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:paymint/notifications/overlay_notification.dart';
import 'package:paymint/services/bitcoin_service.dart';
import 'package:paymint/services/wallets_service.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:paymint/widgets/custom_pin_put/custom_pin_put.dart';
import 'package:provider/provider.dart';

class Lockscreen2View extends StatefulWidget {
  final String routeOnSuccess;

  const Lockscreen2View({Key key, @required this.routeOnSuccess})
      : super(key: key);
  @override
  _Lockscreen2ViewState createState() => _Lockscreen2ViewState();
}

class _Lockscreen2ViewState extends State<Lockscreen2View> {
  _checkUseBiometrics() async {
    final bitcoinService = Provider.of<BitcoinService>(context, listen: false);
    final bool useBiometrics = await bitcoinService.useBiometrics;
    final LocalAuthentication localAuth = LocalAuthentication();

    final canCheckBiometrics = await localAuth.canCheckBiometrics;
    final isDeviceSupported = await localAuth.isDeviceSupported();

    // If useBiometrics is enabled, then show fingerprint auth screen
    if (useBiometrics != null &&
        useBiometrics &&
        canCheckBiometrics &&
        isDeviceSupported) {
      List<BiometricType> availableSystems =
          await localAuth.getAvailableBiometrics();

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
            stickyAuth: true,
          );

          if (didAuthenticate)
            Navigator.pushReplacementNamed(context, widget.routeOnSuccess);
        }
      }
    }
  }

  @override
  void initState() {
    // show system status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        // statusBarBrightness: Brightness.dark,
      ),
    );
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
    final WalletsService walletsService = Provider.of<WalletsService>(context);

    return Scaffold(
      backgroundColor: CFColors.white,
      appBar: AppBar(
        backgroundColor: CFColors.white,
        leadingWidth: 36.0 + 20.0, // account for 20 padding

        leading: Padding(
          padding: EdgeInsets.only(
            top: 10,
            bottom: 10,
            left: 20,
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: AppBarIconButton(
              size: 36,
              onPressed: () {
                Navigator.pop(context);
              },
              circularBorderRadius: 8,
              icon: SvgPicture.asset(
                "assets/svg/chevronLeft.svg",
                color: CFColors.twilight,
                width: 24,
                height: 24,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          // crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: FutureBuilder(
                future: walletsService.currentWalletName,
                builder: (
                  BuildContext context,
                  AsyncSnapshot<String> snapshot,
                ) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot == null ||
                        snapshot.hasError ||
                        snapshot.data == null ||
                        snapshot.data.isEmpty) {
                      // TODO: display error notification?
                      return FittedBox(
                        child: Text(
                          "failed to load wallet",
                          style: GoogleFonts.workSans(
                            color: CFColors.spark,
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                          ),
                        ),
                      );
                    }
                    return FittedBox(
                      child: Text(
                        snapshot.data,
                        style: GoogleFonts.workSans(
                          color: CFColors.spark,
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                        ),
                      ),
                    );
                  } else {
                    return CircularProgressIndicator(
                      color: CFColors.spark,
                      strokeWidth: 2,
                    );
                  }
                },
              ),
            ),
            SizedBox(height: 12),
            Center(
              child: FittedBox(
                child: Text(
                  'Enter PIN',
                  style: GoogleFonts.workSans(
                    color: CFColors.dusk,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            SizedBox(height: 48),
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
              obscureText: "",
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
                color: CFColors.spark,
                border: Border.all(width: 1, color: CFColors.spark),
              ),
              selectedFieldDecoration: _pinPutDecoration,
              followingFieldDecoration: _pinPutDecoration,
              onSubmit: (String pin) async {
                final store = new FlutterSecureStorage();

                final walletName = await walletsService.currentWalletName;
                final id = await walletsService.getWalletId(walletName);
                final storedPin = await store.read(key: '${id}_pin');

                if (storedPin == pin) {
                  OverlayNotification.showSuccess(
                    context,
                    "PIN code correct. Unlocking wallet...",
                    Duration(milliseconds: 2200),
                  );

                  await Future.delayed(Duration(milliseconds: 600));

                  Navigator.pushReplacementNamed(
                      context, widget.routeOnSuccess);
                } else {
                  OverlayNotification.showError(
                    context,
                    'Incorrect PIN. Please try again',
                    Duration(milliseconds: 1500),
                  );

                  await Future.delayed(Duration(milliseconds: 100));

                  _pinTextController.text = '';
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
