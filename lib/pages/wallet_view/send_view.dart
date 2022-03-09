import 'package:barcode_scan2/platform_wrapper.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/notifications/campfire_alert.dart';
import 'package:paymint/pages/wallet_view/confirm_send_view.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/utilities/address_utils.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/misc_global_constants.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:paymint/widgets/gradient_card.dart';
import 'package:provider/provider.dart';

class SendView extends StatefulWidget {
  SendView({Key key, this.autofillArgs}) : super(key: key);

  final Map<String, dynamic> autofillArgs;

  @override
  _SendViewState createState() => _SendViewState(autofillArgs);
}

class _SendViewState extends State<SendView> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final autofillArgs;

  TextEditingController _recipientAddressTextController =
      TextEditingController();

  TextEditingController _noteTextController = TextEditingController();

  TextEditingController _firoAmountController = TextEditingController();
  TextEditingController _fiatAmountController = TextEditingController();

  Decimal _firoAmount = Decimal.zero;
  Decimal _fee = Decimal.zero;
  Decimal _totalAmount = Decimal.zero;
  Decimal _maxFee = Decimal.zero;
  Decimal _balanceMinusMaxFee = Decimal.zero;
  String _currency = "";

  bool _autofill = false;
  String _address = "";
  String _contactName;

  bool _cryptoAmountHasFocus = false;
  bool _fiatAmountHasFocus = false;

  _SendViewState(this.autofillArgs);

  bool get _amountHasFocus => _cryptoAmountHasFocus || _fiatAmountHasFocus;

  void _clearForm() {
    _recipientAddressTextController.text = "";
    _fiatAmountController.text = "";
    _firoAmountController.text = "";
    _noteTextController.text = "";
    _firoAmount = Decimal.zero;
    _fee = Decimal.zero;
    _totalAmount = Decimal.zero;
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
      print("setState called with address = $_address");
    });

    final cryptoAmount = Decimal.tryParse(args["cryptoAmount"].toString());
    if (cryptoAmount == null) {
      return;
    }

    _firoAmount = cryptoAmount;
    setState(() {
      _firoAmountController.text = cryptoAmount.toStringAsFixed(8);
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
    print("SendView args: $autofillArgs");
    if (autofillArgs != null) {
      _parseArgs(autofillArgs);
    }
    setState(() {
      _addressToggleFlag = _recipientAddressTextController.text.isNotEmpty;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<Manager>(context);
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: CFColors.white,
        body: LayoutBuilder(
          builder: (context, constraint) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                top: 8,
                left: 20,
                right: 20,
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
                      _buildSpendableBalanceCard(manager),
                      SizedBox(
                        height: 17,
                      ),

                      // Send to
                      Row(
                        children: [
                          FittedBox(
                            child: Text(
                              "Send to",
                              style: GoogleFonts.workSans(
                                color: CFColors.twilight,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      _buildAddressTextField(manager),
                      SizedBox(
                        height: 16,
                      ),

                      // Note
                      Row(
                        children: [
                          FittedBox(
                            child: Text(
                              "Note (optional)",
                              style: GoogleFonts.workSans(
                                color: CFColors.twilight,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
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
                          hintStyle: GoogleFonts.workSans(
                            color: CFColors.twilight,
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                          ),
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
                              style: GoogleFonts.workSans(
                                color: CFColors.twilight,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      FutureBuilder(
                        future: manager.fiatPrice,
                        builder: (context, price) {
                          if (price.connectionState == ConnectionState.done) {
                            if (price.hasError || price.data == null) {
                              // TODO: show proper connection error
                              print(
                                  "Couldn't fetch price, please check connection");
                              return _buildAmountInputBox(
                                  Decimal.fromInt(-1), manager);
                            }
                            return _buildAmountInputBox(price.data, manager);
                          }

                          print("Fetching price... please wait...");
                          return _buildAmountInputBox(
                              Decimal.fromInt(-1), manager);
                        },
                      ),
                      SizedBox(
                        height: 16,
                      ),

                      _buildTxFeeInfo(),

                      SizedBox(
                        height: 16,
                      ),

                      Spacer(),
                      // Send Button
                      _buildSendButton(manager),
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

  _buildSpendableBalanceCard(Manager manager) {
    return GradientCard(
      gradient: CFColors.fireGradientVerticalLight,
      circularBorderRadius: SizingUtilities.circularBorderRadius,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: 11,
          horizontal: 16,
        ),
        child: Container(
          height: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    _balanceMinusMaxFee = balanceMinusMaxFee.data;
                    print("_balanceMinusMaxFee $_balanceMinusMaxFee");

                    return FittedBox(
                      child: Text(
                        "${_balanceMinusMaxFee <= Decimal.zero ? "0.00000000" : _balanceMinusMaxFee.toStringAsFixed(8)} ${manager.coinTicker}",
                        style: GoogleFonts.workSans(
                          color: CFColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  } else {
                    //TODO: wallet balance loading progress
                    // currently hidden by synchronizing overlay
                    return SizedBox(
                      height: 20,
                      width: 100,
                      child: SpinKitThreeBounce(
                        color: CFColors.white,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  _buildAddressTextField(Manager manager) {
    return TextField(
      style: GoogleFonts.workSans(
        color: CFColors.dusk,
      ),
      readOnly: true,
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
                        onTap: () {
                          _recipientAddressTextController.text = "";
                          _address = "";
                          setState(() {
                            _addressToggleFlag = false;
                            _sendButtonEnabled =
                                (manager.validateAddress(_address) &&
                                    _totalAmount > Decimal.zero);
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
                        onTap: () async {
                          final ClipboardData data =
                              await Clipboard.getData(Clipboard.kTextPlain);
                          if (data != null && data.text.isNotEmpty) {
                            final content = data.text.trim();

                            final isValidAddress =
                                manager.validateAddress(content);
                            if (isValidAddress) {
                              final myAddresses = await manager.allOwnAddresses;
                              print(myAddresses);
                              if (myAddresses.contains(content)) {
                                showDialog(
                                  context: context,
                                  useSafeArea: false,
                                  barrierDismissible: false,
                                  builder: (_) {
                                    return CampfireAlert(
                                        message:
                                            "Sending to your own address is currently disabled.");
                                  },
                                );
                                return;
                              }
                            }

                            _recipientAddressTextController.text = content;
                            _address = content;

                            setState(() {
                              _addressToggleFlag =
                                  _recipientAddressTextController
                                      .text.isNotEmpty;
                              _sendButtonEnabled = (isValidAddress &&
                                  _totalAmount > Decimal.zero);
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
                  onTap: () {
                    Navigator.of(context).pushNamed("/addressbook").then(
                      (value) {
                        if (value == null) {
                          return;
                        }
                        if (value is String) {
                          _recipientAddressTextController.text = value;
                        }
                      },
                    );
                    print("open addressbook icon clicked");
                  },
                  child: SvgPicture.asset(
                    "assets/svg/book-open.svg",
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                GestureDetector(
                  onTap: () async {
                    final qrResult = await BarcodeScanner.scan();
                    final results =
                        AddressUtils.parseFiroUri(qrResult.rawContent);
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
                        setState(() {
                          _firoAmount = amount;
                        });
                      }
                      setState(() {
                        _addressToggleFlag =
                            _recipientAddressTextController.text.isNotEmpty;
                        _sendButtonEnabled =
                            (manager.validateAddress(_address) &&
                                _totalAmount > Decimal.zero);
                      });
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

  _buildMaxFee(Manager manager) {
    return FutureBuilder(
      future: manager.maxFee,
      builder: (context, futureData) {
        if (futureData.connectionState == ConnectionState.done &&
            futureData.data != null) {
          _maxFee = (Decimal.fromInt(futureData.data.fee) /
                  Decimal.fromInt(CampfireConstants.satsPerCoin))
              .toDecimal(
                  scaleOnInfinitePrecision: CampfireConstants.decimalPlaces);
          return FittedBox(
            child: Text(
              "${_maxFee.toStringAsFixed(8)} ${manager.coinTicker}",
              style: GoogleFonts.workSans(
                color: CFColors.twilight,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          );
        } else {
          return FittedBox(
            child: Text(
              "${_maxFee.toStringAsFixed(8)} ${manager.coinTicker}",
              style: GoogleFonts.workSans(
                color: CFColors.twilight,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          );
        }
      },
    );
  }

  _buildTotal() {
    return FittedBox(
      child: Text(
        "${_totalAmount.toStringAsFixed(8)} ${Provider.of<Manager>(context, listen: false).coinTicker}",
        style: GoogleFonts.workSans(
          color: CFColors.twilight,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildTxFeeInfo() {
    final bitcoinService = Provider.of<Manager>(context);
    final isTinyScreen = SizingUtilities.isTinyWidth(context);
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
                  builder: (context) {
                    return _showMaxFeeToolTip(
                        context, tapDownDetails.globalPosition);
                  },
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
            if (!isTinyScreen) _buildMaxFee(bitcoinService),
          ],
        ),
        if (isTinyScreen)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildMaxFee(bitcoinService),
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
                  builder: (context) {
                    return _showMaxFeeToolTip(
                        context, tapDownDetails.globalPosition);
                  },
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
            if (!isTinyScreen) _buildTotal(),
          ],
        ),
        if (isTinyScreen)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildTotal(),
            ],
          ),
      ],
    );
  }

  Widget _showMaxFeeToolTip(BuildContext context, Offset position) {
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

  Widget _buildAmountInputBox(Decimal firoPrice, Manager manager) {
    return Container(
      decoration: BoxDecoration(
        color: CFColors.fog,
        borderRadius:
            BorderRadius.circular(SizingUtilities.circularBorderRadius),
        border: Border.all(
          width: 1,
          color: _amountHasFocus ? CFColors.focusedBorder : CFColors.twilight,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Focus(
              onFocusChange: (hasFocus) {
                setState(() {
                  _cryptoAmountHasFocus = hasFocus;
                });
              },
              child: TextField(
                style: GoogleFonts.workSans(
                  color: CFColors.dusk,
                ),
                controller: _firoAmountController,
                keyboardType: TextInputType.numberWithOptions(
                    signed: false, decimal: true),
                inputFormatters: [
                  // regex to validate a crypto amount with 8 decimal places
                  TextInputFormatter.withFunction((oldValue, newValue) =>
                      RegExp(r'^([0-9]*\.?[0-9]{0,8}|\.[0-9]{0,8})$')
                              .hasMatch(newValue.text)
                          ? newValue
                          : oldValue),
                ],
                onChanged: (String firoAmount) {
                  print(firoAmount);
                  if (firoAmount.isNotEmpty && firoAmount != ".") {
                    _firoAmount = Decimal.parse(firoAmount);
                    setState(() {
                      _totalAmount = _firoAmount + _maxFee;
                      _sendButtonEnabled = (manager.validateAddress(_address) &&
                          _firoAmount > Decimal.zero);
                    });

                    if (firoPrice > Decimal.zero) {
                      final String fiatAmountString =
                          (_firoAmount * firoPrice).toStringAsFixed(2);

                      _fiatAmountController.text = fiatAmountString;
                    }
                  } else {
                    setState(() {
                      _totalAmount = Decimal.zero;
                      _sendButtonEnabled = false;
                    });
                    _fiatAmountController.text = "";
                  }
                },
                decoration: InputDecoration(
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.only(
                    left: 16,
                    top: 14,
                    bottom: 12,
                    right: 16,
                  ),
                  // ticker suffix
                  suffixIcon: UnconstrainedBox(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Text(
                        Provider.of<Manager>(context, listen: false).coinTicker,
                        style: TextStyle(
                          color: CFColors.twilight,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  hintText: "0.00",
                  hintStyle: GoogleFonts.workSans(
                    color: CFColors.twilight,
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            Container(
              height: 1,
              color:
                  _amountHasFocus ? CFColors.focusedBorder : CFColors.twilight,
            ),
            Focus(
              onFocusChange: (hasFocus) {
                setState(() {
                  _fiatAmountHasFocus = hasFocus;
                });
              },
              child: TextField(
                style: GoogleFonts.workSans(
                  color: CFColors.dusk,
                ),
                enabled: firoPrice > Decimal.zero,
                controller: _fiatAmountController,
                keyboardType: TextInputType.numberWithOptions(
                    signed: false, decimal: true),
                inputFormatters: [
                  // regex to validate a fiat amount with 2 decimal places
                  TextInputFormatter.withFunction((oldValue, newValue) =>
                      RegExp(r'^([0-9]*\.?[0-9]{0,2}|\.[0-9]{0,2})$')
                              .hasMatch(newValue.text)
                          ? newValue
                          : oldValue),
                ],
                onChanged: (String fiatAmount) {
                  if (fiatAmount.isNotEmpty && fiatAmount != ".") {
                    final fiatValue = Decimal.parse(fiatAmount);
                    _firoAmount = (fiatValue / firoPrice).toDecimal(
                        scaleOnInfinitePrecision:
                            CampfireConstants.decimalPlaces);

                    final amountString = _firoAmount.toStringAsFixed(8);

                    setState(() {
                      _totalAmount = Decimal.parse(amountString) + _maxFee;
                    });

                    _firoAmountController.text = amountString;
                  } else {
                    setState(() {
                      _totalAmount = Decimal.zero;
                    });
                    _firoAmountController.text = "";
                  }
                },
                decoration: InputDecoration(
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.only(
                    left: 16,
                    top: 14,
                    bottom: 12,
                    right: 16,
                  ),
                  suffixIcon: UnconstrainedBox(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Provider<String>.value(
                        value: Provider.of<Manager>(context).fiatCurrency,
                        builder: (context, child) {
                          _currency = context.watch<String>();
                          return Text(
                            _currency,
                            style: TextStyle(
                              color: CFColors.twilight,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  hintText: firoPrice < Decimal.zero ? "..." : "0.00",
                  hintStyle: GoogleFonts.workSans(
                    color: CFColors.twilight,
                    fontWeight: FontWeight.w400,
                    fontSize: 16, // ScalingUtils.fontScaled(context, 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _buildSendButton(Manager manager) {
    return SizedBox(
      height: 48,
      width: MediaQuery.of(context).size.width - 40,
      child: GradientButton(
        enabled: _sendButtonEnabled,
        onTap: () {
          print("SEND pressed");

          final Decimal availableBalance = _balanceMinusMaxFee < Decimal.zero
              ? Decimal.zero
              : _balanceMinusMaxFee;

          if (_firoAmount > availableBalance) {
            showDialog(
              useSafeArea: false,
              barrierDismissible: false,
              context: context,
              builder: (_) => CampfireAlert(message: "Insufficient balance!"),
            );
          } else {
            // set address to textfield value if it was not auto filled from address book
            // OR if it was but the textfield value does not match anymore
            if (!_autofill ||
                _recipientAddressTextController.text != _contactName) {
              _address = _recipientAddressTextController.text;
            }

            if (manager.validateAddress(_address)) {
              Navigator.of(context)
                  .push(
                PageRouteBuilder(
                  opaque: false,
                  pageBuilder: (
                    context,
                    widget,
                    animation,
                  ) {
                    return ConfirmSendView(
                      amount: _firoAmount,
                      note: _noteTextController.text,
                      address: _address,
                      fee: _fee,
                    );
                  },
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                ),
              )
                  .then(
                (value) {
                  if (value != null && value is bool && value) {
                    _clearForm();
                  }
                },
              );
            } else {
              showDialog(
                useSafeArea: false,
                barrierDismissible: false,
                context: context,
                builder: (_) => CampfireAlert(
                  message: "Invalid address entered",
                ),
              );
            }
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
    );
  }
}
