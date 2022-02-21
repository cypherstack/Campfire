import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:paymint/models/models.dart';
import 'package:paymint/services/coins/coin_service.dart';

class Manager with ChangeNotifier {
  CoinServiceAPI currentWallet;

  String get coinName => currentWallet.coinName;
  String get coinTicker => currentWallet.coinTicker;

  /// create and submit tx to network
  ///
  /// Returns the txid of the sent tx
  /// will throw exceptions on failure
  Future<String> send(
      {@required String toAddress,
      @required int amount,
      Map<String, String> args}) async {
    try {
      final txid = await currentWallet.send(
        toAddress: toAddress,
        amount: amount,
        args: args,
      );
      return txid;
    } catch (e) {
      // rethrow to pass error in alert
      throw e;
    }
  }

  Future<FeeObject> get fees => currentWallet.fees;
  Future<LelantusFeeData> get maxFee => currentWallet.maxFee;

  Future<String> get currentReceivingAddress =>
      currentWallet.currentReceivingAddress;

  Future<Decimal> get balance => currentWallet.balance;
  Future<Decimal> get pendingBalance => currentWallet.pendingBalance;
  Future<Decimal> get totalBalance => currentWallet.totalBalance;
  Future<Decimal> get balanceMinusMaxFee => currentWallet.balanceMinusMaxFee;

  Future<Decimal> get fiatBalance async {
    final balance = await currentWallet.balance;
    final price = await currentWallet.fiatPrice;
    return balance * price;
  }

  Future<Decimal> get fiatTotalBalance async {
    final balance = await currentWallet.totalBalance;
    final price = await currentWallet.fiatPrice;
    return balance * price;
  }

  Future<List<String>> get allOwnAddresses => currentWallet.allOwnAddresses;

  Future<TransactionData> get transactionData => currentWallet.transactionData;

  Future<Decimal> get fiatPrice => currentWallet.fiatPrice;

  String get fiatCurrency => currentWallet.fiatCurrency;
  void changeFiatCurrency(String currency) async {
    currentWallet.changeFiatCurrency(currency);
    notifyListeners();
  }

  Future<bool> get useBiometrics => currentWallet.useBiometrics;
  Future<void> updateBiometricsUsage(bool useBiometrics) =>
      currentWallet.updateBiometricsUsage(useBiometrics);

  Future<void> refresh() async {
    await currentWallet.refresh();
    notifyListeners();
  }

  String get walletName => currentWallet.walletName;
  String get walletId => currentWallet.walletId;

  bool validateAddress(String address) =>
      currentWallet.validateAddress(address);

  Future<List<String>> get mnemonic => currentWallet.mnemonic;

  Future<bool> testNetworkConnection(String address, int port, bool useSSL) =>
      currentWallet.testNetworkConnection(address, port, useSSL);

  dynamic recoverFromMnemonic(String mnemonic) async {
    try {
      await currentWallet.recoverFromMnemonic(mnemonic);
    } catch (e) {
      throw e;
    }
  }
}
