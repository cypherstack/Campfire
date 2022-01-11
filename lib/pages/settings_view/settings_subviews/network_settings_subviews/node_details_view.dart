import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/services/node_service.dart';
import 'package:paymint/utilities/cfcolors.dart';
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
      //TODO show alert telling user they cannot use a name of another existing node
    }
  }

  void _onTestPressed() {
    // TODO implement test connection
    print("test connection pressed. // TODO implement test connection ");
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
        if (_isEditing)
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
              borderRadius: BorderRadius.circular(SizingUtilities.circularBorderRadius),
              boxShadow: [CFColors.standardBoxShadow],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, CupertinoPageRoute(builder: (context) {
                      return NodeDetailsView(isEdit: true);
                    })).then((_) => Navigator.pop(context));
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
                    // TODO implement delete node and show alert asking for delete confirmation
                    print(
                        "delete node pressed. // TODO implement delete node and possibly show alert asking for delete confirmation");

                    Navigator.pop(context);
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
      width: MediaQuery.of(context).size.width - (SizingUtilities.standardPadding * 2),
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
      width: MediaQuery.of(context).size.width - (SizingUtilities.standardPadding * 2),
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
