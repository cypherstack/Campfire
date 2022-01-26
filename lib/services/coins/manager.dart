import 'package:flutter/material.dart';
import 'package:paymint/models/models.dart';
import 'package:paymint/services/coins/coin_service.dart';

class Manager with ChangeNotifier {
  CoinServiceAPI currentWallet;

  /// create and submit tx to network
  ///
  /// Returns the txid of the sent tx
  /// will throw exceptions on failure
  Future<String> send(
      {@required String toAddress,
      @required double amount,
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
  Future<FeeData> get maxFee => currentWallet.maxFee;

  Future<String> get currentReceivingAddress =>
      currentWallet.currentReceivingAddress;

  Future<double> get balance => currentWallet.balance;
  Future<double> get pendingBalance => currentWallet.pendingBalance;
  Future<double> get totalBalance => currentWallet.totalBalance;
  Future<double> get balanceMinusMaxFee => currentWallet.balanceMinusMaxFee;

  Future<double> get fiatBalance async {
    final balance = await currentWallet.balance;
    final price = await currentWallet.fiatPrice;
    return balance * price;
  }

  Future<double> get fiatTotalBalance async {
    final balance = await currentWallet.totalBalance;
    final price = await currentWallet.fiatPrice;
    return balance * price;
  }

  Future<TransactionData> get transactionData => currentWallet.transactionData;

  Future<dynamic> get fiatPrice => currentWallet.fiatPrice;

  Future<String> get fiatCurrency => currentWallet.fiatCurrency;
  Future<void> changeFiatCurrency(String currency) =>
      currentWallet.changeFiatCurrency(currency);

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

  Future<bool> testNetworkConnection(String address, String port) =>
      currentWallet.testNetworkConnection(address, port);

  dynamic recoverFromMnemonic(String mnemonic) async {
    try {
      await currentWallet.recoverFromMnemonic(mnemonic);
    } catch (e) {
      throw e;
    }
  }
}
