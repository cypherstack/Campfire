import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:paymint/notifications/campfire_alert.dart';
import 'package:paymint/services/address_book_service.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/utilities/address_utils.dart';
import 'package:paymint/utilities/barcode_scanner_interface.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/clipboard_interface.dart';
import 'package:paymint/utilities/logger.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:paymint/widgets/custom_buttons/simple_button.dart';
import 'package:provider/provider.dart';

class AddAddressBookEntryView extends StatefulWidget {
  const AddAddressBookEntryView({
    Key key,
    this.barcodeScanner = const BarcodeScannerWrapper(),
    this.clipboard = const ClipboardWrapper(),
  }) : super(key: key);

  final BarcodeScannerInterface barcodeScanner;
  final ClipboardInterface clipboard;

  @override
  _AddAddressBookEntryViewState createState() =>
      _AddAddressBookEntryViewState();
}

class _AddAddressBookEntryViewState extends State<AddAddressBookEntryView> {
  TextEditingController addressTextController = TextEditingController();
  TextEditingController nameTextController = TextEditingController();
  BarcodeScannerInterface scanner;
  ClipboardInterface clipboard;

  bool _enabledSave = false;
  bool _isEmptyAddress = true;

  _updateInvalidAddressText(String address, Manager manager) {
    if (address.isNotEmpty && !manager.validateAddress(address)) {
      return "Invalid address";
    }
    return null;
  }

  @override
  initState() {
    scanner = widget.barcodeScanner;
    clipboard = widget.clipboard;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<Manager>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: CFColors.white,
        title: Text(
          "New address",
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
                          key: Key("addAddressBookEntryViewAddressField"),
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
                              _enabledSave = manager.validateAddress(content) &&
                                  nameTextController.text.isNotEmpty;
                              _isEmptyAddress = content.isEmpty;
                            });
                          },
                          controller: addressTextController,
                          decoration: InputDecoration(
                            errorText: _updateInvalidAddressText(
                                addressTextController.text, manager),
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
                                              "addAddressPasteAddressButtonKey"),
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
                                                    manager.validateAddress(
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
                                              "addAddressBookClearAddressButtonKey"),
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
                                    width: 10,
                                  ),
                                  GestureDetector(
                                    key: Key(
                                        "addAddressBookEntryScanQrButtonKey"),
                                    onTap: () async {
                                      try {
                                        final qrResult = await scanner.scan();

                                        final results =
                                            AddressUtils.parseFiroUri(
                                                qrResult.rawContent);
                                        if (results.isNotEmpty) {
                                          addressTextController.text =
                                              results["address"];
                                          nameTextController.text =
                                              results["label"] ??
                                                  nameTextController.text;
                                          setState(() {
                                            _isEmptyAddress =
                                                addressTextController.text ==
                                                        null ||
                                                    addressTextController
                                                        .text.isEmpty;
                                            _enabledSave =
                                                manager.validateAddress(
                                                        addressTextController
                                                            .text) &&
                                                    nameTextController
                                                        .text.isNotEmpty;
                                          });
                                          // now check for non standard encoded basic address
                                        } else if (manager.validateAddress(
                                            qrResult.rawContent)) {
                                          addressTextController.text =
                                              qrResult.rawContent;
                                          setState(() {
                                            _isEmptyAddress =
                                                addressTextController
                                                    .text.isEmpty;
                                            _enabledSave =
                                                manager.validateAddress(
                                                        addressTextController
                                                            .text) &&
                                                    nameTextController
                                                        .text.isNotEmpty;
                                          });
                                        }
                                      } on PlatformException catch (e, s) {
                                        Logger.print(
                                            "Failed to get camera permissions to scan address qr code: $e\n$s");
                                      }
                                    },
                                    child: SvgPicture.asset(
                                      "assets/svg/qr-code.svg",
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
                          key: Key("addAddressBookEntryViewNameField"),
                          controller: nameTextController,
                          decoration: InputDecoration(
                            hintText: "Enter name",
                          ),
                          onChanged: (_) {
                            setState(() {
                              _enabledSave = manager.validateAddress(
                                      addressTextController.text) &&
                                  nameTextController.text.isNotEmpty;
                            });
                          },
                        ),
                        SizedBox(
                          height: 16,
                        ),
                        Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: SimpleButton(
                                  onTap: () {
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
                            ),
                            SizedBox(
                              width: 16,
                            ),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: GradientButton(
                                  enabled: _enabledSave,
                                  child: Text(
                                    "SAVE",
                                    style: CFTextStyles.button,
                                  ),
                                  onTap: () async {
                                    final addressService =
                                        Provider.of<AddressBookService>(context,
                                            listen: false);

                                    final name = nameTextController.text;
                                    final address = addressTextController.text;

                                    // these should never fail as the save button should not be enabled
                                    // when either field is empty
                                    assert(name.isNotEmpty);
                                    assert(address.isNotEmpty);

                                    if (await addressService
                                        .containsAddress(address)) {
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
                                        await addressService
                                            .addAddressBookEntry(address, name);
                                        // on success pop back to address book
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
                                  },
                                ),
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
