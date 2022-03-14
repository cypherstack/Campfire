import 'package:flutter_test/flutter_test.dart';
import 'package:paymint/models/models.dart';

void main() {
  group("Transaction isMinting", () {
    test("Transaction isMinting unconfirmed mint", () {
      final tx = Transaction(subType: "mint", confirmedStatus: false);
      expect(tx.isMinting, true);
    });

    test("Transaction isMinting confirmed mint", () {
      final tx = Transaction(subType: "mint", confirmedStatus: true);
      expect(tx.isMinting, false);
    });

    test("Transaction isMinting non mint tx", () {
      final tx = Transaction(subType: null, confirmedStatus: false);
      expect(tx.isMinting, false);
    });
  });

  test("Transaction.copyWith", () {
    final tx1 =
        Transaction(subType: "mint", confirmedStatus: true, txid: "some txid");
    final tx2 = tx1.copyWith();

    expect(tx2.toString(), tx1.toString());
  });
}
