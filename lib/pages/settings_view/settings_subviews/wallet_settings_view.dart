import 'package:app_settings/app_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:paymint/electrumx_rpc/cached_electrumx.dart';
import 'package:paymint/notifications/campfire_alert.dart';
import 'package:paymint/notifications/modal_popup_dialog.dart';
import 'package:paymint/pages/settings_view/helpers/builders.dart';
import 'package:paymint/pages/settings_view/settings_subviews/wallet_settings_subviews/rename_wallet_view.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/services/wallets_service.dart';
import 'package:paymint/utilities/biometrics.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/logger.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:paymint/widgets/custom_buttons/simple_button.dart';
import 'package:provider/provider.dart';

import '../../lockscreen_view.dart';

class WalletSettingsView extends StatelessWidget {
  const WalletSettingsView({
    Key key,
    this.cachedClient = const CachedElectrumX(),
    @required this.useBiometrics,
  }) : super(key: key);

  final CachedElectrumX cachedClient;
  final bool useBiometrics;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CFColors.white,
      appBar: buildSettingsAppBar(
        context,
        "Wallet Settings",
      ),
      body: Padding(
        padding: EdgeInsets.only(
          top: 12,
          left: SizingUtilities.standardPadding,
          right: SizingUtilities.standardPadding,
          bottom: SizingUtilities.standardPadding,
        ),
        child: SingleChildScrollView(
          child: WalletSettingsList(
            cachedElectrumX: cachedClient,
            localAuthentication: LocalAuthentication(),
            useBiometrics: useBiometrics,
          ),
        ),
      ),
    );
  }
}

class WalletSettingsList extends StatefulWidget {
  const WalletSettingsList({
    Key key,
    this.cachedElectrumX = const CachedElectrumX(),
    @required this.localAuthentication,
    @required this.useBiometrics,
    this.biometrics = const Biometrics(),
  }) : super(key: key);

  final CachedElectrumX cachedElectrumX;
  final LocalAuthentication localAuthentication;
  final bool useBiometrics;
  final Biometrics biometrics;

  @override
  _WalletSettingsListState createState() => _WalletSettingsListState();
}

class _WalletSettingsListState extends State<WalletSettingsList> {
  final _itemTextStyle = GoogleFonts.workSans(
    color: CFColors.starryNight,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    letterSpacing: 0.25,
  );

  bool useBiometrics;
  CachedElectrumX cachedClient;
  LocalAuthentication localAuthentication;
  Manager _manager;
  Biometrics biometrics;

  @override
  initState() {
    _manager = Provider.of<Manager>(context, listen: false);
    biometrics = widget.biometrics;
    useBiometrics = widget.useBiometrics;
    cachedClient = widget.cachedElectrumX;
    localAuthentication = widget.localAuthentication;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          key: Key("walletSettingsChangePinButtonKey"),
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) => LockscreenView(
                  routeOnSuccess: '/settings/changepinview',
                  biometricsCancelButtonString: "CANCEL",
                  biometricsLocalizedReason: "Authenticate to change PIN",
                  biometricsAuthenticationTitle: "Change PIN",
                ),
                settings: RouteSettings(name: "/settings/changepinlockscreen"),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            color: Colors.white,
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
        CFDivider(),
        GestureDetector(
          key: Key("walletSettingsEnableBiometricsButtonKey"),
          onTap: () async {
            if (useBiometrics) {
              await _manager.updateBiometricsUsage(false);
              setState(() {
                useBiometrics = false;
              });
            } else {
              final canCheckBiometrics =
                  await localAuthentication.canCheckBiometrics;
              final isDeviceSupported =
                  await localAuthentication.isDeviceSupported();
              final listOfauthentifications =
                  await localAuthentication.getAvailableBiometrics();

              if ((canCheckBiometrics &&
                      isDeviceSupported &&
                      listOfauthentifications.isEmpty) ||
                  (canCheckBiometrics &&
                      !isDeviceSupported &&
                      listOfauthentifications.isNotEmpty)) {
                await showDialog(
                  useSafeArea: false,
                  barrierColor: Colors.transparent,
                  barrierDismissible: false,
                  context: context,
                  builder: (context) => ModalPopupDialog(
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
                            "Biometric security features not enabled on current device. Go to system settings?",
                            style: GoogleFonts.workSans(
                              color: CFColors.dusk,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(
                              SizingUtilities.standardPadding),
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
                                      final navigator = Navigator.of(context);
                                      navigator.pop();
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
                                        "SETTINGS",
                                        style: CFTextStyles.button,
                                      ),
                                    ),
                                    onTap: () async {
                                      await AppSettings.openSecuritySettings();
                                      final navigator = Navigator.of(context);
                                      navigator.pop();
                                    },
                                  ),
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              } else if (!canCheckBiometrics) {
                await showDialog(
                  useSafeArea: false,
                  barrierColor: Colors.transparent,
                  barrierDismissible: false,
                  context: context,
                  builder: (context) => CampfireAlert(
                      message:
                          "Biometric security features not available on current device."),
                );
                return;
              }

              if (await biometrics.authenticate(
                cancelButtonText: "CANCEL",
                localizedReason:
                    "Unlock wallet and confirm transactions with your fingerprint",
                title: "Enable fingerprint authentication",
              )) {
                await _manager.updateBiometricsUsage(true);
                setState(() {
                  useBiometrics = true;
                });
              }
            }
          },
          child: Container(
            width: double.infinity,
            color: Colors.white,
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
                BiometricsSwitch(
                  height: 18,
                  width: 36,
                  useBiometrics: useBiometrics,
                ),
              ],
            ),
          ),
        ),
        CFDivider(),
        GestureDetector(
          key: Key("walletSettingsRenameWalletButtonKey"),
          onTap: () async {
            final walletName =
                await Provider.of<WalletsService>(context, listen: false)
                    .currentWalletName;
            Navigator.push(
              context,
              CupertinoPageRoute(
                  builder: (_) => RenameWalletView(
                        oldWalletName: walletName,
                      ),
                  settings: RouteSettings(name: "/settings/renamewallet")),
            );
          },
          child: Container(
            width: double.infinity,
            color: Colors.white,
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
        CFDivider(),
        GestureDetector(
          key: Key("walletSettingsDeleteWalletButtonKey"),
          onTap: () async {
            final walletName =
                await Provider.of<WalletsService>(context, listen: false)
                    .currentWalletName;

            showDialog(
              useSafeArea: false,
              barrierColor: Colors.transparent,
              barrierDismissible: false,
              context: context,
              builder: (_) => ConfirmationDialog(
                message: "Do you want to delete $walletName Wallet?",
                cancelButtonText: "CANCEL",
                confirmButtonText: "DELETE",
                onCancel: () {
                  Navigator.pop(context);
                },
                onConfirm: () async {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => LockscreenView(
                        routeOnSuccess: '/settings/deletewalletwarningview',
                        biometricsAuthenticationTitle: "Confirm delete",
                        biometricsCancelButtonString: "CANCEL",
                        biometricsLocalizedReason:
                            "Continue wallet deletion process via fingerprint authentication",
                      ),
                      settings: RouteSettings(
                          name: "/settings/deletewalletlockscreen"),
                    ),
                  );
                },
              ),
            );
          },
          child: Container(
            width: double.infinity,
            color: Colors.white,
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
        CFDivider(),
        GestureDetector(
          key: Key("walletSettingsClearSharedCacheButtonKey"),
          onTap: () async {
            final coinName = _manager.coinName;
            showDialog(
              useSafeArea: false,
              barrierColor: Colors.transparent,
              barrierDismissible: false,
              context: context,
              builder: (_) => ConfirmationDialog(
                cancelButtonText: "CANCEL",
                confirmButtonText: "CLEAR",
                message:
                    "Are you sure you want to clear all shared cached $coinName transaction data?",
                onCancel: () {
                  Navigator.pop(context);
                },
                onConfirm: () async {
                  Navigator.pop(context);
                  String message = "";
                  try {
                    await cachedClient.clearSharedTransactionCache(
                        coinName: coinName);
                    message = "Transaction cache cleared!";
                  } catch (e, s) {
                    Logger.print("clearSharedTransactionCache failed: $e\n$s");
                    message = "Failed to clear transaction cache.";
                  }
                  showDialog(
                    useSafeArea: false,
                    barrierColor: Colors.transparent,
                    barrierDismissible: false,
                    context: context,
                    builder: (context) => CampfireAlert(message: message),
                  );
                },
              ),
            );
          },
          child: Container(
            width: double.infinity,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.only(
                top: 16,
                bottom: 16,
                right: 10,
              ),
              child: Text(
                "Clear shared transaction cache",
                style: _itemTextStyle,
              ),
            ),
          ),
        )
      ],
    );
  }
}

class BiometricsSwitch extends StatelessWidget {
  const BiometricsSwitch({
    Key key,
    this.useBiometrics,
    this.height,
    this.width,
  }) : super(key: key);

  final bool useBiometrics;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      child: Stack(
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: useBiometrics ? CFColors.spark : CFColors.fog,
              borderRadius: BorderRadius.circular(height / 2),
              border: Border.all(
                color: useBiometrics ? CFColors.spark : CFColors.dew,
                width: 2,
              ),
            ),
          ),
          Container(
            height: height,
            width: width,
            child: Row(
              mainAxisAlignment: useBiometrics
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                // if (_enabled) Spacer(),
                Container(
                  height: height,
                  width: height,
                  decoration: BoxDecoration(
                    color: CFColors.white,
                    borderRadius: BorderRadius.circular(height / 2),
                    border: Border.all(
                      color: useBiometrics ? CFColors.spark : CFColors.dew,
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
}

class CFDivider extends StatelessWidget {
  const CFDivider({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      width: double.infinity,
      color: CFColors.fog,
    );
  }
}

class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    Key key,
    this.message,
    this.confirmButtonText,
    this.cancelButtonText,
    this.onConfirm,
    this.onCancel,
  }) : super(key: key);

  final String message;
  final String confirmButtonText;
  final String cancelButtonText;

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
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
              message ?? "",
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
                          cancelButtonText ?? "CANCEL",
                          style: CFTextStyles.button.copyWith(
                            color: CFColors.dusk,
                          ),
                        ),
                      ),
                      onTap: onCancel,
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
                          confirmButtonText ?? "OK",
                          style: CFTextStyles.button,
                        ),
                      ),
                      onTap: onConfirm,
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
