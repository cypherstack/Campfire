import 'package:flutter_test/flutter_test.dart';
import 'package:paymint/models/models.dart';

void main() {
  test("FeeObject constructor", () {
    final feeObject = FeeObject(fast: "3", medium: "1.5", slow: "0.3");
    expect(feeObject.toString(), "{fast: 3, medium: 1.5, slow: 0.3}");
  });

  test("FeeObject.fromJson factory", () {
    final feeObject = FeeObject.fromJson({
      "fast": 3,
      "average": 1.5,
      "slow": 0.3,
    });
    expect(feeObject.toString(), "{fast: 3, medium: 1.5, slow: 0.3}");
  });
}
