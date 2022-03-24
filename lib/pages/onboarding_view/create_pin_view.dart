import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:paymint/electrumx_rpc/cached_electrumx.dart';
import 'package:paymint/electrumx_rpc/electrumx.dart';
import 'package:paymint/notifications/campfire_alert.dart';
import 'package:paymint/notifications/modal_popup_dialog.dart';
import 'package:paymint/notifications/overlay_notification.dart';
import 'package:paymint/pages/onboarding_view/helpers/builders.dart';
import 'package:paymint/pages/onboarding_view/restore_wallet_view.dart';
import 'package:paymint/services/coins/firo/firo_wallet.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/services/node_service.dart';
import 'package:paymint/services/wallets_service.dart';
import 'package:paymint/utilities/biometrics.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/misc_global_constants.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_pin_put/custom_pin_put.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'backup_key_warning_view.dart';
import 'helpers/create_wallet_type.dart';

class CreatePinView extends StatefulWidget {
  const CreatePinView(
      {Key key,
      @required this.type,
      @required this.walletName,
      this.useTestNet})
      : super(key: key);

  final CreateWalletType type;
  final String walletName;
  final bool useTestNet;

  @override
  _CreatePinViewState createState() => _CreatePinViewState();
}

class _CreatePinViewState extends State<CreatePinView> {
  BoxDecoration get _pinPutDecoration {
    return BoxDecoration(
      color: CFColors.fog,
      border: Border.all(width: 1, color: CFColors.smoke),
      borderRadius: BorderRadius.circular(6),
    );
  }

  PageController _pageController =
      PageController(initialPage: 0, keepPage: true);

  // Attributes for Page 1 of the pageview
  final TextEditingController _pinPutController1 = TextEditingController();
  final FocusNode _pinPutFocusNode1 = FocusNode();

  // Attributes for Page 2 of the pageview
  final TextEditingController _pinPutController2 = TextEditingController();
  final FocusNode _pinPutFocusNode2 = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CFColors.starryNight,
      appBar: buildOnboardingAppBar(context),
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        children: [
          // page 1
          buildOnboardingBody(
            context,
            Container(
              height: MediaQuery.of(context).size.height -
                  SizingUtilities.getStatusBarHeight(context) -
                  80, // 80 is height of onboarding appbar
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: FittedBox(
                      child: Text(
                        "Create a PIN",
                        style: CFTextStyles.pinkHeader,
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
                        duration: Duration(milliseconds: 250),
                        curve: Curves.linear,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // page 2
          buildOnboardingBody(
            context,
            Container(
              height: MediaQuery.of(context).size.height -
                  SizingUtilities.getStatusBarHeight(context) -
                  80, // 80 is height of onboarding appbar
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: FittedBox(
                      child: Text(
                        "Confirm PIN",
                        style: CFTextStyles.pinkHeader,
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
                        // ask if want to use biometrics
                        final bool useBiometrics =
                            await Biometrics.authenticate(
                          cancelButtonText: "SKIP",
                          localizedReason:
                              "Unlock wallet and confirm transactions with your fingerprint",
                          title: "Enable fingerprint authentication",
                        );

                        // handle wallet creation/initialization

                        final walletService =
                            Provider.of<WalletsService>(context, listen: false);
                        final store = new FlutterSecureStorage();

                        final firoNetworkType = widget.useTestNet
                            ? FiroNetworkType.test
                            : FiroNetworkType.main;

                        await walletService.addNewWalletName(
                          widget.walletName,
                          firoNetworkType.name,
                        );
                        final id =
                            await walletService.getWalletId(widget.walletName);

                        // This should never fail as we are writing a new pin for a new wallet
                        assert((await store.read(key: "${id}_pin")) == null);
                        await store.write(key: "${id}_pin", value: pin);

                        if (widget.type == CreateWalletType.NEW) {
                          final manager =
                              Provider.of<Manager>(context, listen: false);

                          showDialog(
                            context: context,
                            useSafeArea: false,
                            barrierDismissible: false,
                            builder: (context) {
                              return _buildKeyGenerationDialog();
                            },
                          );

                          final nodeService =
                              Provider.of<NodeService>(context, listen: false);
                          await nodeService.reInit();
                          ElectrumXNode defaultNode;
                          switch (firoNetworkType) {
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
                                address:
                                    CampfireConstants.defaultIpAddressTestNet,
                                port: CampfireConstants.defaultPortTestNet,
                                name: CampfireConstants.defaultNodeNameTestNet,
                                id: Uuid().v1(),
                                useSSL: CampfireConstants.defaultUseSSLTestNet,
                              );
                              break;
                            default:
                              throw Exception(
                                  "Bad firo network type encountered");
                          }

                          nodeService.createNode(
                            name: defaultNode.name,
                            ipAddress: defaultNode.address,
                            port: defaultNode.port.toString(),
                            useSSL: defaultNode.useSSL,
                          );

                          final appDir =
                              await getApplicationDocumentsDirectory();
                          final firoWallet = FiroWallet(
                            walletId: id,
                            walletName: widget.walletName,
                            networkType: firoNetworkType,
                            client: ElectrumX.from(node: defaultNode),
                            cachedClient: CachedElectrumX.from(
                                node: defaultNode, hivePath: appDir.path),
                          );
                          final success = await firoWallet.initializeWallet();
                          if (!success) {
                            await firoWallet.exit();
                            await walletService.deleteWallet(widget.walletName);
                            await showDialog(
                              context: context,
                              useSafeArea: false,
                              barrierDismissible: false,
                              builder: (context) {
                                return CampfireAlert(
                                    message:
                                        "Failed to connect to network. Check your internet connection.");
                              },
                            );
                            final nav = Navigator.of(context);
                            nav.pop();
                            nav.pop();
                            nav.pop();
                            nav.pop();
                            return;
                          }
                          manager.currentWallet = firoWallet;
                          await manager.updateBiometricsUsage(useBiometrics);
                          await Future.delayed(Duration(seconds: 3));

                          Navigator.pop(context);
                        }

                        // String message;
                        Widget nextView;

                        switch (widget.type) {
                          // push restore wallet page
                          case CreateWalletType.RESTORE:
                            // message = "PIN code successfully set";
                            nextView = RestoreWalletFormView(
                              walletName: widget.walletName,
                              firoNetworkType: firoNetworkType,
                            );

                            break;

                          // push new wallet page
                          case CreateWalletType.NEW:
                            // message = "PIN code successfully set";
                            nextView = BackupKeyWarningView(
                                walletName: widget.walletName);

                            break;
                        }

                        // OverlayNotification.showSuccess(
                        //   context,
                        //   message,
                        //   Duration(milliseconds: 2000),
                        // );

                        await Future.delayed(Duration(milliseconds: 700));

                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) {
                              return nextView;
                            },
                          ),
                        );
                      } else {
                        _pageController.animateTo(
                          0,
                          duration: Duration(milliseconds: 250),
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
            ),
          ),
        ],
      ),
    );
  }

  _buildKeyGenerationDialog() {
    return WillPopScope(
      onWillPop: () async {
        //TODO ideally delete partially created wallet and return true
        // currently this causes a crash:
        // _CreatePinViewState#2e3ba(lifecycle state: defunct, not mounted)

        // final walletService =
        //     Provider.of<WalletsService>(context, listen: false);
        // walletService.deleteWallet(widget.walletName);
        // Navigator.pop(context);
        // return true;
        return false;
      },
      child: ModalPopupDialog(
        child: Container(
          width: MediaQuery.of(context).size.width -
              (SizingUtilities.standardPadding * 2),
          child: Column(
            children: [
              SizedBox(
                height: 28,
              ),
              FittedBox(
                child: Text(
                  "Generating backup key",
                  style: CFTextStyles.pinkHeader.copyWith(
                    fontSize: 16,
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
            ],
          ),
        ),
      ),
    );
  }
}
