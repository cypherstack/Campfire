import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/notifications/campfire_alert.dart';
import 'package:paymint/notifications/overlay_notification.dart';
import 'package:paymint/services/bitcoin_service.dart';
import 'package:paymint/services/node_service.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:paymint/widgets/custom_buttons/simple_button.dart';
import 'package:provider/provider.dart';

class AddCustomNodeView extends StatefulWidget {
  const AddCustomNodeView({Key key}) : super(key: key);

  @override
  _AddCustomNodeViewState createState() => _AddCustomNodeViewState();
}

class _AddCustomNodeViewState extends State<AddCustomNodeView> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _portController = TextEditingController();
  // final _usernameController = TextEditingController();
  // final _passwordController = TextEditingController();

  final TextStyle _titleStyle = GoogleFonts.workSans(
    color: CFColors.dusk,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  final TextStyle _hintStyle = GoogleFonts.workSans(
    color: CFColors.twilight,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  void _onSavePressed() async {
    final name = _nameController.text;
    final url = _addressController.text;
    final port = _portController.text;

    final nodesService = Provider.of<NodeService>(context, listen: false);

    // try to create a new node
    final success =
        nodesService.createNode(name: name, ipAddress: url, port: port);

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
    final bitcoinService = Provider.of<BitcoinService>(context, listen: false);

    final canConnect = await bitcoinService.testConnection(
        _addressController.text, _portController.text);

    if (canConnect) {
      OverlayNotification.showSuccess(
          context, "Connection test passed!", Duration(seconds: 2));
    } else {
      OverlayNotification.showError(
          context, "Connection failed!", Duration(seconds: 2));
    }
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
                      SizedBox(height: 12),
                      _buildSaveButton(context),
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
        "Add custom node",
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
              FocusScope.of(context).unfocus();
              await Future.delayed(Duration(milliseconds: 50));

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
    );
  }

  _buildForm(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration:
              InputDecoration(hintText: "Node name", hintStyle: _hintStyle),
        ),
        SizedBox(
          height: 12,
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _addressController,
                decoration: InputDecoration(
                    hintText: "IP address", hintStyle: _hintStyle),
              ),
            ),
            SizedBox(
              width: 16,
            ),
            Expanded(
              child: TextField(
                controller: _portController,
                decoration:
                    InputDecoration(hintText: "Port", hintStyle: _hintStyle),
              ),
            ),
          ],
        ),
        // SizedBox(
        //   height: 12,
        // ),
        // TextField(
        //   controller: _usernameController,
        // ),
        // SizedBox(
        //   height: 12,
        // ),
        // TextField(
        //   controller: _passwordController,
        // ),
        // Row(
        //   children: [
        //     Checkbox(
        //       value: _useSSL,
        //       onChanged: _isEditing
        //           ? (newValue) {
        //         setState(() {
        //           _useSSL = newValue;
        //         });
        //       }
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
        onTap: () async {
          _onSavePressed();
        },
      ),
    );
  }
}
