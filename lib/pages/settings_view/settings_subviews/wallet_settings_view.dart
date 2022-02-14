import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/electrumx_rpc/cached_electrumx.dart';
import 'package:paymint/notifications/campfire_alert.dart';
import 'package:paymint/notifications/modal_popup_dialog.dart';
import 'package:paymint/pages/settings_view/helpers/builders.dart';
import 'package:paymint/pages/settings_view/settings_subviews/wallet_settings_subviews/rename_wallet_view.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/services/wallets_service.dart';
import 'package:paymint/utilities/biometrics.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:paymint/widgets/custom_buttons/simple_button.dart';
import 'package:provider/provider.dart';

import '../../lockscreen2.dart';

class WalletSettingsView extends StatelessWidget {
  const WalletSettingsView({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _itemWidth = MediaQuery.of(context).size.width -
        (SizingUtilities.standardPadding * 2);

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
          child: WalletSettingsList(itemWidth: _itemWidth),
        ),
      ),
    );
  }
}

class WalletSettingsList extends StatefulWidget {
  const WalletSettingsList({Key key, this.itemWidth}) : super(key: key);

  final itemWidth;
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

  bool _useBiometrics = false;

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<Manager>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(context, CupertinoPageRoute(builder: (context) {
              return Lockscreen2View(
                routeOnSuccess: '/settings/changepinview',
                biometricsCancelButtonString: "CANCEL",
                biometricsLocalizedReason: "Authenticate to change PIN",
                biometricsAuthenticationTitle: "Change PIN",
              );
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
        Divider(width: widget.itemWidth),
        GestureDetector(
          onTap: () async {
            if (_useBiometrics) {
              await manager.updateBiometricsUsage(false);
            } else {
              if (await Biometrics.authenticate(
                cancelButtonText: "CANCEL",
                localizedReason:
                    "Unlock wallet and confirm transactions with your fingerprint",
                title: "Enable fingerprint authentication",
              )) {
                await manager.updateBiometricsUsage(true);
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
                future: manager.useBiometrics,
                builder: (context, AsyncSnapshot<bool> snapshot) {
                  final double height = 18;
                  final double width = 36;
                  if (snapshot.connectionState == ConnectionState.done) {
                    _useBiometrics =
                        snapshot.data == null ? false : snapshot.data;
                  }
                  return Container(
                    height: height,
                    width: width,
                    child: Stack(
                      children: [
                        Container(
                          width: width,
                          height: height,
                          decoration: BoxDecoration(
                            color:
                                _useBiometrics ? CFColors.spark : CFColors.fog,
                            borderRadius: BorderRadius.circular(height / 2),
                            border: Border.all(
                              color: _useBiometrics
                                  ? CFColors.spark
                                  : CFColors.dew,
                              width: 2,
                            ),
                          ),
                        ),
                        Container(
                          height: height,
                          width: width,
                          child: Row(
                            mainAxisAlignment: _useBiometrics
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            children: [
                              // if (_enabled) Spacer(),
                              Container(
                                height: height,
                                width: height,
                                decoration: BoxDecoration(
                                  color: CFColors.white,
                                  borderRadius:
                                      BorderRadius.circular(height / 2),
                                  border: Border.all(
                                    color: _useBiometrics
                                        ? CFColors.spark
                                        : CFColors.dew,
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
                },
              ),
            ],
          ),
        ),
        Divider(width: widget.itemWidth),
        GestureDetector(
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
        Divider(width: widget.itemWidth),
        GestureDetector(
          onTap: () async {
            showDialog(
              useSafeArea: false,
              barrierColor: Colors.transparent,
              barrierDismissible: false,
              context: context,
              builder: (context) => WalletDeleteConfirmDialog(),
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
        Divider(width: widget.itemWidth),
        GestureDetector(
          onTap: () async {
            showDialog(
              useSafeArea: false,
              barrierColor: Colors.transparent,
              barrierDismissible: false,
              context: context,
              builder: (context) => ClearSharedCacheConfirmDialog(),
            );
          },
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
        )
      ],
    );
  }
}

class Divider extends StatelessWidget {
  const Divider({Key key, this.width}) : super(key: key);

  final width;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      width: width,
      color: CFColors.fog,
    );
  }
}

class WalletDeleteConfirmDialog extends StatelessWidget {
  const WalletDeleteConfirmDialog({Key key}) : super(key: key);

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
            child: Provider<Future<String>>.value(
              value: Provider.of<WalletsService>(context).currentWalletName,
              builder: (context, child) {
                return FutureBuilder(
                  future: context.watch<Future<String>>(),
                  builder: (context, AsyncSnapshot<String> name) {
                    String walletName = "...";
                    if (name.connectionState == ConnectionState.done) {
                      walletName = name.data;
                    }
                    return Text(
                      "Do you want to delete $walletName Wallet?",
                      style: GoogleFonts.workSans(
                        color: CFColors.dusk,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    );
                  },
                );
              },
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
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) {
                              return Lockscreen2View(
                                routeOnSuccess:
                                    '/settings/deletewalletwarningview',
                                biometricsAuthenticationTitle: "Confirm delete",
                                biometricsCancelButtonString: "CANCEL",
                                biometricsLocalizedReason:
                                    "Continue wallet deletion process via fingerprint authentication",
                              );
                            },
                          ),
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
  }
}

class ClearSharedCacheConfirmDialog extends StatelessWidget {
  const ClearSharedCacheConfirmDialog({Key key}) : super(key: key);

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
              child: Provider<String>.value(
                value: Provider.of<Manager>(context).coinName,
                builder: (context, child) {
                  return Text(
                    "Are you sure you want to clear all shared cached ${context.watch<String>()} transaction data?",
                    style: GoogleFonts.workSans(
                      color: CFColors.dusk,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  );
                },
              )),
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
                          "CLEAR",
                          style: CFTextStyles.button,
                        ),
                      ),
                      onTap: () async {
                        final client = CachedElectrumX();
                        final manager =
                            Provider.of<Manager>(context, listen: false);
                        final success =
                            await client.clearSharedTransactionCache(
                                coinName: manager.coinName);
                        String message = "";
                        if (success) {
                          message = "Transaction cache cleared!";
                        } else {
                          message = "Failed to clear transaction cache.";
                        }
                        Navigator.of(context).pop();
                        showDialog(
                          useSafeArea: false,
                          barrierColor: Colors.transparent,
                          barrierDismissible: false,
                          context: context,
                          builder: (context) => CampfireAlert(message: message),
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
  }
}
