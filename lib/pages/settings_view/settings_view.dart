import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/notifications/modal_popup_dialog.dart';
import 'package:paymint/pages/address_book_view/address_book_view.dart';
import 'package:paymint/pages/lockscreen_view.dart';
import 'package:paymint/pages/settings_view/settings_subviews/about_view.dart';
import 'package:paymint/pages/settings_view/settings_subviews/currency_view.dart';
import 'package:paymint/pages/settings_view/settings_subviews/network_settings_view.dart';
import 'package:paymint/pages/settings_view/settings_subviews/wallet_settings_view.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/services/wallets_service.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/logger.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:paymint/widgets/custom_buttons/simple_button.dart';
import 'package:provider/provider.dart';

import '../wallet_selection_view.dart';
import 'helpers/builders.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({Key key}) : super(key: key);

  _buildItem(String iconAsset, String text, VoidCallback onTap, Key key) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        height: SizingUtilities.standardButtonHeight,
        child: Row(
          children: [
            SvgPicture.asset(
              iconAsset,
              color: CFColors.twilight,
              height: 24,
              width: 24,
            ),
            SizedBox(
              width: SizingUtilities.standardPadding,
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  child: Text(
                    text,
                    style: GoogleFonts.workSans(
                      color: CFColors.starryNight,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      letterSpacing: 0.25,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> logout(Manager manager, WalletsService walletsService,
      BuildContext context) async {
    await manager.exitCurrentWallet();
    await walletsService.setCurrentWalletName("");
    await walletsService.refreshWallets();

    Navigator.pushAndRemoveUntil(
      context,
      CupertinoPageRoute(
        maintainState: false,
        builder: (_) => WalletSelectionView(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CFColors.white,
      appBar: buildSettingsAppBar(
        context,
        "Settings",
        rightButton: Padding(
          padding: EdgeInsets.only(
            top: 10,
            bottom: 10,
            right: 20,
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: AppBarIconButton(
              key: Key("settingsLogoutAppBarButton"),
              size: 36,
              icon: SvgPicture.asset(
                "assets/svg/log-out.svg",
                color: CFColors.twilight,
                width: 24,
                height: 24,
              ),
              circularBorderRadius: 8,
              onPressed: () async {
                final walletsService =
                    Provider.of<WalletsService>(context, listen: false);
                final walletName = await walletsService.currentWalletName;

                showDialog(
                  useSafeArea: false,
                  barrierColor: Colors.transparent,
                  context: context,
                  builder: (ctx) {
                    return ModalPopupDialog(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 28,
                            ),
                            child: Text(
                              "Do you want to log out from $walletName Wallet?",
                              style: GoogleFonts.workSans(
                                color: CFColors.dusk,
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 4,
                              left: SizingUtilities.standardPadding,
                              right: SizingUtilities.standardPadding,
                              bottom: SizingUtilities.standardPadding,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height:
                                        SizingUtilities.standardButtonHeight,
                                    child: SimpleButton(
                                      child: FittedBox(
                                        child: Text(
                                          "CANCEL",
                                          style: CFTextStyles.button.copyWith(
                                            color: CFColors.dusk,
                                          ),
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 16,
                                ),
                                Expanded(
                                  child: SizedBox(
                                    height:
                                        SizingUtilities.standardButtonHeight,
                                    child: GradientButton(
                                      child: FittedBox(
                                        child: Text(
                                          "LOG OUT",
                                          style: CFTextStyles.button,
                                        ),
                                      ),
                                      onTap: () async {
                                        Logger.print("log out pressed");
                                        final manager = Provider.of<Manager>(
                                            context,
                                            listen: false);
                                        await logout(
                                            manager, walletsService, context);
                                      },
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SizingUtilities.standardPadding,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 22,
              ),
              // address book item
              _buildItem(
                "assets/svg/book-open.svg",
                "Address Book",
                () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => AddressBookView(),
                      settings: RouteSettings(name: "/settings/addressbook"),
                    ),
                  );
                },
                Key("settingsOptionAddressBook"),
              ),
              Container(
                height: 1,
                width: double.infinity,
                color: CFColors.fog,
              ),
              // address book item
              _buildItem(
                "assets/svg/radio.svg",
                "Network",
                () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => NetworkSettingsView(),
                      settings: RouteSettings(name: "/settings/network"),
                    ),
                  );
                },
                Key("settingsOptionNetwork"),
              ),
              Container(
                height: 1,
                width: double.infinity,
                color: CFColors.fog,
              ),
              // address book item
              _buildItem(
                "assets/svg/lock.svg",
                "Wallet Backup",
                () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => LockscreenView(
                        routeOnSuccess: '/settings/walletbackup',
                        biometricsAuthenticationTitle: "Show backup key",
                        biometricsCancelButtonString: "CANCEL",
                        biometricsLocalizedReason:
                            "Unlock using fingerprint to show backup key",
                      ),
                      settings:
                          RouteSettings(name: "/settings/walletbackupoption"),
                    ),
                  );
                },
                Key("settingsOptionWalletBackup"),
              ),
              Container(
                height: 1,
                width: double.infinity,
                color: CFColors.fog,
              ),
              // address book item
              _buildItem(
                "assets/svg/settings.svg",
                "Wallet Settings",
                () async {
                  final manager = Provider.of<Manager>(context, listen: false);
                  final useBiometrics = await manager.useBiometrics;
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => WalletSettingsView(
                        useBiometrics: useBiometrics,
                      ),
                      settings:
                          RouteSettings(name: "/settings/walletsettingsoption"),
                    ),
                  );
                },
                Key("settingsOptionWalletSettings"),
              ),
              Container(
                height: 1,
                width: double.infinity,
                color: CFColors.fog,
              ),
              // address book item
              _buildItem(
                "assets/svg/ellipsis.svg",
                "About",
                () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => AboutView(),
                      settings: RouteSettings(name: "/settings/about"),
                    ),
                  );
                },
                Key("settingsOptionAbout"),
              ),
              Container(
                height: 1,
                width: double.infinity,
                color: CFColors.fog,
              ),
              _buildItem(
                "assets/svg/usd-circle.svg",
                "Currency",
                () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => CurrencyView(),
                      settings: RouteSettings(name: "/settings/currency"),
                    ),
                  );
                },
                Key("settingsOptionCurrency"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
