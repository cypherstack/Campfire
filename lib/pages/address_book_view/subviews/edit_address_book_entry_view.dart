import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:paymint/notifications/campfire_alert.dart';
import 'package:paymint/services/address_book_service.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/utilities/cfcolors.dart';
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
  }) : super(key: key);

  final String name;
  final String address;

  @override
  _EditAddressBookEntryViewState createState() =>
      _EditAddressBookEntryViewState();
}

class _EditAddressBookEntryViewState extends State<EditAddressBookEntryView> {
  TextEditingController addressTextController = TextEditingController();
  TextEditingController nameTextController = TextEditingController();

  var _manager;

  bool _enabledSave;
  bool _isEmptyAddress;

  @override
  initState() {
    _manager = Provider.of<Manager>(context, listen: false);
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
    print("controller address: $address");
    print("controller name: $name");
    print("widget address: ${widget.address}");
    print("widget name: ${widget.name}");

    if (name == widget.name && address == widget.address) {
      // no need to update anything
      print("same same");
      return;
    }

    final addressService =
        Provider.of<AddressBookService>(context, listen: false);

    if (name.isEmpty || address.isEmpty) {
      print("both empoty");
      showDialog(
        context: context,
        useSafeArea: false,
        barrierDismissible: false,
        builder: (_) {
          return CampfireAlert(message: "Please fill out both fields.");
        },
      );
    } else {
      if (address == widget.address) {
        print("editing name only!");
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
                message:
                    "The address you entered is already in your contacts!");
          },
        );
      } else {
        try {
          print("editing address and possibly name!");

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
                size: 36,
                onPressed: () {
                  Navigator.pop(context);
                },
                circularBorderRadius: SizingUtilities.circularBorderRadius,
                icon: SvgPicture.asset(
                  "assets/svg/chevronLeft.svg",
                  color: CFColors.twilight,
                )),
          ),
        ),
      ),
      body: Container(
        color: CFColors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: 16,
                    left: 20,
                    right: 20,
                    bottom: 12,
                  ),
                  child: TextField(
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
                        _enabledSave = _manager.validateAddress(content) &&
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
                                    onTap: () async {
                                      final ClipboardData data =
                                          await Clipboard.getData(
                                              Clipboard.kTextPlain);

                                      if (data != null &&
                                          data.text.isNotEmpty) {
                                        final content = data.text.trim();
                                        addressTextController.text = content;
                                        setState(() {
                                          _enabledSave = _manager
                                                  .validateAddress(content) &&
                                              nameTextController
                                                  .text.isNotEmpty;
                                          _isEmptyAddress = content.isEmpty;
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
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: 12,
                  ),
                  child: TextField(
                    controller: nameTextController,
                    decoration: InputDecoration(
                      hintText: "Enter name",
                    ),
                    onChanged: (_) {
                      setState(() {
                        _enabledSave = _manager
                                .validateAddress(addressTextController.text) &&
                            nameTextController.text.isNotEmpty;
                      });
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    height: 48,
                    width: (screenWidth - 40 - 16) / 2,
                    child: SimpleButton(
                      onTap: () {
                        Logger.print("cancel add new address entry pressed");
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
                      onTap: () {
                        _saveEditedAddressEntry(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
