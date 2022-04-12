import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/notifications/campfire_alert.dart';
import 'package:paymint/notifications/modal_popup_dialog.dart';
import 'package:paymint/services/node_service.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/logger.dart';
import 'package:paymint/utilities/misc_global_constants.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:paymint/widgets/custom_buttons/simple_button.dart';
import 'package:provider/provider.dart';

import '../pages/settings_view/settings_subviews/network_settings_subviews/node_details_view.dart';

class NodeCard extends StatefulWidget {
  const NodeCard({Key key, this.nodeName, this.nodeData}) : super(key: key);

  final String nodeName;
  final Map<String, dynamic> nodeData;

  @override
  _NodeCardState createState() => _NodeCardState();
}

class _NodeCardState extends State<NodeCard> {
  String _name;

  Color _backgroundColor = CFColors.white;

  @override
  void initState() {
    _name = widget.nodeName;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final nodeService = Provider.of<NodeService>(context);
    return GestureDetector(
      onTapDown: (tapDownDetails) {
        Logger.print(tapDownDetails.globalPosition);
        showDialog(
          barrierColor: Colors.transparent,
          context: context,
          builder: (builderContext) {
            final position = tapDownDetails.globalPosition;
            return Stack(
              children: [
                Positioned(
                  top: position.dy - 20,
                  left: position.dx,
                  child: Container(
                    decoration: BoxDecoration(
                      color: CFColors.white,
                      borderRadius: BorderRadius.circular(
                          SizingUtilities.circularBorderRadius),
                      boxShadow: [CFColors.standardBoxShadow],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 10,
                              left: 12,
                              right: 12 +
                                  40.0, // +40 to give it mo9re width as per the design
                              bottom: 10,
                            ),
                            child: Text(
                              "Connect",
                              style: GoogleFonts.workSans(
                                decoration: TextDecoration.none,
                                color: CFColors.midnight,
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          onTap: () async {
                            await nodeService.setCurrentNode(_name);
                            Navigator.pop(context);
                          },
                        ),
                        GestureDetector(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 10,
                              left: 12,
                              right: 12,
                              bottom: 10,
                            ),
                            child: Text(
                              "Details",
                              style: GoogleFonts.workSans(
                                decoration: TextDecoration.none,
                                color: CFColors.midnight,
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          onTap: () async {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (_) => NodeDetailsView(
                                  isEdit: false,
                                  nodeData: widget.nodeData,
                                  nodeName: _name,
                                ),
                                settings: RouteSettings(
                                  name: "/nodedetailsview",
                                ),
                              ),
                            );
                          },
                        ),
                        if (_name != CampfireConstants.defaultNodeName)
                          GestureDetector(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 10,
                                left: 12,
                                right: 12,
                                bottom: 10,
                              ),
                              child: Text(
                                "Edit",
                                style: GoogleFonts.workSans(
                                  decoration: TextDecoration.none,
                                  color: CFColors.midnight,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            onTap: () async {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (_) => NodeDetailsView(
                                    isEdit: true,
                                    nodeData: widget.nodeData,
                                    nodeName: _name,
                                  ),
                                  settings: RouteSettings(
                                    name: "/editnodedetailsview",
                                  ),
                                ),
                              );
                            },
                          ),
                        if (_name != CampfireConstants.defaultNodeName)
                          GestureDetector(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 10,
                                left: 12,
                                right: 12,
                                bottom: 10,
                              ),
                              child: Text(
                                "Delete",
                                style: GoogleFonts.workSans(
                                  decoration: TextDecoration.none,
                                  color: CFColors.midnight,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            onTap: () async {
                              showDialog(
                                useSafeArea: false,
                                barrierColor: Colors.transparent,
                                barrierDismissible: false,
                                context: builderContext,
                                builder: (ctx) => ModalPopupDialog(
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
                                          "Do you want to delete $_name?",
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
                                                height: SizingUtilities
                                                    .standardButtonHeight,
                                                child: SimpleButton(
                                                  child: FittedBox(
                                                    child: Text(
                                                      "CANCEL",
                                                      style: CFTextStyles.button
                                                          .copyWith(
                                                        color: CFColors.dusk,
                                                      ),
                                                    ),
                                                  ),
                                                  onTap: () {
                                                    Navigator.of(context).pop();
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 16,
                                            ),
                                            Expanded(
                                              child: SizedBox(
                                                height: SizingUtilities
                                                    .standardButtonHeight,
                                                child: GradientButton(
                                                  child: FittedBox(
                                                    child: Text(
                                                      "DELETE",
                                                      style:
                                                          CFTextStyles.button,
                                                    ),
                                                  ),
                                                  onTap: () async {
                                                    bool success =
                                                        await nodeService
                                                            .deleteNode(_name);
                                                    Navigator.of(context).pop();
                                                    Navigator.of(context).pop();
                                                    if (!success) {
                                                      showDialog(
                                                        useSafeArea: false,
                                                        barrierDismissible:
                                                            false,
                                                        context: ctx,
                                                        builder: (_) =>
                                                            CampfireAlert(
                                                                message:
                                                                    "Error: Could not delete node named \"$_name\"!"),
                                                      );
                                                    }
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
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ).then((_) {
          if (mounted) {
            setState(() {
              _backgroundColor = CFColors.white;
            });
          }
        });
      },
      onTap: () {
        setState(() {
          _backgroundColor = CFColors.fog;
        });
      },
      child: Container(
        color: _backgroundColor,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 14),
          child: Row(
            children: [
              SvgPicture.asset(
                "assets/svg/node.svg",
                height: 24,
                width: 24,
                color: CFColors.twilight,
              ),
              SizedBox(
                width: 18,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _name,
                    style: GoogleFonts.workSans(
                      color: CFColors.starryNight,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 0.25,
                    ),
                  ),
                  if (nodeService.activeNodeName == _name)
                    Text(
                      "Connected",
                      style: GoogleFonts.workSans(
                        color: CFColors.twilight,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
