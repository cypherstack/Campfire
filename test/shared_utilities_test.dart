import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paymint/utilities/shared_utilities.dart';

void main() {
  group("satoshisToAmount", () {
    test("12345", () {
      expect(Utilities.satoshisToAmount(12345), Decimal.parse("0.00012345"));
    });

    test("100012345", () {
      expect(
          Utilities.satoshisToAmount(100012345), Decimal.parse("1.00012345"));
    });

    test("0", () {
      expect(Utilities.satoshisToAmount(0), Decimal.zero);
    });

    test("1000000000", () {
      expect(Utilities.satoshisToAmount(1000000000), Decimal.parse("10"));
    });
  });

  group("satoshiAmountToPrettyString", () {
    final locale = "en_US";
    test("12345", () {
      expect(
          Utilities.satoshiAmountToPrettyString(12345, locale), "0.00012345");
    });

    test("100012345", () {
      expect(Utilities.satoshiAmountToPrettyString(100012345, locale),
          "1.00012345");
    });

    test("123450000", () {
      expect(Utilities.satoshiAmountToPrettyString(123450000, locale),
          "1.23450000");
    });

    test("1230045000", () {
      expect(Utilities.satoshiAmountToPrettyString(1230045000, locale),
          "12.30045000");
    });

    test("1000000000", () {
      expect(Utilities.satoshiAmountToPrettyString(1000000000, locale),
          "10.00000000");
    });

    test("0", () {
      expect(Utilities.satoshiAmountToPrettyString(0, locale), "0.00000000");
    });
  });

  group("extractDateFrom", () {
    test("1614578400", () {
      expect(Utilities.extractDateFrom(1614578400, localized: false),
          "1 Mar 2021, 6:00");
    });

    test("1641589563", () {
      expect(Utilities.extractDateFrom(1641589563, localized: false),
          "7 Jan 2022, 21:06");
    });
  });

  group("formatDate", () {
    test("formatDate", () {
      final date = DateTime(2020);
      expect(Utilities.formatDate(date), "01/01/20");
    });
    test("formatDate", () {
      final date = DateTime(2021, 2, 6, 23, 58);
      expect(Utilities.formatDate(date), "02/06/21");
    });
    test("formatDate", () {
      final date = DateTime(2021, 13);
      expect(Utilities.formatDate(date), "01/01/22");
    });
    test("formatDate", () {
      final date = DateTime(2021, 2, 35);
      expect(Utilities.formatDate(date), "03/07/21");
    });
  });
}
