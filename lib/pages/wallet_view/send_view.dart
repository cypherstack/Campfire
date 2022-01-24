import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:majascan/majascan.dart';
import 'package:paymint/models/models.dart';
import 'package:paymint/notifications/campfire_alert.dart';
import 'package:paymint/pages/wallet_view/confirm_send_view.dart';
import 'package:paymint/services/bitcoin_service.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/currency_utils.dart';
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

  double _firoAmount = 0;
  double _fee = 0;
  double _totalAmount = 0;
  double _maxFee = 0;
  List<String> _balance = [];
  String _currency = "";

  bool _autofill = false;
  String _address = "";
  String _contactName;

  bool _cryptoAmountHasFocus = false;
  bool _fiatAmountHasFocus = false;

  _SendViewState(this.autofillArgs);

  bool get _amountHasFocus => _cryptoAmountHasFocus || _fiatAmountHasFocus;

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

    final cryptoAmount = args["cryptoAmount"] as double;
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

  _updateInvalidAddressText(String address, BitcoinService bitcoinService) {
    if (address.isNotEmpty && !bitcoinService.validateFiroAddress(address)) {
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
    final BitcoinService bitcoinService = Provider.of<BitcoinService>(context);
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
                      _buildSpendableBalanceCard(bitcoinService),
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
                      _buildAddressTextField(bitcoinService),
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
                        future: bitcoinService.bitcoinPrice,
                        builder: (context, price) {
                          if (price.connectionState == ConnectionState.done) {
                            if (price.hasError || price.data == null) {
                              // TODO: show proper connection error
                              print(
                                  "Couldn't fetch price, please check connection");
                              return _buildAmountInputBox(0, bitcoinService);
                            }
                            return _buildAmountInputBox(
                                price.data, bitcoinService);
                          }

                          print("Fetching price... please wait...");
                          return _buildAmountInputBox(0, bitcoinService);
                        },
                      ),
                      SizedBox(
                        height: 16,
                      ),

                      FutureBuilder(
                        future: bitcoinService.fees,
                        builder: (BuildContext context,
                            AsyncSnapshot<FeeObject> feeObject) {
                          if (feeObject.connectionState ==
                              ConnectionState.done) {
                            if (feeObject == null || feeObject.hasError) {
                              // TODO: connection error notification
                              return _buildTxFeeInfo();
                            }

                            // TODO is this the correct fee?
                            _fee = feeObject.data.medium;

                            return _buildTxFeeInfo();
                          } else {
                            return _buildTxFeeInfo();
                          }
                        },
                      ),

                      SizedBox(
                        height: 16,
                      ),

                      Spacer(),
                      // Send Button
                      _buildSendButton(bitcoinService),
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

  _buildSpendableBalanceCard(BitcoinService bitcoinService) {
    return GradientCard(
      gradient: CFColors.fireGradientVerticalLight,
      circularBorderRadius: SizingUtilities.circularBorderRadius,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: 11,
          horizontal: 16,
        ),
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
              future: bitcoinService.balance,
              builder: (
                BuildContext context,
                AsyncSnapshot<dynamic> balanceData,
              ) {
                if (balanceData.connectionState == ConnectionState.done) {
                  if (balanceData == null ||
                      balanceData.hasError ||
                      balanceData.data == null ||
                      balanceData.data.length != 5) {
                    // TODO: Display failed overlay 'Unable to fetch balance data.\nPlease check connection'
                    return Text(
                      "... ${CurrencyUtilities.coinName}",
                      style: GoogleFonts.workSans(
                        color: CFColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }
                  _balance = balanceData.data;

                  return FittedBox(
                    child: Text(
                      "${double.parse(_balance[4]) < _maxFee ? "0.00000000" : _balance[4]} ${CurrencyUtilities.coinName}",
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
    );
  }

  _buildAddressTextField(BitcoinService bitcoinService) {
    return TextField(
      style: GoogleFonts.workSans(
        color: CFColors.dusk,
      ),
      readOnly: true,
      controller: _recipientAddressTextController,
      decoration: InputDecoration(
        errorText: _updateInvalidAddressText(_address, bitcoinService),
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
                                (bitcoinService.validateFiroAddress(_address) &&
                                    _totalAmount > 0);
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
                          final content = data.text.trim();
                          _recipientAddressTextController.text = content;
                          _address = content;

                          setState(() {
                            _addressToggleFlag =
                                _recipientAddressTextController.text.isNotEmpty;
                            _sendButtonEnabled =
                                (bitcoinService.validateFiroAddress(_address) &&
                                    _totalAmount > 0);
                            print(
                                _address.toString() + _totalAmount.toString());
                          });
                        },
                        child: SvgPicture.asset(
                          "assets/svg/clipboard.svg",
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
                    print("read qr code icon button tapped");
                    // TODO implement parse qr code
                    String qrResult = await MajaScan.startScan(
                      title: "Scan address QR Code",
                      barColor: CFColors.white,
                      titleColor: CFColors.dusk,
                      qRCornerColor: CFColors.spark,
                      qRScannerColor: CFColors.midnight,
                      flashlightEnable: true,
                      scanAreaScale: 0.7,
                    );
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

  _buildMaxFee(BitcoinService bitcoinService) {
    return FutureBuilder(
      future: bitcoinService.maxFee,
      builder: (context, futureData) {
        if (futureData.connectionState == ConnectionState.done &&
            futureData.data != null) {
          _maxFee = futureData.data.fee / 100000000;
          return FittedBox(
            child: Text(
              "${_maxFee.toStringAsFixed(8)} ${CurrencyUtilities.coinName}",
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
              "${_maxFee.toStringAsFixed(8)} ${CurrencyUtilities.coinName}",
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
        "${_totalAmount.toStringAsFixed(8)} ${CurrencyUtilities.coinName}",
        style: GoogleFonts.workSans(
          color: CFColors.twilight,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildTxFeeInfo() {
    final BitcoinService bitcoinService = Provider.of<BitcoinService>(context);
    final isTinyScreen = SizingUtilities.isTinyWidth(context);
    return Column(
      children: [
        // Transaction fee
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

  Widget _buildAmountInputBox(
      dynamic firoPrice, BitcoinService bitcoinService) {
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
                    _firoAmount = double.parse(firoAmount);
                    setState(() {
                      _totalAmount = _firoAmount + _maxFee;
                      _sendButtonEnabled =
                          (bitcoinService.validateFiroAddress(_address) &&
                              _firoAmount > 0);
                    });

                    if (firoPrice is double && firoPrice > 0) {
                      final String fiatAmountString =
                          (_firoAmount * firoPrice).toStringAsFixed(2);

                      _fiatAmountController.text = fiatAmountString;
                    }
                  } else {
                    setState(() {
                      _totalAmount = 0;
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
                        CurrencyUtilities.coinName,
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
                enabled: firoPrice is double && firoPrice > 0,
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
                    final fiatValue = double.parse(fiatAmount);
                    _firoAmount = fiatValue / firoPrice;

                    final amountString = _firoAmount.toStringAsFixed(8);

                    setState(() {
                      _totalAmount = double.parse(amountString) + _maxFee;
                    });

                    _firoAmountController.text = amountString;
                  } else {
                    setState(() {
                      _totalAmount = 0;
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
                        child: FutureBuilder(
                          future: CurrencyUtilities.fetchPreferredCurrency(),
                          builder: (context, futureData) {
                            if (futureData.connectionState ==
                                ConnectionState.done) {
                              _currency = futureData.data;
                              return Text(
                                _currency,
                                style: TextStyle(
                                  color: CFColors.twilight,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              );
                            }
                            return Text(
                              _currency == "" ? "..." : _currency,
                              style: TextStyle(
                                color: CFColors.twilight,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            );
                          },
                        )),
                  ),
                  hintText: firoPrice == 0 ? "..." : "0.00",
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

  _buildSendButton(BitcoinService bitcoinService) {
    return SizedBox(
      height: 48,
      width: MediaQuery.of(context).size.width - 40,
      child: GradientButton(
        enabled: _sendButtonEnabled,
        onTap: () {
          print("SEND pressed");

          final availableBalance = double.parse(_balance[4]) < _maxFee
              ? 0.0
              : double.parse(_balance[4]);

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

            if (bitcoinService.validateFiroAddress(_address)) {
              Navigator.of(context).push(
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
