import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:paymint/models/models.dart';

abstract class CoinServiceAPI {
  String get coinName {
    throw Exception("This getter \"coinName\" musty be overridden!");
  }

  String get coinTicker {
    throw Exception("This getter \"coinTicker\" musty be overridden!");
  }

  /// create and submit tx to network
  ///
  /// Returns the txid of the sent tx
  /// will throw exceptions on failure
  Future<String> send(
      {@required String toAddress,
      @required int amount,
      Map<String, String> args});

  Future<FeeObject> get fees;
  Future<LelantusFeeData> get maxFee;

  Future<String> get currentReceivingAddress;

  Future<Decimal> get balance;
  Future<Decimal> get pendingBalance;
  Future<Decimal> get totalBalance;
  Future<Decimal> get balanceMinusMaxFee;

  Future<List<String>> get allOwnAddresses;

  Future<TransactionData> get transactionData;

  Future<Decimal> get fiatPrice;

  Future<String> get fiatCurrency;
  Future<void> changeFiatCurrency(String currency);

  Future<bool> get useBiometrics;
  Future<void> updateBiometricsUsage(bool useBiometrics);

  Future<void> refresh();

  String get walletName;
  String get walletId;

  bool validateAddress(String address);

  Future<List<String>> get mnemonic;

  Future<bool> testNetworkConnection(String address, int port);

  dynamic recoverFromMnemonic(String mnemonic);
}
