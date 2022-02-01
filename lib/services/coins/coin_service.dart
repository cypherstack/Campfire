import 'package:flutter/material.dart';
import 'package:paymint/models/models.dart';

abstract class CoinServiceAPI {
  /// create and submit tx to network
  ///
  /// Returns the txid of the sent tx
  /// will throw exceptions on failure
  Future<String> send(
      {@required String toAddress,
      @required double amount,
      Map<String, String> args});

  Future<FeeObject> get fees;
  Future<LelantusFeeData> get maxFee;

  Future<String> get currentReceivingAddress;

  Future<double> get balance;
  Future<double> get pendingBalance;
  Future<double> get totalBalance;
  Future<double> get balanceMinusMaxFee;

  Future<TransactionData> get transactionData;

  Future<dynamic> get fiatPrice;

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