import 'package:decimal/decimal.dart';
import 'package:paymint/services/globals.dart';
import 'package:paymint/utilities/misc_global_constants.dart';

class Utilities {
  static Decimal satoshisToAmount(int sats) =>
      (Decimal.fromInt(sats) / Decimal.fromInt(CampfireConstants.satsPerCoin))
          .toDecimal(scaleOnInfinitePrecision: CampfireConstants.decimalPlaces);

  static String amountToPrettyString(double amount) =>
      "${Decimal.parse(amount.toString())}";

  ///
  static String satoshiAmountToPrettyString(int sats) {
    final amount = satoshisToAmount(sats);
    return amount.toStringAsFixed(CampfireConstants.decimalPlaces);
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
