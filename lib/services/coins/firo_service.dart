import 'dart:convert';
import 'dart:developer';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:decimal/decimal.dart';
import 'package:firo_flutter/firo_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:lelantus/lelantus.dart';
import 'package:paymint/electrumx_rpc/cached_electrumx.dart';
import 'package:paymint/electrumx_rpc/electrumx.dart';
import 'package:paymint/models/fee_object_model.dart';
import 'package:paymint/models/lelantus_coin.dart';
import 'package:paymint/models/lelantus_fee_data.dart';
import 'package:paymint/models/models.dart' as models;
import 'package:paymint/models/transactions_model.dart';
import 'package:paymint/models/utxo_model.dart';
import 'package:paymint/services/coins/coin_service.dart';
import 'package:paymint/services/event_bus/events/node_connection_status_changed_event.dart';
import 'package:paymint/services/event_bus/events/nodes_changed_event.dart';
import 'package:paymint/services/event_bus/events/refresh_percent_changed_event.dart';
import 'package:paymint/services/event_bus/global_event_bus.dart';
import 'package:paymint/services/node_service.dart';
import 'package:paymint/utilities/currency_utils.dart';
import 'package:paymint/utilities/logger.dart';
import 'package:paymint/utilities/misc_global_constants.dart';
import 'package:paymint/utilities/shared_utilities.dart';
import 'package:uuid/uuid.dart';

import '../globals.dart';

const JMINT_INDEX = 5;
const MINT_INDEX = 2;
const TRANSACTION_LELANTUS = 8;
const ANONYMITY_SET_EMPTY_ID = 0;

final firoNetwork = NetworkType(
    messagePrefix: '\x18Zcoin Signed Message:\n',
    bech32: 'bc',
    bip32: Bip32Type(public: 0x0488b21e, private: 0x0488ade4),
    pubKeyHash: 0x52,
    scriptHash: 0x07,
    wif: 0xd2);

final firoNetworkType = bip32.NetworkType(
    wif: 0xd2, bip32: bip32.Bip32Type(public: 0x0488b21e, private: 0x0488ade4));

Isolate isolate;

Future<ReceivePort> getIsolate(Map<String, dynamic> arguments) async {
  ReceivePort receivePort =
      ReceivePort(); //port for isolate to receive messages.
  arguments['sendPort'] = receivePort.sendPort;
  while (true) {
    if (isolate == null) {
      print("starting isolate ${arguments['function']}");
      isolate = await Isolate.spawn(executeNative, arguments);
      break;
    }
  }
  return receivePort;
}

Future<void> executeNative(arguments) async {
  SendPort sendPort = arguments['sendPort'];
  String function = arguments['function'];
  Node node = arguments['node'];
  try {
    if (function == "createJoinSplit") {
      int spendAmount = arguments['spendAmount'];
      String address = arguments['address'];
      bool subtractFeeFromAmount = arguments['subtractFeeFromAmount'];
      String mnemonic = arguments['mnemonic'];
      int index = arguments['index'];
      Decimal price = arguments['price'];
      List<DartLelantusEntry> lelantusEntries = arguments['lelantusEntries'];
      if (!(spendAmount == null ||
          address == null ||
          subtractFeeFromAmount == null ||
          mnemonic == null ||
          index == null ||
          price == null ||
          lelantusEntries == null ||
          node == null)) {
        var joinSplit = await isolateCreateJoinSplitTransaction(
            spendAmount,
            address,
            subtractFeeFromAmount,
            mnemonic,
            index,
            price,
            lelantusEntries,
            node);
        sendPort.send(joinSplit);
        return;
      }
    } else if (function == "estimateJoinSplit") {
      int spendAmount = arguments['spendAmount'];
      bool subtractFeeFromAmount = arguments['subtractFeeFromAmount'];
      List<DartLelantusEntry> lelantusEntries = arguments['lelantusEntries'];

      if (!(spendAmount == null ||
          subtractFeeFromAmount == null ||
          lelantusEntries == null ||
          node == null)) {
        var feeData = await isolateEstimateJoinSplitFee(
            spendAmount, subtractFeeFromAmount, lelantusEntries, node);
        sendPort.send(feeData);
        return;
      }
    } else if (function == "restore") {
      String mnemonic = arguments['mnemonic'];
      TransactionData transactionData = arguments['transactionData'];
      String currency = arguments['currency'];
      String coinName = arguments['coinName'];

      if (!(mnemonic == null || transactionData == null || node == null)) {
        var restoreData = await isolateRestore(
            node, mnemonic, transactionData, currency, coinName);
        sendPort.send(restoreData);
        return;
      }
    }
    print("Error Arguments for $function not formatted correctly");
    sendPort.send("Error");
  } catch (e) {
    print("An error was thrown in this isolate $function");
    sendPort.send("Error");
  }
}

void stop() {
  if (isolate != null) {
    print('Stopping Isolate...');
    isolate.kill(priority: Isolate.immediate);
    isolate = null;
  }
}

isolateRestore(Node node, String mnemonic, TransactionData data,
    String currency, String coinName) async {
  List<int> jindexes = [];
  Map<dynamic, LelantusCoin> _lelantus_coins = Map();
  final setDataMap = Map();

  final spendTxIds = List.empty(growable: true);
  var lastFoundIndex = 0;
  var currentIndex = 0;

  try {
    final latestSetId = await getLatestSetId(node);
    for (var setId = 1; setId <= latestSetId; setId++) {
      final setData = await getSetData(node, setId);
      setDataMap[setId] = setData;
    }

    final usedSerialNumbers = (await getUsedCoinSerials(node))['serials'];
    Set usedSerialNumbersSet = Set();
    for (int ind = 0; ind < usedSerialNumbers.length; ind++) {
      usedSerialNumbersSet.add(usedSerialNumbers[ind]);
    }

    while (currentIndex < lastFoundIndex + 20) {
      final mintKeyPair = await _getNode(MINT_INDEX, currentIndex, mnemonic);
      final mintTag = CreateTag(uint8listToString(mintKeyPair.privateKey),
          currentIndex, uint8listToString(mintKeyPair.identifier));

      for (var setId = 1; setId <= latestSetId; setId++) {
        final Map<String, dynamic> setData = setDataMap[setId];
        setData.forEach((key, value) {});
        var foundMint = null;
        for (int indexMint = 0;
            indexMint < setData['mints'].length;
            indexMint++) {
          if (setData['mints'][indexMint][1] == mintTag) {
            foundMint = setData['mints'][indexMint];
            break;
          }
        }
        if (foundMint != null) {
          lastFoundIndex = currentIndex;
          final amount = foundMint[2];
          final serialNumber = GetSerialNumber(
            amount,
            uint8listToString(mintKeyPair.privateKey),
            currentIndex,
          );
          _lelantus_coins[foundMint[3]] = LelantusCoin(
            currentIndex,
            amount,
            foundMint[0],
            foundMint[3],
            setId,
            usedSerialNumbersSet.contains(serialNumber),
          );
          print(
              "amount ${_lelantus_coins[foundMint[3]].value} used ${_lelantus_coins[foundMint[3]].isUsed}");
        } else {
          var foundJmint = null;
          for (int indexJmint = 0;
              indexJmint < setData['jmints'].length;
              indexJmint++) {
            if (setData['jmints'][indexJmint][1] == mintTag) {
              foundJmint = setData['jmints'][indexJmint];
              break;
            }
          }
          if (foundJmint != null) {
            lastFoundIndex = currentIndex;

            final keyPath = GetAesKeyPath(foundJmint[0]);
            final aesKeyPair = await _getNode(JMINT_INDEX, keyPath, mnemonic);
            final aesPrivateKey = uint8listToString(aesKeyPair.privateKey);
            if (aesPrivateKey != null) {
              final amount = decryptMintAmount(
                aesPrivateKey,
                foundJmint[2],
              );

              final serialNumber = GetSerialNumber(
                amount,
                uint8listToString(mintKeyPair.privateKey),
                currentIndex,
              );

              _lelantus_coins[foundJmint[3]] = LelantusCoin(
                currentIndex,
                amount,
                foundJmint[0],
                foundJmint[3],
                setId,
                usedSerialNumbersSet.contains(serialNumber),
              );
              jindexes.add(currentIndex);

              spendTxIds.add(foundJmint[3]);
            }
          }
        }
      }

      currentIndex++;
    }
  } catch (e) {
    Logger.print("Exception rethrown from isolateRestore(): $e");
    throw e;
  }

  Map<String, dynamic> result = Map();
  print("mints $_lelantus_coins");
  print("jmints $spendTxIds");

  result['_lelantus_coins'] = _lelantus_coins;
  result['mintIndex'] = lastFoundIndex + 1;
  result['jindex'] = jindexes;

  // Edit the receive transactions with the mint fees.
  Map<String, models.Transaction> editedTransactions =
      Map<String, models.Transaction>();
  _lelantus_coins.forEach((key, value) {
    String txid = value.txId;
    var tx = data.findTransaction(txid);
    if (tx == null) {
      // This is a jmint.
      return;
    }
    List<models.Transaction> inputs = [];
    tx.inputs.forEach((element) {
      var input = data.findTransaction(element.txid);
      if (input != null) {
        inputs.add(input);
      }
    });
    if (inputs.isEmpty) {
      //some error.
      return;
    }

    int mintfee = tx.fees;
    int sharedfee = mintfee ~/ inputs.length;
    inputs.forEach((element) {
      editedTransactions[element.txid] = models.Transaction(
          txid: element.txid,
          confirmedStatus: element.confirmedStatus,
          timestamp: element.timestamp,
          txType: element.txType,
          amount: element.amount,
          aliens: element.aliens,
          worthNow: element.worthNow,
          worthAtBlockTimestamp: element.worthAtBlockTimestamp,
          fees: sharedfee,
          inputSize: element.inputSize,
          outputSize: element.outputSize,
          inputs: element.inputs,
          outputs: element.outputs,
          address: element.address,
          height: element.height,
          subType: "mint");
    });
  });
  print(editedTransactions);

  Map<String, models.Transaction> transactionMap = data.getAllTransactions();
  print(transactionMap);

  editedTransactions.forEach((key, value) {
    transactionMap.update(key, (_value) => value);
  });
  transactionMap.removeWhere((key, value) =>
      _lelantus_coins.containsKey(key) ||
      (value.height == -1 && !value.confirmedStatus));
  transactionMap.forEach((key, value) {
    print(value);
  });

  // Create the joinsplit transactions.
  final spendTxs =
      await getJMintTransactions(node, spendTxIds, currency, coinName);
  print(spendTxs);
  spendTxs.forEach((element) {
    transactionMap[element.txid] = element;
  });

  final TransactionData newTxData = TransactionData.fromMap(transactionMap);
  result['newTxData'] = newTxData;
  return result;
}

Future<int> getLatestSetId(Node node) async {
  try {
    final client = ElectrumX(server: node.address, port: node.port);
    final id = await client.getLatestCoinId();
    return id;
  } catch (e) {
    Logger.print("Exception rethrown in firo_service.dart: $e");
    throw e;
  }
}

Future<Map<String, dynamic>> getSetData(Node node, int setID) async {
  try {
    final client = ElectrumX(server: node.address, port: node.port);
    final response = await client.getCoinsForRecovery(setId: setID);
    return response;
  } catch (e) {
    Logger.print("Exception rethrown in firo_service.dart: $e");
    throw e;
  }
}

Future<dynamic> getUsedCoinSerials(Node node) async {
  try {
    final client = ElectrumX(server: node.address, port: node.port);
    final response = await client.getUsedCoinSerials();
    return response;
  } catch (e) {
    Logger.print("Exception rethrown in firo_service.dart: $e");
    throw e;
  }
}

Future<List<models.Transaction>> getJMintTransactions(
  Node node,
  List transactions,
  String currency,
  String coinName,
) async {
  try {
    final currentPrice = await _getFiroPrice(baseCurrency: currency);

    List<models.Transaction> txs = [];

    final cachedClient = CachedElectrumX(server: node.address, port: node.port);

    for (int i = 0; i < transactions.length; i++) {
      try {
        final tx = await cachedClient.getTransaction(
          tx_hash: transactions[i],
          verbose: true,
          coinName: coinName,
        );

        // TODO not sure if removing here increases or decreases performance
        // tx.remove("lelantusData");
        // tx.remove("hex");
        // tx.remove("hash");
        // tx.remove("blockhash");
        // tx.remove("blocktime");
        // tx.remove("instantlock");
        // tx.remove("chainlock");
        // tx.remove("version");

        tx["confirmed_status"] =
            tx["confirmations"] != null && tx["confirmations"] > 0;
        // tx.remove("confirmations");

        tx["timestamp"] = tx["time"];
        // tx.remove("time");

        tx["txType"] = "Sent";

        var sendIndex = 1;

        if (tx["vout"][0]["value"] != null && tx["vout"][0]["value"] > 0) {
          sendIndex = 0;
        }
        tx["amount"] = tx["vout"][sendIndex]["value"];

        tx["address"] = tx["vout"][sendIndex]["scriptPubKey"]["addresses"][0];

        tx["fees"] = tx["vin"][0]["nFees"];
        tx["inputSize"] = tx["vin"].length;
        tx["outputSize"] = tx["vout"].length;

        // tx.remove("vin");
        // tx.remove("vout");
        // tx.remove("size");
        // tx.remove("vsize");
        // tx.remove("type");
        // tx.remove("locktime");
        final decimalAmount = Decimal.parse(tx["amount"].toString());

        tx["worthNow"] = (currentPrice * decimalAmount).toStringAsFixed(2);
        tx["worthAtBlockTimestamp"] = tx["worthNow"];

        tx["subType"] = "join";
        txs.add(models.Transaction.fromLelantusJson(tx));
      } catch (e) {
        Logger.print("Exception caught in getJMintTransactions(): $e");
      }
    }
    return txs;
  } catch (e) {
    Logger.print("Exception rethrown in getJMintTransactions(): $e");
    throw e;
  }
}

Future<LelantusFeeData> isolateEstimateJoinSplitFee(
    int spendAmount,
    bool subtractFeeFromAmount,
    List<DartLelantusEntry> lelantusEntries,
    Node node) async {
  for (int i = 0; i < lelantusEntries.length; i++) {}

  List<int> changeToMint = List.empty(growable: true);
  List<int> spendCoinIndexes = List.empty(growable: true);
  print(lelantusEntries);
  final fee = estimateFee(
    spendAmount,
    subtractFeeFromAmount,
    lelantusEntries,
    changeToMint,
    spendCoinIndexes,
  );

  final estimateFeeData =
      LelantusFeeData(changeToMint[0], fee, spendCoinIndexes);
  return estimateFeeData;
}

isolateCreateJoinSplitTransaction(
  int spendAmount,
  String address,
  bool subtractFeeFromAmount,
  String mnemonic,
  int index,
  dynamic price,
  List<DartLelantusEntry> lelantusEntries,
  Node node,
) async {
  final getanonymityset = await getAnonymitySet(node);

  final estimateJoinSplitFee = await isolateEstimateJoinSplitFee(
      spendAmount, subtractFeeFromAmount, lelantusEntries, node);
  var changeToMint = estimateJoinSplitFee.changeToMint;
  var fee = estimateJoinSplitFee.fee;
  var spendCoinIndexes = estimateJoinSplitFee.spendCoinIndexes;
  print("$changeToMint $fee $spendCoinIndexes");
  if (spendCoinIndexes.isEmpty) {
    print("Error, Not enough funds.");
    return 1;
  }

  final tx = new TransactionBuilder(network: firoNetwork);
  int locktime = await getBlockHead(node);
  tx.setLockTime(locktime);

  tx.setVersion(3 | (TRANSACTION_LELANTUS << 16));

  tx.addInput(
    '0000000000000000000000000000000000000000000000000000000000000000',
    4294967295,
    4294967295,
    Uint8List(0),
  );

  final jmintKeyPair = await _getNode(MINT_INDEX, index, mnemonic);

  final String jmintprivatekey = uint8listToString(jmintKeyPair.privateKey);

  final keyPath = getMintKeyPath(changeToMint, jmintprivatekey, index);

  final aesKeyPair = await _getNode(JMINT_INDEX, keyPath, mnemonic);
  final aesPrivateKey = uint8listToString(aesKeyPair.privateKey);
  if (aesPrivateKey == null) {
    print(
      'firo_walvar:createLelantusSpendTx key pair is undefined',
    );
    return 3;
  }

  final jmintData = createJMintScript(
    changeToMint,
    uint8listToString(jmintKeyPair.privateKey),
    index,
    uint8listToString(jmintKeyPair.identifier),
    aesPrivateKey,
  );

  tx.addOutput(
    stringToUint8List(jmintData),
    0,
  );

  int amount = spendAmount;
  if (subtractFeeFromAmount) {
    amount -= fee;
  }
  tx.addOutput(
    address,
    amount,
  );

  final extractedTx = tx.buildIncomplete();
  extractedTx.setPayload(Uint8List(0));
  final txHash = extractedTx.getId();

  final List<int> setIds = [];
  final List<List<String>> anonymitySets = [];
  final List<String> anonymitySetHashes = [];
  final List<String> groupBlockHashes = [];
  for (var i = 0; i < lelantusEntries.length; i++) {
    final anonymitySetId = lelantusEntries[i].anonymitySetId;
    if (!setIds.contains(anonymitySetId)) {
      setIds.add(anonymitySetId);
      List<Map> _anonymity_sets = [null, getanonymityset];
      if (_anonymity_sets[anonymitySetId] != null) {
        final anonymitySet = _anonymity_sets[anonymitySetId];
        anonymitySetHashes.add(anonymitySet['setHash']);
        groupBlockHashes.add(anonymitySet['blockHash']);
        anonymitySets.add(anonymitySet['serializedCoins']);
      }
    }
  }

  final spendScript = createJoinSplitScript(
      txHash,
      spendAmount,
      subtractFeeFromAmount,
      uint8listToString(jmintKeyPair.privateKey),
      index,
      lelantusEntries,
      setIds,
      anonymitySets,
      anonymitySetHashes,
      groupBlockHashes);

  final finalTx = new TransactionBuilder(network: firoNetwork);
  finalTx.setLockTime(locktime);

  finalTx.setVersion(3 | (TRANSACTION_LELANTUS << 16));

  finalTx.addOutput(
    stringToUint8List(jmintData),
    0,
  );

  finalTx.addOutput(
    address,
    amount,
  );

  final extTx = finalTx.buildIncomplete();
  extTx.addInput(
    stringToUint8List(
        '0000000000000000000000000000000000000000000000000000000000000000'),
    4294967295,
    4294967295,
    stringToUint8List("c9"),
  );
  extTx.setPayload(stringToUint8List(spendScript));

  final txHex = extTx.toHex();
  final txId = extTx.getId();
  print("txid  $txId");
  Logger.print("$txHex");
  return {
    "txid": txId,
    "txHex": txHex,
    "value": amount,
    // TODO: check if cast toDouble is required
    "fees": Utilities.satoshisToAmount(fee).toDouble(),
    "jmintValue": changeToMint,
    "publicCoin": "jmintData.publicCoin",
    "spendCoinIndexes": spendCoinIndexes,
    "height": locktime,
    "txType": "Sent",
    "confirmed_status": false,
    // TODO: check if cast toDouble is required
    "amount": Utilities.satoshisToAmount(fee).toDouble(),
    "worthNow": ((Decimal.fromInt(amount) * price) /
            Decimal.fromInt(CampfireConstants.satsPerCoin))
        .toDecimal(scaleOnInfinitePrecision: 2)
        .toStringAsFixed(2),
    "address": address,
    "timestamp": DateTime.now().millisecondsSinceEpoch ~/ 1000,
    "subType": "join",
  };
}

uint8listToString(Uint8List list) {
  String result = "";
  for (var n in list) {
    result +=
        (n.toRadixString(16).length == 1 ? "0" : "") + n.toRadixString(16);
  }
  return result;
}

stringToUint8List(String string) {
  List<int> mintlist = List.empty(growable: true);
  for (var leg = 0; leg < string.length; leg = leg + 2) {
    mintlist.add(int.parse(string.substring(leg, leg + 2), radix: 16));
  }
  Uint8List mintu8 = Uint8List.fromList(mintlist);
  return mintu8;
}

Future<bip32.BIP32> _getNode(int chain, int index, String mnemonic) async {
  final seed = bip39.mnemonicToSeed(mnemonic);
  final root = bip32.BIP32.fromSeed(seed);

  final node = root.derivePath("m/44'/136'/0'/$chain/$index");
  return node;
}

Future<dynamic> getAnonymitySet(Node node) async {
  try {
    final client = ElectrumX(server: node.address, port: node.port);
    var tod = await client.getAnonymitySet();
    tod['serializedCoins'] = tod['serializedCoins'].cast<String>();

    return tod;
  } catch (e) {
    Logger.print("Exception rethrown in getAnonymitySet(): $e");
    throw e;
  }
}

Future<int> getBlockHead(Node node) async {
  try {
    final client = ElectrumX(server: node.address, port: node.port);
    final tip = await client.getBlockHeadTip();
    return tip["height"];
  } catch (e) {
    Logger.print("Exception rethrown in getBlockHead(): $e");
    throw e;
  }
}
// end of isolates

Future<Decimal> _getFiroPrice({String baseCurrency}) async {
  try {
    String currency =
        baseCurrency ?? await CurrencyUtilities.fetchPreferredCurrency();
    currency = currency.toLowerCase();

    final binanceResponse = await http.get(
      Uri.parse("https://api.binance.com/api/v3/ticker/price?symbol=FIROBTC"),
      headers: {'Content-Type': 'application/json'},
    );

    final coinGeckoResponse = await http.get(
      Uri.parse(
          "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=$currency"),
      headers: {'Content-Type': 'application/json'},
    );

    final binanceData = json.decode(binanceResponse.body);
    final Decimal firoBtcPrice = Decimal.tryParse(binanceData["price"]);

    final coinGeckoData = json.decode(coinGeckoResponse.body);
    final Decimal btcUsdPrice =
        Decimal.tryParse(coinGeckoData["bitcoin"][currency].toString());

    if (btcUsdPrice != null && firoBtcPrice != null) {
      return firoBtcPrice * btcUsdPrice;
    } else {
      Logger.print("Firo price API call(s) failed.");
      return Decimal.fromInt(-1);
    }
  } catch (e) {
    Logger.print("Exception caught in _getFiroPrice(): $e");
    return Decimal.fromInt(-1);
  }
}

/// Handles a single instance of a firo wallet
class Firo extends CoinServiceAPI {
  @override
  String get coinName => "Firo";

  @override
  String get coinTicker => "FIRO";

  @override
  Future<List<String>> get mnemonic => getMnemonicList();

  @override
  Future<String> get fiatCurrency => currency;

  @override
  Future<void> changeFiatCurrency(String currency) async {
    await changeCurrency(currency);
  }

  @override
  Future<Decimal> get fiatPrice => bitcoinPrice;

  // index 0 and 1 for the funds available to spend.
  // index 2 and 3 for all the funds in the wallet (including the undependable ones)
  @override
  Future<Decimal> get balance async {
    final balances = await this.balances;
    return balances[0];
  }

  // index 0 and 1 for the funds available to spend.
  // index 2 and 3 for all the funds in the wallet (including the undependable ones)
  @override
  Future<Decimal> get pendingBalance async {
    final balances = await this.balances;
    return balances[2] - balances[0];
  }

  // index 0 and 1 for the funds available to spend.
  // index 2 and 3 for all the funds in the wallet (including the undependable ones)
  @override
  Future<Decimal> get totalBalance async {
    final balances = await this.balances;
    return balances[2];
  }

  /// return spendable balance minus the maximum tx fee
  @override
  Future<Decimal> get balanceMinusMaxFee async {
    final balances = await this.balances;
    final maxFee = await this.maxFee;
    return balances[0] - Utilities.satoshisToAmount(maxFee.fee);
  }

  @override
  Future<TransactionData> get transactionData => lelantusTransactionData;

  @override
  bool validateAddress(String address) {
    return Address.validateAddress(address, firoNetwork);
  }

  /// Holds final balances, all utxos under control
  Future<UtxoData> _utxoData;
  Future<UtxoData> get utxoData => _utxoData;

  /// Holds wallet transaction data
  Future<TransactionData> _transactionData;
  Future<TransactionData> get _txnData =>
      _transactionData ??= _fetchTransactionData();

  /// Holds wallet lelantus transaction data
  Future<TransactionData> _lelantusTransactionData;
  Future<TransactionData> get lelantusTransactionData =>
      _lelantusTransactionData;

  /// Holds the max fee that can be sent
  Future<LelantusFeeData> _maxFee;
  @override
  Future<LelantusFeeData> get maxFee => _maxFee ??= _fetchMaxFee();

  /// Holds the current balance data
  Future<List<Decimal>> _balances;
  Future<List<Decimal>> get balances => _balances ??= _getFullBalance();

  /// Holds all outputs for wallet, used for displaying utxos in app security view
  List<UtxoObject> _outputsList = [];

  // Hold the current price of Bitcoin in the currency specified in parameter below
  Future<Decimal> _bitcoinPrice;
  Future<Decimal> get bitcoinPrice => _bitcoinPrice ??= _getFiroPrice();

  // currently isn't used but required due to abstract parent class
  Future<FeeObject> _feeObject;
  @override
  Future<FeeObject> get fees => _feeObject;

  /// Holds preferred fiat currency
  Future<String> _currency;
  Future<String> get currency =>
      _currency ??= CurrencyUtilities.fetchPreferredCurrency();

  /// Holds updated receiving address
  Future<String> _currentReceivingAddress;
  @override
  Future<String> get currentReceivingAddress => _currentReceivingAddress;

  Future<bool> _useBiometrics;
  @override
  Future<bool> get useBiometrics => _useBiometrics ??= _fetchUseBiometrics();

  String _walletName;
  @override
  String get walletName => _walletName;

  // setter for updating on rename
  set walletName(String newName) => walletName = newName;

  /// unique wallet id
  String _walletId;
  @override
  String get walletId => _walletId;

  Future<Node> _currentNode;
  Future<Node> get currentNode => _currentNode ?? _getCurrentNode();

  Future<List<String>> _allOwnAddresses;
  @override
  Future<List<String>> get allOwnAddresses =>
      _allOwnAddresses ??= _fetchAllOwnAddresses();

  @override
  Future<bool> testNetworkConnection(String address, int port) async {
    try {
      final client = ElectrumX(server: address, port: port);
      final response =
          await client.request(command: 'blockchain.headers.subscribe');

      return response != null;
    } catch (e) {
      Logger.print("Exception caught in getBlockHead(): $e");
      return false;
    }
  }

  /// returns txid on successful send
  ///
  /// can throw
  @override
  Future<String> send(
      {String toAddress, int amount, Map<String, String> args}) async {
    try {
      dynamic txHexOrError =
          await _createJoinSplitTransaction(amount, toAddress, false);
      Logger.print("txHexOrError $txHexOrError");
      if (txHexOrError is int) {
        // Here, we assume that transaction crafting returned an error
        switch (txHexOrError) {
          case 1:
            throw Exception("Insufficient balance!");
          case 2:
            throw Exception("Insufficient funds to pay for tx fee");
          default:
            throw Exception("Error Creating Transaction!");
        }
      } else {
        if (await _submitLelantusToNetwork(txHexOrError)) {
          final txid = (txHexOrError as Map<String, dynamic>)["txid"] as String;
          return txid;
        } else {
          //TODO provide more info
          throw Exception("Transaction failed.");
        }
      }
    } catch (e) {
      Logger.print("Exception rethrown in firo send(): $e");
      throw e;
    }
  }

  Future<List<String>> getMnemonicList() async {
    final secureStore = new FlutterSecureStorage();
    final mnemonicString =
        await secureStore.read(key: '${this._walletId}_mnemonic');
    final List<String> data = mnemonicString.split(' ');
    return data;
  }

  // Constructor
  Firo({@required String walletId, @required String walletName}) {
    this._walletId = walletId;
    this._walletName = walletName;

    // add listener for nodes changed
    GlobalEventBus.instance.on<NodesChangedEvent>().listen((event) async {
      final newNode = await _getCurrentNode();
      this._currentNode = Future(() => newNode);
      refresh();
    });

    _initializeWallet().whenComplete(() {
      this._utxoData = _fetchUtxoData();
      this._transactionData = _fetchTransactionData();
    }).whenComplete(() => _checkReceivingAddressForTransactions());
  }

  /// Initializes the user's wallet and sets class getters. Will create a wallet if one does not
  /// already exist.
  Future<void> _initializeWallet() async {
    final wallet = await Hive.openBox(this._walletId);

    if (wallet.isEmpty) {
      // Triggers for new users automatically. Generates new wallet
      await _generateNewWallet(wallet);
      wallet.put("id", this._walletId);
      final newNode = await _getCurrentNode();
      this._currentNode = Future(() => newNode);
      this._lelantusTransactionData = _getLelantusTransactionData();
    } else {
      // Wallet already exists, triggers for a returning user
      final newNode = await _getCurrentNode();
      this._currentNode = Future(() => newNode);
      this._lelantusTransactionData = _getLelantusTransactionData();
      this._currentReceivingAddress = _getCurrentAddressForChain(0);
      this._useBiometrics = _fetchUseBiometrics();
    }
  }

  /// Generates initial wallet values such as mnemonic, chain (receive/change) arrays and indexes.
  Future<void> _generateNewWallet(Box<dynamic> wallet) async {
    final secureStore = new FlutterSecureStorage();
    await secureStore.write(
        key: '${this._walletId}_mnemonic',
        value: bip39.generateMnemonic(strength: 256));
    // Set relevant indexes
    await wallet.put('receivingIndex', 0);
    await wallet.put('use_biometrics', false);
    await wallet.put('changeIndex', 0);
    await wallet.put('mintIndex', 0);
    await wallet.put('blocked_tx_hashes', [
      "0xdefault"
    ]); // A list of transaction hashes to represent frozen utxos in wallet
    // initialize address book entries
    await wallet.put('addressBookEntries', <String, String>{});

    // initialize default node
    final nodes = <String, dynamic>{};
    nodes.addAll({
      CampfireConstants.defaultNodeName: {
        "id": Uuid().v1(),
        "ipAddress": CampfireConstants.defaultIpAddress,
        "port": CampfireConstants.defaultPort.toString(),
      }
    });
    await wallet.put('nodes', nodes);
    await wallet.put('jindex', []);
    await wallet.put('activeNodeName', CampfireConstants.defaultNodeName);
    // Generate and add addresses to relevant arrays
    final initialReceivingAddress = await _generateAddressForChain(0, 0);
    final initialChangeAddress = await _generateAddressForChain(1, 0);
    await _addToAddressesArrayForChain(initialReceivingAddress, 0);
    await _addToAddressesArrayForChain(initialChangeAddress, 1);
    this._currentReceivingAddress = Future(() => initialReceivingAddress);
    this._useBiometrics = _fetchUseBiometrics();
  }

  /// Refreshes display data for the wallet
  @override
  Future<void> refresh() async {
    try {
      GlobalEventBus.instance
          .fire(NodeConnectionStatusChangedEvent(NodeConnectionStatus.loading));

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.0));

      final UtxoData newUtxoData = await _fetchUtxoData();
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.1));

      final TransactionData newTxData = await _fetchTransactionData();
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.2));

      final dynamic newBtcPrice = await _getFiroPrice();
      Logger.print("Refreshed price: $newBtcPrice");
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.25));

      final FeeObject feeObj = await _getFees();
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.35));

      await _checkReceivingAddressForTransactions();
      final useBiometrics = await _fetchUseBiometrics();
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.50));

      this._utxoData = Future(() => newUtxoData);
      this._transactionData = Future(() => newTxData);
      this._bitcoinPrice = Future(() => newBtcPrice);
      this._feeObject = Future(() => feeObj);
      this._useBiometrics = Future(() => useBiometrics);
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.60));

      final wallet = await Hive.openBox(this._walletId);
      final Map _lelantus_coins = await wallet.get('_lelantus_coins');
      Logger.print("_lelantus_coins at refresh: $_lelantus_coins");
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.70));

      await _refreshLelantusData();
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.80));

      await _autoMint();
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.90));

      var balance = await _getFullBalance();
      if (balance == null) {
        throw Exception("getFullBalance() in refreshWalletData() failed");
      }
      this._balances = Future(() => balance);

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.95));

      final maxFee = await _fetchMaxFee();
      this._maxFee = Future(() => maxFee);

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(1.0));

      GlobalEventBus.instance
          .fire(NodeConnectionStatusChangedEvent(NodeConnectionStatus.synced));
    } catch (error) {
      GlobalEventBus.instance.fire(
          NodeConnectionStatusChangedEvent(NodeConnectionStatus.disconnected));
      Logger.print("Caught exception in refreshWalletData(): $error");
    }
  }

  Future<LelantusFeeData> _fetchMaxFee() async {
    var lelantusEntry = await _getLelantusEntry();
    final balance = await this.balance;
    final node = await currentNode;
    ReceivePort receivePort = await getIsolate({
      "function": "estimateJoinSplit",
      "spendAmount": (balance * Decimal.fromInt(CampfireConstants.satsPerCoin))
          .toBigInt()
          .toInt(),
      "subtractFeeFromAmount": true,
      "lelantusEntries": lelantusEntry,
      "node": node,
    });

    var message = await receivePort.first;
    if (message is String) {
      Logger.print("this is a string");
      stop();
      throw Exception("_fetchMaxFee isolate failed");
    }
    stop();
    Logger.print('Closing estimateJoinSplit!');
    return message;
  }

  Future<List<DartLelantusEntry>> _getLelantusEntry() async {
    final secureStore = new FlutterSecureStorage();
    final mnemonic = await secureStore.read(key: '${this._walletId}_mnemonic');
    final List<LelantusCoin> lelantusCoins = await _getUnspentCoins();
    final waitLelantusEntries = lelantusCoins.map((coin) async {
      final keyPair = await _getNode(MINT_INDEX, coin.index, mnemonic);
      final String privateKey = uint8listToString(keyPair.privateKey);
      if (privateKey == null) {
        Logger.print("error bad key");
        return DartLelantusEntry(1, 0, 0, 0, 0, '');
      }
      return DartLelantusEntry(coin.isUsed ? 1 : 0, 0, coin.anonymitySetId,
          coin.value, coin.index, privateKey);
    }).toList();

    final lelantusEntries = await Future.wait(waitLelantusEntries);

    return lelantusEntries;
  }

  _getUnspentCoins() async {
    final wallet = await Hive.openBox(this._walletId);
    final Map _lelantus_coins = await wallet.get('_lelantus_coins');
    List jindexes = await wallet.get('jindex');
    final data = await _txnData;
    List<LelantusCoin> coins = [];
    if (_lelantus_coins == null) {
      return coins;
    }

    final node = await currentNode;
    final cachedClient = CachedElectrumX(server: node.address, port: node.port);
    final lelantusCoinsList = _lelantus_coins.values.toList(growable: false);
    for (int i = 0; i < lelantusCoinsList.length; i++) {
      final txn = await cachedClient.getTransaction(
        tx_hash: lelantusCoinsList[i].txId,
        verbose: true,
        coinName: this.coinName,
      );
      final confirmations = txn["confirmations"];
      bool isUnconfirmed = confirmations is int && confirmations < 1;
      if (!jindexes.contains(lelantusCoinsList[i].index) &&
          data.findTransaction(lelantusCoinsList[i].txId) == null) {
        isUnconfirmed = true;
      }
      if (!lelantusCoinsList[i].isUsed &&
          lelantusCoinsList[i].anonymitySetId != ANONYMITY_SET_EMPTY_ID &&
          !isUnconfirmed) {
        coins.add(lelantusCoinsList[i]);
      }
    }

    // _lelantus_coins.forEach((key, value) async {
    //   final tx = data.findTransaction(value.txId);
    //   bool isUnconfirmed = tx == null ? false : !tx.confirmedStatus;
    //   if (!jindexes.contains(value.index) && tx == null) {
    //     isUnconfirmed = true;
    //   }
    //   if (!value.isUsed &&
    //       value.anonymitySetId != ANONYMITY_SET_EMPTY_ID &&
    //       !isUnconfirmed) {
    //     coins.add(value);
    //   }
    // });
    return coins;
  }

  // index 0 and 1 for the funds available to spend.
  // index 2 and 3 for all the funds in the wallet (including the undependable ones)
  Future<List<Decimal>> _getFullBalance() async {
    try {
      final wallet = await Hive.openBox(this._walletId);
      final Map _lelantus_coins = await wallet.get('_lelantus_coins');
      final utxos = await utxoData;
      final Decimal price = await bitcoinPrice;
      final data = await _txnData;
      List jindexes = await wallet.get('jindex');
      int intLelantusBalance = 0;
      Decimal unconfirmedLelantusBalance = Decimal.zero;
      if (_lelantus_coins != null && data != null) {
        _lelantus_coins.forEach((key, value) {
          final tx = data.findTransaction(value.txId);
          if (!jindexes.contains(value.index) && tx == null) {
            // This coin is not confirmed and may be replaced
          } else if (!value.isUsed &&
              (tx == null ? true : tx.confirmedStatus != false)) {
            intLelantusBalance += value.value;
          }
          // else if (tx != null && tx.confirmedStatus == false) {
          //   unconfirmedLelantusBalance += value.value / 100000000;
          // }
        });
      }
      final int utxosIntValue = utxos == null ? 0 : utxos.satoshiBalance;
      final Decimal utxosValue = Utilities.satoshisToAmount(utxosIntValue);

      List<Decimal> balances = List.empty(growable: true);

      Decimal lelantusBalance = Utilities.satoshisToAmount(intLelantusBalance);

      balances.add(lelantusBalance);

      if (price == null) {
        balances.add(Decimal.fromInt(-1));
      } else {
        balances.add(lelantusBalance * price);
      }

      balances.add(lelantusBalance + utxosValue + unconfirmedLelantusBalance);

      if (price == null) {
        balances.add(Decimal.fromInt(-1));
      } else {
        balances.add(
            (lelantusBalance + utxosValue + unconfirmedLelantusBalance) *
                price);
      }
      return balances;
    } catch (e) {
      Logger.print("Exception rethrown in getFullBalance(): $e");
      throw e;
    }
  }

  dynamic _autoMint() async {
    try {
      var mintResult = await _mintSelection();
      if (mintResult == null || mintResult is String) {
        print("nothing to mint");
        return;
      }
      await _submitLelantusToNetwork(mintResult);
    } catch (e) {
      Logger.print("Exception caught in _autoMint(): $e");
    }
  }

  /// Returns the mint transaction hex to mint all of the available funds.
  dynamic _mintSelection() async {
    final List<UtxoObject> availableOutputs = this._outputsList;
    final List<UtxoObject> spendableOutputs = [];

    // Build list of spendable outputs and totaling their satoshi amount
    for (var i = 0; i < availableOutputs.length; i++) {
      if (availableOutputs[i].blocked == false &&
          availableOutputs[i].status.confirmed == true) {
        spendableOutputs.add(availableOutputs[i]);
      }
    }

    final wallet = await Hive.openBox(this._walletId);
    final Map _lelantus_coins = await wallet.get('_lelantus_coins');
    final data = await _txnData;
    if (data != null && _lelantus_coins != null) {
      final dataMap = data.getAllTransactions();
      dataMap.forEach((key, value) {
        if (value.inputs != null && value.inputs.length > 0) {
          value.inputs.forEach((element) {
            if (_lelantus_coins.keys.contains(value.txid) &&
                spendableOutputs.firstWhere(
                        (output) => output.txid == element.txid,
                        orElse: () => null) !=
                    null) {
              spendableOutputs
                  .removeWhere((output) => output.txid == element.txid);
            }
          });
        }
      });
    }

    // If there is no Utxos to mint then stop the function.
    if (spendableOutputs.length == 0) {
      return "Error None To Mint";
    }

    int satoshisBeingUsed = 0;
    List<UtxoObject> utxoObjectsToUse = [];

    for (var i = 0; i < spendableOutputs.length; i++) {
      utxoObjectsToUse.add(spendableOutputs[i]);
      satoshisBeingUsed += spendableOutputs[i].value;
    }

    var tmpTx = await buildMintTransaction(utxoObjectsToUse, satoshisBeingUsed);
    final feesObject = await fees;

    int vsize = tmpTx['transaction'].virtualSize();
    final Decimal dvsize = Decimal.fromInt(vsize);
    final Decimal fastFee = Decimal.parse(feesObject.fast);
    int firoFee =
        (dvsize * fastFee * Decimal.fromInt(100000)).toDouble().ceil();
    // int firoFee = (vsize * feesObject.fast * (1 / 1000.0) * 100000000).ceil();

    if (firoFee < vsize) {
      firoFee = vsize + 1;
    }
    firoFee = firoFee + 10;
    int satoshiAmountToSend = satoshisBeingUsed - firoFee;

    dynamic transaction =
        await buildMintTransaction(utxoObjectsToUse, satoshiAmountToSend);
    transaction['transaction'] = "";
    Logger.print(transaction.toString());
    Logger.print(transaction['txHex']);
    return transaction;
  }

  /// returns a valid txid if successful
  Future<String> submitHexToNetwork(String hex) async {
    try {
      final node = await currentNode;
      final client = ElectrumX(server: node.address, port: node.port);
      final txid = await client.broadcastTransaction(rawTx: hex);
      return txid;
    } catch (e) {
      Logger.print("Caught exception in submitHexToNetwork(\"$hex\"): $e");
      // return an invalid tx
      return "transaction submission failed";
    }
  }

  /// Builds and signs a transaction
  ///
  /// Throws an exception if the http response status code is not 200 or 201
  /// OR if json encoding/decoding fails
  /// OR rethrows earlier exception
  Future<dynamic> buildMintTransaction(
      List<UtxoObject> utxosToUse, int satoshisPerRecipient) async {
    List<String> addressesToDerive = [];

    final node = await currentNode;
    final cachedClient = CachedElectrumX(server: node.address, port: node.port);

    // Populating the addresses to derive
    for (var i = 0; i < utxosToUse.length; i++) {
      final txid = utxosToUse[i].txid;
      final outputIndex = utxosToUse[i].vout;

      // txid may not work for this as txid may not always be the same as tx_hash?
      final tx = await cachedClient.getTransaction(
        tx_hash: txid,
        verbose: true,
        coinName: this.coinName,
      );

      final vouts = tx["vout"];
      if (vouts != null && vouts.length <= outputIndex + 1) {
        final address = vouts[outputIndex]["scriptPubKey"]["addresses"][0];
        if (address != null) {
          addressesToDerive.add(address);
        }
      }
    }

    final secureStore = new FlutterSecureStorage();
    final seed = bip39.mnemonicToSeed(
        await secureStore.read(key: '${this._walletId}_mnemonic'));

    final root = bip32.BIP32.fromSeed(seed, firoNetworkType);

    List<ECPair> elipticCurvePairArray = [];
    List<Uint8List> outputDataArray = [];

    for (var i = 0; i < addressesToDerive.length; i++) {
      final addressToCheckFor = addressesToDerive[i];

      for (var i = 0; i < 2000; i++) {
        final nodeReceiving = root.derivePath("m/44'/136'/0'/0/$i");
        final nodeChange = root.derivePath("m/44'/136'/0'/1/$i");

        if (P2PKH(
                    network: firoNetwork,
                    data: new PaymentData(pubkey: nodeReceiving.publicKey))
                .data
                .address ==
            addressToCheckFor) {
          Logger.print('Receiving found on loop $i');
          elipticCurvePairArray
              .add(ECPair.fromWIF(nodeReceiving.toWIF(), network: firoNetwork));
          outputDataArray.add(P2PKH(
                  network: firoNetwork,
                  data: new PaymentData(pubkey: nodeReceiving.publicKey))
              .data
              .output);
          break;
        }
        if (P2PKH(
                    network: firoNetwork,
                    data: new PaymentData(pubkey: nodeChange.publicKey))
                .data
                .address ==
            addressToCheckFor) {
          Logger.print('Change found on loop $i');
          elipticCurvePairArray
              .add(ECPair.fromWIF(nodeChange.toWIF(), network: firoNetwork));

          outputDataArray.add(P2PKH(
                  network: firoNetwork,
                  data: new PaymentData(pubkey: nodeChange.publicKey))
              .data
              .output);
          break;
        }
      }
    }

    final txb = new TransactionBuilder(network: firoNetwork);
    txb.setVersion(2);
    int height = await getBlockHead(node);
    txb.setLockTime(height);
    int amount = 0;
    // Add transaction inputs
    for (var i = 0; i < utxosToUse.length; i++) {
      txb.addInput(
          utxosToUse[i].txid, utxosToUse[i].vout, null, outputDataArray[i]);
      amount += utxosToUse[i].value;
    }

    final wallet = await Hive.openBox(this._walletId);
    final index = await wallet.get('mintIndex');
    Logger.print("index of mint $index");

    Uint8List mintu8 =
        stringToUint8List(await _getMintHex(satoshisPerRecipient, index));

    txb.addOutput(mintu8, satoshisPerRecipient);

    for (var i = 0; i < utxosToUse.length; i++) {
      txb.sign(
        vin: i,
        keyPair: elipticCurvePairArray[i],
        witnessValue: utxosToUse[i].value,
      );
    }
    var incomplete = txb.buildIncomplete();
    var txId = incomplete.getId();
    var txHex = incomplete.toHex();
    int fee = amount - incomplete.outs[0].value;

    var price = await bitcoinPrice;
    price = price ?? 1;
    var builtHex = txb.build();
    // return builtHex;
    return {
      "transaction": builtHex,
      "txid": txId,
      "txHex": txHex,
      "value": amount - fee,
      "fees": Utilities.satoshisToAmount(fee).toDouble(),
      "publicCoin": "",
      "height": height,
      "txType": "Sent",
      "confirmed_status": false,
      "amount": Utilities.satoshisToAmount(amount).toDouble(),
      "worthNow": ((Decimal.fromInt(amount) * price) /
              Decimal.fromInt(CampfireConstants.satsPerCoin))
          .toDecimal(scaleOnInfinitePrecision: 2)
          .toStringAsFixed(2),
      "timestamp": DateTime.now().millisecondsSinceEpoch ~/ 1000,
      "subType": "mint",
    };
  }

  Future<TransactionData> _refreshLelantusData() async {
    final wallet = await Hive.openBox(this._walletId);
    final Map _lelantus_coins = await wallet.get('_lelantus_coins');
    List jindexes = await wallet.get('jindex');

    // Get all joinsplit transaction ids
    final lelantusTxData = await lelantusTransactionData;
    if (lelantusTxData == null) {
      return null;
    }
    final listLelantusTxData = lelantusTxData.getAllTransactions();
    List<String> joinsplits = [];
    for (final tx in listLelantusTxData.values) {
      if (tx.subType == "join") {
        joinsplits.add(tx.txid);
      }
    }
    if (_lelantus_coins != null) {
      for (final coin in _lelantus_coins.values) {
        if (jindexes != null) {
          if (jindexes.contains(coin.index) &&
              !joinsplits.contains(coin.txId)) {
            joinsplits.add(coin.txId);
          }
        }
      }
    }

    final String currency = await CurrencyUtilities.fetchPreferredCurrency();
    // Grab the most recent information on all the joinsplits
    final updatedJSplit = await getJMintTransactions(
        await currentNode, joinsplits, currency, this.coinName);

    // update all of joinsplits that are now confirmed.
    for (final tx in updatedJSplit) {
      final currenttx = listLelantusTxData[tx.txid];
      if (currenttx == null) {
        // this send was accidentally not included in the list
        listLelantusTxData[tx.txid] = tx;
        continue;
      }
      if (currenttx.confirmedStatus != tx.confirmedStatus) {
        listLelantusTxData[tx.txid] = tx;
      }
    }

    final txData = await _txnData;
    if (txData == null) {
      return null;
    }
    final listTxData = txData.getAllTransactions();
    listTxData.forEach((key, value) {
      // ignore change addresses
      bool hasAtLeastOneRecieve = false;
      int howManyRecieveInputs = 0;
      if (value.inputs != null) {
        value.inputs.forEach((element) {
          if (listLelantusTxData.containsKey(element.txid) &&
                  listLelantusTxData[element.txid].txType == "Received"
              // &&
              // listLelantusTxData[element.txid].subType != "mint"
              ) {
            hasAtLeastOneRecieve = true;
            howManyRecieveInputs++;
          }
        });
      }

      if (value.txType == "Received" &&
          !listLelantusTxData.containsKey(value.txid)) {
        // Every receive should be listed whether minted or not.
        listLelantusTxData[value.txid] = value;
      } else if (value.txType == "Sent" &&
          hasAtLeastOneRecieve &&
          value.subType == "mint") {
        // use mint sends to update receives with user readable values.

        int sharedFee = value.fees ~/ howManyRecieveInputs;

        value.inputs.forEach((element) {
          if (listLelantusTxData.containsKey(element.txid) &&
              listLelantusTxData[element.txid].txType == "Received") {
            listLelantusTxData[element.txid] = listLelantusTxData[element.txid]
                .copyWith(
                    fees: sharedFee,
                    subType: "mint",
                    height: value.height,
                    confirmedStatus: value.confirmedStatus);
          }
        });
      }
    });

    // update the _lelantusTransactionData
    final TransactionData newTxData =
        TransactionData.fromMap(listLelantusTxData);
    Logger.print(newTxData.txChunks);
    this._lelantusTransactionData = Future(() => newTxData);
    await wallet.put('latest_lelantus_tx_model', newTxData);
  }

  _getMintHex(int amount, int index) async {
    final secureStore = new FlutterSecureStorage();
    final mnemonic = await secureStore.read(key: '${this._walletId}_mnemonic');
    final mintKeyPair = await _getNode(MINT_INDEX, index, mnemonic);
    String keydata = uint8listToString(mintKeyPair.privateKey);
    String seedID = uint8listToString(mintKeyPair.identifier);
    String mintHex = getMintScript(amount, keydata, index, seedID);
    return mintHex;
  }

  Future<bool> _submitLelantusToNetwork(dynamic transactionInfo) async {
    final txid = await submitHexToNetwork(transactionInfo['txHex']);
    // success if txid matches the generated txid
    print(transactionInfo['txid']);
    if (txid == transactionInfo['txid']) {
      final wallet = await Hive.openBox(this._walletId);
      int index = await wallet.get('mintIndex');
      final Map _lelantus_coins = await wallet.get('_lelantus_coins');
      Map coins;
      if (_lelantus_coins == null || _lelantus_coins.isEmpty) {
        coins = Map();
      } else {
        coins = {..._lelantus_coins};
      }

      if (transactionInfo['spendCoinIndexes'] != null) {
        // This is a joinsplit

        // Update all of the coins that have been spent.
        for (final key in coins.keys) {
          if ((transactionInfo['spendCoinIndexes'] as List<int>)
              .contains(coins[key].index)) {
            coins[key] = LelantusCoin(
                coins[key].index,
                coins[key].value,
                coins[key].publicCoin,
                coins[key].txId,
                coins[key].anonymitySetId,
                true);
          }
        }

        // if a jmint was made add it to the unspent coin index
        LelantusCoin jmint = LelantusCoin(
            index,
            transactionInfo['jmintValue'] ?? 0,
            transactionInfo['publicCoin'],
            transactionInfo['txid'],
            1,
            false);
        if (jmint.value > 0) {
          coins[jmint.txId] = jmint;
          //TODO uncomment this
          List jindexes = await wallet.get('jindex');
          jindexes.add(index);
          await wallet.put('jindex', jindexes);
          await wallet.put('mintIndex', index + 1);
        }
        // TODO uncomment this
        await wallet.put('_lelantus_coins', coins);

        // add the send transaction
        TransactionData data = await _lelantusTransactionData;
        Map transactions = data.getAllTransactions();
        transactions[transactionInfo['txid']] =
            models.Transaction.fromLelantusJson(transactionInfo);
        final TransactionData newTxData = TransactionData.fromMap(transactions);
        await wallet.put('latest_lelantus_tx_model', newTxData);
        var ldata = await wallet.get('latest_lelantus_tx_model');
        _lelantusTransactionData = Future(() => ldata);
      } else {
        // This is a mint
        Logger.print("this is a mint");

        LelantusCoin mint = LelantusCoin(index, transactionInfo['value'],
            transactionInfo['publicCoin'], transactionInfo['txid'], 1, false);
        if (mint.value > 0) {
          coins[mint.txId] = mint;
          await wallet.put('mintIndex', index + 1);
        }
        Logger.print(coins);
        await wallet.put('_lelantus_coins', coins);
      }
      return true;
    } else {
      // Failed to send to network
      return false;
    }
  }

  Future<bool> _fetchUseBiometrics() async {
    final wallet = await Hive.openBox(this._walletId);
    final useBiometrics = await wallet.get('use_biometrics');
    return useBiometrics == null ? false : useBiometrics;
  }

  Future<FeeObject> _getFees() async {
    try {
      final node = await currentNode;
      final client = ElectrumX(server: node.address, port: node.port);
      final result = await client.getFeeRate();

      final String fee = Utilities.satoshiAmountToPrettyString(result["rate"]);

      final fees = {
        "fast": fee,
        "average": fee,
        "slow": fee,
      };
      final FeeObject feeObject = FeeObject.fromJson(fees);
      return feeObject;
    } catch (e) {
      Logger.print("Exception rethrown from _getFees(): $e");
      throw e;
    }
  }

  Future<Node> _getCurrentNode() async {
    final wallet = await Hive.openBox(this._walletId);
    final nodes = wallet.get('nodes');
    final name = wallet.get('activeNodeName');
    try {
      final String address = nodes[name]["ipAddress"];
      final int port = int.parse(nodes[name]["port"]);
      return Node(
        address: address,
        port: port,
        name: name,
      );
    } catch (e) {
      Logger.print("Exception rethrown from _getCurrentNode(): $e");
      throw e;
    }
  }

  //TODO call get transaction and check each tx to see if it is a "received" tx?
  Future<int> _getReceivedTxCount({String address}) async {
    try {
      final node = await currentNode;
      final client = ElectrumX(server: node.address, port: node.port);
      final transactions = await client.getHistory(address: address);
      return transactions.length;
    } catch (e) {
      Logger.print(
          "Exception rethrown in _getReceivedTxCount(address: $address): $e");
      throw e;
    }
  }

  Future<void> _checkReceivingAddressForTransactions() async {
    try {
      final String currentExternalAddr =
          await this._getCurrentAddressForChain(0);
      final int numtxs =
          await _getReceivedTxCount(address: currentExternalAddr);
      Logger.print(
          'Number of txs for current receiving addr: ' + numtxs.toString());

      if (numtxs >= 1) {
        final wallet = await Hive.openBox(this._walletId);

        await _incrementAddressIndexForChain(
            0); // First increment the receiving index
        final newReceivingIndex =
            await wallet.get('receivingIndex'); // Check the new receiving index
        final newReceivingAddress = await _generateAddressForChain(0,
            newReceivingIndex); // Use new index to derive a new receiving address
        await _addToAddressesArrayForChain(newReceivingAddress,
            0); // Add that new receiving address to the array of receiving addresses
        this._currentReceivingAddress = Future(() =>
            newReceivingAddress); // Set the new receiving address that the service
      }
    } catch (e) {
      Logger.print(
          "Exception rethrown from _checkReceivingAddressForTransactions(): $e");
      throw e;
    }
  }

  Future<List<String>> _fetchAllOwnAddresses() async {
    final List<String> allAddresses = [];
    final wallet = await Hive.openBox(this._walletId);
    final List receivingAddresses = await wallet.get('receivingAddresses');
    final List changeAddresses = await wallet.get('changeAddresses');

    for (var i = 0; i < receivingAddresses.length; i++) {
      allAddresses.add(receivingAddresses[i]);
    }
    for (var i = 0; i < changeAddresses.length; i++) {
      allAddresses.add(changeAddresses[i]);
    }
    return allAddresses;
  }

  Future<TransactionData> _fetchTransactionData() async {
    final wallet = await Hive.openBox(this._walletId);
    final List<String> allAddresses = [];
    final String currency = await CurrencyUtilities.fetchPreferredCurrency();
    final List receivingAddresses = await wallet.get('receivingAddresses');
    final List changeAddresses = await wallet.get('changeAddresses');

    for (var i = 0; i < receivingAddresses.length; i++) {
      allAddresses.add(receivingAddresses[i]);
    }
    for (var i = 0; i < changeAddresses.length; i++) {
      allAddresses.add(changeAddresses[i]);
    }

    print("receiving addresses: $receivingAddresses");
    print("change addresses: $changeAddresses");

    List<Map<String, dynamic>> allTxHashes = [];
    int latestTxnBlockHeight = 0;

    final node = await currentNode;
    final client = ElectrumX(server: node.address, port: node.port);

    for (final address in allAddresses) {
      final txs = await client.getHistory(address: address);
      for (final map in txs) {
        // check to get latest Txn Height
        if (map["height"] > latestTxnBlockHeight) {
          latestTxnBlockHeight = map["height"];
        }
        // ignore duplicates
        if (!allTxHashes.contains(map)) {
          allTxHashes.add(map);
        }
      }
    }

    log("allTxHashes: $allTxHashes");

    final TransactionData storedTxnData = await wallet.get('latest_tx_model');
    final int storedTxnDataHeight =
        (await wallet.get('storedTxnDataHeight')) ?? 0;

    final Map<String, models.Transaction> transactionsMap = {};

    if (storedTxnData == null) {
    } else {
      final int currentHeight = (await client.getBlockHeadTip())['height'];
      log("current chain height: $currentHeight");

      // return stored txnData if no new blocks have been found since last fetch
      // OR if no new transactions exist since last fetch
      if (storedTxnDataHeight == currentHeight ||
          storedTxnDataHeight == latestTxnBlockHeight) {
        return storedTxnData;
      }

      transactionsMap.addAll(storedTxnData.getAllTransactions());

      final int confirmationBuffer = 10;
      for (int i = 0; i < allTxHashes.length; i++) {
        if (allTxHashes[i]['height'] <=
            (storedTxnDataHeight - confirmationBuffer)) {
          allTxHashes.removeAt(i);
        }
      }
    }

    List<Map<String, dynamic>> allTransactions = [];

    final cachedClient = CachedElectrumX(server: node.address, port: node.port);
    for (final txHash in allTxHashes) {
      final tx = await cachedClient.getTransaction(
          tx_hash: txHash["tx_hash"], verbose: true, coinName: this.coinName);
      // delete unused large parts
      tx.remove("hex");
      tx.remove("lelantusData");

      allTransactions.add(tx);
    }

    log("allTransactions length: ${allTransactions.length}");

    // sort thing stuff
    final currentPrice = await _getFiroPrice(baseCurrency: currency);
    final List<Map<String, dynamic>> midSortedArray = [];

    for (final txObject in allTransactions) {
      List<String> sendersArray = [];
      List<String> recipientsArray = [];

      // Usually only has value when txType = 'Send'
      int inputAmtSentFromWallet = 0;
      // Usually has value regardless of txType due to change addresses
      int outputAmtAddressedToWallet = 0;

      Map<String, dynamic> midSortedTx = {};
      List<dynamic> aliens = [];

      for (final input in txObject["vin"]) {
        final address = input["address"];
        if (address != null) {
          sendersArray.add(address);
        }
      }

      log("sendersArray: $sendersArray");

      for (final output in txObject["vout"]) {
        final addresses = output["scriptPubKey"]["addresses"];
        if (addresses != null) {
          recipientsArray.add(addresses[0]);
        }
      }
      log("recipientsArray: $recipientsArray");

      final foundInSenders =
          allAddresses.every((element) => sendersArray.contains(element));
      log("foundInSenders: $foundInSenders");

      String outAddress = "";

      int fees = 0;

      // If txType = Sent, then calculate inputAmtSentFromWallet, calculate who received how much in aliens array (check outputs)
      if (foundInSenders) {
        int outAmount = 0;
        int inAmount = 0;
        bool nFeesUsed = false;

        for (final input in txObject["vin"]) {
          final nFees = input["nFees"];
          if (nFees != null) {
            nFeesUsed = true;
            fees = (Decimal.parse(nFees.toString()) *
                    Decimal.fromInt(CampfireConstants.satsPerCoin))
                .toBigInt()
                .toInt();
          }
          final address = input["address"];
          final value = input["valueSat"];
          if (address != null && value != null) {
            if (allAddresses.contains(address)) {
              inputAmtSentFromWallet += value;
            }
          }

          if (value != null) {
            inAmount += value;
          }
        }

        for (final output in txObject["vout"]) {
          final addresses = output["scriptPubKey"]["addresses"];
          if (addresses != null) {
            final address = addresses[0];
            final value = output["value"];
            if (address != null && value != null) {
              if (changeAddresses.contains(address)) {
                inputAmtSentFromWallet -= (Decimal.parse(value.toString()) *
                        Decimal.fromInt(CampfireConstants.satsPerCoin))
                    .toBigInt()
                    .toInt();
              } else {
                outAddress = address;
              }
            }
            if (value != null) {
              outAmount += (Decimal.parse(value.toString()) *
                      Decimal.fromInt(CampfireConstants.satsPerCoin))
                  .toBigInt()
                  .toInt();
            }
          }
        }

        fees = nFeesUsed ? fees : inAmount - outAmount;
        inputAmtSentFromWallet -= inAmount - outAmount;
      } else {
        for (final input in txObject["vin"]) {
          final nFees = input["nFees"];
          if (nFees != null) {
            fees += (Decimal.parse(nFees.toString()) *
                    Decimal.fromInt(CampfireConstants.satsPerCoin))
                .toBigInt()
                .toInt();
          }
        }

        for (final output in txObject["vout"]) {
          final addresses = output["scriptPubKey"]["addresses"];
          if (addresses != null) {
            final address = addresses[0];
            final value = output["value"];
            print(address + value.toString());
            if (address != null) {
              if (allAddresses.contains(address)) {
                outputAmtAddressedToWallet += (Decimal.parse(value.toString()) *
                        Decimal.fromInt(CampfireConstants.satsPerCoin))
                    .toBigInt()
                    .toInt();
                outAddress = address;
              }
            }
          }
        }
      }

      // create final tx map
      midSortedTx["txid"] = txObject["txid"];
      midSortedTx["confirmed_status"] = (txObject["confirmations"] != null) &&
          (txObject["confirmations"] > 0);
      midSortedTx["timestamp"] = txObject["blocktime"];
      if (foundInSenders) {
        midSortedTx["txType"] = "Sent";
        midSortedTx["amount"] = inputAmtSentFromWallet;
        final worthNow =
            ((currentPrice * Decimal.fromInt(inputAmtSentFromWallet)) /
                    Decimal.fromInt(CampfireConstants.satsPerCoin))
                .toDecimal(scaleOnInfinitePrecision: 2)
                .toStringAsFixed(2);
        midSortedTx["worthNow"] = worthNow;
        midSortedTx["worthAtBlockTimestamp"] = worthNow;
        if (txObject["vout"][0]["scriptPubKey"]["type"] == "lelantusmint") {
          midSortedTx["subType"] = "mint";
        }
      } else {
        midSortedTx["txType"] = "Received";
        midSortedTx["amount"] = outputAmtAddressedToWallet;
        final worthNow =
            ((currentPrice * Decimal.fromInt(outputAmtAddressedToWallet)) /
                    Decimal.fromInt(CampfireConstants.satsPerCoin))
                .toDecimal(scaleOnInfinitePrecision: 2)
                .toStringAsFixed(2);
        midSortedTx["worthNow"] = worthNow;
      }
      midSortedTx["aliens"] = aliens;
      midSortedTx["fees"] = fees;
      midSortedTx["address"] = outAddress;
      midSortedTx["height"] = txObject["height"];
      midSortedTx["inputSize"] = txObject["vin"].length;
      midSortedTx["outputSize"] = txObject["vout"].length;
      midSortedTx["inputs"] = txObject["vin"];
      midSortedTx["outputs"] = txObject["vout"];

      midSortedArray.add(midSortedTx);
      log("midSortedTx: $midSortedTx");
    }

    // sort by date  ----  //TODO not sure if needed
    // shouldn't be any issues with a null timestamp but I got one at some point?
    midSortedArray.sort((a, b) {
      final aT = a["timestamp"];
      final bT = b["timestamp"];

      if (aT == null && bT == null) {
        return 0;
      } else if (aT == null) {
        return -1;
      } else if (bT == null) {
        return 1;
      } else {
        return bT - aT;
      }
    });

    // buildDateTimeChunks
    final result = {"dateTimeChunks": <dynamic>[]};
    final dateArray = <dynamic>[];

    for (int i = 0; i < midSortedArray.length; i++) {
      final txObject = midSortedArray[i];
      final date = models.extractDateFromTimestamp(txObject["timestamp"]);
      final txTimeArray = [txObject["timestamp"], date];

      if (dateArray.contains(txTimeArray[1])) {
        result["dateTimeChunks"].forEach((chunk) {
          if (models.extractDateFromTimestamp(chunk["timestamp"]) ==
              txTimeArray[1]) {
            if (chunk["transactions"] == null) {
              chunk["transactions"] = <Map<String, dynamic>>[];
            }
            chunk["transactions"].add(txObject);
          }
        });
      } else {
        dateArray.add(txTimeArray[1]);
        final chunk = {
          "timestamp": txTimeArray[0],
          "transactions": [txObject],
        };
        result["dateTimeChunks"].add(chunk);
      }
    }

    final newTxnList = TransactionData.fromJson(result).getAllTransactions();
    transactionsMap.addAll(newTxnList);
    final txModel = TransactionData.fromMap(transactionsMap);
    await wallet.put('storedTxnDataHeight', latestTxnBlockHeight);
    await wallet.put('latest_tx_model', txModel);
    return txModel;
  }

  Future<UtxoData> _fetchUtxoData() async {
    final wallet = await Hive.openBox(this._walletId);
    final List<String> allAddresses = [];
    final String currency = await CurrencyUtilities.fetchPreferredCurrency();
    final List receivingAddresses = await wallet.get('receivingAddresses');
    final List changeAddresses = await wallet.get('changeAddresses');

    for (var i = 0; i < receivingAddresses.length; i++) {
      if (!allAddresses.contains(receivingAddresses[i])) {
        allAddresses.add(receivingAddresses[i]);
      }
    }
    for (var i = 0; i < changeAddresses.length; i++) {
      if (!allAddresses.contains(changeAddresses[i])) {
        allAddresses.add(changeAddresses[i]);
      }
    }

    try {
      final node = await currentNode;
      final client = ElectrumX(server: node.address, port: node.port);

      final utxoData = <List<Map<String, dynamic>>>[];

      for (int i = 0; i < allAddresses.length; i++) {
        final utxos = await client.getUTXOs(address: allAddresses[i]);
        if (utxos.isNotEmpty) {
          utxoData.add(utxos);
        }
      }

      Decimal currentPrice = await _getFiroPrice(baseCurrency: currency);
      final List<Map<String, dynamic>> outputArray = [];
      int satoshiBalance = 0;

      final cachedClient =
          CachedElectrumX(server: node.address, port: node.port);
      for (int i = 0; i < utxoData.length; i++) {
        for (int j = 0; j < utxoData[i].length; j++) {
          int value = utxoData[i][j]["value"];
          satoshiBalance += value;

          final txn = await cachedClient.getTransaction(
            tx_hash: utxoData[i][j]["tx_hash"],
            verbose: true,
            coinName: this.coinName,
          );

          final Map<String, dynamic> tx = {};

          tx["txid"] = txn["txid"];
          tx["vout"] = utxoData[i][j]["tx_pos"];
          tx["value"] = value;

          tx["status"] = <String, dynamic>{};
          tx["status"]["confirmed"] =
              txn["confirmations"] == null ? false : txn["confirmations"] > 0;
          tx["status"]["block_height"] = txn["height"];
          tx["status"]["block_hash"] = txn["blockhash"];
          tx["status"]["block_time"] = txn["blocktime"];

          final fiatValue = ((Decimal.fromInt(value) * currentPrice) /
                  Decimal.fromInt(CampfireConstants.satsPerCoin))
              .toDecimal(scaleOnInfinitePrecision: 2);
          tx["rawWorth"] = fiatValue;
          tx["fiatWorth"] = currencyMap[currency] + fiatValue.toString();
          ;
          outputArray.add(tx);
        }
      }

      Decimal currencyBalanceRaw =
          ((Decimal.fromInt(satoshiBalance) * currentPrice) /
                  Decimal.fromInt(CampfireConstants.satsPerCoin))
              .toDecimal(scaleOnInfinitePrecision: 2);

      final Map<String, dynamic> result = {
        "total_user_currency":
            currencyMap[currency] + currencyBalanceRaw.toString(),
        "total_sats": satoshiBalance,
        "total_btc": (Decimal.fromInt(satoshiBalance) /
                Decimal.fromInt(CampfireConstants.satsPerCoin))
            .toDecimal(
                scaleOnInfinitePrecision: CampfireConstants.decimalPlaces)
            .toString(),
        "outputArray": outputArray,
      };

      final dataModel = UtxoData.fromJson(result);

      final List<UtxoObject> allOutputs = dataModel.unspentOutputArray;
      Logger.print('Outputs fetched: $allOutputs');
      await _sortOutputs(allOutputs);
      await wallet.put('latest_utxo_model', dataModel);
      return dataModel;
    } catch (e) {
      Logger.print("Output fetch unsuccessful: $e");
      final latestTxModel = await wallet.get('latest_utxo_model');
      final currency = await CurrencyUtilities.fetchPreferredCurrency();
      final currencySymbol = currencyMap[currency];

      if (latestTxModel == null) {
        final emptyModel = {
          "total_user_currency": "${currencySymbol}0.00",
          "total_sats": 0,
          "total_btc": "0",
          "outputArray": []
        };
        return UtxoData.fromJson(emptyModel);
      } else {
        Logger.print("Old output model located");
        return latestTxModel;
      }
    }
  }

  Future<TransactionData> _getLelantusTransactionData() async {
    final wallet = await Hive.openBox(this._walletId);

    final latestModel = await wallet.get('latest_lelantus_tx_model');

    if (latestModel == null) {
      final emptyModel = {"dateTimeChunks": []};
      return TransactionData.fromJson(emptyModel);
    } else {
      Logger.print("Old transaction model located");
      return latestModel;
    }
  }

  /// Returns the latest receiving/change (external/internal) address for the wallet depending on [chain]
  /// [chain] - Use 0 for receiving (external), 1 for change (internal). Should not be any other value!
  Future<String> _getCurrentAddressForChain(int chain) async {
    final wallet = await Hive.openBox(this._walletId);
    if (chain == 0) {
      final externalChainArray = await wallet.get('receivingAddresses');
      return externalChainArray.last;
    } else {
      // Here, we assume that chain == 1
      final internalChainArray = await wallet.get('changeAddresses');
      return internalChainArray.last;
    }
  }

  /// Generates a new internal or external chain address for the wallet using a BIP84 derivation path.
  /// [chain] - Use 0 for receiving (external), 1 for change (internal). Should not be any other value!
  /// [index] - This can be any integer >= 0
  Future<String> _generateAddressForChain(int chain, int index) async {
    final secureStore = new FlutterSecureStorage();
    final mnemonic = await secureStore.read(key: '${this._walletId}_mnemonic');
    final seed = bip39.mnemonicToSeed(mnemonic);
    final root = bip32.BIP32.fromSeed(seed);
    final node = root.derivePath("m/44'/136'/0'/$chain/$index");

    return P2PKH(
            network: firoNetwork, data: new PaymentData(pubkey: node.publicKey))
        .data
        .address;
  }

  /// Increases the index for either the internal or external chain, depending on [chain].
  /// [chain] - Use 0 for receiving (external), 1 for change (internal). Should not be any other value!
  Future<void> _incrementAddressIndexForChain(int chain) async {
    final wallet = await Hive.openBox(this._walletId);
    if (chain == 0) {
      final newIndex = wallet.get('receivingIndex') + 1;
      await wallet.put('receivingIndex', newIndex);
    } else {
      // Here we assume chain == 1 since it can only be either 0 or 1
      final newIndex = wallet.get('changeIndex') + 1;
      await wallet.put('changeIndex', newIndex);
    }
  }

  /// Adds [address] to the relevant chain's address array, which is determined by [chain].
  /// [address] - Expects a standard native segwit address
  /// [chain] - Use 0 for receiving (external), 1 for change (internal). Should not be any other value!
  Future<void> _addToAddressesArrayForChain(String address, int chain) async {
    final wallet = await Hive.openBox(this._walletId);
    String chainArray = '';
    if (chain == 0) {
      chainArray = 'receivingAddresses';
    } else {
      chainArray = 'changeAddresses';
    }

    final addressArray = wallet.get(chainArray);
    if (addressArray == null) {
      Logger.print(
          'Attempting to add the following to array for chain $chain:' +
              [address].toString());
      await wallet.put(chainArray, [address]);
    } else {
      // Make a deep copy of the existing list
      final newArray = [];
      addressArray.forEach((_address) => newArray.add(_address));
      newArray.add(address); // Add the address passed into the method
      await wallet.put(chainArray, newArray);
    }
  }

  /// Takes in a list of UtxoObjects and adds a name (dependent on object index within list)
  /// and checks for the txid associated with the utxo being blocked and marks it accordingly.
  /// Now also checks for output labeling.
  _sortOutputs(List<UtxoObject> utxos) async {
    final wallet = await Hive.openBox(this._walletId);
    final blockedHashArray = wallet.get('blocked_tx_hashes');
    final lst = [];
    if (blockedHashArray != null)
      blockedHashArray.forEach((hash) => lst.add(hash));
    final labels = await Hive.openBox('labels');

    this._outputsList = [];

    for (var i = 0; i < utxos.length; i++) {
      if (labels.get(utxos[i].txid) != null) {
        utxos[i].txName = labels.get(utxos[i].txid);
      } else {
        utxos[i].txName = 'Output #$i';
      }

      if (utxos[i].status.confirmed == false) {
        this._outputsList.add(utxos[i]);
      } else {
        if (lst.contains(utxos[i].txid)) {
          utxos[i].blocked = true;
          this._outputsList.add(utxos[i]);
        } else if (!lst.contains(utxos[i].txid)) {
          this._outputsList.add(utxos[i]);
        }
      }
    }
  }

  /// wrapper for recoverWalletFromBIP32SeedPhrase()
  @override
  dynamic recoverFromMnemonic(String mnemonic) async {
    try {
      await recoverWalletFromBIP32SeedPhrase(mnemonic);
    } catch (e) {
      Logger.print("Exception rethrown from recoverFromMnemonic(): $e");
      throw e;
    }
  }

  /// Recovers wallet from [suppliedMnemonic]. Expects a valid mnemonic.
  dynamic recoverWalletFromBIP32SeedPhrase(String suppliedMnemonic) async {
    try {
      final String mnemonic = suppliedMnemonic;
      final seed = bip39.mnemonicToSeed(mnemonic);
      final root = bip32.BIP32.fromSeed(seed);

      List<String> receivingAddressArray = [];
      List<String> changeAddressArray = [];

      int receivingIndex = 0;
      int changeIndex = 0;

      // The gap limit will be capped at 20
      int receivingGapCounter = 0;
      int changeGapCounter = 0;

      // Deriving and checking for receiving addresses
      for (var i = 0; i < 1000; i++) {
        await Future.delayed(Duration(milliseconds: 650));
        // Break out of loop when receivingGapCounter hits 20
        if (receivingGapCounter == 20) {
          break;
        }

        final currentNode = root.derivePath("m/44'/136'/0'/0/$i");
        final address = P2PKH(
                network: firoNetwork,
                data: new PaymentData(pubkey: currentNode.publicKey))
            .data
            .address;

        try {
          final int numTxs = await _getReceivedTxCount(address: address);
          if (numTxs >= 1) {
            receivingIndex = i;
            receivingAddressArray.add(address);
          } else if (numTxs == 0) {
            receivingGapCounter += 1;
          }
        } catch (e) {
          Logger.print(
              "Exception rethrown from recoverWalletFromBIP32SeedPhrase(): $e");
          throw e;
        }
      }

      // Deriving and checking for change addresses
      for (var i = 0; i < 1000; i++) {
        await Future.delayed(Duration(milliseconds: 650));
        // Same gap limit for change as for receiving, breaks when it hits 20
        if (changeGapCounter == 20) {
          break;
        }

        final currentNode = root.derivePath("m/44'/136'/0'/1/$i");
        final address = P2PKH(
                network: firoNetwork,
                data: new PaymentData(pubkey: currentNode.publicKey))
            .data
            .address;

        try {
          final int numTxs = await _getReceivedTxCount(address: address);
          if (numTxs >= 1) {
            changeIndex = i;
            changeAddressArray.add(address);
          } else if (numTxs == 0) {
            changeGapCounter += 1;
          }
        } catch (e) {
          Logger.print(
              "Exception rethrown from recoverWalletFromBIP32SeedPhrase(): $e");
          throw e;
        }
      }

      // If restoring a wallet that never received any funds, then set receivingArray manually
      // If we didn't do this, it'd store an empty array
      if (receivingIndex == 0) {
        final String receivingAddress =
            await _generateAddressForChain(0, receivingIndex);
        receivingAddressArray.add(receivingAddress);
      }

      // If restoring a wallet that never sent any funds with change, then set changeArray
      // manually. If we didn't do this, it'd store an empty array.
      if (changeIndex == 0) {
        final String changeAddress =
            await _generateAddressForChain(1, changeIndex);
        changeAddressArray.add(changeAddress);
      }

      final wallet = await Hive.openBox(this._walletId);
      await wallet.put('receivingAddresses', receivingAddressArray);
      await wallet.put('changeAddresses', changeAddressArray);
      await wallet.put('receivingIndex', receivingIndex);
      await wallet.put('changeIndex', changeIndex);

      // initialize default node
      final nodes = <String, dynamic>{};
      nodes.addAll({
        CampfireConstants.defaultNodeName: {
          "id": Uuid().v1(),
          "ipAddress": CampfireConstants.defaultIpAddress,
          "port": CampfireConstants.defaultPort.toString(),
        }
      });
      await wallet.put('nodes', nodes);
      await wallet.put('activeNodeName', CampfireConstants.defaultNodeName);

      final secureStore = new FlutterSecureStorage();
      await secureStore.write(
          key: '${this._walletId}_mnemonic', value: suppliedMnemonic.trim());
      await _restore();
    } catch (e) {
      Logger.print(
          "Exception rethrown from recoverWalletFromBIP32SeedPhrase(): $e");
      throw e;
    }
  }

  _restore() async {
    final wallet = await Hive.openBox(this._walletId);
    final secureStore = new FlutterSecureStorage();
    final mnemonic = await secureStore.read(key: '${this._walletId}_mnemonic');
    TransactionData data = await _txnData;
    Node node = await currentNode;
    final String currency = await CurrencyUtilities.fetchPreferredCurrency();

    ReceivePort receivePort = await getIsolate({
      "function": "restore",
      "node": node,
      "mnemonic": mnemonic,
      "transactionData": data,
      "currency": currency,
      "coinName": this.coinName,
    });

    var message = await receivePort.first;
    if (message is String) {
      Logger.print("restore() ->> this is a string");
      stop();
      throw Exception("isolate restore failed.");
    }
    stop();

    await wallet.put('mintIndex', message['mintIndex']);
    await wallet.put('_lelantus_coins', message['_lelantus_coins']);
    await wallet.put('jindex', message['jindex']);
    this._lelantusTransactionData = Future(() => message['newTxData']);

    await wallet.put('latest_lelantus_tx_model', message['newTxData']);
  }

  /// Changes the biometrics auth setting used on the lockscreen as an alternative
  /// to the pattern lock
  @override
  updateBiometricsUsage(bool enabled) async {
    final wallet = await Hive.openBox(this._walletId);

    await wallet.put('use_biometrics', enabled);
    _useBiometrics = Future(() => enabled);
  }

  /// Switches preferred fiat currency for display and data fetching purposes
  changeCurrency(String newCurrency) async {
    final prefs = await Hive.openBox('prefs');
    await prefs.put('currency', newCurrency);
    this._currency = Future(() => newCurrency);
  }

  Future<dynamic> _createJoinSplitTransaction(
      int spendAmount, String address, bool subtractFeeFromAmount) async {
    final price = await bitcoinPrice;
    Node node = await currentNode;
    final wallet = await Hive.openBox(this._walletId);
    final secureStore = new FlutterSecureStorage();
    final mnemonic = await secureStore.read(key: '${this._walletId}_mnemonic');
    final index = await wallet.get('mintIndex');
    var lelantusEntry = await _getLelantusEntry();

    ReceivePort receivePort = await getIsolate({
      "function": "createJoinSplit",
      "spendAmount": spendAmount,
      "address": address,
      "subtractFeeFromAmount": subtractFeeFromAmount,
      "mnemonic": mnemonic,
      "index": index,
      "price": price,
      "lelantusEntries": lelantusEntry,
      "node": node,
    });
    var message = await receivePort.first;
    if (message is String) {
      Logger.print("Error in CreateJoinSplit: $message");
      stop();
      return 3;
    }
    if (message is int) {
      stop();
      return message;
    }
    stop();
    Logger.print('Closing createJoinSplit!');
    return message;
  }
}
