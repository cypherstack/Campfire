import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:paymint/notifications/campfire_alert.dart';
import 'package:paymint/services/address_book_service.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/clipboard_interface.dart';
import 'package:paymint/utilities/logger.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:paymint/widgets/custom_buttons/simple_button.dart';
import 'package:provider/provider.dart';

class EditAddressBookEntryView extends StatefulWidget {
  const EditAddressBookEntryView({
    Key key,
    @required this.name,
    @required this.address,
    this.clipboard = const ClipboardWrapper(),
  }) : super(key: key);

  final String name;
  final String address;
  final ClipboardInterface clipboard;

  @override
  _EditAddressBookEntryViewState createState() =>
      _EditAddressBookEntryViewState();
}

class _EditAddressBookEntryViewState extends State<EditAddressBookEntryView> {
  TextEditingController addressTextController = TextEditingController();
  TextEditingController nameTextController = TextEditingController();
  ClipboardInterface clipboard;
  var _manager;

  bool _enabledSave;
  bool _isEmptyAddress;

  @override
  initState() {
    _manager = Provider.of<Manager>(context, listen: false);
    clipboard = widget.clipboard;
    addressTextController.text = widget.address;
    nameTextController.text = widget.name;
    _enabledSave =
        _manager.validateAddress(widget.address) && widget.name.isNotEmpty;
    _isEmptyAddress = widget.address.isEmpty;
    super.initState();
  }

  _updateInvalidAddressText(String address, Manager manager) {
    if (address.isNotEmpty && !manager.validateAddress(address)) {
      return "Invalid address";
    }
    return null;
  }

  Future<void> _saveEditedAddressEntry(BuildContext context) async {
    final name = nameTextController.text;
    final address = addressTextController.text;

    if (name == widget.name && address == widget.address) {
      // no need to update anything
      Navigator.pop(context);
      return;
    }

    // these should never fail as the send button should be disabled
    // if either field is left empty
    assert(name.isNotEmpty);
    assert(address.isNotEmpty);

    final addressService =
        Provider.of<AddressBookService>(context, listen: false);

    if (address == widget.address) {
      await addressService.removeAddressBookEntry(address);
      await addressService.addAddressBookEntry(address, name);
      // on success pop back to address book
      Navigator.pop(context);
      Navigator.pop(context);
    } else if (await addressService.containsAddress(address)) {
      showDialog(
        context: context,
        useSafeArea: false,
        barrierDismissible: false,
        builder: (_) {
          return CampfireAlert(
              message: "The address you entered is already in your contacts!");
        },
      );
    } else {
      try {
        // add the edited contact
        await addressService.addAddressBookEntry(address, name);

        // remove the original
        await addressService.removeAddressBookEntry(widget.address);

        // on success pop back to address book
        Navigator.pop(context);
        Navigator.pop(context);
      } catch (error) {
        showDialog(
          context: context,
          useSafeArea: false,
          barrierDismissible: false,
          builder: (_) {
            return CampfireAlert(
                message:
                    "The address you entered is already in your contacts!");
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: CFColors.white,
        title: Text(
          "Edit Contact",
          style: TextStyle(
            color: CFColors.dusk,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        // leading appbar button
        leadingWidth: 36.0 + 20.0, // account for 20 padding
        leading: Padding(
          padding: EdgeInsets.only(
            top: 10, // * screenSize.height / 640,
            bottom: 10, // * screenSize.height / 640,
            left: 20, // * screenSize.width / 360,
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: AppBarIconButton(
              key: Key("editAddressBookEntryBackButtonKey"),
              size: 36,
              onPressed: () {
                Navigator.pop(context);
              },
              circularBorderRadius: SizingUtilities.circularBorderRadius,
              icon: SvgPicture.asset(
                "assets/svg/chevronLeft.svg",
                color: CFColors.twilight,
              ),
            ),
          ),
        ),
      ),
      body: Container(
        color: CFColors.white,
        child: LayoutBuilder(
          builder: (context, constraint) {
            return Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  top: 8,
                  left: 4,
                  right: 4,
                  bottom: 16,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    // subtract top and bottom padding set in parent
                    minHeight: constraint.maxHeight - 8 - 16,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        TextField(
                          key: Key("editAddressBookEntryAddressFieldKey"),
                          readOnly: false,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(
                                RegExp("[a-zA-Z0-9]{34}")),
                          ],
                          toolbarOptions: ToolbarOptions(
                            copy: true,
                            cut: false,
                            paste: true,
                            selectAll: false,
                          ),
                          onChanged: (newValue) {
                            final content = newValue;
                            setState(() {
                              _enabledSave =
                                  _manager.validateAddress(content) &&
                                      nameTextController.text.isNotEmpty;
                              _isEmptyAddress = content.isEmpty;
                            });
                          },
                          controller: addressTextController,
                          decoration: InputDecoration(
                            errorText: _updateInvalidAddressText(
                                addressTextController.text, _manager),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: CFColors.twilight,
                              ),
                              borderRadius: BorderRadius.circular(
                                  SizingUtilities.circularBorderRadius),
                            ),
                            hintText: "Paste address",
                            contentPadding: EdgeInsets.only(
                              left: 16,
                              top: 12,
                              bottom: 12,
                              right: 0,
                            ),
                            suffixIcon: UnconstrainedBox(
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                  ),
                                  _isEmptyAddress
                                      ? GestureDetector(
                                          key: Key(
                                              "editAddressBookEntryPasteAddressButtonKey"),
                                          onTap: () async {
                                            final ClipboardData data =
                                                await clipboard.getData(
                                                    Clipboard.kTextPlain);

                                            if (data != null &&
                                                data.text.isNotEmpty) {
                                              final content = data.text.trim();
                                              addressTextController.text =
                                                  content;
                                              setState(() {
                                                _enabledSave =
                                                    _manager.validateAddress(
                                                            content) &&
                                                        nameTextController
                                                            .text.isNotEmpty;
                                                _isEmptyAddress =
                                                    content.isEmpty;
                                              });
                                            }
                                          },
                                          child: SvgPicture.asset(
                                            "assets/svg/clipboard.svg",
                                            color: CFColors.twilight,
                                            width: 20,
                                            height: 20,
                                          ),
                                        )
                                      : GestureDetector(
                                          key: Key(
                                              "editAddressBookEntryClearAddressButtonKey"),
                                          onTap: () async {
                                            addressTextController.text = "";
                                            setState(() {
                                              _enabledSave = false;
                                              _isEmptyAddress = true;
                                            });
                                          },
                                          child: SvgPicture.asset(
                                            "assets/svg/x.svg",
                                            color: CFColors.twilight,
                                            width: 20,
                                            height: 20,
                                          ),
                                        ),
                                  SizedBox(
                                    width: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 12,
                        ),
                        TextField(
                          key: Key("editAddressBookEntryNameFieldKey"),
                          controller: nameTextController,
                          decoration: InputDecoration(
                            hintText: "Enter name",
                          ),
                          onChanged: (_) {
                            setState(() {
                              _enabledSave = _manager.validateAddress(
                                      addressTextController.text) &&
                                  nameTextController.text.isNotEmpty;
                            });
                          },
                        ),
                        SizedBox(
                          height: 12,
                        ),
                        Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SizedBox(
                              height: 48,
                              width: (screenWidth - 40 - 16) / 2,
                              child: SimpleButton(
                                onTap: () async {
                                  FocusScope.of(context).unfocus();
                                  await Future.delayed(
                                      Duration(milliseconds: 150));
                                  Logger.print(
                                      "cancel add new address entry pressed");
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  "CANCEL",
                                  style: CFTextStyles.button.copyWith(
                                    color: CFColors.dusk,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 48,
                              width: (screenWidth - 40 - 16) / 2,
                              child: GradientButton(
                                enabled: _enabledSave,
                                child: Text(
                                  "SAVE",
                                  style: CFTextStyles.button,
                                ),
                                onTap: () async {
                                  FocusScope.of(context).unfocus();
                                  await Future.delayed(
                                      Duration(milliseconds: 150));
                                  _saveEditedAddressEntry(context);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
