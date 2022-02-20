import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/pages/onboarding_view/backup_key_view.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/services/wallets_service.dart';
import 'package:paymint/utilities/backup_key_warning.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:provider/provider.dart';

import 'helpers/builders.dart';
import 'onboarding_view.dart';

class BackupKeyWarningView extends StatefulWidget {
  const BackupKeyWarningView({Key key, @required this.walletName})
      : super(key: key);

  final String walletName;

  @override
  _BackupKeyWarningViewState createState() => _BackupKeyWarningViewState();
}

class _BackupKeyWarningViewState extends State<BackupKeyWarningView> {
  bool _checkboxIsChecked = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _onBackPressed();
        return true;
      },
      child: Scaffold(
        backgroundColor: CFColors.starryNight,
        appBar: buildOnboardingAppBar(
          context,
          backButtonPressed: _onBackPressed,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, "/mainview");
                },
                child: Text(
                  "SKIP",
                  style: CFTextStyles.button,
                ),
              ),
            ),
          ],
        ),
        body: buildOnboardingBody(
          context,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 40,
              ),
              Center(
                child: FittedBox(
                  child: Text(
                    "Backup Key",
                    style: CFTextStyles.pinkHeader,
                  ),
                ),
              ),
              _buildWarning(),
              _buildCheckBox(),
              _buildViewKeyButton(),
            ],
          ),
        ),
      ),
    );
  }

  _buildCheckBox() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: 16,
      ),
      child: Row(
        children: [
          Container(
            child: Checkbox(
              value: _checkboxIsChecked,
              onChanged: (newValue) {
                setState(() {
                  _checkboxIsChecked = newValue;
                });
                print("checkbox clicked. New value = $newValue");
              },
            ),
          ),
          Expanded(
            child: Text(
              "I understand that if I lose my backup key, I will not be able to access my funds.",
              style: GoogleFonts.workSans(
                color: CFColors.dusk,
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _buildViewKeyButton() {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: 20,
      ),
      child: SizedBox(
        height: 48,
        child: GradientButton(
          enabled: _checkboxIsChecked,
          onTap: () {
            if (_checkboxIsChecked) {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) {
                    return BackupKeyView();
                  },
                ),
              );
            }
          },
          child: FittedBox(
            child: Text(
              "VIEW BACKUP KEY",
              style: GoogleFonts.workSans(
                color: CFColors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  _buildWarning() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Material(
          color: CFColors.fog,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(SizingUtilities.circularBorderRadius),
            side: BorderSide(
              width: 1,
              color: CFColors.smoke,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 20,
            ),
            child: SingleChildScrollView(
              child: Text(
                BACKUP_KEY_WARNING,
                style: GoogleFonts.workSans(
                  color: CFColors.dusk,
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _onBackPressed() async {
    // delete created wallet name and pin
    final walletsService = Provider.of<WalletsService>(context, listen: false);
    int result = await walletsService.deleteWallet(widget.walletName);
    // set manager wallet to null if it isn't already
    Provider.of<Manager>(context, listen: false).currentWallet = null;

    print("delete result: $result");
    // check if last wallet was deleted
    if (result == 2) {
      Navigator.pushAndRemoveUntil(
        context,
        CupertinoPageRoute(
          maintainState: false,
          builder: (_) => OnboardingView(),
        ),
        (_) => false,
      );
    } else {
      // TODO pop back to multiple wallets view or go back to naming?
      final nav = Navigator.of(context);
      nav.pop();
      nav.pop();
    }
  }
}
