import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/pages/settings_view/settings_subviews/network_settings_subviews/node_card.dart';
import 'package:paymint/services/event_bus/events/node_connection_status_changed_event.dart';
import 'package:paymint/services/event_bus/global_event_bus.dart';
import 'package:paymint/services/node_service.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:provider/provider.dart';

import '../helpers/builders.dart';

class NetworkSettingsView extends StatefulWidget {
  const NetworkSettingsView({Key key}) : super(key: key);

  @override
  _NetworkSettingsViewState createState() => _NetworkSettingsViewState();
}

class _NetworkSettingsViewState extends State<NetworkSettingsView> {
  final _labelTextStyle = GoogleFonts.workSans(
    color: CFColors.twilight,
    fontWeight: FontWeight.w500,
    fontSize: 12,
  );

  final _itemTextStyle = GoogleFonts.workSans(
    color: CFColors.starryNight,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    letterSpacing: 0.25,
  );

  String _statusLabel = "Synchronized";
  StreamSubscription _nodeConnectionStatusChangedEventListener;

  @override
  initState() {
    // TODO add animations and other icons based on status
    _nodeConnectionStatusChangedEventListener =
        GlobalEventBus.instance.on<NodeConnectionStatusChangedEvent>().listen((event) {
      print("event caught");
      String newLabel;
      switch (event.newStatus) {
        case NodeConnectionStatus.synced:
          newLabel = "Synchronized";
          break;
        case NodeConnectionStatus.loading:
          newLabel = "Synchronizing";
          break;
        case NodeConnectionStatus.disconnected:
          newLabel = "Disconnected";
          break;
        case NodeConnectionStatus.connecting:
          newLabel = "Connecting";
          break;
      }
      if (newLabel != _statusLabel) {
        setState(() {
          _statusLabel = newLabel;
        });
      }
    });

    super.initState();
  }

  @override
  dispose() {
    _nodeConnectionStatusChangedEventListener.cancel();
    super.dispose();
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
              size: 36,
              icon: SvgPicture.asset(
                "assets/svg/plus.svg",
                color: CFColors.twilight,
              ),
              circularBorderRadius: SizingUtilities.circularBorderRadius,
              onPressed: () {
                Navigator.pushNamed(context, "/settings/addcustomnode");
              },
            ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(SizingUtilities.standardPadding),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                child: Text(
                  "Blockchain Status",
                  style: _labelTextStyle,
                ),
              ),
            ),
            Container(
              height: 52,
              child: Row(
                children: [
                  SizedBox(
                    width: 8,
                  ),
                  SvgPicture.asset(
                    "assets/svg/check-circle3.svg",
                    color: CFColors.twilight,
                    width: 24,
                    height: 24,
                  ),
                  SizedBox(
                    width: SizingUtilities.standardPadding,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      child: Text(
                        _statusLabel,
                        style: _itemTextStyle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                child: Text(
                  "My Nodes",
                  style: _labelTextStyle,
                ),
              ),
            ),
            SizedBox(
              height: 8,
            ),
            Expanded(
              child: ListView(
                children: _buildNodeList(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _buildNodeList(BuildContext context) {
    List<Widget> list = [];
    final nodeService = Provider.of<NodeService>(context);

    nodeService.nodes.forEach(
      (key, value) {
        // final isConnected = key == nodeService.activeNodeName;
        list.add(
          NodeCard(
            key: ValueKey(key),
            nodeName: key,
            nodeData: Map<String, dynamic>.from(value),
            // isConnected: isConnected,
          ),
        );
      },
    );

    return list;
  }
}
