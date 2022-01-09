import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/services/wallets_service.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:paymint/widgets/custom_buttons/simple_button.dart';
import 'package:provider/provider.dart';

import 'lockscreen2.dart';
import 'onboarding_view/helpers/builders.dart';
import 'onboarding_view/helpers/create_wallet_type.dart';
import 'onboarding_view/terms_and_conditions_view.dart';

class WalletSelectionView extends StatefulWidget {
  const WalletSelectionView({Key key}) : super(key: key);

  @override
  _WalletSelectionViewState createState() => _WalletSelectionViewState();
}

class _WalletSelectionViewState extends State<WalletSelectionView> {
  @override
  void initState() {
    // show system status bar
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
    //     overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        // statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    super.initState();
  }
  //
  // @override
  // void dispose() {
  //   // hide system status bar
  //   SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
  //       overlays: [SystemUiOverlay.bottom]);
  //   super.dispose();
  // }

  _buildWalletsList(
    BuildContext context,
    AsyncSnapshot<List<String>> snapshot,
    WalletsService walletsService,
  ) {
    if (snapshot.data.length == 0) {
      return Center(
        child: Container(
          // TODO: ask designers for svg to be displayed here
          // this should never occur as there should be at least one
          // wallet when this is displayed
          child: Text(
            'No transactions found...',
            textScaleFactor: 1.1,
            style: TextStyle(color: CFColors.warning),
          ),
        ),
      );
    } else {
      return Container(
        padding: EdgeInsets.symmetric(
          vertical: 0,
          horizontal: 16,
        ),
        child: ListView.builder(
          itemCount: snapshot.data.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.all(
                SizingUtilities.listItemSpacing / 2,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: CFColors.white,
                  boxShadow: [
                    CFColors.standardBoxShadow,
                  ],
                  borderRadius:
                      BorderRadius.circular(SizingUtilities.circularBorderRadius),
                ),
                child: MaterialButton(
                  padding: EdgeInsets.only(
                    top: 12,
                    bottom: 12,
                    left: 16,
                    right: 8,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(SizingUtilities.circularBorderRadius),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        snapshot.data[index],
                        style: GoogleFonts.workSans(
                          color: CFColors.dusk,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      SvgPicture.asset(
                        "assets/svg/chevron-right.svg",
                        color: CFColors.dusk,
                      )
                    ],
                  ),
                  onPressed: () async {
                    await walletsService.setCurrentWalletName(snapshot.data[index]);
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (context) {
                          return Lockscreen2View(
                            routeOnSuccess: '/mainview',
                          );
                        },
                      ),
                    );
                    // Navigator.of(context).pushReplacement(
                    //   CupertinoPageRoute(
                    //     builder: (context) {
                    //       walletsService.setCurrentWalletName(snapshot.data[index]);
                    //       return LockscreenView();
                    //     },
                    //   ),
                    // );
                  },
                ),
              ),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final WalletsService walletsService = Provider.of<WalletsService>(context);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    return Scaffold(
        backgroundColor: CFColors.starryNight,
        body: Column(
          children: [
            SizedBox(
              height: 64,
            ),
            Center(
              child: Image(
                image: AssetImage(
                  "assets/images/splash.png",
                ),
                width: MediaQuery.of(context).size.width * 0.41,
              ),
            ),
            SizedBox(
              height: 32,
            ),
            Expanded(
              child: buildOnboardingBody(
                context,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 40,
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: FittedBox(
                        child: Text(
                          "Welcome",
                          style: CFTextStyles.pinkHeader,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 6,
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: FittedBox(
                        child: Text(
                          "Choose your wallet",
                          style: GoogleFonts.workSans(
                            color: CFColors.dusk,
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Expanded(
                      child: FutureBuilder(
                        future: walletsService.walletNames,
                        builder: (
                          BuildContext context,
                          AsyncSnapshot<List<String>> snapshot,
                        ) {
                          if (snapshot.connectionState == ConnectionState.done) {
                            return _buildWalletsList(context, snapshot, walletsService);
                          } else {
                            return CircularProgressIndicator(
                              color: CFColors.spark,
                              strokeWidth: 2,
                            );
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        height: 48,
                        child: GradientButton(
                          onTap: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (_) => TermsAndConditionsView(
                                  type: CreateWalletType.NEW,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            "CREATE NEW WALLET",
                            style: CFTextStyles.button,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        height: 48,
                        child: SimpleButton(
                          onTap: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (_) => TermsAndConditionsView(
                                  type: CreateWalletType.RESTORE,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            "RESTORE WALLET",
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
                    SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ));
  }
}
