import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:paymint/electrumx_rpc/electrumx.dart';
import 'package:paymint/models/models.dart';
import 'package:paymint/services/coins/coin_service.dart';

class Manager with ChangeNotifier {
  CoinServiceAPI _currentWallet;

  set currentWallet(CoinServiceAPI newValue) {
    _currentWallet = newValue;
  }

  bool get hasWallet => _currentWallet != null;

  String get coinName => _currentWallet.coinName;
  String get coinTicker => _currentWallet.coinTicker;

  /// create and submit tx to network
  ///
  /// Returns the txid of the sent tx
  /// will throw exceptions on failure
  Future<String> send(
      {@required String toAddress,
      @required int amount,
      Map<String, String> args}) async {
    try {
      final txid = await _currentWallet.send(
        toAddress: toAddress,
        amount: amount,
        args: args,
      );
      notifyListeners();
      return txid;
    } catch (e) {
      // rethrow to pass error in alert
      throw e;
    }
  }

  Future<FeeObject> get fees => _currentWallet.fees;
  Future<LelantusFeeData> get maxFee => _currentWallet.maxFee;

  Future<String> get currentReceivingAddress =>
      _currentWallet.currentReceivingAddress;

  Future<Decimal> get balance => _currentWallet.balance;
  Future<Decimal> get pendingBalance => _currentWallet.pendingBalance;
  Future<Decimal> get totalBalance => _currentWallet.totalBalance;
  Future<Decimal> get balanceMinusMaxFee => _currentWallet.balanceMinusMaxFee;

  Future<Decimal> get fiatBalance async {
    final balance = await _currentWallet.balance;
    final price = await _currentWallet.fiatPrice;
    return balance * price;
  }

  Future<Decimal> get fiatTotalBalance async {
    final balance = await _currentWallet.totalBalance;
    final price = await _currentWallet.fiatPrice;
    return balance * price;
  }

  Future<List<String>> get allOwnAddresses => _currentWallet.allOwnAddresses;

  Future<TransactionData> get transactionData => _currentWallet.transactionData;

  Future<Decimal> get fiatPrice => _currentWallet.fiatPrice;

  String get fiatCurrency => _currentWallet.fiatCurrency;
  void changeFiatCurrency(String currency) async {
    _currentWallet.changeFiatCurrency(currency);
    notifyListeners();
  }

  Future<bool> get useBiometrics => _currentWallet.useBiometrics;
  Future<void> updateBiometricsUsage(bool useBiometrics) async {
    _currentWallet.updateBiometricsUsage(useBiometrics);
    notifyListeners();
  }

  Future<void> refresh() async {
    await _currentWallet.refresh();
    notifyListeners();
  }

  String get walletName => _currentWallet.walletName;
  String get walletId => _currentWallet.walletId;

  bool validateAddress(String address) =>
      _currentWallet.validateAddress(address);

  Future<List<String>> get mnemonic => _currentWallet.mnemonic;

  Future<bool> testNetworkConnection(ElectrumX client) =>
      _currentWallet.testNetworkConnection(client);

  dynamic recoverFromMnemonic(String mnemonic) async {
    try {
      await _currentWallet.recoverFromMnemonic(mnemonic);
    } catch (e) {
      throw e;
    }
  }

  Future<void> exitCurrentWallet() async {
    await _currentWallet.exit();
    _currentWallet = null;
  }
}
