import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/notifications/campfire_alert.dart';
import 'package:paymint/notifications/modal_popup_dialog.dart';
import 'package:paymint/notifications/overlay_notification.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/services/node_service.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/misc_global_constants.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:paymint/widgets/custom_buttons/simple_button.dart';
import 'package:provider/provider.dart';

class NodeDetailsView extends StatefulWidget {
  const NodeDetailsView({
    Key key,
    @required this.isEdit,
    @required this.nodeName,
    @required this.nodeData,
  }) : super(key: key);

  final bool isEdit;
  final String nodeName;
  final Map<String, dynamic> nodeData;

  @override
  _NodeDetailsViewState createState() => _NodeDetailsViewState(isEdit);
}

class _NodeDetailsViewState extends State<NodeDetailsView> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _portController = TextEditingController();
  // final _usernameController = TextEditingController();
  // final _passwordController = TextEditingController();

  // var _useSSL = false;
  final _isEditing;

  final TextStyle _titleStyle = GoogleFonts.workSans(
    color: CFColors.dusk,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  _NodeDetailsViewState(this._isEditing);

  void _onSavePressed() async {
    final name = _nameController.text;
    final ipAddress = _addressController.text;
    final port = _portController.text;

    final nodesService = Provider.of<NodeService>(context, listen: false);
    final id = widget.nodeData["id"];
    final success = nodesService.editNode(
      id: id,
      originalName: widget.nodeName,
      updatedName: name,
      updatedIpAddress: ipAddress,
      updatedPort: port,
    );

    // check for duplicate node name
    if (success) {
      FocusScope.of(context).unfocus();
      await Future.delayed(Duration(milliseconds: 200));
      Navigator.pop(context);
    } else {
      showDialog(
        useSafeArea: false,
        barrierDismissible: false,
        context: context,
        builder: (_) => CampfireAlert(
            message: "A node with the name \"$name\" already exists!"),
      );
    }
  }

  void _onTestPressed() async {
    final manager = Provider.of<Manager>(context, listen: false);

    final canConnect = await manager.testNetworkConnection(
        _addressController.text, int.parse(_portController.text));

    if (canConnect) {
      OverlayNotification.showSuccess(
          context, "Connection test passed!", Duration(seconds: 2));
    } else {
      OverlayNotification.showError(
          context, "Connection failed!", Duration(seconds: 2));
    }
  }

  @override
  void initState() {
    _nameController.text = widget.nodeName;
    _addressController.text = widget.nodeData["ipAddress"];
    _portController.text = widget.nodeData["port"];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Padding(
        padding: EdgeInsets.only(
          top: 10,
          left: SizingUtilities.standardPadding,
          right: SizingUtilities.standardPadding,
          bottom: SizingUtilities.standardPadding,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      _buildForm(context),
                      Spacer(),
                      _buildTestButton(context),
                      if (_isEditing) SizedBox(height: 12),
                      if (_isEditing) _buildSaveButton(context),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: CFColors.white,
      title: Text(
        _isEditing ? "Edit node" : "Node Details",
        style: _titleStyle,
      ),
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
            onPressed: () async {
              if (_isEditing) {
                FocusScope.of(context).unfocus();
                await Future.delayed(Duration(milliseconds: 50));
              }

              final navigator = Navigator.of(context);
              navigator.pop();
              navigator.pop();
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
      actions: [
        if (!_isEditing && widget.nodeName != CampfireConstants.defaultNodeName)
          Padding(
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
                  "assets/svg/more-vertical.svg",
                  color: CFColors.twilight,
                  width: 24,
                  height: 24,
                ),
                circularBorderRadius: 8,
                onPressed: () async {
                  FocusScope.of(context).unfocus();
                  await Future.delayed(Duration(milliseconds: 50));

                  showDialog(
                    barrierColor: Colors.transparent,
                    context: context,
                    builder: (context) {
                      return _buildPopupMenu(context);
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  _buildPopupMenu(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: SizingUtilities.getStatusBarHeight(context) + 9,
          right: SizingUtilities.standardPadding,
          child: Container(
            decoration: BoxDecoration(
              color: CFColors.white,
              borderRadius:
                  BorderRadius.circular(SizingUtilities.circularBorderRadius),
              boxShadow: [CFColors.standardBoxShadow],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        CupertinoPageRoute(builder: (context) {
                      return NodeDetailsView(
                        isEdit: true,
                        nodeData: widget.nodeData,
                        nodeName: widget.nodeName,
                      );
                    })).then((_) {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      navigator.pop();
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 10,
                      left: 12,
                      right: 12,
                      bottom: 5,
                    ),
                    child: Text(
                      "Edit node",
                      style: GoogleFonts.workSans(
                        decoration: TextDecoration.none,
                        color: CFColors.midnight,
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      useSafeArea: false,
                      barrierColor: Colors.transparent,
                      barrierDismissible: false,
                      context: context,
                      builder: (context) => _buildNodeDeleteConfirmDialog(),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 5,
                      left: 12,
                      right: 12,
                      bottom: 10,
                    ),
                    child: Text(
                      "Delete node",
                      style: GoogleFonts.workSans(
                        decoration: TextDecoration.none,
                        color: CFColors.midnight,
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  _buildNodeDeleteConfirmDialog() {
    final nodeService = Provider.of<NodeService>(context, listen: false);
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
              "Do you want to delete ${widget.nodeName}?",
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
                        final navigator = Navigator.of(context);
                        navigator.pop();
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
                          "DELETE",
                          style: CFTextStyles.button,
                        ),
                      ),
                      onTap: () async {
                        bool success =
                            await nodeService.deleteNode(widget.nodeName);
                        if (success) {
                          final navigator = Navigator.of(context);
                          navigator.pop();
                          navigator.pop();
                          navigator.pop();
                          navigator.pop();
                        } else {
                          showDialog(
                            useSafeArea: false,
                            barrierDismissible: false,
                            context: context,
                            builder: (_) => CampfireAlert(
                                message:
                                    "Error: Could not delete node named \"${widget.nodeName}\"!"),
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
    );
  }

  _buildForm(BuildContext context) {
    return Column(
      children: [
        TextField(
          enabled: _isEditing,
          controller: _nameController,
        ),
        SizedBox(
          height: 12,
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                enabled: _isEditing,
                controller: _addressController,
              ),
            ),
            SizedBox(
              width: 16,
            ),
            Expanded(
              child: TextField(
                enabled: _isEditing,
                controller: _portController,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        // SizedBox(
        //   height: 12,
        // ),
        // TextField(
        //   enabled: _isEditing,
        //   controller: _usernameController,
        // ),
        // SizedBox(
        //   height: 12,
        // ),
        // TextField(
        //   enabled: _isEditing,
        //   controller: _passwordController,
        // ),
        // Row(
        //   children: [
        //     Checkbox(
        //       value: _useSSL,
        //       onChanged: _isEditing
        //           ? (newValue) {
        //               setState(() {
        //                 _useSSL = newValue;
        //               });
        //             }
        //           : null,
        //     ),
        //     Text(
        //       "Use SSL",
        //       style: GoogleFonts.workSans(
        //         color: CFColors.dusk,
        //         fontWeight: FontWeight.w400,
        //         fontSize: 14,
        //       ),
        //     )
        //   ],
        // ),
      ],
    );
  }

  _buildTestButton(BuildContext context) {
    return SizedBox(
      height: 48,
      width: MediaQuery.of(context).size.width -
          (SizingUtilities.standardPadding * 2),
      child: SimpleButton(
        child: FittedBox(
          child: Text(
            "TEST CONNECTION",
            style: CFTextStyles.button.copyWith(
              color: CFColors.dusk,
            ),
          ),
        ),
        onTap: () {
          _onTestPressed();
        },
      ),
    );
  }

  _buildSaveButton(BuildContext context) {
    return SizedBox(
      height: 48,
      width: MediaQuery.of(context).size.width -
          (SizingUtilities.standardPadding * 2),
      child: GradientButton(
        child: Text(
          "SAVE",
          style: CFTextStyles.button,
        ),
        onTap: () {
          _onSavePressed();
          Navigator.pop(context);
        },
      ),
    );
  }
}
