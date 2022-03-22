import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:paymint/models/models.dart';
import 'package:paymint/services/coins/coin_service.dart';
import 'package:paymint/services/coins/firo/firo_wallet.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/services/event_bus/events/updated_in_background_event.dart';
import 'package:paymint/services/event_bus/global_event_bus.dart';

import 'firo_wallet_test.mocks.dart';
import 'manager_test.mocks.dart';
import 'sample_data/transaction_data_samples.dart';

@GenerateMocks([FiroWallet])
void main() {
  test("Manager should have no wallet on initialization", () {
    final manager = Manager();

    expect(manager.hasWallet, false);
  });

  test("Manager should have no backgroundRefreshListener on initialization",
      () {
    final manager = Manager();

    expect(manager.hasBackgroundRefreshListener, false);
  });

  group("set currentWallet", () {
    test("non null CoinServiceAPI subclass", () {
      final manager = Manager();

      manager.currentWallet = MockFiroWallet();
      expect(manager.hasWallet, true);
      expect(manager.hasBackgroundRefreshListener, true);
    });

    test("attempt to set to null should fail", () {
      final manager = Manager();

      expect(() => manager.currentWallet = null, throwsA(isA<Exception>()));
      expect(manager.hasWallet, false);
    });
  });

  test("get coinName", () {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.coinName).thenAnswer((_) => "Firo");
    final manager = Manager();
    manager.currentWallet = wallet;

    expect(manager.coinName, "Firo");
  });

  test("get coinTicker", () {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.coinTicker).thenAnswer((_) => "FIRO");

    final manager = Manager();
    manager.currentWallet = wallet;

    expect(manager.coinTicker, "FIRO");
  });

  group("send", () {
    test("successful send", () async {
      final CoinServiceAPI wallet = MockFiroWallet();
      when(wallet.send(toAddress: "some address", amount: 1987634))
          .thenAnswer((_) async => "some txid");

      final manager = Manager();
      manager.currentWallet = wallet;

      expect(await manager.send(toAddress: "some address", amount: 1987634),
          "some txid");
    });

    test("failed send", () {
      final CoinServiceAPI wallet = MockFiroWallet();
      when(wallet.send(toAddress: "some address", amount: 1987634))
          .thenThrow(Exception("Tx failed!"));

      final manager = Manager();
      manager.currentWallet = wallet;

      expect(() => manager.send(toAddress: "some address", amount: 1987634),
          throwsA(isA<Exception>()));
    });
  });

  test("fees", () async {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.fees)
        .thenAnswer((_) async => FeeObject(fast: "10", medium: "5", slow: "1"));

    final manager = Manager();
    manager.currentWallet = wallet;

    final feeObject = await manager.fees;

    expect(feeObject.fast, "10");
    expect(feeObject.medium, "5");
    expect(feeObject.slow, "1");
  });

  test("maxFee", () async {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.maxFee)
        .thenAnswer((_) async => LelantusFeeData(100, 10, [123, 321, 0]));

    final manager = Manager();
    manager.currentWallet = wallet;

    final lelantusFeeData = await manager.maxFee;

    expect(lelantusFeeData.fee, 10);
    expect(lelantusFeeData.changeToMint, 100);
    expect(lelantusFeeData.spendCoinIndexes, [123, 321, 0]);
  });

  test("get currentReceivingAddress", () async {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.currentReceivingAddress)
        .thenAnswer((_) async => "Some address string");

    final manager = Manager();
    manager.currentWallet = wallet;

    expect(await manager.currentReceivingAddress, "Some address string");
  });

  group("get balances", () {
    test("balance", () async {
      final CoinServiceAPI wallet = MockFiroWallet();
      when(wallet.balance).thenAnswer((_) async => Decimal.ten);

      final manager = Manager();
      manager.currentWallet = wallet;

      expect(await manager.balance, Decimal.ten);
    });

    test("pendingBalance", () async {
      final CoinServiceAPI wallet = MockFiroWallet();
      when(wallet.pendingBalance).thenAnswer((_) async => Decimal.fromInt(23));

      final manager = Manager();
      manager.currentWallet = wallet;

      expect(await manager.pendingBalance, Decimal.fromInt(23));
    });

    test("totalBalance", () async {
      final wallet = MockFiroWallet();
      when(wallet.totalBalance).thenAnswer((_) async => Decimal.fromInt(2));

      final manager = Manager();
      manager.currentWallet = wallet;

      expect(await manager.totalBalance, Decimal.fromInt(2));
    });

    test("balanceMinusMaxFee", () async {
      final CoinServiceAPI wallet = MockFiroWallet();
      when(wallet.balanceMinusMaxFee).thenAnswer((_) async => Decimal.one);

      final manager = Manager();
      manager.currentWallet = wallet;

      expect(await manager.balanceMinusMaxFee, Decimal.one);
    });

    test("fiatBalance", () async {
      final CoinServiceAPI wallet = MockFiroWallet();
      when(wallet.balance).thenAnswer((_) async => Decimal.fromInt(104));
      when(wallet.fiatPrice).thenAnswer((_) async => Decimal.fromInt(22));

      final manager = Manager();
      manager.currentWallet = wallet;

      expect(await manager.fiatBalance, Decimal.fromInt(22 * 104));
    });

    test("fiatTotalBalance", () async {
      final CoinServiceAPI wallet = MockFiroWallet();
      when(wallet.totalBalance).thenAnswer((_) async => Decimal.fromInt(14));
      when(wallet.fiatPrice).thenAnswer((_) async => Decimal.fromInt(12));
      final manager = Manager();
      manager.currentWallet = wallet;

      expect(await manager.fiatTotalBalance, Decimal.fromInt(12 * 14));
    });
  });

  test("allOwnAddresses", () async {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.allOwnAddresses)
        .thenAnswer((_) async => ["address1", "address2", "address3"]);

    final manager = Manager();
    manager.currentWallet = wallet;

    expect(await manager.allOwnAddresses, ["address1", "address2", "address3"]);
  });

  test("transactionData", () async {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.transactionData)
        .thenAnswer((_) async => TransactionData.fromJson(dateTimeChunksJson));

    final manager = Manager();
    manager.currentWallet = wallet;

    final expectedMap =
        TransactionData.fromJson(dateTimeChunksJson).getAllTransactions();
    final result = (await manager.transactionData).getAllTransactions();

    expect(result.length, expectedMap.length);

    for (int i = 0; i < expectedMap.length; i++) {
      final resultTxid = result.keys.toList(growable: false)[i];
      expect(result[resultTxid].toString(), expectedMap[resultTxid].toString());
    }
  });

  test("get fiatPrice", () async {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.fiatPrice).thenAnswer((_) async => Decimal.ten);

    final manager = Manager();
    manager.currentWallet = wallet;

    expect(await manager.fiatPrice, Decimal.ten);
  });

  test("get fiatCurrency", () {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.fiatCurrency).thenAnswer((_) => "USD");

    final manager = Manager();
    manager.currentWallet = wallet;

    expect(manager.fiatCurrency, "USD");
  });

  test("changeFiatCurrency", () {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.changeFiatCurrency("USD")).thenReturn(null);

    final manager = Manager();
    manager.currentWallet = wallet;

    manager.changeFiatCurrency("USD");

    verify(wallet.changeFiatCurrency("USD")).called(1);
  });

  test("get useBiometrics", () async {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.useBiometrics).thenAnswer((_) async => true);

    final manager = Manager();
    manager.currentWallet = wallet;

    expect(await manager.useBiometrics, true);
  });

  test("updateBiometricsUsage", () {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.updateBiometricsUsage(true)).thenReturn(null);

    final manager = Manager();
    manager.currentWallet = wallet;

    manager.updateBiometricsUsage(true);

    verify(wallet.updateBiometricsUsage(true)).called(1);
  });

  test("refresh", () async {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.refresh()).thenReturn(null);

    final manager = Manager();
    manager.currentWallet = wallet;

    await manager.refresh();

    verify(wallet.refresh()).called(1);
  });

  test("get walletName", () {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.walletName).thenAnswer((_) => "Some wallet name");
    final manager = Manager();
    manager.currentWallet = wallet;

    expect(manager.walletName, "Some wallet name");
  });

  test("get walletId", () {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.walletId).thenAnswer((_) => "Some wallet ID");

    final manager = Manager();
    manager.currentWallet = wallet;

    expect(manager.walletId, "Some wallet ID");
  });

  group("validateAddress", () {
    test("some valid address", () {
      final CoinServiceAPI wallet = MockFiroWallet();
      when(wallet.validateAddress("a valid address")).thenAnswer((_) => true);

      final manager = Manager();
      manager.currentWallet = wallet;

      expect(manager.validateAddress("a valid address"), true);
    });

    test("some invalid address", () {
      final CoinServiceAPI wallet = MockFiroWallet();
      when(wallet.validateAddress("an invalid address"))
          .thenAnswer((_) => false);

      final manager = Manager();
      manager.currentWallet = wallet;

      expect(manager.validateAddress("an invalid address"), false);
    });
  });

  test("get mnemonic", () async {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.mnemonic)
        .thenAnswer((_) async => ["Some", "seed", "word", "list"]);

    final manager = Manager();
    manager.currentWallet = wallet;

    expect(await manager.mnemonic, ["Some", "seed", "word", "list"]);
  });

  test("testNetworkConnection", () async {
    final CoinServiceAPI wallet = MockFiroWallet();
    final client = MockElectrumX();
    when(wallet.testNetworkConnection(client)).thenAnswer((_) async => true);

    final manager = Manager();
    manager.currentWallet = wallet;

    expect(await manager.testNetworkConnection(client), true);
  });

  group("recoverFromMnemonic", () {
    test("successfully recover", () async {
      final CoinServiceAPI wallet = MockFiroWallet();
      when(wallet.recoverFromMnemonic("Some valid mnemonic")).thenReturn(null);

      final manager = Manager();
      manager.currentWallet = wallet;

      await manager.recoverFromMnemonic("Some valid mnemonic");

      verify(wallet.recoverFromMnemonic("Some valid mnemonic")).called(1);
    });

    test("failed recovery", () async {
      final CoinServiceAPI wallet = MockFiroWallet();
      when(wallet.recoverFromMnemonic("Some invalid mnemonic"))
          .thenThrow(Exception("Invalid mnemonic"));

      final manager = Manager();
      manager.currentWallet = wallet;

      expect(() => manager.recoverFromMnemonic("Some invalid mnemonic"),
          throwsA(isA<Exception>()));

      verify(wallet.recoverFromMnemonic("Some invalid mnemonic")).called(1);
    });

    test("failed recovery due to some other error", () async {
      final CoinServiceAPI wallet = MockFiroWallet();
      when(wallet.recoverFromMnemonic("Some valid mnemonic"))
          .thenThrow(Error());

      final manager = Manager();
      manager.currentWallet = wallet;

      expect(() => manager.recoverFromMnemonic("Some valid mnemonic"),
          throwsA(isA<Error>()));

      verify(wallet.recoverFromMnemonic("Some valid mnemonic")).called(1);
    });
  });

  test("exitCurrentWallet", () async {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.exit()).thenReturn(null);

    final manager = Manager();
    manager.currentWallet = wallet;

    await manager.exitCurrentWallet();

    expect(manager.hasBackgroundRefreshListener, false);
    expect(manager.hasWallet, false);

    verify(wallet.exit()).called(1);
  });

  test("dispose", () {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.exit()).thenReturn(null);

    final manager = Manager();
    manager.currentWallet = wallet;

    expect(() => manager.dispose(), returnsNormally);
  });

  test("act on event", () async {
    final CoinServiceAPI wallet = MockFiroWallet();
    when(wallet.exit()).thenReturn(null);

    final manager = Manager();
    manager.currentWallet = wallet;

    expect(
        () => GlobalEventBus.instance
            .fire(UpdatedInBackgroundEvent("act on event - test message")),
        returnsNormally);

    expect(() => manager.dispose(), returnsNormally);
  });
}
