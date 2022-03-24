import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/notifications/overlay_notification.dart';
import 'package:paymint/services/wallets_service.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:paymint/widgets/custom_pin_put/custom_pin_put.dart';
import 'package:provider/provider.dart';

class ChangePinView extends StatefulWidget {
  const ChangePinView({Key key}) : super(key: key);

  @override
  _ChangePinViewState createState() => _ChangePinViewState();
}

class _ChangePinViewState extends State<ChangePinView> {
  BoxDecoration get _pinPutDecoration {
    return BoxDecoration(
      color: CFColors.fog,
      border: Border.all(width: 1, color: CFColors.smoke),
      borderRadius: BorderRadius.circular(6),
    );
  }

  PageController _pageController =
      PageController(initialPage: 0, keepPage: true);

  // Attributes for Page 1 of the page view
  final TextEditingController _pinPutController1 = TextEditingController();
  final FocusNode _pinPutFocusNode1 = FocusNode();

  // Attributes for Page 2 of the page view
  final TextEditingController _pinPutController2 = TextEditingController();
  final FocusNode _pinPutFocusNode2 = FocusNode();

  @override
  Widget build(BuildContext context) {
    final walletService = Provider.of<WalletsService>(context, listen: false);
    return Scaffold(
      backgroundColor: CFColors.white,
      appBar: _buildAppBar(),
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        children: [
          // page 1
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.center,
                child: FittedBox(
                  child: FutureBuilder(
                    future: walletService.currentWalletName,
                    builder: (context, snapshot) {
                      String title = "...";
                      if (snapshot.connectionState == ConnectionState.done) {
                        title = snapshot.data;
                        return Text(
                          title,
                          style: CFTextStyles.pinkHeader,
                        );
                      } else {
                        return Text(
                          title,
                          style: CFTextStyles.pinkHeader,
                        );
                      }
                    },
                  ),
                ),
              ),
              SizedBox(
                height: 12,
              ),
              Align(
                alignment: Alignment.center,
                child: FittedBox(
                  child: Text(
                    "New PIN",
                    style: CFTextStyles.body,
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
                focusNode: _pinPutFocusNode1,
                controller: _pinPutController1,
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
                onSubmit: (String pin) {
                  _pageController.nextPage(
                    duration: Duration(milliseconds: 100),
                    curve: Curves.linear,
                  );
                },
              ),
            ],
          ),

          // page 2

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.center,
                child: FittedBox(
                  child: FutureBuilder(
                    future: walletService.currentWalletName,
                    builder: (context, snapshot) {
                      String title = "...";
                      if (snapshot.connectionState == ConnectionState.done) {
                        title = snapshot.data;
                        return Text(
                          title,
                          style: CFTextStyles.pinkHeader,
                        );
                      } else {
                        return Text(
                          title,
                          style: CFTextStyles.pinkHeader,
                        );
                      }
                    },
                  ),
                ),
              ),
              SizedBox(
                height: 12,
              ),
              Align(
                alignment: Alignment.center,
                child: FittedBox(
                  child: Text(
                    "Confirm new PIN",
                    style: CFTextStyles.body,
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
                focusNode: _pinPutFocusNode2,
                controller: _pinPutController2,
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
                  if (_pinPutController1.text == _pinPutController2.text) {
                    final store = new FlutterSecureStorage();
                    final walletName = await walletService.currentWalletName;
                    final id = await walletService.getWalletId(walletName);

                    // This should never fail as we are overwriting the existing pin
                    assert((await store.read(key: "${id}_pin")) != null);
                    await store.write(key: "${id}_pin", value: pin);

                    OverlayNotification.showSuccess(
                      context,
                      "New PIN is set up",
                      Duration(milliseconds: 2000),
                    );

                    await Future.delayed(Duration(milliseconds: 100));

                    Navigator.of(context).pop();
                  } else {
                    _pageController.animateTo(
                      0,
                      duration: Duration(milliseconds: 100),
                      curve: Curves.linear,
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
            ],
          ),
        ],
      ),
    );
  }

  _buildAppBar() {
    return AppBar(
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
    );
  }
}
