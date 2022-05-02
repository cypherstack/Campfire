import 'package:decimal/decimal.dart';
import 'package:devicelocale/devicelocale.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/notifications/campfire_alert.dart';
import 'package:paymint/pages/wallet_view/confirm_send_view.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/utilities/address_utils.dart';
import 'package:paymint/utilities/barcode_scanner_interface.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/clipboard_interface.dart';
import 'package:paymint/utilities/logger.dart';
import 'package:paymint/utilities/misc_global_constants.dart';
import 'package:paymint/utilities/shared_utilities.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/amount_input_field.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:paymint/widgets/gradient_card.dart';
import 'package:provider/provider.dart';

class SendView extends StatefulWidget {
  const SendView({
    Key key,
    this.autofillArgs,
    this.clipboard = const ClipboardWrapper(),
    this.barcodeScanner = const BarcodeScannerWrapper(),
  }) : super(key: key);

  final Map<String, dynamic> autofillArgs;
  final ClipboardInterface clipboard;
  final BarcodeScannerInterface barcodeScanner;

  @override
  _SendViewState createState() => _SendViewState(autofillArgs);
}

class _SendViewState extends State<SendView> {
  ClipboardInterface clipboard;
  BarcodeScannerInterface scanner;
  final autofillArgs;

  TextEditingController _recipientAddressTextController =
      TextEditingController();

  TextEditingController _noteTextController = TextEditingController();

  TextEditingController _firoAmountController = TextEditingController();
  TextEditingController _fiatAmountController = TextEditingController();

  AmountInputFieldController amountController;
  void amountChanged() {
    final manager = Provider.of<Manager>(context, listen: false);
    setState(() {
      _sendButtonEnabled = amountController.cryptoAmount > Decimal.zero &&
          manager.validateAddress(_address);
    });
  }

  Decimal _balanceMinusMaxFee = Decimal.zero;
  bool _autofill = false;
  String _address = "";
  String _contactName;

  String _locale = "en_US"; // default

  _SendViewState(this.autofillArgs);

  Future<void> _fetchLocale() async {
    _locale = (await Devicelocale.currentLocale) ?? _locale;
  }

  void _clearForm() {
    _recipientAddressTextController.text = "";
    _fiatAmountController.text = "";
    _firoAmountController.text = "";
    _noteTextController.text = "";
    amountController.clearAmounts();
    _address = "";
    _contactName = null;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _addressToggleFlag = false;
    });
  }

  /// parse args and autofill fill form
  void _parseArgs(Map<String, dynamic> args) async {
    final addressBookEntry = args["addressBookEntry"] as Map<String, String>;
    if (addressBookEntry == null) {
      throw Exception("SendView addressBookEntry argument must not be null!");
    }

    _address = addressBookEntry["address"];
    _contactName = addressBookEntry["name"];
    _autofill = true;
    setState(() {
      _recipientAddressTextController.text = _contactName;
      Logger.print("setState called with address = $_address");
    });

    final cryptoAmount = Decimal.tryParse(args["cryptoAmount"].toString());
    if (cryptoAmount == null) {
      return;
    }

    amountController.cryptoAmount = cryptoAmount;
    setState(() {
      _firoAmountController.text = Utilities.localizedStringAsFixed(
        value: cryptoAmount,
        locale: _locale,
        decimalPlaces: CampfireConstants.decimalPlaces,
      );
    });
  }

  bool _addressToggleFlag = true;
  bool _sendButtonEnabled = false;

  _updateInvalidAddressText(String address, Manager manager) {
    if (address.isNotEmpty && !manager.validateAddress(address)) {
      return "Invalid address";
    }
    return null;
  }

  @override
  initState() {
    _fetchLocale();
    clipboard = widget.clipboard;
    scanner = widget.barcodeScanner;
    amountController = AmountInputFieldController(amountChanged: amountChanged);
    Logger.print("SendView args: $autofillArgs");
    if (autofillArgs != null) {
      _parseArgs(autofillArgs);
    }
    setState(() {
      _addressToggleFlag = _recipientAddressTextController.text.isNotEmpty;
    });
    Logger.print("object: initmystate");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
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
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SpendableBalanceWidget(
                          locale: _locale,
                          onBalanceMinusMaxFeeChanged: (newValue) =>
                              _balanceMinusMaxFee = newValue,
                          onBalanceTapped: (balance) {
                            _firoAmountController.text = balance;
                          },
                        ),
                        SizedBox(
                          height: 17,
                        ),

                        // Send to
                        Row(
                          children: [
                            FittedBox(
                              child: Text(
                                "Send to",
                                style: CFTextStyles.label,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        _buildAddressTextField(),
                        SizedBox(
                          height: 16,
                        ),

                        // Note
                        Row(
                          children: [
                            FittedBox(
                              child: Text(
                                "Note (optional)",
                                style: CFTextStyles.label,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        TextField(
                          style: GoogleFonts.workSans(
                            color: CFColors.dusk,
                          ),
                          controller: _noteTextController,
                          decoration: InputDecoration(
                            fillColor: CFColors.fog,
                            border: OutlineInputBorder(),
                            hintText: "Type something...",
                            hintStyle: CFTextStyles.textFieldHint,
                          ),
                        ),
                        SizedBox(
                          height: 16,
                        ),

                        // Amount
                        Row(
                          children: [
                            FittedBox(
                              child: Text(
                                "Amount",
                                style: CFTextStyles.label,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        AmountInputField(
                          cryptoAmountController: _firoAmountController,
                          fiatAmountController: _fiatAmountController,
                          controller: amountController,
                          locale: _locale,
                        ),

                        SizedBox(
                          height: 16,
                        ),

                        TransactionFeeInfoWidget(
                          amountController: amountController,
                          locale: _locale,
                          isTinyScreen: SizingUtilities.isTinyWidth(context),
                          onMaxFeeChanged: (_) => {},
                        ),

                        SizedBox(
                          height: 16,
                        ),

                        Spacer(),
                        // Send Button
                        SizedBox(
                          height: 48,
                          width: MediaQuery.of(context).size.width - 40,
                          child: GradientButton(
                            enabled: _sendButtonEnabled,
                            onTap: () async {
                              Logger.print("SEND pressed");

                              // don't allow send to self
                              final manager =
                                  Provider.of<Manager>(context, listen: false);
                              final myAddresses = await manager.allOwnAddresses;
                              if (myAddresses.contains(
                                  _recipientAddressTextController.text)) {
                                showDialog(
                                  context: context,
                                  useSafeArea: false,
                                  barrierDismissible: false,
                                  builder: (_) {
                                    return CampfireAlert(
                                      message:
                                          "Sending to your own address is currently disabled.",
                                    );
                                  },
                                );
                                return;
                              }

                              final Decimal availableBalance =
                                  _balanceMinusMaxFee < Decimal.zero
                                      ? Decimal.zero
                                      : _balanceMinusMaxFee;

                              if (amountController.cryptoAmount >
                                  availableBalance) {
                                showDialog(
                                  useSafeArea: false,
                                  barrierDismissible: false,
                                  context: context,
                                  builder: (_) => CampfireAlert(
                                      message: "Insufficient balance!"),
                                );
                              } else {
                                // set address to textfield value if it was not auto filled from address book
                                // OR if it was but the textfield value does not match anymore
                                if (!_autofill ||
                                    _recipientAddressTextController.text !=
                                        _contactName) {
                                  _address =
                                      _recipientAddressTextController.text;
                                }

                                Navigator.of(context)
                                    .push(
                                  PageRouteBuilder(
                                    opaque: false,
                                    pageBuilder: (context, widget, animation) {
                                      return ConfirmSendView(
                                        amount: amountController.cryptoAmount,
                                        note: _noteTextController.text,
                                        address: _address,
                                      );
                                    },
                                    transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                                  ),
                                )
                                    .then(
                                  (value) {
                                    if (value != null &&
                                        value is bool &&
                                        value) {
                                      _clearForm();
                                    }
                                  },
                                );
                              }
                            },
                            child: Text(
                              "SEND",
                              style: GoogleFonts.workSans(
                                color: CFColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
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

  _buildAddressTextField() {
    final manager = Provider.of<Manager>(context, listen: false);
    return TextField(
      key: Key("sendViewAddressFieldKey"),
      style: GoogleFonts.workSans(
        color: CFColors.dusk,
      ),
      readOnly: false,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp("[a-zA-Z0-9]{34}")),
      ],
      toolbarOptions: ToolbarOptions(
        copy: true,
        cut: false,
        paste: true,
        selectAll: false,
      ),
      onChanged: (newValue) {
        _address = newValue;
        setState(() {
          _addressToggleFlag = newValue.isNotEmpty;
          _sendButtonEnabled = (manager.validateAddress(_address) &&
              amountController.cryptoAmount > Decimal.zero);
        });
      },
      controller: _recipientAddressTextController,
      decoration: InputDecoration(
        errorText: _updateInvalidAddressText(_address, manager),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: CFColors.twilight,
          ),
          borderRadius:
              BorderRadius.circular(SizingUtilities.circularBorderRadius),
        ),
        contentPadding: EdgeInsets.only(
          left: 16,
          top: 12,
          bottom: 12,
          right: 5,
        ),
        hintText: "Paste address",
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: UnconstrainedBox(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _addressToggleFlag
                    ? GestureDetector(
                        key: Key("sendViewClearAddressFieldButtonKey"),
                        onTap: () {
                          _recipientAddressTextController.text = "";
                          _address = "";
                          setState(() {
                            _addressToggleFlag = false;
                            _sendButtonEnabled = (manager
                                    .validateAddress(_address) &&
                                amountController.cryptoAmount > Decimal.zero);
                          });
                        },
                        child: SvgPicture.asset(
                          "assets/svg/x.svg",
                          color: CFColors.twilight,
                          width: 20,
                          height: 20,
                        ),
                      )
                    : GestureDetector(
                        key: Key("sendViewPasteAddressFieldButtonKey"),
                        onTap: () async {
                          final ClipboardData data =
                              await clipboard.getData(Clipboard.kTextPlain);
                          if (data != null && data.text.isNotEmpty) {
                            final content = data.text.trim();

                            final isValidAddress =
                                manager.validateAddress(content);

                            _recipientAddressTextController.text = content;
                            _address = content;

                            setState(() {
                              _addressToggleFlag =
                                  _recipientAddressTextController
                                      .text.isNotEmpty;
                              _sendButtonEnabled = (isValidAddress &&
                                  amountController.cryptoAmount > Decimal.zero);
                            });
                          }
                        },
                        child: SvgPicture.asset(
                          _recipientAddressTextController.text == "" ||
                                  _recipientAddressTextController.text == null
                              ? "assets/svg/clipboard.svg"
                              : "assets/svg/x.svg",
                          color: CFColors.twilight,
                          width: 20,
                          height: 20,
                        ),
                      ),
                SizedBox(
                  width: 10,
                ),
                GestureDetector(
                  key: Key("sendViewAddressBookButtonKey"),
                  onTap: () {
                    Navigator.of(context).pushNamed("/addressbook").then(
                      (value) {
                        if (value is String) {
                          _recipientAddressTextController.text = value;
                        }
                      },
                    );
                    Logger.print("open addressbook icon clicked");
                  },
                  child: SvgPicture.asset(
                    "assets/svg/book-open.svg",
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                GestureDetector(
                  key: Key("sendViewScanQrButtonKey"),
                  onTap: () async {
                    try {
                      final qrResult = await scanner.scan();
                      final results =
                          AddressUtils.parseFiroUri(qrResult?.rawContent);
                      if (results.isNotEmpty) {
                        // auto fill address
                        _address = results["address"];
                        _recipientAddressTextController.text = _address;

                        // autofill notes field
                        if (results["message"] != null) {
                          _noteTextController.text = results["message"];
                        } else if (results["label"] != null) {
                          _noteTextController.text = results["label"];
                        }

                        // autofill amount field
                        if (results["amount"] != null) {
                          final amount = Decimal.parse(results["amount"]);
                          _firoAmountController.text = amount.toString();
                          amountController.cryptoAmount = amount;
                        }
                        setState(() {
                          _addressToggleFlag =
                              _recipientAddressTextController.text.isNotEmpty;
                          _sendButtonEnabled =
                              (manager.validateAddress(_address) &&
                                  amountController.cryptoAmount > Decimal.zero);
                        });

                        // now check for non standard encoded basic address
                      } else if (manager.validateAddress(qrResult.rawContent)) {
                        _address = qrResult.rawContent;
                        _recipientAddressTextController.text = _address;
                        setState(() {
                          _addressToggleFlag =
                              _recipientAddressTextController.text.isNotEmpty;
                          _sendButtonEnabled =
                              (manager.validateAddress(_address) &&
                                  amountController.cryptoAmount > Decimal.zero);
                        });
                      }
                    } on PlatformException catch (e, s) {
                      // here we ignore the exception caused by not giving permission
                      // to use the camera to scan a qr code
                      Logger.print(
                          "Failed to get camera permissions while trying to scan qr code in SendView: $e\n$s");
                    }
                  },
                  child: SvgPicture.asset(
                    "assets/svg/qr-code.svg",
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SpendableBalanceWidget extends StatefulWidget {
  const SpendableBalanceWidget({
    Key key,
    this.onBalanceMinusMaxFeeChanged,
    this.locale,
    this.onBalanceTapped,
  }) : super(key: key);

  final void Function(Decimal) onBalanceMinusMaxFeeChanged;
  final void Function(String) onBalanceTapped;
  final String locale;

  @override
  _SpendableBalanceWidgetState createState() => _SpendableBalanceWidgetState();
}

class _SpendableBalanceWidgetState extends State<SpendableBalanceWidget> {
  Decimal tempBalanceMinusMaxFee = Decimal.zero;

  void Function(Decimal) onBalanceMinusMaxFeeChanged;
  void Function(String) onBalanceTapped;
  String locale;

  @override
  void initState() {
    this.onBalanceMinusMaxFeeChanged = widget.onBalanceMinusMaxFeeChanged;
    this.onBalanceTapped = widget.onBalanceTapped;
    this.locale = widget.locale;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<Manager>(context);
    final isTinyScreen = SizingUtilities.isTinyWidth(context);
    return GradientCard(
      gradient: CFColors.fireGradientVerticalLight,
      circularBorderRadius: SizingUtilities.circularBorderRadius,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: 11,
          horizontal: 16,
        ),
        child: Container(
          height: isTinyScreen ? 36 : 20,
          child: Column(
            children: [
              if (isTinyScreen)
                Row(
                  children: [
                    FittedBox(
                      child: Text(
                        "You can spend: ",
                        style: GoogleFonts.workSans(
                          color: CFColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Spacer(),
                  ],
                ),
              if (isTinyScreen) Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  !isTinyScreen
                      ? FittedBox(
                          child: Text(
                            "You can spend: ",
                            style: GoogleFonts.workSans(
                              color: CFColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : Spacer(),
                  FutureBuilder(
                    future: manager.balanceMinusMaxFee,
                    builder: (
                      BuildContext context,
                      AsyncSnapshot<Decimal> balanceMinusMaxFee,
                    ) {
                      if (balanceMinusMaxFee.connectionState ==
                          ConnectionState.done) {
                        if (balanceMinusMaxFee == null ||
                            balanceMinusMaxFee.hasError ||
                            balanceMinusMaxFee.data == null) {
                          return Text(
                            "... ${manager.coinTicker}",
                            style: GoogleFonts.workSans(
                              color: CFColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }
                        if (tempBalanceMinusMaxFee != balanceMinusMaxFee.data) {
                          tempBalanceMinusMaxFee = balanceMinusMaxFee.data;
                          onBalanceMinusMaxFeeChanged(tempBalanceMinusMaxFee);
                        }
                      }
                      final balanceString = Utilities.localizedStringAsFixed(
                        value: tempBalanceMinusMaxFee <= Decimal.zero
                            ? Decimal.zero
                            : tempBalanceMinusMaxFee,
                        locale: locale,
                        decimalPlaces: CampfireConstants.decimalPlaces,
                      );
                      return GestureDetector(
                        onTap: () => onBalanceTapped(balanceString),
                        child: FittedBox(
                          child: Text(
                            "$balanceString ${manager.coinTicker}",
                            style: GoogleFonts.workSans(
                              color: CFColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TransactionFeeInfoWidget extends StatelessWidget {
  const TransactionFeeInfoWidget({
    Key key,
    this.locale,
    this.amountController,
    this.isTinyScreen,
    this.onMaxFeeChanged,
  }) : super(key: key);

  final String locale;
  final AmountInputFieldController amountController;
  final bool isTinyScreen;
  final void Function(Decimal) onMaxFeeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Transaction fee
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTapDown: (tapDownDetails) {
                showDialog(
                  barrierColor: Colors.transparent,
                  context: context,
                  builder: (context) => MaxFeeTooltipWidget(
                    position: tapDownDetails.globalPosition,
                  ),
                );
              },
              child: Row(
                children: [
                  FittedBox(
                    child: Text(
                      "Maximum Transaction fee",
                      style: GoogleFonts.workSans(
                        color: CFColors.twilight,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      SvgPicture.asset(
                        "assets/svg/alert-circle.svg",
                        color: CFColors.twilight,
                        width: 8,
                        height: 8,
                      ),
                      SizedBox(
                        height: 4,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isTinyScreen)
              MaxFeeWidget(
                locale: locale,
                onMaxFeeChanged: (newValue) => onMaxFeeChanged(newValue),
              ),
          ],
        ),
        if (isTinyScreen)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              MaxFeeWidget(
                locale: locale,
                onMaxFeeChanged: (newValue) => onMaxFeeChanged(newValue),
              ),
            ],
          ),
        SizedBox(
          height: 16,
        ),

        // Total amount to send
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTapDown: (tapDownDetails) {
                showDialog(
                  barrierColor: Colors.transparent,
                  context: context,
                  builder: (context) => MaxFeeTooltipWidget(
                    position: tapDownDetails.globalPosition,
                  ),
                );
              },
              child: Row(
                children: [
                  FittedBox(
                    child: Text(
                      "Total amount to send",
                      style: GoogleFonts.workSans(
                        color: CFColors.twilight,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      SvgPicture.asset(
                        "assets/svg/alert-circle.svg",
                        color: CFColors.twilight,
                        width: 8,
                        height: 8,
                      ),
                      SizedBox(
                        height: 4,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isTinyScreen)
              TotalAmountWidget(
                total: amountController.cryptoTotal,
                locale: locale,
              ),
          ],
        ),
        if (isTinyScreen)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TotalAmountWidget(
                total: amountController.cryptoTotal,
                locale: locale,
              ),
            ],
          ),
      ],
    );
  }
}

class MaxFeeTooltipWidget extends StatelessWidget {
  const MaxFeeTooltipWidget({
    Key key,
    @required this.position,
  }) : super(key: key);

  final Offset position;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
      },
      child: Stack(
        children: [
          Positioned(
            top: position.dy - 10,
            left: 20.0,
            child: Container(
              width: MediaQuery.of(context).size.width - 40,
              decoration: BoxDecoration(
                color: CFColors.white,
                borderRadius:
                    BorderRadius.circular(SizingUtilities.circularBorderRadius),
                boxShadow: [CFColors.standardBoxShadow],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  "This is the maximum possible fee. Actual fee is calculated when attempting to send and will generally be less.",
                  maxLines: 7,
                  style: GoogleFonts.workSans(
                    decoration: TextDecoration.none,
                    color: CFColors.twilight,
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class MaxFeeWidget extends StatelessWidget {
  const MaxFeeWidget({
    Key key,
    this.onMaxFeeChanged,
    this.locale,
  }) : super(key: key);

  final void Function(Decimal) onMaxFeeChanged;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<Manager>(context);
    return FutureBuilder(
      future: manager.maxFee,
      builder: (context, futureData) {
        Decimal maxFee = Decimal.zero;
        if (futureData.connectionState == ConnectionState.done &&
            futureData.data != null) {
          var prev = maxFee;
          maxFee = (Decimal.fromInt(futureData.data.fee) /
                  Decimal.fromInt(CampfireConstants.satsPerCoin))
              .toDecimal(
                  scaleOnInfinitePrecision: CampfireConstants.decimalPlaces);
          if (prev != maxFee) {
            onMaxFeeChanged(maxFee);
          }
        }
        return FittedBox(
          child: Text(
            "${Utilities.localizedStringAsFixed(
              value: maxFee,
              locale: locale,
              decimalPlaces: CampfireConstants.decimalPlaces,
            )} ${manager.coinTicker}",
            style: GoogleFonts.workSans(
              color: CFColors.twilight,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        );
      },
    );
  }
}

class TotalAmountWidget extends StatelessWidget {
  const TotalAmountWidget({
    Key key,
    this.total,
    this.locale,
  }) : super(key: key);

  final Decimal total;
  final String locale;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: Text(
        "${Utilities.localizedStringAsFixed(
          value: total,
          locale: locale,
          decimalPlaces: CampfireConstants.decimalPlaces,
        )} ${Provider.of<Manager>(context, listen: false).coinTicker}",
        style: GoogleFonts.workSans(
          color: CFColors.twilight,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }
}
