import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:paymint/notifications/modal_popup_dialog.dart';
import 'package:paymint/pages/settings_view/helpers/builders.dart';
import 'package:paymint/pages/settings_view/settings_subviews/wallet_settings_subviews/rename_wallet_view.dart';
import 'package:paymint/pages/wallet_selection_view.dart';
import 'package:paymint/services/bitcoin_service.dart';
import 'package:paymint/services/wallets_service.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:paymint/widgets/custom_buttons/simple_button.dart';
import 'package:provider/provider.dart';

import '../../lockscreen2.dart';

class WalletSettingsView extends StatefulWidget {
  const WalletSettingsView({Key key}) : super(key: key);

  @override
  _WalletSettingsViewState createState() => _WalletSettingsViewState();
}

class _WalletSettingsViewState extends State<WalletSettingsView> {
  final _itemTextStyle = GoogleFonts.workSans(
    color: CFColors.starryNight,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    letterSpacing: 0.25,
  );

  bool _useBiometrics = false;

  @override
  Widget build(BuildContext context) {
    final _itemWidth =
        MediaQuery.of(context).size.width - (SizingUtilities.standardPadding * 2);

    return Scaffold(
      backgroundColor: CFColors.white,
      appBar: buildSettingsAppBar(
        context,
        "Wallet Settings",
        rightButton: Padding(
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
                  builder: (context) {
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
                                    height: SizingUtilities.standardButtonHeight,
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
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 16,
                                ),
                                Expanded(
                                  child: SizedBox(
                                    height: SizingUtilities.standardButtonHeight,
                                    child: GradientButton(
                                      child: FittedBox(
                                        child: Text(
                                          "LOG OUT",
                                          style: CFTextStyles.button,
                                        ),
                                      ),
                                      onTap: () async {
                                        print("log out pressed");
                                        await walletsService.refreshWallets();

                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          CupertinoPageRoute(
                                            maintainState: false,
                                            builder: (_) => WalletSelectionView(),
                                          ),
                                          (_) => false,
                                        );
                                      },
                                    ),
                                  ),
                                )
                              ],
                            ),
                          )
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
        padding: EdgeInsets.only(
          top: 12,
          left: SizingUtilities.standardPadding,
          right: SizingUtilities.standardPadding,
          bottom: SizingUtilities.standardPadding,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildOptionsList(context, _itemWidth),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOptionsList(BuildContext context, double itemWidth) {
    final bitcoinService = Provider.of<BitcoinService>(context);
    return [
      Container(
        // width: itemWidth,
        child: GestureDetector(
          onTap: () {
            Navigator.push(context, CupertinoPageRoute(builder: (context) {
              return Lockscreen2View(routeOnSuccess: '/settings/changepinview');
            }));
          },
          child: Padding(
            padding: const EdgeInsets.only(
              top: 16,
              bottom: 16,
              right: 10,
            ),
            child: Text(
              "Change PIN",
              style: _itemTextStyle,
            ),
          ),
        ),
      ),
      _buildDivider(itemWidth),
      GestureDetector(
        onTap: () async {
          if (_useBiometrics) {
            await bitcoinService.updateBiometricsUsage();
          } else {
            final LocalAuthentication localAuthentication = LocalAuthentication();

            bool canCheckBiometrics = await localAuthentication.canCheckBiometrics;

            if (canCheckBiometrics) {
              List<BiometricType> availableSystems =
                  await localAuthentication.getAvailableBiometrics();

              if (Platform.isIOS) {
                if (availableSystems.contains(BiometricType.face)) {
                  // Write iOS specific code when required
                } else if (availableSystems.contains(BiometricType.fingerprint)) {
                  // Write iOS specific code when required
                }
              } else if (Platform.isAndroid) {
                if (availableSystems.contains(BiometricType.fingerprint)) {
                  bool didAuthenticate =
                      await localAuthentication.authenticateWithBiometrics(
                    localizedReason: 'Please authenticate to enable biometric lock',
                    stickyAuth: true,
                  );
                  if (didAuthenticate) {
                    await bitcoinService.updateBiometricsUsage();
                  }
                }
              }
            }
          }
        },
        child: Row(
          children: [
            Container(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 16,
                  bottom: 16,
                  right: 10,
                ),
                child: Text(
                  "Enable biometric authentication",
                  style: _itemTextStyle,
                ),
              ),
            ),
            Spacer(),
            FutureBuilder(
              future: bitcoinService.useBiometrics,
              builder: (context, AsyncSnapshot<bool> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  _useBiometrics = snapshot.data == null ? false : snapshot.data;
                  return _buildSwitch(context, 18, 36, _useBiometrics);
                } else {
                  // possibly display loading animation here but likely not needed
                  return _buildSwitch(context, 18, 36, false);
                }
              },
            ),
          ],
        ),
      ),
      _buildDivider(itemWidth),
      Container(
        // width: itemWidth,
        child: GestureDetector(
          onTap: () async {
            final walletName = await Provider.of<WalletsService>(context, listen: false)
                .currentWalletName;
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) => RenameWalletView(
                  oldWalletName: walletName,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(
              top: 16,
              bottom: 16,
              right: 10,
            ),
            child: Text(
              "Rename wallet",
              style: _itemTextStyle,
            ),
          ),
        ),
      ),
      _buildDivider(itemWidth),
      Container(
        // width: itemWidth,
        child: GestureDetector(
          onTap: () async {
            final confirmDialog = await _buildWalletDeleteConfirmDialog();
            showDialog(
              useSafeArea: false,
              barrierColor: Colors.transparent,
              barrierDismissible: false,
              context: context,
              builder: (context) => confirmDialog,
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(
              top: 16,
              bottom: 16,
              right: 10,
            ),
            child: Text(
              "Delete wallet",
              style: _itemTextStyle,
            ),
          ),
        ),
      ),
    ];
  }

  _buildSwitch(BuildContext context, double height, double width, bool isActive) {
    return Container(
      height: height,
      width: width,
      child: Stack(
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: isActive ? CFColors.spark : CFColors.fog,
              borderRadius: BorderRadius.circular(height / 2),
              border: Border.all(
                color: isActive ? CFColors.spark : CFColors.dew,
                width: 2,
              ),
            ),
          ),
          Container(
            height: height,
            width: width,
            child: Row(
              mainAxisAlignment:
                  isActive ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                // if (_enabled) Spacer(),
                Container(
                  height: height,
                  width: height,
                  decoration: BoxDecoration(
                    color: CFColors.white,
                    borderRadius: BorderRadius.circular(height / 2),
                    border: Border.all(
                      color: isActive ? CFColors.spark : CFColors.dew,
                      width: 2,
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  _buildDivider(double width) {
    return Container(
      height: 1,
      width: width,
      color: CFColors.fog,
    );
  }

  _buildWalletDeleteConfirmDialog() async {
    final walletsService = Provider.of<WalletsService>(context, listen: false);
    final walletName = await walletsService.currentWalletName;

    return ModalPopupDialog(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 28,
              left: 24,
              right: 24,
              bottom: 12,
            ),
            child: Text(
              "Do you want to delete $walletName Wallet?",
              style: GoogleFonts.workSans(
                color: CFColors.dusk,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(SizingUtilities.standardPadding),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: SizingUtilities.standardButtonHeight,
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
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
                SizedBox(
                  width: 16,
                ),
                Expanded(
                  child: SizedBox(
                    height: SizingUtilities.standardButtonHeight,
                    child: GradientButton(
                      child: FittedBox(
                        child: Text(
                          "DELETE",
                          style: CFTextStyles.button,
                        ),
                      ),
                      onTap: () async {
                        Navigator.push(context, CupertinoPageRoute(builder: (context) {
                          return Lockscreen2View(
                              routeOnSuccess: '/settings/deletewalletwarningview');
                        }));
                      },
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
