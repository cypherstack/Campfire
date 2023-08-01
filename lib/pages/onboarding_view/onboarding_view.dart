import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:paymint/notifications/campfire_alert.dart';
import 'package:paymint/pages/onboarding_view/helpers/create_wallet_type.dart';
import 'package:paymint/pages/onboarding_view/terms_and_conditions_view.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/misc_global_constants.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:paymint/widgets/custom_buttons/simple_button.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({Key key}) : super(key: key);

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  @override
  void initState() {
    if (!CampfireConstants.sunsettingWarningShownNonConstant) {
      CampfireConstants.sunsettingWarningShownNonConstant = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        Hive.openBox('wallets')
            .then((box) => box.put("sunsettingWarningShown", true));
        await showDialog<void>(
          useSafeArea: false,
          barrierDismissible: false,
          context: context,
          builder: (_) => CampfireAlert(
            message:
                "We're sunsetting Campfire. We recommend moving funds to another "
                "Firo Wallet, like Stack Wallet. Campfire will be remade in the "
                "coming months after Spark with a brand new shiny codebase.",
          ),
        );
      });
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: CFColors.starryNight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image(
                    image: AssetImage("assets/images/splash.png"),
                    width: MediaQuery.of(context).size.width * 0.5,
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  FittedBox(
                    child: Text(
                      "Pay the world with Firo.",
                      style: GoogleFonts.workSans(
                        color: CFColors.mist,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.15,
                vertical: MediaQuery.of(context).size.height * 0.08,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 48,
                    width: MediaQuery.of(context).size.width - 40,
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
                      shadows: [],
                      child: FittedBox(
                        child: Text(
                          "CREATE NEW WALLET",
                          style: CFTextStyles.button,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  SizedBox(
                    height: 48,
                    width: MediaQuery.of(context).size.width - 40,
                    child: SimpleButton(
                      shadows: [],
                      color: Colors.transparent,
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            // settings: RouteSettings(name: "/onboardingview"),
                            builder: (_) => TermsAndConditionsView(
                              type: CreateWalletType.RESTORE,
                            ),
                          ),
                        );
                      },
                      child: FittedBox(
                        child: Text(
                          "RESTORE WALLET",
                          style: CFTextStyles.button,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
