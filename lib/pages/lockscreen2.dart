import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:paymint/electrumx_rpc/cached_electrumx.dart';
import 'package:paymint/electrumx_rpc/electrumx.dart';
import 'package:paymint/notifications/campfire_alert.dart';
import 'package:paymint/notifications/overlay_notification.dart';
import 'package:paymint/services/coins/firo/firo_wallet.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/services/node_service.dart';
import 'package:paymint/services/wallets_service.dart';
import 'package:paymint/utilities/biometrics.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/misc_global_constants.dart';
import 'package:paymint/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:paymint/widgets/custom_pin_put/custom_pin_put.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class Lockscreen2View extends StatefulWidget {
  final String routeOnSuccess;
  final String biometricsAuthenticationTitle;
  final String biometricsLocalizedReason;
  final String biometricsCancelButtonString;

  const Lockscreen2View(
      {Key key,
      @required this.routeOnSuccess,
      this.biometricsAuthenticationTitle,
      this.biometricsLocalizedReason,
      this.biometricsCancelButtonString})
      : super(key: key);
  @override
  _Lockscreen2ViewState createState() => _Lockscreen2ViewState();
}

class _Lockscreen2ViewState extends State<Lockscreen2View> {
  _checkUseBiometrics() async {
    final manager = Provider.of<Manager>(context, listen: false);
    final walletsService = Provider.of<WalletsService>(context, listen: false);
    bool useBiometrics = false;

    // check if authenticating wallet log in
    if (!manager.hasWallet) {
      final walletId = await walletsService
          .getWalletId(await walletsService.currentWalletName);
      final wallet = await Hive.openBox(walletId);
      useBiometrics = await wallet.get('use_biometrics') ?? false;
    } else {
      useBiometrics = await manager.useBiometrics;
    }

    final title = widget.biometricsAuthenticationTitle ?? manager.walletName;
    final localizedReason = widget.biometricsLocalizedReason ?? "Unlock wallet";
    final cancelButtonText = widget.biometricsCancelButtonString ?? "CANCEL";

    if (useBiometrics) {
      if (await Biometrics.authenticate(
          title: title,
          localizedReason: localizedReason,
          cancelButtonText: cancelButtonText)) {
        // check if initial log in
        if (widget.routeOnSuccess == "/mainview") {
          final networkName = await walletsService.networkName;
          final walletName = await walletsService.currentWalletName;
          final id = await walletsService.getWalletId(walletName);
          await logIn(networkName, walletName, id);
        }

        Navigator.pushReplacementNamed(context, widget.routeOnSuccess);
      }
      // leave this commented to enable pin fall back should biometrics not work properly
      // else {
      //   Navigator.pop(context);
      // }
    }
  }

  Future<void> logIn(
      String networkName, String walletName, String walletId) async {
    FiroNetworkType firoNetworkType;
    final nodeService = Provider.of<NodeService>(context, listen: false);
    await nodeService.reInit();
    ElectrumXNode node = nodeService.currentNode;
    if (node == null) {
      switch (networkName) {
        case "main":
          firoNetworkType = FiroNetworkType.main;
          node = ElectrumXNode(
            address: CampfireConstants.defaultIpAddress,
            port: CampfireConstants.defaultPort,
            name: CampfireConstants.defaultNodeName,
            id: Uuid().v1(),
            useSSL: CampfireConstants.defaultUseSSL,
          );
          break;
        case "test":
          firoNetworkType = FiroNetworkType.test;
          node = ElectrumXNode(
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

      nodeService.createNode(
        name: node.name,
        ipAddress: node.address,
        port: node.port.toString(),
        useSSL: node.useSSL,
      );
    }
    final manager = Provider.of<Manager>(context, listen: false);
    final appDir = await getApplicationDocumentsDirectory();
    final firoWallet = FiroWallet(
      walletId: walletId,
      walletName: walletName,
      networkType: firoNetworkType,
      client: ElectrumX.from(node: node),
      cachedClient: CachedElectrumX.from(node: node, hivePath: appDir.path),
    );
    final success = await firoWallet.initializeWallet();
    if (!success) {
      await showDialog(
        context: context,
        useSafeArea: false,
        barrierDismissible: false,
        builder: (context) {
          return CampfireAlert(
              message:
                  "Failed to connect to network. Check your internet connection and make sure the Electrum X node you are connected to is not having any issues.");
        },
      );
    }
    manager.currentWallet = firoWallet;
  }

  @override
  void initState() {
    // show system status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        // statusBarBrightness: Brightness.dark,
      ),
    );
    super.initState();
    _checkUseBiometrics();
  }

  BoxDecoration get _pinPutDecoration {
    return BoxDecoration(
      color: CFColors.fog,
      border: Border.all(width: 1, color: CFColors.smoke),
      borderRadius: BorderRadius.circular(6),
    );
  }

  final _pinTextController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final WalletsService walletsService = Provider.of<WalletsService>(context);

    return Scaffold(
      backgroundColor: CFColors.white,
      appBar: AppBar(
        backgroundColor: CFColors.white,
        leadingWidth: 36.0 + 20.0, // account for 20 padding

        leading: Padding(
          padding: EdgeInsets.only(
            top: 10,
            bottom: 10,
            left: 20,
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: AppBarIconButton(
              size: 36,
              onPressed: () {
                Navigator.pop(context);
              },
              circularBorderRadius: 8,
              icon: SvgPicture.asset(
                "assets/svg/chevronLeft.svg",
                color: CFColors.twilight,
                width: 24,
                height: 24,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          // crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: FutureBuilder(
                future: walletsService.currentWalletName,
                builder: (
                  BuildContext context,
                  AsyncSnapshot<String> snapshot,
                ) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot == null ||
                        snapshot.hasError ||
                        snapshot.data == null ||
                        snapshot.data.isEmpty) {
                      // TODO: display error notification?
                      return FittedBox(
                        child: Text(
                          "failed to load wallet",
                          style: GoogleFonts.workSans(
                            color: CFColors.spark,
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                          ),
                        ),
                      );
                    }
                    return FittedBox(
                      child: Text(
                        snapshot.data,
                        style: GoogleFonts.workSans(
                          color: CFColors.spark,
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                        ),
                      ),
                    );
                  } else {
                    return CircularProgressIndicator(
                      color: CFColors.spark,
                      strokeWidth: 2,
                    );
                  }
                },
              ),
            ),
            SizedBox(height: 12),
            Center(
              child: FittedBox(
                child: Text(
                  'Enter PIN',
                  style: GoogleFonts.workSans(
                    color: CFColors.dusk,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            SizedBox(height: 48),
            CustomPinPut(
              fieldsCount: 4,
              eachFieldHeight: 12,
              eachFieldWidth: 12,
              textStyle: GoogleFonts.workSans(
                fontSize: 1,
              ),
              focusNode: _pinFocusNode,
              controller: _pinTextController,
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
                final store = new FlutterSecureStorage();

                final walletName = await walletsService.currentWalletName;
                final id = await walletsService.getWalletId(walletName);
                final storedPin = await store.read(key: '${id}_pin');

                if (storedPin == pin) {
                  OverlayNotification.showSuccess(
                    context,
                    "PIN code correct. Unlocking wallet...",
                    Duration(milliseconds: 2200),
                  );

                  // check if initial log in
                  if (widget.routeOnSuccess == "/mainview") {
                    final networkName = await walletsService.networkName;
                    await logIn(networkName, walletName, id);
                  }

                  await Future.delayed(Duration(milliseconds: 100));

                  Navigator.pushReplacementNamed(
                      context, widget.routeOnSuccess);
                } else {
                  OverlayNotification.showError(
                    context,
                    'Incorrect PIN. Please try again',
                    Duration(milliseconds: 1500),
                  );

                  await Future.delayed(Duration(milliseconds: 100));

                  _pinTextController.text = '';
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
