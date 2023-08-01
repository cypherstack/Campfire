import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/notifications/campfire_alert.dart';
import 'package:paymint/notifications/modal_popup_dialog.dart';
import 'package:paymint/pages/one_time_rescan_failed_dialog.dart';
import 'package:paymint/pages/settings_view/settings_view.dart';
import 'package:paymint/pages/wallet_selection_view.dart';
import 'package:paymint/pages/wallet_view/receive_view.dart';
import 'package:paymint/pages/wallet_view/send_view.dart';
import 'package:paymint/pages/wallet_view/wallet_view.dart';
import 'package:paymint/services/coins/firo/firo_wallet.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/services/event_bus/events/refresh_percent_changed_event.dart';
import 'package:paymint/services/event_bus/global_event_bus.dart';
import 'package:paymint/services/events.dart';
import 'package:paymint/services/wallets_service.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:provider/provider.dart';
import 'package:wakelock/wakelock.dart';

import '../widgets/custom_buttons/app_bar_icon_button.dart';

/// MainView refers to the main tab bar navigation and view system in place
class MainView extends StatefulWidget {
  MainView({Key key, this.pageIndex, this.args, this.disableRefreshOnInit})
      : super(key: key);

  final int pageIndex;
  final Map<String, dynamic> args;
  final bool disableRefreshOnInit;

  @override
  _MainViewState createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  NodeConnectionStatus nodeState = NodeConnectionStatus.loading;
  int _currentIndex = 1;
  final double _navBarRadius = SizingUtilities.circularBorderRadius * 1.8;

  bool _hasSynced = false;
  bool _disableRefreshOnInit = false;

  GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();

  List<Widget> children;

  /// Tab icon color based on tab selection
  Color _buildIconColor(int index) {
    if (index == this._currentIndex) {
      return CFColors.spark;
    } else {
      return CFColors.twilight;
    }
  }

  // TODO: bring back styling that Flutter 2.10 broke
  /// Tab text color based on tab selection
  // TextStyle _buildTextStyle(int index) {
  //   if (index == this._currentIndex) {
  //     return GoogleFonts.workSans(
  //       textStyle: TextStyle(
  //         color: CFColors.spark,
  //         fontSize: 14,
  //         fontWeight: FontWeight.w600,
  //         fontStyle: FontStyle.normal,
  //       ),
  //     );
  //   } else {
  //     return GoogleFonts.workSans(
  //       textStyle: TextStyle(
  //         color: CFColors.twilight,
  //         fontSize: 14,
  //         fontWeight: FontWeight.w600,
  //         fontStyle: FontStyle.normal,
  //       ),
  //     );
  //   }
  // }

  void _setCurrentIndex(int newIndex) {
    setState(() {
      _currentIndex = newIndex;
    });
  }

  StreamSubscription _nodeConnectionStatusChangedEventListener;
  StreamSubscription _refreshPercentChangedEventListener;

  double _percentChanged = 0.0;

  Future<void> _oneTimeRescan() async {
    Wakelock.enable();
    // show restoring in progress
    showDialog(
      context: context,
      useSafeArea: false,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
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
                  "Rescanning wallet",
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
                height: 12,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FittedBox(
                  child: Text(
                    "Do not close or leave the app until this completes!",
                    style: GoogleFonts.workSans(
                      color: CFColors.dusk,
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                    maxLines: 2,
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

    try {
      // do rescan
      await Provider.of<Manager>(context, listen: false).fullRescan();

      // mark one time rescan success
      await (Provider.of<Manager>(
        context,
        listen: false,
      ).currentWallet as FiroWallet)
          .setOneTimeSunsettingRescanDone();

      // start refreshing
      Provider.of<Manager>(
        context,
        listen: false,
      ).refresh();

      // pop scanning dialog
      Navigator.pop(context);

      showDialog(
        context: context,
        useSafeArea: false,
        barrierDismissible: false,
        builder: (_) => CampfireAlert(message: "Rescan succeeded"),
      );
      Wakelock.disable();
    } catch (e) {
      Wakelock.disable();
      // pop waiting dialog
      Navigator.pop(context);
      // show restoring wallet failed dialog
      final result = await showDialog<dynamic>(
        context: context,
        useSafeArea: false,
        barrierDismissible: false,
        builder: (_) => OneTimeRescanFailedDialog(
          errorMessage: e.toString(),
        ),
      );

      if (result == "retry") {
        return await _oneTimeRescan();
      } else {
        Navigator.pop(context);
      }
    }
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

    if (widget.disableRefreshOnInit != null) {
      _disableRefreshOnInit = widget.disableRefreshOnInit;
      nodeState = NodeConnectionStatus.synced;
    }

    if (widget.pageIndex != null) {
      _currentIndex = widget.pageIndex;
    }

    children = [
      SendView(
        autofillArgs: widget.args,
      ),
      WalletView(),
      ReceiveView(),
      // MoreView(),
    ];

    _nodeConnectionStatusChangedEventListener = GlobalEventBus.instance
        .on<NodeConnectionStatusChangedEvent>()
        .listen((event) {
      if (nodeState != event.newStatus) {
        setState(() {
          nodeState = event.newStatus;
        });
        _disableRefreshOnInit = false;
      }
    });

    _refreshPercentChangedEventListener = GlobalEventBus.instance
        .on<RefreshPercentChangedEvent>()
        .listen((event) {
      setState(() {
        _percentChanged = event.percent;
      });
    });

    final manager = Provider.of<Manager>(context, listen: false);

    if ((manager.currentWallet as FiroWallet).getOneTimeSunsettingRescanDone) {
      if (!_disableRefreshOnInit) {
        manager.refresh();
      }
    } else {
      // init rescan
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _oneTimeRescan();
      });
    }

    super.initState();
  }

  @override
  dispose() {
    _nodeConnectionStatusChangedEventListener?.cancel();
    _refreshPercentChangedEventListener?.cancel();
    super.dispose();
  }

  AppBar buildAppBar(BuildContext context) {
    final manager = Provider.of<Manager>(context, listen: false);
    final walletsService = Provider.of<WalletsService>(context);
    return AppBar(
      backgroundColor: CFColors.white,
      title: FutureBuilder(
        future: walletsService.currentWalletName,
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Text(
              snapshot.data == null ? "Error loading wallet..." : snapshot.data,
              style: GoogleFonts.workSans(
                color: CFColors.spark,
                fontSize: 16,
                fontWeight: FontWeight.w600,
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

      // trailing appbar button
      actions: [
        Padding(
          padding: EdgeInsets.only(
            top: 10,
            bottom: 10,
            right: 20,
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: AppBarIconButton(
              key: Key("mainViewSettingsButton"),
              size: 36,
              icon: SvgPicture.asset(
                "assets/svg/menu.svg",
                color: CFColors.twilight,
                width: 24,
                height: 24,
              ),
              circularBorderRadius: 8,
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => SettingsView(),
                    settings: RouteSettings(name: "/settingsview"),
                  ),
                );
              },
            ),
          ),
        ),
      ],

      // leading appbar button
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
            key: Key("mainViewRefreshButton"),
            size: 36,
            onPressed: () {
              if (nodeState != NodeConnectionStatus.loading) {
                manager.refresh();
              }
            },
            circularBorderRadius: 8,
            icon: _selectIconAsset(),
          ),
        ),
      ),
    );
  }

  _selectIconAsset() {
    switch (nodeState) {
      case NodeConnectionStatus.synced:
        return SvgPicture.asset(
          "assets/svg/radio.svg",
          color: CFColors.twilight,
          width: 24,
          height: 24,
        );

      case NodeConnectionStatus.connecting:
        return SvgPicture.asset(
          "assets/svg/refresh-cw.svg",
          color: CFColors.twilight,
          width: 24,
          height: 24,
        );

      case NodeConnectionStatus.disconnected:
        return SvgPicture.asset(
          "assets/svg/radio-disconnected.svg",
          color: CFColors.twilight,
          width: 24,
          height: 24,
        );

      case NodeConnectionStatus.loading:
        return SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            color: CFColors.twilight,
            strokeWidth: 2,
          ),
        );
    }
  }

  bool _exitOnBackButton = false;

  Future<bool> _onWillPop(BuildContext context) async {
    if (_exitOnBackButton == false) {
      Timer timer = Timer(Duration(milliseconds: 3000), () {
        Navigator.of(context, rootNavigator: true).pop();
        _exitOnBackButton = false;
      });
      _exitOnBackButton = true;
      // TODO proper log out notification dialog
      await showDialog(
        context: context,
        useSafeArea: false,
        barrierDismissible: false,
        builder: (context) {
          return ModalPopupDialog(
            child: Container(
              width: MediaQuery.of(context).size.width -
                  (SizingUtilities.standardPadding * 2),
              child: Padding(
                padding: const EdgeInsets.all(SizingUtilities.standardPadding),
                child: Column(
                  children: [
                    Text(
                      "Tapping BACK again will log out of current wallet",
                      style: CFTextStyles.button.copyWith(
                        color: CFColors.spark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ).then((_) {
        timer?.cancel();
        timer = null;
      });
    }

    if (_exitOnBackButton) {
      final manager = Provider.of<Manager>(context, listen: false);
      final walletsService =
          Provider.of<WalletsService>(context, listen: false);
      await manager.exitCurrentWallet();
      await walletsService.setCurrentWalletName("");
      await walletsService.refreshWallets();
      // Navigator.of(context).popUntil((route) => route.settings.name == '/');
      Navigator.pushAndRemoveUntil(
        context,
        CupertinoPageRoute(
          maintainState: false,
          builder: (_) => WalletSelectionView(),
        ),
        (_) => false,
      );
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).userGestureInProgress) {
          // disable pull back navigation
          return false;
        } else {
          // check with user if we should log out
          return await _onWillPop(context);
        }
      },
      child: Scaffold(
        key: _key,
        backgroundColor: CFColors.white,
        appBar: buildAppBar(context),
        extendBody: false,
        bottomNavigationBar: Container(
          height: SizingUtilities.bottomToolBarHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(_navBarRadius),
              topRight: Radius.circular(_navBarRadius),
            ),
            boxShadow: <BoxShadow>[
              CFColors.standardBoxShadow,
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(_navBarRadius),
              topRight: Radius.circular(_navBarRadius),
            ),
            child: BottomNavigationBar(
              backgroundColor: CFColors.mist,
              // elevation: 0,
              currentIndex: _currentIndex,
              type: BottomNavigationBarType.fixed,
              onTap: _setCurrentIndex,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              items: [
                BottomNavigationBarItem(
                    icon: SvgPicture.asset(
                      "assets/svg/upload-2.svg",
                      color: _buildIconColor(0), // Index 0 -> send view
                      key: Key("mainViewNavBarSendItemKey"),
                    ),
                    // TODO: bring back styling that Flutter 2.10 broke
                    label: "Send"
                    // title: Text(
                    //   "Send",
                    //   style: _buildTextStyle(0),
                    // ),
                    ),
                BottomNavigationBarItem(
                    icon: SvgPicture.asset(
                      "assets/svg/wallet-2.svg",
                      color: _buildIconColor(1), // Index 1 -> wallet view
                      key: Key("mainViewNavBarWalletItemKey"),
                    ),
                    label: "Wallet"
                    // title: Text(
                    //   "Wallet",
                    //   style: _buildTextStyle(1),
                    // ),
                    ),
                BottomNavigationBarItem(
                    icon: SvgPicture.asset(
                      "assets/svg/download-2.svg",
                      color: _buildIconColor(2), // Index 2 -> receive view
                      key: Key("mainViewNavBarReceiveItemKey"),
                    ),
                    label: "Receive"
                    // title: Text(
                    //   "Receive",
                    //   style: _buildTextStyle(2),
                    // ),
                    ),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            IndexedStack(
              children: children,
              index: _currentIndex,
            ),
            if (nodeState == NodeConnectionStatus.loading &&
                !_disableRefreshOnInit)
              _buildSyncing(_percentChanged),
            if (nodeState == NodeConnectionStatus.synced &&
                !_disableRefreshOnInit)
              _buildConnected(),
            if (nodeState == NodeConnectionStatus.disconnected &&
                !_disableRefreshOnInit)
              _buildDisconnected(),
          ],
        ),
        // ),
      ),
    );
  }

  Column _buildDisconnected() {
    return Column(
      children: [
        _buildDropDown(context, "Could not connect. Tap to retry.",
            CFColors.dropdownError),
      ],
    );
  }

  Widget _buildConnected() {
    if (_hasSynced) {
      return Container();
    }
    _hasSynced = true;
    return Column(
      children: [
        FutureBuilder(
          future: Future.delayed(Duration(seconds: 3)),
          builder: (context, snapshot) {
            // return empty container to clear message after some time
            if (snapshot.connectionState == ConnectionState.done) {
              return Container();
            } else {
              return _buildDropDown(
                  context, "Connected", CFColors.notificationSuccess);
            }
          },
        ),
      ],
    );
  }

  Column _buildSyncing(double percent) {
    _hasSynced = false;
    final percentString = (percent * 100).toStringAsFixed(0);
    Container container;
    if (percent == 0.05) {
      container = _buildDropDown(
          context,
          "Synchronizing ($percentString%)\n Please do not exit.",
          CFColors.dropdownSynchronizing);
    } else if (percent == -0.013) {
      container = _buildDropDown(
          context,
          "Rescanning for update\n Please do not exit.\n This may take a few minutes.",
          CFColors.dropdownSynchronizing);
    } else {
      container = _buildDropDown(context, "Synchronizing ($percentString%)",
          CFColors.dropdownSynchronizing);
    }
    return Column(
      children: [
        container,
      ],
    );
  }

  Container _buildDropDown(
      BuildContext context, String message, Color backgroundColor) {
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(SizingUtilities.circularBorderRadius),
            bottomRight: Radius.circular(SizingUtilities.circularBorderRadius),
          ),
          boxShadow: [
            BoxShadow(
              color: CFColors.shadowColor,
              spreadRadius: 0.2,
              blurRadius: 1,
              offset: Offset(0, 2),
            )
          ]),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: FittedBox(
            child: Text(
              message,
              style: GoogleFonts.workSans(
                decoration: TextDecoration.none,
                color: CFColors.dusk,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
