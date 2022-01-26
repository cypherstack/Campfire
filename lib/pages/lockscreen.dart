import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/notifications/overlay_notification.dart';
import 'package:paymint/pages/wallet_selection_view.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/services/wallets_service.dart';
import 'package:paymint/utilities/biometrics.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:paymint/widgets/custom_pin_put/custom_pin_put.dart';
import 'package:provider/provider.dart';

class LockscreenView extends StatefulWidget {
  @override
  _LockscreenViewState createState() => _LockscreenViewState();
}

class _LockscreenViewState extends State<LockscreenView> {
  _checkUseBiometrics() async {
    final manager = Provider.of<Manager>(context, listen: false);

    if (await manager.useBiometrics &&
        await Biometrics.authenticate(
          title: manager.walletName,
          localizedReason: "Unlock wallet",
          cancelButtonText: "CANCEL",
        )) {
      Navigator.pushReplacementNamed(context, '/mainview');
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
        actions: [
          Padding(
            padding: EdgeInsets.only(
              top: 10,
              bottom: 10,
              right: 20,
            ),
            child: AspectRatio(
              aspectRatio: 1,
              child: AppBarIconButton(
                size: 36,
                icon: SvgPicture.asset(
                  "assets/svg/log-out.svg",
                  color: CFColors.twilight,
                ),
                circularBorderRadius: SizingUtilities.circularBorderRadius,
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    CupertinoPageRoute(
                      builder: (_) {
                        return WalletSelectionView();
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                    //TODO: change the loading display?
                    return SpinKitThreeBounce(
                      color: CFColors.spark,
                      size: 20,
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
                    Duration(milliseconds: 1200),
                  );

                  await Future.delayed(Duration(milliseconds: 600));

                  Navigator.pushReplacementNamed(context, '/mainview');
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
