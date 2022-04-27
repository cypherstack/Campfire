import 'package:decimal/decimal.dart';
import 'package:paymint/electrumx_rpc/electrumx.dart';
import 'package:paymint/models/fee_object_model.dart';
import 'package:paymint/models/lelantus_fee_data.dart';
import 'package:paymint/models/transactions_model.dart';
import 'package:paymint/services/coins/coin_service.dart';

class FakeCoinServiceAPI extends CoinServiceAPI {
  @override
  // TODO: implement allOwnAddresses
  Future<List<String>> get allOwnAddresses => throw UnimplementedError();

  @override
  // TODO: implement balance
  Future<Decimal> get balance => throw UnimplementedError();

  @override
  // TODO: implement balanceMinusMaxFee
  Future<Decimal> get balanceMinusMaxFee => throw UnimplementedError();

  @override
  void changeFiatCurrency(String currency) {
    // TODO: implement changeFiatCurrency
  }

  @override
  // TODO: implement currentReceivingAddress
  Future<String> get currentReceivingAddress => throw UnimplementedError();

  @override
  Future<void> exit() {
    // TODO: implement exit
    throw UnimplementedError();
  }

  @override
  // TODO: implement fees
  Future<FeeObject> get fees => throw UnimplementedError();

  @override
  // TODO: implement fiatCurrency
  String get fiatCurrency => throw UnimplementedError();

  @override
  // TODO: implement fiatPrice
  Future<Decimal> get fiatPrice => throw UnimplementedError();

  @override
  // TODO: implement maxFee
  Future<LelantusFeeData> get maxFee => throw UnimplementedError();

  @override
  // TODO: implement mnemonic
  Future<List<String>> get mnemonic => throw UnimplementedError();

  @override
  // TODO: implement pendingBalance
  Future<Decimal> get pendingBalance => throw UnimplementedError();

  @override
  Future<void> recoverFromMnemonic(String mnemonic) {
    // TODO: implement recoverFromMnemonic
    throw UnimplementedError();
  }

  @override
  Future<void> refresh() {
    // TODO: implement refresh
    throw UnimplementedError();
  }

  @override
  Future<String> send(
      {String toAddress, int amount, Map<String, String> args}) {
    // TODO: implement send
    throw UnimplementedError();
  }

  @override
  Future<bool> testNetworkConnection(ElectrumX client) {
    // TODO: implement testNetworkConnection
    throw UnimplementedError();
  }

  @override
  // TODO: implement totalBalance
  Future<Decimal> get totalBalance => throw UnimplementedError();

  @override
  // TODO: implement transactionData
  Future<TransactionData> get transactionData => throw UnimplementedError();

  @override
  Future<void> updateBiometricsUsage(bool useBiometrics) {
    // TODO: implement updateBiometricsUsage
    throw UnimplementedError();
  }

  @override
  // TODO: implement useBiometrics
  Future<bool> get useBiometrics => throw UnimplementedError();

  @override
  bool validateAddress(String address) {
    // TODO: implement validateAddress
    throw UnimplementedError();
  }

  @override
  // TODO: implement walletId
  String get walletId => throw UnimplementedError();

  @override
  // TODO: implement walletName
  String get walletName => throw UnimplementedError();

  @override
  Future<bool> initializeWallet() {
    // TODO: implement initializeWallet
    throw UnimplementedError();
  }

  @override
  Future<void> fullRescan() {
    // TODO: implement fullRescan
    throw UnimplementedError();
  }
}
