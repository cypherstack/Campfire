import 'package:decimal/decimal.dart';
import 'package:decimal/intl.dart';
import 'package:intl/intl.dart';
import 'package:intl/number_symbols_data.dart' show numberFormatSymbols;
import 'package:paymint/services/globals.dart';
import 'package:paymint/utilities/misc_global_constants.dart';

class Utilities {
  static Decimal satoshisToAmount(int sats) =>
      (Decimal.fromInt(sats) / Decimal.fromInt(CampfireConstants.satsPerCoin))
          .toDecimal(scaleOnInfinitePrecision: CampfireConstants.decimalPlaces);

  ///
  static String satoshiAmountToPrettyString(int sats, String locale) {
    final amount = satoshisToAmount(sats);
    return localizedStringAsFixed(
        value: amount,
        locale: locale,
        decimalPlaces: CampfireConstants.decimalPlaces);
  }

  // format date string from unix timestamp
  static String extractDateFrom(int timestamp, {bool localized = true}) {
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

    if (!localized) {
      date = date.toUtc();
    }

    final minutes =
        date.minute < 10 ? "0${date.minute}" : date.minute.toString();
    return "${date.day} ${monthMapShort[date.month]} ${date.year}, ${date.hour}:$minutes";
  }

  static String localizedStringAsFixed({
    Decimal value,
    String locale,
    int decimalPlaces = 0,
  }) {
    assert(decimalPlaces >= 0);

    final format = NumberFormat.decimalPattern(locale);
    var result = format.format(DecimalIntl(value));

    final intValue = value.truncate();
    final fraction = value - intValue;

    if (fraction == Decimal.zero) {
      final separator = numberFormatSymbols[locale]?.DECIMAL_SEP ??
          numberFormatSymbols[locale.substring(0, 2)].DECIMAL_SEP;

      return result +
          separator +
          fraction.toStringAsFixed(decimalPlaces).substring(2);
    } else if (intValue == Decimal.zero) {
      final separator = numberFormatSymbols[locale]?.DECIMAL_SEP ??
          numberFormatSymbols[locale.substring(0, 2)].DECIMAL_SEP;
      return "0" +
          separator +
          fraction.toStringAsFixed(decimalPlaces).substring(2);
    } else {
      final regex = RegExp("[0-9]");
      var lastIndex = result.length - 1;
      while (lastIndex > 0) {
        final char = result[lastIndex];
        if (regex.hasMatch(char)) {
          lastIndex--;
          result = result.substring(0, lastIndex + 1);
        } else {
          break;
        }
      }

      if (decimalPlaces == 0) {
        lastIndex--;
        result = result.substring(0, lastIndex);
      } else {
        result = result + fraction.toStringAsFixed(decimalPlaces).substring(2);
      }

      return result;
    }
  }

  // format date string as dd/mm/yy from DateTime object
  static String formatDate(DateTime date) {
    // prepend '0' if needed
    final day = date.day < 10 ? "0${date.day}" : "${date.day}";

    // prepend '0' if needed
    final month = date.month < 10 ? "0${date.month}" : "${date.month}";

    // get last two digits of value
    final shortYear = date.year % 100;

    // prepend '0' if needed
    final year = shortYear < 10 ? "0$shortYear" : "$shortYear";

    return "$month/$day/$year";
  }
}
