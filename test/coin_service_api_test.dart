import 'package:flutter_test/flutter_test.dart';
import 'package:paymint/services/coins/coin_service.dart';

import 'fake_coin_service_api.dart';

void main() {
  test("coinName throws", () {
    final CoinServiceAPI coinServiceAPI = FakeCoinServiceAPI();

    expect(() => coinServiceAPI.coinName, throwsA(isA<Exception>()));
  });

  test("coinTicker throws", () {
    final CoinServiceAPI coinServiceAPI = FakeCoinServiceAPI();

    expect(() => coinServiceAPI.coinTicker, throwsA(isA<Exception>()));
  });
}
