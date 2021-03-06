import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/misc_global_constants.dart';
import 'package:paymint/utilities/shared_utilities.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:provider/provider.dart';

class AmountInputFieldController {
  Decimal _cryptoAmount;
  Decimal get cryptoAmount => _cryptoAmount ?? Decimal.zero;

  set cryptoAmount(Decimal value) {
    final isNewValue = _cryptoAmount != value;
    _cryptoAmount = value;
    if (amountChanged != null && isNewValue) {
      amountChanged();
    }
  }

  Decimal _cryptoTotal;
  Decimal get cryptoTotal => _cryptoTotal ?? Decimal.zero;

  set cryptoTotal(Decimal value) {
    final isNewValue = _cryptoTotal != value;
    _cryptoTotal = value;
    if (totalChanged != null && isNewValue) {
      totalChanged();
    }
  }

  bool hasFocus = false;
  VoidCallback amountChanged;
  VoidCallback totalChanged;

  AmountInputFieldController({
    this.amountChanged,
    this.totalChanged,
  });

  void clearAmounts() {
    cryptoAmount = Decimal.zero;
    cryptoTotal = Decimal.zero;
  }
}

class AmountInputField extends StatefulWidget {
  const AmountInputField({
    Key key,
    this.cryptoAmountController,
    this.fiatAmountController,
    this.controller,
    this.locale,
  }) : super(key: key);

  final AmountInputFieldController controller;
  final TextEditingController cryptoAmountController;
  final TextEditingController fiatAmountController;
  final String locale;

  @override
  _AmountInputFieldState createState() => _AmountInputFieldState();
}

class _AmountInputFieldState extends State<AmountInputField> {
  AmountInputFieldController controller;
  TextEditingController cryptoAmountController;
  TextEditingController fiatAmountController;

  bool _cryptoAmountHasFocus = false;
  bool _fiatAmountHasFocus = false;

  Decimal _tempPrice = Decimal.zero;

  VoidCallback onCryptoAmountChanged;
  bool cryptoAmountChangeLock = false;

  void _cryptoAmountChanged() async {
    if (!cryptoAmountChangeLock) {
      final String cryptoAmount = cryptoAmountController.text;
      if (cryptoAmount.isNotEmpty &&
          cryptoAmount != "." &&
          cryptoAmount != ",") {
        controller.cryptoAmount = cryptoAmount.contains(",")
            ? Decimal.parse(cryptoAmount.replaceFirst(",", "."))
            : Decimal.parse(cryptoAmount);
        final manager = Provider.of<Manager>(context, listen: false);
        final maxFee = (await manager.maxFee)?.fee ?? 0;
        setState(() {
          controller.cryptoTotal =
              controller.cryptoAmount + Utilities.satoshisToAmount(maxFee);
        });

        if (_tempPrice > Decimal.zero) {
          final String fiatAmountString = Utilities.localizedStringAsFixed(
            value: controller.cryptoAmount * _tempPrice,
            locale: widget.locale,
            decimalPlaces: 2,
          );

          fiatAmountController.text = fiatAmountString;
        }
      } else {
        setState(() {
          controller.cryptoTotal = Decimal.zero;
          controller.cryptoAmount = Decimal.zero;
        });
        fiatAmountController.text = "";
      }
    }
  }

  @override
  void initState() {
    controller = widget.controller;
    cryptoAmountController = widget.cryptoAmountController;
    fiatAmountController = widget.fiatAmountController;
    onCryptoAmountChanged = _cryptoAmountChanged;
    cryptoAmountController.addListener(onCryptoAmountChanged);
    super.initState();
  }

  @override
  void dispose() {
    cryptoAmountController.removeListener(onCryptoAmountChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<Manager>(context);
    return Container(
      decoration: BoxDecoration(
        color: CFColors.fog,
        borderRadius:
            BorderRadius.circular(SizingUtilities.circularBorderRadius),
        border: Border.all(
          width: 1,
          color: controller.hasFocus ? CFColors.focusedBorder : CFColors.dew,
        ),
      ),
      child: Center(
        child: FutureBuilder(
          future: manager.fiatPrice,
          builder: (context, priceData) {
            if (priceData.connectionState == ConnectionState.done &&
                priceData.data is Decimal) {
              if (_tempPrice != priceData.data) {
                _tempPrice = priceData.data;
              }
            }
            return Column(
              children: [
                Focus(
                  onFocusChange: (hasFocus) {
                    _cryptoAmountHasFocus = hasFocus;
                    setState(() {
                      controller.hasFocus =
                          _cryptoAmountHasFocus || _fiatAmountHasFocus;
                    });
                  },
                  child: TextField(
                    key: Key("amountInputFieldCryptoTextFieldKey"),
                    style: GoogleFonts.workSans(
                      color: CFColors.dusk,
                    ),
                    controller: cryptoAmountController,
                    keyboardType: TextInputType.numberWithOptions(
                        signed: false, decimal: true),
                    inputFormatters: [
                      // regex to validate a crypto amount with 8 decimal places
                      TextInputFormatter.withFunction((oldValue, newValue) =>
                          RegExp(r'^([0-9]*[,.]?[0-9]{0,8}|[,.][0-9]{0,8})$')
                                  .hasMatch(newValue.text)
                              ? newValue
                              : oldValue),
                    ],
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
                            Provider.of<Manager>(context, listen: false)
                                .coinTicker,
                            style: CFTextStyles.textFieldSuffix,
                          ),
                        ),
                      ),
                      hintText: Utilities.localizedStringAsFixed(
                        value: Decimal.zero,
                        locale: widget.locale,
                        decimalPlaces: 2,
                      ),
                      hintStyle: CFTextStyles.textFieldHint,
                    ),
                  ),
                ),
                Container(
                  height: 1,
                  color: controller.hasFocus
                      ? CFColors.focusedBorder
                      : CFColors.dew,
                ),
                Focus(
                  onFocusChange: (hasFocus) {
                    _fiatAmountHasFocus = hasFocus;
                    setState(() {
                      controller.hasFocus =
                          _cryptoAmountHasFocus || _fiatAmountHasFocus;
                    });
                  },
                  child: TextField(
                    key: Key("amountInputFieldFiatTextFieldKey"),
                    style: GoogleFonts.workSans(
                      color: CFColors.dusk,
                    ),
                    // enabled: widget.price > Decimal.zero,
                    controller: fiatAmountController,
                    keyboardType: TextInputType.numberWithOptions(
                      signed: false,
                      decimal: true,
                    ),
                    inputFormatters: [
                      // regex to validate a fiat amount with 2 decimal places
                      TextInputFormatter.withFunction((oldValue, newValue) =>
                          RegExp(r'^([0-9]*[,.]?[0-9]{0,2}|[,.][0-9]{0,2})$')
                                  .hasMatch(newValue.text)
                              ? newValue
                              : oldValue),
                    ],
                    onChanged: (String fiatAmount) async {
                      if (fiatAmount.isNotEmpty &&
                          fiatAmount != "." &&
                          fiatAmount != ",") {
                        final fiatValue = fiatAmount.contains(",")
                            ? Decimal.parse(fiatAmount.replaceFirst(",", "."))
                            : Decimal.parse(fiatAmount);

                        controller.cryptoAmount = _tempPrice <= Decimal.zero
                            ? Decimal.zero
                            : controller.cryptoAmount = (fiatValue / _tempPrice)
                                .toDecimal(
                                    scaleOnInfinitePrecision:
                                        CampfireConstants.decimalPlaces);

                        final amountString = Utilities.localizedStringAsFixed(
                          value: controller.cryptoAmount,
                          locale: widget.locale,
                          decimalPlaces: CampfireConstants.decimalPlaces,
                        );

                        final maxFee = (await manager.maxFee)?.fee ?? 0;
                        setState(() {
                          controller.cryptoTotal = controller.cryptoAmount +
                              Utilities.satoshisToAmount(maxFee);
                        });

                        cryptoAmountChangeLock = true;
                        cryptoAmountController.text = amountString;
                        cryptoAmountChangeLock = false;
                      } else {
                        setState(() {
                          controller.cryptoTotal = Decimal.zero;
                        });
                        cryptoAmountChangeLock = true;
                        cryptoAmountController.text = "";
                        cryptoAmountChangeLock = false;

                        controller.cryptoAmount = Decimal.zero;
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
                              return Text(
                                context.watch<String>(),
                                style: CFTextStyles.textFieldSuffix,
                              );
                            },
                          ),
                        ),
                      ),
                      hintText: _tempPrice < Decimal.zero
                          ? "..."
                          : Utilities.localizedStringAsFixed(
                              value: Decimal.zero,
                              locale: widget.locale,
                              decimalPlaces: 2,
                            ),
                      hintStyle: CFTextStyles.textFieldHint,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
