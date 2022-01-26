import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:majascan/majascan.dart';
import 'package:paymint/notifications/campfire_alert.dart';
import 'package:paymint/services/address_book_service.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/utilities/address_utils.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:paymint/widgets/custom_buttons/simple_button.dart';
import 'package:provider/provider.dart';

class AddAddressBookEntryView extends StatefulWidget {
  const AddAddressBookEntryView({Key key}) : super(key: key);

  @override
  _AddAddressBookEntryViewState createState() =>
      _AddAddressBookEntryViewState();
}

class _AddAddressBookEntryViewState extends State<AddAddressBookEntryView> {
  TextEditingController addressTextController = TextEditingController();
  TextEditingController nameTextController = TextEditingController();

  Future<void> _saveNewAddressEntry(BuildContext context) async {
    final addressService =
        Provider.of<AddressBookService>(context, listen: false);

    final name = nameTextController.text;
    final address = addressTextController.text;

    if (name.isEmpty || address.isEmpty) {
      showDialog(
        context: context,
        useSafeArea: false,
        barrierDismissible: false,
        builder: (_) {
          return CampfireAlert(message: "Please fill out both fields.");
        },
      );
    } else {
      if (await addressService.containsAddress(address)) {
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
          await addressService.addAddressBookEntry(address, name);
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
    }
  }

  bool _enabledSave = false;
  bool _isEmptyAddress = true;

  _updateInvalidAddressText(String address, Manager manager) {
    if (address.isNotEmpty && !manager.validateAddress(address)) {
      return "Invalid address";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<Manager>(context, listen: false);
    final screenWidth = MediaQuery.of(context).size.width;

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
                    readOnly: true,
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
                                    onTap: () async {
                                      final ClipboardData data =
                                          await Clipboard.getData(
                                              Clipboard.kTextPlain);
                                      final content = data.text.trim();
                                      addressTextController.text = content;
                                      setState(() {
                                        _enabledSave = manager
                                                .validateAddress(content) &&
                                            nameTextController.text.isNotEmpty;
                                        _isEmptyAddress = content.isEmpty;
                                      });
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
                              width: 10,
                            ),
                            GestureDetector(
                              onTap: () async {
                                String qrResult = await MajaScan.startScan(
                                  title: "Scan address QR Code",
                                  barColor: CFColors.white,
                                  titleColor: CFColors.dusk,
                                  qRCornerColor: CFColors.spark,
                                  qRScannerColor: CFColors.midnight,
                                  flashlightEnable: true,
                                  scanAreaScale: 0.7,
                                );

                                final results =
                                    AddressUtils.parseFiroUri(qrResult);
                                if (results.isNotEmpty) {
                                  addressTextController.text =
                                      results["address"];
                                  nameTextController.text = results["label"] ??
                                      nameTextController.text;
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
                        _enabledSave = manager
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
                    width: (screenWidth - 40 - 16) /
                        2, // 20+20 padding, 16 spacing
                    child: SimpleButton(
                      onTap: () {
                        print("cancel add new address entry pressed");
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
                    width: (screenWidth - 40 - 16) /
                        2, // 20+20 padding, 16 spacing,
                    child: GradientButton(
                      enabled: _enabledSave,
                      child: Text(
                        "SAVE",
                        style: CFTextStyles.button,
                      ),
                      onTap: () {
                        _saveNewAddressEntry(context);
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
