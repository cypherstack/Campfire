import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/pages/onboarding_view/helpers/create_wallet_type.dart';
import 'package:paymint/pages/onboarding_view/terms_and_conditions_view.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:paymint/widgets/custom_buttons/simple_button.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({Key key}) : super(key: key);

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
                          style: CFTextStyles.gradientButton,
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
                          style: CFTextStyles.gradientButton,
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
