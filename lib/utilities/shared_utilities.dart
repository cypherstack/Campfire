import 'package:decimal/decimal.dart';
import 'package:paymint/services/globals.dart';

class Utilities {
  static double satoshisToAmount(int sats) =>
      double.parse((sats / 100000000.0).toStringAsFixed(8));

  static String amountToPrettyString(double amount) =>
      "${Decimal.parse(amount.toString())}";

  ///
  static String satoshiAmountToPrettyString(int sats) =>
      "${Decimal.parse(satoshisToAmount(sats).toString())}";

  // format date string from unix timestamp
  static String extractDateFrom(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

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
