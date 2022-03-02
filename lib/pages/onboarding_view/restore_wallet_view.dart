import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:barcode_scan2/platform_wrapper.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip39/src/wordlists/english.dart' as bip39wordlist;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:paymint/electrumx_rpc/cached_electrumx.dart';
import 'package:paymint/electrumx_rpc/electrumx.dart';
import 'package:paymint/notifications/campfire_alert.dart';
import 'package:paymint/notifications/modal_popup_dialog.dart';
import 'package:paymint/pages/onboarding_view/onboarding_view.dart';
import 'package:paymint/services/coins/firo/firo_wallet.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/services/wallets_service.dart';
import 'package:paymint/utilities/address_utils.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/misc_global_constants.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:paymint/widgets/custom_buttons/simple_button.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'helpers/builders.dart';

enum InputStatus {
  empty,
  valid,
  invalid,
}

class RestoreWalletFormView extends StatefulWidget {
  const RestoreWalletFormView(
      {Key key, @required this.walletName, @required this.firoNetworkType})
      : super(key: key);

  final String walletName;
  final FiroNetworkType firoNetworkType;

  @override
  _RestoreWalletFormViewState createState() => _RestoreWalletFormViewState();
}

class _RestoreWalletFormViewState extends State<RestoreWalletFormView> {
  final _formKey = GlobalKey<FormState>();
  final _seedWordCount = CampfireConstants.seedPhraseWordCount;

  final HashSet<String> _wordListHashSet = HashSet.from(bip39wordlist.WORDLIST);

  final List<TextEditingController> _controllers = [];
  final List<InputStatus> _inputStatuses = [];

  @override
  void initState() {
    for (int i = 0; i < _seedWordCount; i++) {
      _controllers.add(TextEditingController());
      _inputStatuses.add(InputStatus.empty);
    }
    super.initState();
  }

  bool _isValidMnemonicWord(String word) {
    return _wordListHashSet.contains(word);
  }

  OutlineInputBorder _buildOutlineInputBorder(Color color) {
    return OutlineInputBorder(
      borderSide: BorderSide(
        width: 1,
        color: color,
      ),
      borderRadius: BorderRadius.circular(SizingUtilities.circularBorderRadius),
    );
  }

  InputDecoration _getInputDecorationFor(InputStatus status) {
    Color fillColor;
    Color borderColor;
    switch (status) {
      case InputStatus.empty:
        fillColor = CFColors.fog;
        borderColor = CFColors.twilight;
        break;
      case InputStatus.invalid:
        fillColor = CFColors.error.withOpacity(0.2);
        borderColor = CFColors.error;
        break;
      case InputStatus.valid:
        fillColor = CFColors.success.withOpacity(0.2);
        borderColor = CFColors.success;
        break;
    }
    return InputDecoration(
      fillColor: fillColor,
      filled: true,
      contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      hintText: "Enter word...",
      hintStyle: GoogleFonts.workSans(
        color: CFColors.twilight,
        fontWeight: FontWeight.w400,
        fontSize: 16,
      ),
      enabledBorder: _buildOutlineInputBorder(borderColor),
      focusedBorder: _buildOutlineInputBorder(borderColor),
      errorBorder: _buildOutlineInputBorder(borderColor),
      disabledBorder: _buildOutlineInputBorder(borderColor),
    );
  }

  _clearAndPopulateMnemonic(List<String> words) {
    final count = min(_controllers.length, words.length);

    // replace field content with listed words
    for (int i = 0; i < count; i++) {
      final word = words[i];
      _controllers[i].text = words[i];
      if (_isValidMnemonicWord(word)) {
        setState(() {
          _inputStatuses[i] = InputStatus.valid;
        });
      } else {
        setState(() {
          _inputStatuses[i] = InputStatus.invalid;
        });
      }
    }

    // clear remaining fields
    for (int i = count; i < _controllers.length; i++) {
      _controllers[i].text = "";
      setState(() {
        _inputStatuses[i] = InputStatus.empty;
      });
    }
  }

  _onBackPressed(int pops) async {
    // delete created wallet name and pin
    final walletsService = Provider.of<WalletsService>(context, listen: false);
    int result = await walletsService.deleteWallet(widget.walletName);

    // set manager wallet to null if it isn't already
    Provider.of<Manager>(context, listen: false).currentWallet = null;

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
      FocusScope.of(context).unfocus();
      await Future.delayed(Duration(milliseconds: 100));

      final nav = Navigator.of(context);
      for (int i = 0; i < pops; i++) {
        nav.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _onBackPressed(2);
        return true;
      },
      child: Scaffold(
        backgroundColor: CFColors.starryNight,
        appBar: buildOnboardingAppBar(
          context,
          backButtonPressed: () async {
            await _onBackPressed(2);
          },
        ),
        body: buildOnboardingBody(
          context,
          Column(
            children: [
              SizedBox(
                height: 40,
              ),
              FittedBox(
                child: Text(
                  "Restore wallet",
                  style: CFTextStyles.pinkHeader,
                ),
              ),
              SizedBox(
                height: 13,
              ),
              FittedBox(
                child: Text(
                  "Enter your 24-word backup key.",
                  style: GoogleFonts.workSans(
                    color: CFColors.dusk,
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 8,
                      ),
                      child: SizedBox(
                        height: 48,
                        child: SimpleButton(
                          onTap: () async {
                            final qrResult = await BarcodeScanner.scan();
                            final results = AddressUtils.decodeQRSeedData(
                                qrResult.rawContent);

                            if (results["mnemonic"] != null) {
                              final list = (results["mnemonic"] as List)
                                  ?.map((value) => value as String)
                                  ?.toList(growable: false);
                              if (list.length > 0) {
                                _clearAndPopulateMnemonic(list);
                              }
                            }
                          },
                          child: FittedBox(
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  "assets/svg/qr-code.svg",
                                  color: CFColors.dusk,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  "SCAN QR",
                                  style: GoogleFonts.workSans(
                                    color: CFColors.dusk,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 8,
                        right: 20,
                      ),
                      child: SizedBox(
                        height: 48,
                        child: SimpleButton(
                          onTap: () async {
                            final ClipboardData data =
                                await Clipboard.getData(Clipboard.kTextPlain);

                            if (data != null && data.text.isNotEmpty) {
                              final content = data.text.trim();
                              final list = content.split(" ");
                              _clearAndPopulateMnemonic(list);
                            }
                          },
                          child: FittedBox(
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  "assets/svg/clipboard.svg",
                                  color: CFColors.dusk,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  "PASTE",
                                  style: GoogleFonts.workSans(
                                    color: CFColors.dusk,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 20 - (SizingUtilities.listItemSpacing / 2),
                    left: 20,
                    right: 20 - (SizingUtilities.listItemSpacing / 2),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildWordEntryList(),
                        _buildRestoreButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _buildWordEntryList() {
    final List<TableRow> children = [];

    for (int i = 1; i <= _seedWordCount; i++) {
      final row = TableRow(children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.fill,
          child: Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Center(
              child: FittedBox(
                alignment: Alignment.topRight,
                child: Text(
                  i < 10 ? " $i" : "$i",
                  style: GoogleFonts.workSans(
                    color: CFColors.dusk,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(
            SizingUtilities.listItemSpacing / 2,
          ),
          child: TextFormField(
            decoration: _getInputDecorationFor(_inputStatuses[i - 1]),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged: (value) {
              if (value == null || value.isEmpty) {
                setState(() {
                  _inputStatuses[i - 1] = InputStatus.empty;
                });
              } else if (_isValidMnemonicWord(value)) {
                setState(() {
                  _inputStatuses[i - 1] = InputStatus.valid;
                });
              } else {
                setState(() {
                  _inputStatuses[i - 1] = InputStatus.invalid;
                });
              }
            },
            validator: (value) {
              if (value == null) {
                return "value is null!!!!!";
              } else if (value.isEmpty) {
                return null;
              } else if (!_isValidMnemonicWord(value)) {
                return "Please check spelling";
              }

              return null;
            },
            controller: _controllers[i - 1],
            style: CFTextStyles.textField,
            // decoration: _getInputDecoration(_formKey.currentState.validate()),
          ),
        )
      ]);
      children.add(row);
    }

    return Form(
      key: _formKey,
      child: Table(
        columnWidths: {
          0: IntrinsicColumnWidth(),
          1: FlexColumnWidth(),
        },
        children: children,
      ),
    );
  }

  _buildRestoreButton() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 16,
        bottom: 20,
      ),
      child: SizedBox(
        height: 48,
        width: MediaQuery.of(context).size.width -
            (SizingUtilities.standardPadding * 2),
        child: GradientButton(
          onTap: () async {
            //TODO seems hacky fix for renderflex error
            // wait for keyboard to disappear
            FocusScope.of(context).unfocus();
            await Future.delayed(Duration(milliseconds: 100));

            if (_formKey.currentState.validate()) {
              String mnemonic = "";
              _controllers.forEach(
                (element) {
                  mnemonic += " ${element.text.trim()}";
                },
              );
              mnemonic = mnemonic.trim();

              if (bip39.validateMnemonic(mnemonic) == false) {
                showDialog(
                  useSafeArea: false,
                  barrierDismissible: false,
                  context: context,
                  builder: (_) =>
                      CampfireAlert(message: "Invalid seed phrase!"),
                );
              } else {
                // show restoring in progress
                showDialog(
                  context: context,
                  useSafeArea: false,
                  barrierDismissible: false,
                  builder: (context) {
                    return _buildWaitDialog();
                  },
                );

                final manager = Provider.of<Manager>(context, listen: false);
                // should already be null but just in case:
                manager.currentWallet = null;

                final walletsService =
                    Provider.of<WalletsService>(context, listen: false);
                await walletsService.refreshWallets();

                final walletName = await walletsService.currentWalletName;
                final walletId = await walletsService.getWalletId(walletName);
                ElectrumXNode defaultNode;
                switch (widget.firoNetworkType) {
                  case FiroNetworkType.main:
                    defaultNode = ElectrumXNode(
                      address: CampfireConstants.defaultIpAddress,
                      port: CampfireConstants.defaultPort,
                      name: CampfireConstants.defaultNodeName,
                      id: Uuid().v1(),
                      useSSL: CampfireConstants.defaultUseSSL,
                    );
                    break;
                  case FiroNetworkType.test:
                    defaultNode = ElectrumXNode(
                      address: CampfireConstants.defaultIpAddressTestNet,
                      port: CampfireConstants.defaultPortTestNet,
                      name: CampfireConstants.defaultNodeNameTestNet,
                      id: Uuid().v1(),
                      useSSL: CampfireConstants.defaultUseSSLTestNet,
                    );
                    break;
                  default:
                    throw Exception("Bad firo network type encountered");
                }
                final appDir = await getApplicationDocumentsDirectory();
                final firoWallet = FiroWallet(
                  walletId: walletId,
                  walletName: walletName,
                  networkType: widget.firoNetworkType,
                  client: ElectrumX.from(node: defaultNode),
                  cachedClient: CachedElectrumX.from(
                      node: defaultNode, hivePath: appDir.path),
                );
                await firoWallet.initializeWallet();
                manager.currentWallet = firoWallet;

                try {
                  final secureStore = new FlutterSecureStorage();
                  await secureStore.write(
                      key: '${walletId}_mnemonic', value: mnemonic.trim());
                  await manager.recoverFromMnemonic(mnemonic);
                  Navigator.pushReplacementNamed(context, "/mainview");

                  Timer timer = Timer(Duration(milliseconds: 2200), () {
                    Navigator.of(context, rootNavigator: true).pop();
                  });

                  showDialog(
                    context: context,
                    useSafeArea: false,
                    barrierDismissible: false,
                    builder: (context) {
                      return _buildRecoveryCompleteDialog();
                    },
                  ).then(
                    (_) {
                      timer.cancel();
                      timer = null;
                    },
                  );
                } catch (e) {
                  // pop waiting dialog
                  Navigator.pop(context);

                  // show restoring wallet failed dialog
                  showDialog(
                    context: context,
                    useSafeArea: false,
                    barrierDismissible: false,
                    builder: (context) {
                      return _buildRestoreFailedDialog(e.toString());
                    },
                  );
                }
              }
            }
          },
          child: Text(
            "RESTORE",
            style: GoogleFonts.workSans(
              color: CFColors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  _buildWaitDialog() {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: ModalPopupDialog(
        child: Column(
          children: [
            SizedBox(
              height: 28,
            ),
            FittedBox(
              child: Text(
                "Restoring wallet",
                style: CFTextStyles.pinkHeader.copyWith(
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(
              height: 12,
            ),
            FittedBox(
              child: Text(
                "This may take a while.",
                style: GoogleFonts.workSans(
                  color: CFColors.dusk,
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            ),
            SizedBox(
              height: 50,
            ),
            Container(
              width: 98,
              height: 98,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(49),
                border: Border.all(
                  color: CFColors.dew,
                  width: 2,
                ),
              ),
              child: Center(
                child: Container(
                  height: 40,
                  width: 40,
                  child: CircularProgressIndicator(
                    color: CFColors.spark,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 50,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 48,
                  child: TextButton(
                    onPressed: () async {
                      await _onBackPressed(5);
                      // final walletsService =
                      //     Provider.of<WalletsService>(context, listen: false);
                      // final name = await walletsService.currentWalletName;
                      // int result = await walletsService.deleteWallet(name);
                      //
                      // // check if last wallet was deleted
                      // if (result == 2) {
                      //   Navigator.pushAndRemoveUntil(
                      //     context,
                      //     CupertinoPageRoute(
                      //       maintainState: false,
                      //       builder: (_) => OnboardingView(),
                      //     ),
                      //     (_) => false,
                      //   );
                      // } else {
                      //   final navigator = Navigator.of(context);
                      //   navigator.pop();
                      //   navigator.pop();
                      //   navigator.pop();
                      //   navigator.pop();
                      //   navigator.pop();
                      // }
                    },
                    child: FittedBox(
                      child: Text(
                        "CANCEL",
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
                  width: 20,
                ),
              ],
            ),
            SizedBox(
              height: 8,
            ),
          ],
        ),
      ),
    );
  }

  _buildRecoveryCompleteDialog() {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: ModalPopupDialog(
        child: Column(
          children: [
            SizedBox(
              height: 28,
            ),
            FittedBox(
              child: Text(
                "Wallet Restored!",
                style: CFTextStyles.pinkHeader.copyWith(
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(
              height: 12,
            ),
            FittedBox(
              child: Text(
                "Get ready to spend your Firo.",
                style: GoogleFonts.workSans(
                  color: CFColors.dusk,
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            ),
            SizedBox(
              height: 50,
            ),
            Container(
              width: 98,
              height: 98,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(49),
                border: Border.all(
                  color: CFColors.dew,
                  width: 2,
                ),
              ),
              child: Center(
                child: Container(
                  height: 50,
                  width: 50,
                  child: SvgPicture.asset(
                    "assets/svg/check-circle.svg",
                    color: CFColors.spark,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width -
                  (SizingUtilities.standardPadding * 2),
              // add height of button and sized box from WaitDialog so
              // the center widget is at the same height as the
              // circular progress indicator in WaitDialog
              height: 50.0 + 48.0 + 8.0,
            ),
          ],
        ),
      ),
    );
  }

  _buildRestoreFailedDialog(String errorMessage) {
    return WillPopScope(
      onWillPop: () async {
        await _onBackPressed(5);
        return true;
      },
      child: ModalPopupDialog(
        child: Column(
          children: [
            SizedBox(
              height: 28,
            ),
            FittedBox(
              child: Text(
                "Restoring wallet failed.",
                style: CFTextStyles.pinkHeader.copyWith(
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(
              height: 12,
            ),
            Center(
              child: Text(
                errorMessage == null ? "" : errorMessage,
                style: GoogleFonts.workSans(
                  color: CFColors.dusk,
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            ),
            SizedBox(
              height: 50,
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(SizingUtilities.standardPadding),
                child: SizedBox(
                  height: SizingUtilities.standardButtonHeight,
                  width: SizingUtilities.standardFixedButtonWidth,
                  child: GradientButton(
                    child: FittedBox(
                      child: Text(
                        "OK",
                        style: CFTextStyles.button,
                      ),
                    ),
                    onTap: () {
                      _onBackPressed(5);
                    },
                  ),
                ),
              ),
            ),
            SizedBox(
              height: SizingUtilities.standardPadding,
            ),
          ],
        ),
      ),
    );
  }
}
