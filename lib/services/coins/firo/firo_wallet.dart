import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip32/src/utils/wif.dart' as wif;
import 'package:bip39/bip39.dart' as bip39;
import 'package:decimal/decimal.dart';
import 'package:firo_flutter/firo_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:lelantus/lelantus.dart';
import 'package:path_provider/path_provider.dart';
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
import 'package:paymint/services/event_bus/events/updated_in_background_event.dart';
import 'package:paymint/services/event_bus/global_event_bus.dart';
import 'package:paymint/services/price.dart';
import 'package:paymint/utilities/address_utils.dart';
import 'package:paymint/utilities/flutter_secure_storage_interface.dart';
import 'package:paymint/utilities/logger.dart';
import 'package:paymint/utilities/misc_global_constants.dart';
import 'package:paymint/utilities/shared_utilities.dart';
import 'package:uuid/uuid.dart';

import '../../globals.dart';

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

final firoTestNetwork = NetworkType(
    messagePrefix: '\x18Zcoin Signed Message:\n',
    bech32: 'bc',
    bip32: Bip32Type(public: 0x043587cf, private: 0x04358394),
    pubKeyHash: 0x41,
    scriptHash: 0xb2,
    wif: 0xb9);

enum FiroNetworkType { main, test }

// isolate

Map<ReceivePort, Isolate> isolates = Map();

Future<ReceivePort> getIsolate(Map<String, dynamic> arguments) async {
  ReceivePort receivePort =
      ReceivePort(); //port for isolate to receive messages.
  arguments['sendPort'] = receivePort.sendPort;
  print("starting isolate ${arguments['function']}");
  Isolate isolate = await Isolate.spawn(executeNative, arguments);
  isolates[receivePort] = isolate;
  return receivePort;
}

Future<void> executeNative(arguments) async {
  print(arguments);
  SendPort sendPort = arguments['sendPort'];
  String function = arguments['function'];
  try {
    if (function == "createJoinSplit") {
      int spendAmount = arguments['spendAmount'];
      String address = arguments['address'];
      bool subtractFeeFromAmount = arguments['subtractFeeFromAmount'];
      String mnemonic = arguments['mnemonic'];
      int index = arguments['index'];
      Decimal price = arguments['price'];
      List<DartLelantusEntry> lelantusEntries = arguments['lelantusEntries'];
      String coinName = arguments['coinName'];
      dynamic network = arguments['network'];
      ElectrumX client = arguments['electrumXClient'];
      CachedElectrumX cachedClient = arguments['cachedElectrumXClient'];
      if (!(spendAmount == null ||
          address == null ||
          subtractFeeFromAmount == null ||
          mnemonic == null ||
          index == null ||
          price == null ||
          lelantusEntries == null ||
          client == null ||
          cachedClient == null ||
          coinName == null ||
          network == null)) {
        var joinSplit = await isolateCreateJoinSplitTransaction(
            spendAmount,
            address,
            subtractFeeFromAmount,
            mnemonic,
            index,
            price,
            lelantusEntries,
            client,
            cachedClient,
            coinName,
            network);
        sendPort.send(joinSplit);
        return;
      }
    } else if (function == "estimateJoinSplit") {
      int spendAmount = arguments['spendAmount'];
      bool subtractFeeFromAmount = arguments['subtractFeeFromAmount'];
      List<DartLelantusEntry> lelantusEntries = arguments['lelantusEntries'];

      if (!(spendAmount == null ||
          subtractFeeFromAmount == null ||
          lelantusEntries == null)) {
        var feeData = await isolateEstimateJoinSplitFee(
            spendAmount, subtractFeeFromAmount, lelantusEntries);
        sendPort.send(feeData);
        return;
      }
    } else if (function == "restore") {
      int latestSetId = arguments['latestSetId'];
      Map setDataMap = arguments['setDataMap'];
      dynamic usedSerialNumbers = arguments['usedSerialNumbers'];
      String mnemonic = arguments['mnemonic'];
      TransactionData transactionData = arguments['transactionData'];
      String currency = arguments['currency'];
      String coinName = arguments['coinName'];
      dynamic network = arguments['network'];
      CachedElectrumX cachedClient = arguments['cachedElectrumXClient'];
      Decimal currentPrice = arguments['currentPrice'];
      if (!(mnemonic == null ||
          transactionData == null ||
          cachedClient == null ||
          latestSetId == null ||
          setDataMap == null ||
          usedSerialNumbers == null ||
          network == null ||
          coinName == null ||
          currency == null ||
          currentPrice == null)) {
        var restoreData = await isolateRestore(
            cachedClient,
            mnemonic,
            transactionData,
            currency,
            coinName,
            latestSetId,
            setDataMap,
            usedSerialNumbers,
            network,
            currentPrice);
        sendPort.send(restoreData);
        return;
      }
    } else if (function == "isolateDerive") {
      String mnemonic = arguments['mnemonic'];
      int from = arguments['from'];
      int to = arguments['to'];
      dynamic network = arguments['network'];
      if (!(mnemonic == null ||
          from == null ||
          to == null ||
          network == null)) {
        var derived = await isolateDerive(mnemonic, from, to, network);
        sendPort.send(derived);
        return;
      }
    }
    print("Error Arguments for $function not formatted correctly");
    sendPort.send("Error");
  } catch (e) {
    print("An error was thrown in this isolate $function");
    print(e);
    sendPort.send("Error");
  }
}

void stop(ReceivePort port) {
  Isolate isolate = isolates[port];
  if (isolate != null) {
    print('Stopping Isolate...');
    isolate.kill(priority: Isolate.immediate);
    isolate = null;
  }
}

isolateDerive(String mnemonic, int from, int to, dynamic _network) async {
  Map<String, dynamic> result = Map();
  Map<int, dynamic> allReceive = Map();
  Map<int, dynamic> allChange = Map();
  final root = getBip32Root(mnemonic, _network);
  for (int i = from; i < to; i++) {
    var currentNode = getBip32NodeFromRoot(0, i, root);
    var address = P2PKH(
            network: _network,
            data: new PaymentData(pubkey: currentNode.publicKey))
        .data
        .address;
    allReceive[i] = {
      "publicKey": uint8listToString(currentNode.publicKey),
      "wif": currentNode.toWIF(),
      "fingerprint": uint8listToString(currentNode.fingerprint),
      "identifier": uint8listToString(currentNode.identifier),
      "privateKey": uint8listToString(currentNode.privateKey),
      "address": address,
    };

    currentNode = getBip32NodeFromRoot(1, i, root);
    address = P2PKH(
            network: _network,
            data: new PaymentData(pubkey: currentNode.publicKey))
        .data
        .address;
    allChange[i] = {
      "publicKey": uint8listToString(currentNode.publicKey),
      "wif": currentNode.toWIF(),
      "fingerprint": uint8listToString(currentNode.fingerprint),
      "identifier": uint8listToString(currentNode.identifier),
      "privateKey": uint8listToString(currentNode.privateKey),
      "address": address,
    };
    if (i % 50 == 0) {
      Logger.print("thread at $i");
    }
  }
  result['receive'] = allReceive;
  result['change'] = allChange;
  return result;
}

isolateRestore(
    CachedElectrumX cachedClient,
    String mnemonic,
    TransactionData data,
    String currency,
    String coinName,
    int _latestSetId,
    Map _setDataMap,
    dynamic _usedSerialNumbers,
    dynamic network,
    Decimal currentPrice) async {
  List<int> jindexes = [];
  Map<dynamic, LelantusCoin> _lelantus_coins = Map();

  final spendTxIds = List.empty(growable: true);
  var lastFoundIndex = 0;
  var currentIndex = 0;

  try {
    Map dataMintMaps = Map();
    Map dataJMintMaps = Map();
    for (var setId = 1; setId <= _latestSetId; setId++) {
      final Map<String, dynamic> setData = _setDataMap[setId];
      Map<String, dynamic> setDataMints = Map();
      for (int i = 0; i < setData['mints'].length; i++) {
        final value = setData['mints'][i];
        setDataMints[value[1]] = value;
      }
      Map<String, dynamic> setDataJMints = Map();
      for (int i = 0; i < setData['jmints'].length; i++) {
        final value = setData['jmints'][i];
        setDataJMints[value[1]] = value;
      }
      dataMintMaps[setId] = setDataMints;
      dataJMintMaps[setId] = setDataJMints;
    }

    final usedSerialNumbers = _usedSerialNumbers['serials'];
    Set usedSerialNumbersSet = Set();
    for (int ind = 0; ind < usedSerialNumbers.length; ind++) {
      usedSerialNumbersSet.add(usedSerialNumbers[ind]);
    }

    final root = getBip32Root(mnemonic, network);
    while (currentIndex < lastFoundIndex + 20) {
      final mintKeyPair = getBip32NodeFromRoot(MINT_INDEX, currentIndex, root);
      final mintTag = CreateTag(uint8listToString(mintKeyPair.privateKey),
          currentIndex, uint8listToString(mintKeyPair.identifier));

      for (var setId = 1; setId <= _latestSetId; setId++) {
        var foundMint = dataMintMaps[setId][mintTag];

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
          var foundJmint = dataJMintMaps[setId][mintTag];
          if (foundJmint != null) {
            lastFoundIndex = currentIndex;

            final keyPath = GetAesKeyPath(foundJmint[0]);
            final aesKeyPair = getBip32NodeFromRoot(JMINT_INDEX, keyPath, root);
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
  final spendTxs = await getJMintTransactions(
      cachedClient, spendTxIds, currency, coinName, true, currentPrice);
  print(spendTxs);
  spendTxs.forEach((element) {
    transactionMap[element.txid] = element;
  });

  final TransactionData newTxData = TransactionData.fromMap(transactionMap);
  result['newTxData'] = newTxData;
  return result;
}

Future<LelantusFeeData> isolateEstimateJoinSplitFee(int spendAmount,
    bool subtractFeeFromAmount, List<DartLelantusEntry> lelantusEntries) async {
  Logger.print("estimateJoinsplit ree");
  for (int i = 0; i < lelantusEntries.length; i++) {
    Logger.print(lelantusEntries[i]);
  }
  Logger.print("$spendAmount $subtractFeeFromAmount");

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
  Logger.print(
      "estimateFeeData ${estimateFeeData.changeToMint} ${estimateFeeData.fee} ${estimateFeeData.spendCoinIndexes}");
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
  ElectrumX client,
  CachedElectrumX cachedClient,
  String coinName,
  dynamic _network,
) async {
  final getanonymityset = await getAnonymitySet(cachedClient, true, coinName);

  final estimateJoinSplitFee = await isolateEstimateJoinSplitFee(
      spendAmount, subtractFeeFromAmount, lelantusEntries);
  var changeToMint = estimateJoinSplitFee.changeToMint;
  var fee = estimateJoinSplitFee.fee;
  var spendCoinIndexes = estimateJoinSplitFee.spendCoinIndexes;
  print("$changeToMint $fee $spendCoinIndexes");
  if (spendCoinIndexes.isEmpty) {
    print("Error, Not enough funds.");
    return 1;
  }

  final tx = new TransactionBuilder(network: _network);
  int locktime = await getBlockHead(client);
  tx.setLockTime(locktime);

  tx.setVersion(3 | (TRANSACTION_LELANTUS << 16));

  tx.addInput(
    '0000000000000000000000000000000000000000000000000000000000000000',
    4294967295,
    4294967295,
    Uint8List(0),
  );

  final jmintKeyPair = getBip32Node(MINT_INDEX, index, mnemonic, _network);

  final String jmintprivatekey = uint8listToString(jmintKeyPair.privateKey);

  final keyPath = getMintKeyPath(changeToMint, jmintprivatekey, index);

  final aesKeyPair = getBip32Node(JMINT_INDEX, keyPath, mnemonic, _network);
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

  final finalTx = new TransactionBuilder(network: _network);
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
    "amount": Utilities.satoshisToAmount(amount).toDouble(),
    "worthNow": ((Decimal.fromInt(amount) * price) /
            Decimal.fromInt(CampfireConstants.satsPerCoin))
        .toDecimal(scaleOnInfinitePrecision: 2)
        .toStringAsFixed(2),
    "address": address,
    "timestamp": DateTime.now().millisecondsSinceEpoch ~/ 1000,
    "subType": "join",
  };
}

/// set hivePath to null unless calling this function in an isolate
Future<List<models.Transaction>> getJMintTransactions(
  CachedElectrumX cachedClient,
  List transactions,
  String currency,
  String coinName,
  bool outsideMainIsolate,
  Decimal currentPrice,
) async {
  try {
    List<models.Transaction> txs = [];

    for (int i = 0; i < transactions.length; i++) {
      try {
        final tx = await cachedClient.getTransaction(
          tx_hash: transactions[i],
          verbose: true,
          coinName: coinName,
          callOutSideMainIsolate: outsideMainIsolate,
        );

        tx["confirmed_status"] =
            tx["confirmations"] != null && tx["confirmations"] > 0;
        tx["timestamp"] = tx["time"];
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

        final decimalAmount = Decimal.parse(tx["amount"].toString());

        tx["worthNow"] = (currentPrice * decimalAmount).toStringAsFixed(2);
        tx["worthAtBlockTimestamp"] = tx["worthNow"];

        tx["subType"] = "join";
        txs.add(models.Transaction.fromLelantusJson(tx));
      } catch (e, s) {
        Logger.print("Exception caught in getJMintTransactions(): $e");
        Logger.print(s);
        throw e;
      }
    }
    return txs;
  } catch (e) {
    Logger.print("Exception rethrown in getJMintTransactions(): $e");
    throw e;
  }
}

Future<dynamic> getAnonymitySet(CachedElectrumX cachedClient,
    bool callOutSideMainIsolate, String coinName) async {
  try {
    var tod = await cachedClient.getAnonymitySet(
      groupId: "1",
      coinName: coinName,
      callOutSideMainIsolate: callOutSideMainIsolate,
    );
    tod['serializedCoins'] = tod['serializedCoins'].cast<String>();

    return tod;
  } catch (e) {
    Logger.print("Exception rethrown in getAnonymitySet(): $e");
    throw e;
  }
}

Future<int> getBlockHead(ElectrumX client) async {
  try {
    final tip = await client.getBlockHeadTip();
    return tip["height"];
  } catch (e) {
    Logger.print("Exception rethrown in getBlockHead(): $e");
    throw e;
  }
}
// end of isolates

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

bip32.BIP32 getBip32Node(
    int chain, int index, String mnemonic, NetworkType network) {
  final root = getBip32Root(mnemonic, network);

  final node = getBip32NodeFromRoot(chain, index, root);
  return node;
}

bip32.BIP32 getBip32NodeFromRoot(int chain, int index, bip32.BIP32 root) {
  final node = root.derivePath("m/44'/136'/0'/$chain/$index");
  return node;
}

bip32.BIP32 getBip32Root(String mnemonic, NetworkType network) {
  final seed = bip39.mnemonicToSeed(mnemonic);
  final firoNetworkType = bip32.NetworkType(
    wif: network.wif,
    bip32: bip32.Bip32Type(
      public: network.bip32.public,
      private: network.bip32.private,
    ),
  );

  final root = bip32.BIP32.fromSeed(seed, firoNetworkType);
  return root;
}

/// Handles a single instance of a firo wallet
class FiroWallet extends CoinServiceAPI {
  Timer timer;
  FiroNetworkType _networkType;
  FiroNetworkType get networkType => _networkType;

  Set<String> unconfirmedTxs = {};

  NetworkType get _network {
    switch (networkType) {
      case FiroNetworkType.main:
        return firoNetwork;
      case FiroNetworkType.test:
        return firoTestNetwork;
      default:
        throw Exception("Firo network type not set!");
    }
  }

  @override
  String get coinName => networkType == FiroNetworkType.main ? "Firo" : "tFiro";

  @override
  String get coinTicker =>
      networkType == FiroNetworkType.main ? "FIRO" : "tFIRO";

  @override
  Future<List<String>> get mnemonic => _getMnemonicList();

  @override
  String get fiatCurrency => currency;

  @override
  void changeFiatCurrency(String currency) {
    _changeCurrency(currency);
  }

  @override
  Future<Decimal> get fiatPrice => firoPrice;

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
    return Address.validateAddress(address, _network);
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
      _lelantusTransactionData ??= _getLelantusTransactionData();

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
  Future<Decimal> get firoPrice => Future(() async =>
      _priceAPI.getPrice(ticker: coinTicker, baseCurrency: currency));

  // currently isn't used but required due to abstract parent class
  Future<FeeObject> _feeObject;
  @override
  Future<FeeObject> get fees => _feeObject;

  /// Holds preferred fiat currency
  String _currency;
  String get currency => _currency ??= fetchPreferredCurrency();

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
  set walletName(String newName) => _walletName = newName;

  /// unique wallet id
  String _walletId;
  @override
  String get walletId => _walletId;

  Future<ElectrumXNode> _currentNode;
  Future<ElectrumXNode> get currentNode => _currentNode ?? _getCurrentNode();

  Future<List<String>> _allOwnAddresses;
  @override
  Future<List<String>> get allOwnAddresses =>
      _allOwnAddresses ??= _fetchAllOwnAddresses();

  @override
  Future<bool> testNetworkConnection(ElectrumX client) async {
    try {
      final result = await client.getBlockHeadTip();

      return result["height"] != null && result["height"] is int;
    } catch (_) {
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

          // temporarily update apdate available balance until a full refresh is done
          Decimal sendTotal = Utilities.satoshisToAmount(txHexOrError["value"]);
          sendTotal += Decimal.parse(txHexOrError["fees"].toString());
          final bals = await balances;
          bals[0] -= sendTotal;
          _balances = Future(() => bals);

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

  Future<List<String>> _getMnemonicList() async {
    final mnemonicString =
        await _secureStore.read(key: '${this._walletId}_mnemonic');
    final List<String> data = mnemonicString.split(' ');
    return data;
  }

  ElectrumX _electrumXClient;
  ElectrumX get electrumXClient => _electrumXClient;

  CachedElectrumX _cachedElectrumXClient;
  CachedElectrumX get cachedElectrumXClient => _cachedElectrumXClient;

  FlutterSecureStorageInterface _secureStore;

  PriceAPI _priceAPI;

  StreamSubscription _nodesChangedListener;

  // Constructor
  FiroWallet(
      {@required String walletId,
      @required String walletName,
      @required FiroNetworkType networkType,
      @required ElectrumX client,
      @required CachedElectrumX cachedClient,
      PriceAPI priceAPI,
      FlutterSecureStorageInterface secureStore}) {
    this._walletId = walletId;
    this._walletName = walletName;
    this._networkType = networkType;
    this._electrumXClient = client;
    this._cachedElectrumXClient = cachedClient;

    _priceAPI = priceAPI == null ? PriceAPI(Client()) : priceAPI;
    _secureStore = secureStore == null
        ? SecureStorageWrapper(FlutterSecureStorage())
        : secureStore;

    // add listener for nodes changed
    _nodesChangedListener =
        GlobalEventBus.instance.on<NodesChangedEvent>().listen((event) async {
      final appDir = await getApplicationDocumentsDirectory();
      final newNode = await _getCurrentNode();
      this._currentNode = Future(() => newNode);
      this._cachedElectrumXClient =
          CachedElectrumX.from(node: newNode, hivePath: appDir.path);
      this._electrumXClient = ElectrumX.from(node: newNode);
      refresh();
    });
  }

  /// Initializes the wallet class and sets class getters. Will create a wallet if one does not
  /// already exist.
  Future<void> initializeWallet() async {
    final wallet = await Hive.openBox(this._walletId);

    if (wallet.isEmpty) {
      // Triggers for new users automatically. Generates new wallet
      await _generateNewWallet(wallet);
      wallet.put("id", this._walletId);
      final newNode = await _getCurrentNode();
      this._currentNode = Future(() => newNode);
      final lelantusTxData = await _getLelantusTransactionData();
      this._lelantusTransactionData = Future(() => lelantusTxData);
    } else {
      // Wallet already exists, triggers for a returning user
      final newNode = await _getCurrentNode();
      this._currentNode = Future(() => newNode);
      final lelantusTxData = await _getLelantusTransactionData();
      this._lelantusTransactionData = Future(() => lelantusTxData);
      final currentAddress = await _getCurrentAddressForChain(0);
      this._currentReceivingAddress = Future(() => currentAddress);
      final useBio = await _fetchUseBiometrics();
      this._useBiometrics = Future(() => useBio);
    }

    this._utxoData = _fetchUtxoData();
    this._transactionData = _fetchTransactionData();

    await _checkReceivingAddressForTransactions();
  }

  Future<bool> refreshIfThereIsNewData() async {
    if (longMutex) return false;
    Logger.print("refreshIfThereIsNewData");

    bool needsRefresh = false;
    Logger.print("unonconfirmeds $unconfirmedTxs");
    for (String txid in unconfirmedTxs) {
      final txn = await electrumXClient.getTransaction(tx_hash: txid);
      var confirmations = txn["confirmations"];
      if (!(confirmations is int)) continue;
      bool isUnconfirmed = confirmations < 1;
      if (!isUnconfirmed) {
        unconfirmedTxs = {};
        needsRefresh = true;
        break;
      }
    }
    if (!needsRefresh) {
      var allOwnAddresses = await this.allOwnAddresses;
      List<Map<String, dynamic>> allTxs = await _fetchHistory(allOwnAddresses);
      models.TransactionData txData = await _txnData;
      for (Map transaction in allTxs) {
        if (txData.findTransaction(transaction['tx_hash']) == null) {
          Logger.print(
              " txid not found in address history already ${transaction['tx_hash']}");
          needsRefresh = true;
          break;
        }
      }
    }
    return needsRefresh;
  }

  Future<void> getAllTxsToWatch(
    TransactionData txData,
    TransactionData lTxData,
  ) async {
    Logger.print("periodic");

    Logger.print(txData.txChunks);
    Logger.print(lTxData.txChunks);
    Set<String> needRefresh = {};

    for (models.TransactionChunk chunk in txData.txChunks) {
      for (models.Transaction tx in chunk.transactions) {
        models.Transaction lTx = lTxData.findTransaction(tx.txid);
        if (!tx.confirmedStatus) {
          // Get all normal txs that are at 0 confirmations
          needRefresh.add(tx.txid);
          print("1 ${tx.txid}");
        } else if (lTx != null &&
            (lTx.inputs.isEmpty || lTx.inputs[0].txid == null) &&
            lTx.confirmedStatus == false &&
            tx.txType == "Received") {
          // If this is a received that is past 1 or more confirmations and has not been minted,
          needRefresh.add(tx.txid);
          print("2 ${tx.txid}");
        }
      }
    }

    for (models.TransactionChunk chunk in txData.txChunks) {
      for (models.Transaction tx in chunk.transactions) {
        if (!tx.confirmedStatus && tx.inputs[0].txid != null) {
          // Get all normal txs that are at 0 confirmations
          needRefresh.remove(tx.inputs[0].txid);
        }
      }
    }
    for (models.TransactionChunk chunk in lTxData.txChunks) {
      for (models.Transaction lTX in chunk.transactions) {
        models.Transaction tx = txData.findTransaction(lTX.txid);
        if (!lTX.confirmedStatus && tx == null) {
          // if this is a ltx transaction that is unconfirmed and not represented in the normal transaction set.
          needRefresh.add(lTX.txid);
          print("3 ${lTX.txid}");
        }
      }
    }
    Logger.print("needRefresh $needRefresh");
    unconfirmedTxs = needRefresh;
  }

  /// Generates initial wallet values such as mnemonic, chain (receive/change) arrays and indexes.
  Future<void> _generateNewWallet(Box<dynamic> wallet) async {
    final features = await electrumXClient.getServerFeatures();
    print("features: $features");
    if (_networkType == FiroNetworkType.main) {
      if (features['genesis_hash'] != CampfireConstants.firoGenesisHash) {
        throw Exception("genesis hash does not match!");
      }
    } else if (_networkType == FiroNetworkType.test) {
      if (features['genesis_hash'] != CampfireConstants.firoTestGenesisHash) {
        throw Exception("genesis hash does not match!");
      }
    }

    await _secureStore.write(
        key: '${this._walletId}_mnemonic',
        value: bip39.generateMnemonic(strength: 256));
    // Set relevant indexes
    await wallet.put('receivingIndex', 0);
    await wallet.put('changeIndex', 0);
    await wallet.put('mintIndex', 0);
    await wallet.put('blocked_tx_hashes', [
      "0xdefault"
    ]); // A list of transaction hashes to represent frozen utxos in wallet
    // initialize address book entries
    await wallet.put('addressBookEntries', <String, String>{});

    await wallet.put('jindex', []);
    // Generate and add addresses to relevant arrays
    final initialReceivingAddress = await _generateAddressForChain(0, 0);
    final initialChangeAddress = await _generateAddressForChain(1, 0);
    await _addToAddressesArrayForChain(initialReceivingAddress, 0);
    await _addToAddressesArrayForChain(initialChangeAddress, 1);
    this._currentReceivingAddress = Future(() => initialReceivingAddress);
    this._useBiometrics = _fetchUseBiometrics();
  }

  bool refreshMutex = false;

  /// Refreshes display data for the wallet
  @override
  Future<void> refresh() async {
    if (refreshMutex) {
      print("denied");
      return;
    } else {
      refreshMutex = true;
    }
    Logger.print("PROCESSORS ${Platform.numberOfProcessors}");
    try {
      GlobalEventBus.instance
          .fire(NodeConnectionStatusChangedEvent(NodeConnectionStatus.loading));

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.0));

      final wallet = await Hive.openBox(this._walletId);
      if (wallet.get('receiveDerivations') == null) {
        GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.05));
        final mnemonic =
            await _secureStore.read(key: '${this._walletId}_mnemonic');
        await fillAddresses(mnemonic,
            NUMBER_OF_THREADS:
                Platform.numberOfProcessors - isolates.length - 1);
      }

      final newUtxoData = _fetchUtxoData();
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.1));

      final newTxData = _fetchTransactionData();
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.2));

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.25));

      final FeeObject feeObj = await _getFees();
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.35));

      await _checkReceivingAddressForTransactions();
      final useBiometrics = await _fetchUseBiometrics();
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.50));

      this._utxoData = Future(() => newUtxoData);
      this._transactionData = Future(() => newTxData);
      this._feeObject = Future(() => feeObj);
      this._useBiometrics = Future(() => useBiometrics);
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.60));

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

      var txData = (await _txnData);
      var lTxData = (await lelantusTransactionData);
      await getAllTxsToWatch(txData, lTxData);

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(1.0));

      GlobalEventBus.instance
          .fire(NodeConnectionStatusChangedEvent(NodeConnectionStatus.synced));
      refreshMutex = false;
      if (timer == null) {
        timer = Timer.periodic(Duration(seconds: 150), (timer) async {
          bool shouldNotify = await refreshIfThereIsNewData();
          if (shouldNotify) {
            await refresh();
            GlobalEventBus.instance.fire(
                UpdatedInBackgroundEvent("New data found in background!"));
          }
        });
      }
    } catch (error, strace) {
      refreshMutex = false;
      GlobalEventBus.instance.fire(
          NodeConnectionStatusChangedEvent(NodeConnectionStatus.disconnected));
      Logger.print("Caught exception in refreshWalletData(): $error");
      Logger.print(strace.toString());
    }
  }

  Future<LelantusFeeData> _fetchMaxFee() async {
    var lelantusEntry = await _getLelantusEntry();
    final balance = await this.balance;
    int spendAmount = (balance * Decimal.fromInt(CampfireConstants.satsPerCoin))
        .toBigInt()
        .toInt();
    if (spendAmount == 0 || lelantusEntry.isEmpty) {
      return LelantusFeeData(0, 0, []);
    }
    ReceivePort receivePort = await getIsolate({
      "function": "estimateJoinSplit",
      "spendAmount": spendAmount,
      "subtractFeeFromAmount": true,
      "lelantusEntries": lelantusEntry,
    });

    var message = await receivePort.first;
    if (message is String) {
      Logger.print("this is a string");
      stop(receivePort);
      throw Exception("_fetchMaxFee isolate failed");
    }
    stop(receivePort);
    Logger.print('Closing estimateJoinSplit!');
    return message;
  }

  Future<List<DartLelantusEntry>> _getLelantusEntry() async {
    final mnemonic = await _secureStore.read(key: '${this._walletId}_mnemonic');
    final List<LelantusCoin> lelantusCoins = await _getUnspentCoins();
    final root = getBip32Root(mnemonic, _network);
    final waitLelantusEntries = lelantusCoins.map((coin) async {
      final keyPair = getBip32NodeFromRoot(MINT_INDEX, coin.index, root);
      final String privateKey = uint8listToString(keyPair.privateKey);
      if (privateKey == null) {
        Logger.print("error bad key");
        return DartLelantusEntry(1, 0, 0, 0, 0, '');
      }
      return DartLelantusEntry(coin.isUsed ? 1 : 0, 0, coin.anonymitySetId,
          coin.value, coin.index, privateKey);
    }).toList();

    final lelantusEntries = await Future.wait(waitLelantusEntries);

    if (lelantusEntries != null && lelantusEntries.isNotEmpty) {
      lelantusEntries.removeWhere((element) => element.amount == 0);
    }

    return lelantusEntries;
  }

  Future<List<LelantusCoin>> _getUnspentCoins() async {
    final wallet = await Hive.openBox(this._walletId);
    Map _lelantus_coins = await wallet.get('_lelantus_coins');
    if (_lelantus_coins != null && _lelantus_coins.isNotEmpty) {
      _lelantus_coins.removeWhere((key, value) => value.value == 0);
    }
    List jindexes = await wallet.get('jindex');
    final data = await _txnData;
    final lelantusData = await _lelantusTransactionData;
    List<LelantusCoin> coins = [];
    if (_lelantus_coins == null) {
      return coins;
    }

    final lelantusCoinsList = _lelantus_coins.values.toList(growable: false);
    for (int i = 0; i < lelantusCoinsList.length; i++) {
      print("hi ${lelantusCoinsList[i]}");
      final txn = await cachedElectrumXClient.getTransaction(
        tx_hash: lelantusCoinsList[i].txId,
        verbose: true,
        coinName: this.coinName,
        callOutSideMainIsolate: false,
      );
      final confirmations = txn["confirmations"];
      bool isUnconfirmed = confirmations is int && confirmations < 1;
      if (!jindexes.contains(lelantusCoinsList[i].index) &&
          data.findTransaction(lelantusCoinsList[i].txId) == null) {
        isUnconfirmed = true;
      }
      if ((data != null &&
              data.findTransaction(lelantusCoinsList[i].txId) != null &&
              !data
                  .findTransaction(lelantusCoinsList[i].txId)
                  .confirmedStatus) ||
          (lelantusData != null &&
              lelantusData.findTransaction(lelantusCoinsList[i].txId) != null &&
              !lelantusData
                  .findTransaction(lelantusCoinsList[i].txId)
                  .confirmedStatus)) {
        continue;
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
      Map _lelantus_coins = await wallet.get('_lelantus_coins');
      if (_lelantus_coins != null && _lelantus_coins.isNotEmpty) {
        _lelantus_coins.removeWhere((key, value) => value.value == 0);
      }
      final utxos = await utxoData;
      final Decimal price = await firoPrice;
      final data = await _txnData;
      final lData = await _lelantusTransactionData;
      List jindexes = await wallet.get('jindex');
      int intLelantusBalance = 0;
      int unconfirmedLelantusBalance = 0;
      if (_lelantus_coins != null && data != null) {
        _lelantus_coins.forEach((key, value) {
          final tx = data.findTransaction(value.txId);
          var ltx;
          if (lData != null) {
            ltx = lData.findTransaction(value.txId);
          }
          Logger.print("$value $tx $ltx");
          if (!jindexes.contains(value.index) && tx == null) {
            // This coin is not confirmed and may be replaced
          } else if (jindexes.contains(value.index) &&
              tx == null &&
              !value.isUsed &&
              ltx != null &&
              !ltx.confirmedStatus) {
            unconfirmedLelantusBalance += value.value;
          } else if (jindexes.contains(value.index) && !value.isUsed) {
            intLelantusBalance += value.value;
          } else if (!value.isUsed &&
              (tx == null ? true : tx.confirmedStatus != false)) {
            intLelantusBalance += value.value;
          } else if (tx != null && tx.confirmedStatus == false) {
            unconfirmedLelantusBalance += value.value;
          }
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

      Decimal _unconfirmedLelantusBalance =
          Utilities.satoshisToAmount(unconfirmedLelantusBalance);

      balances.add(lelantusBalance + utxosValue + _unconfirmedLelantusBalance);

      if (price == null) {
        balances.add(Decimal.fromInt(-1));
      } else {
        balances.add(
            (lelantusBalance + utxosValue + _unconfirmedLelantusBalance) *
                price);
      }
      print("balances $balances");
      return balances;
    } catch (e) {
      Logger.print("Exception rethrown in getFullBalance(): $e");
      throw e;
    }
  }

  Future<void> _autoMint() async {
    try {
      var mintResult = await _mintSelection();
      if (mintResult == null || mintResult.isEmpty) {
        print("nothing to mint");
        return;
      }
      await _submitLelantusToNetwork(mintResult);
    } catch (e, st) {
      Logger.print("Exception caught in _autoMint(): $e");
      Logger.print(st);
    }
  }

  /// Returns the mint transaction hex to mint all of the available funds.
  Future<Map<String, dynamic>> _mintSelection() async {
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
    Map _lelantus_coins = await wallet.get('_lelantus_coins');
    if (_lelantus_coins != null && _lelantus_coins.isNotEmpty) {
      _lelantus_coins.removeWhere((key, value) => value.value == 0);
    }
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
      Logger.print("_mintSelection(): No spendable outputs found");
      return {};
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

    Map<String, dynamic> transaction =
        await buildMintTransaction(utxoObjectsToUse, satoshiAmountToSend);
    transaction['transaction'] = "";
    Logger.print(transaction.toString());
    Logger.print(transaction['txHex']);
    return transaction;
  }

  /// returns a valid txid if successful
  Future<String> submitHexToNetwork(String hex) async {
    try {
      final txid = await electrumXClient.broadcastTransaction(rawTx: hex);
      return txid;
    } catch (e) {
      Logger.print("Caught exception in submitHexToNetwork(\"$hex\"): $e");
      // return an invalid tx
      return "transaction submission failed";
    }
  }

  /// Builds and signs a transaction
  Future<Map<String, dynamic>> buildMintTransaction(
      List<UtxoObject> utxosToUse, int satoshisPerRecipient) async {
    List<String> addressesToDerive = [];

    final wallet = await Hive.openBox(this._walletId);

    // Populating the addresses to derive
    for (var i = 0; i < utxosToUse.length; i++) {
      final txid = utxosToUse[i].txid;
      final outputIndex = utxosToUse[i].vout;

      // txid may not work for this as txid may not always be the same as tx_hash?
      final tx = await cachedElectrumXClient.getTransaction(
        tx_hash: txid,
        verbose: true,
        coinName: this.coinName,
        callOutSideMainIsolate: false,
      );

      final vouts = tx["vout"];
      if (vouts != null && outputIndex < vouts.length) {
        final address = vouts[outputIndex]["scriptPubKey"]["addresses"][0];
        if (address != null) {
          addressesToDerive.add(address);
        }
      }
    }

    List<ECPair> elipticCurvePairArray = [];
    List<Uint8List> outputDataArray = [];
    var receiveDerivations = wallet.get('receiveDerivations');
    var changeDerivations = wallet.get('changeDerivations');

    for (var i = 0; i < addressesToDerive.length; i++) {
      final addressToCheckFor = addressesToDerive[i];

      for (var i = 0; i < receiveDerivations.length; i++) {
        var receive = receiveDerivations[i];
        var change = changeDerivations[i];

        if (receive['address'] == addressToCheckFor) {
          Logger.print('Receiving found on loop $i');
          Logger.print(
              'decoded receive[\'wif\'] version: ${wif.decode(receive['wif'])}, _network: $_network');
          elipticCurvePairArray
              .add(ECPair.fromWIF(receive['wif'], network: _network));
          outputDataArray.add(P2PKH(
                  network: _network,
                  data: new PaymentData(
                      pubkey: stringToUint8List(receive['publicKey'])))
              .data
              .output);
          break;
        }
        if (change['address'] == addressToCheckFor) {
          Logger.print('Change found on loop $i');
          Logger.print(
              'decoded change[\'wif\'] version: ${wif.decode(change['wif'])}, _network: $_network');
          elipticCurvePairArray
              .add(ECPair.fromWIF(change['wif'], network: _network));

          outputDataArray.add(P2PKH(
                  network: _network,
                  data: new PaymentData(
                      pubkey: stringToUint8List(change['publicKey'])))
              .data
              .output);
          break;
        }
      }
    }

    final txb = new TransactionBuilder(network: _network);
    txb.setVersion(2);

    int height = await getBlockHead(electrumXClient);
    txb.setLockTime(height);
    int amount = 0;
    // Add transaction inputs
    for (var i = 0; i < utxosToUse.length; i++) {
      txb.addInput(
          utxosToUse[i].txid, utxosToUse[i].vout, null, outputDataArray[i]);
      amount += utxosToUse[i].value;
    }

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

    var price = await firoPrice;
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

    final String currency = fetchPreferredCurrency();
    final currentPrice = await this._priceAPI.getPrice(
          ticker: this.coinTicker,
          baseCurrency: currency,
        );
    // Grab the most recent information on all the joinsplits

    final updatedJSplit = await getJMintTransactions(cachedElectrumXClient,
        joinsplits, currency, this.coinName, false, currentPrice);

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
    Logger.print(txData.txChunks);
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
    final mnemonic = await _secureStore.read(key: '${this._walletId}_mnemonic');
    final mintKeyPair =
        getBip32Node(MINT_INDEX, index, mnemonic, this._network);
    String keydata = uint8listToString(mintKeyPair.privateKey);
    String seedID = uint8listToString(mintKeyPair.identifier);
    String mintHex = getMintScript(amount, keydata, index, seedID);
    return mintHex;
  }

  Future<bool> _submitLelantusToNetwork(dynamic transactionInfo) async {
    final txid = await submitHexToNetwork(transactionInfo['txHex']);
    // success if txid matches the generated txid
    Logger.print("_submitLelantusToNetwork txid: ${transactionInfo['txid']}");
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
          List jindexes = await wallet.get('jindex');
          jindexes.add(index);
          await wallet.put('jindex', jindexes);
          await wallet.put('mintIndex', index + 1);
        }
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
      final result = await electrumXClient.getFeeRate();

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

  Future<ElectrumXNode> _getCurrentNode() async {
    final wallet = await Hive.openBox(this._walletId);
    var nodes = await wallet.get('nodes');

    if (nodes == null || nodes.isEmpty) {
      // initialize default node
      nodes = <String, dynamic>{};
      String ip;
      String port;
      bool useSSL;
      String nodeName;
      if (networkType == FiroNetworkType.main) {
        ip = CampfireConstants.defaultIpAddress;
        port = CampfireConstants.defaultPort.toString();
        useSSL = CampfireConstants.defaultUseSSL;
        nodeName = CampfireConstants.defaultNodeName;
      } else if (networkType == FiroNetworkType.test) {
        ip = CampfireConstants.defaultIpAddressTestNet;
        port = CampfireConstants.defaultPortTestNet.toString();
        useSSL = CampfireConstants.defaultUseSSLTestNet;
        nodeName = CampfireConstants.defaultNodeNameTestNet;
      }

      nodes.addAll({
        nodeName: {
          "id": Uuid().v1(),
          "ipAddress": ip,
          "port": port,
          "useSSL": useSSL,
        }
      });

      await wallet.put('nodes', nodes);
      await wallet.put('activeNodeName', nodeName);
    }

    final name = await wallet.get('activeNodeName');
    try {
      final String address = nodes[name]["ipAddress"];
      final int port = int.parse(nodes[name]["port"]);
      final bool useSSL = nodes[name]["useSSL"];
      return ElectrumXNode(
        address: address,
        port: port,
        name: name,
        useSSL: useSSL,
      );
    } catch (e, s) {
      Logger.print("Exception rethrown from _getCurrentNode(): $e");
      Logger.print(s);
      throw e;
    }
  }

  //TODO call get transaction and check each tx to see if it is a "received" tx?
  Future<int> _getReceivedTxCount({String address}) async {
    try {
      final scripthash = AddressUtils.convertToScriptHash(address, _network);
      final transactions =
          await electrumXClient.getHistory(scripthash: scripthash);
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
    } catch (e, s) {
      Logger.print(
          "Exception rethrown from _checkReceivingAddressForTransactions(): $e");
      Logger.print(s);
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

  Future<List<Map<String, dynamic>>> _fetchHistory(
      List<String> allAddresses) async {
    List<Map<String, dynamic>> allTxHashes = [];
    // int latestTxnBlockHeight = 0;

    for (final address in allAddresses) {
      final scripthash = AddressUtils.convertToScriptHash(address, _network);
      final txs = await electrumXClient.getHistory(scripthash: scripthash);
      for (final map in txs) {
        if (!allTxHashes.contains(map)) {
          map['address'] = address;
          allTxHashes.add(map);
        }
      }
    }

    return allTxHashes;
  }

  Future<TransactionData> _fetchTransactionData() async {
    final wallet = await Hive.openBox(this._walletId);
    final List<String> allAddresses = [];
    final String currency = fetchPreferredCurrency();
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

    allTxHashes = await _fetchHistory(allAddresses);

    List<Map<String, dynamic>> allTransactions = [];

    for (final txHash in allTxHashes) {
      final tx = await cachedElectrumXClient.getTransaction(
        tx_hash: txHash["tx_hash"],
        verbose: true,
        coinName: this.coinName,
        callOutSideMainIsolate: false,
      );
      // delete unused large parts
      tx.remove("hex");
      tx.remove("lelantusData");

      allTransactions.add(tx);
    }

    Logger.print("allTransactions length: ${allTransactions.length}");

    // sort thing stuff
    final currentPrice = await this
        ._priceAPI
        .getPrice(ticker: coinTicker, baseCurrency: currency);
    final List<Map<String, dynamic>> midSortedArray = [];

    Logger.print("refresh the txs");
    for (final txObject in allTransactions) {
      Logger.print(txObject);
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

      Logger.print("sendersArray: $sendersArray");

      for (final output in txObject["vout"]) {
        final addresses = output["scriptPubKey"]["addresses"];
        if (addresses != null) {
          recipientsArray.add(addresses[0]);
        }
      }
      Logger.print("recipientsArray: $recipientsArray");

      final foundInSenders =
          allAddresses.any((element) => sendersArray.contains(element));
      Logger.print("foundInSenders: $foundInSenders");

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
          final value = output["value"];
          if (addresses != null) {
            final address = addresses[0];
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
          }
          if (value != null) {
            outAmount += (Decimal.parse(value.toString()) *
                    Decimal.fromInt(CampfireConstants.satsPerCoin))
                .toBigInt()
                .toInt();
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
      midSortedTx["timestamp"] = txObject["blocktime"] ??
          (DateTime.now().millisecondsSinceEpoch ~/ 1000);
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
    final Map<String, dynamic> result = {"dateTimeChunks": <dynamic>[]};
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

    return TransactionData.fromJson(result);
    // final newTxnList = TransactionData.fromJson(result).getAllTransactions();
    // transactionsMap.addAll(newTxnList);
    // final txModel = TransactionData.fromMap(transactionsMap);
    // await wallet.put('storedTxnDataHeight', latestTxnBlockHeight);
    // await wallet.put('latest_tx_model', txModel);
    // return txModel;
  }

  Future<UtxoData> _fetchUtxoData() async {
    final wallet = await Hive.openBox(this._walletId);
    final List<String> allAddresses = [];
    final String currency = fetchPreferredCurrency();
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
      final utxoData = <List<Map<String, dynamic>>>[];

      for (int i = 0; i < allAddresses.length; i++) {
        final scripthash =
            AddressUtils.convertToScriptHash(allAddresses[i], _network);
        final utxos = await electrumXClient.getUTXOs(scripthash: scripthash);
        if (utxos.isNotEmpty) {
          utxoData.add(utxos);
        }
      }

      Decimal currentPrice = await this
          ._priceAPI
          .getPrice(ticker: coinTicker, baseCurrency: currency);
      final List<Map<String, dynamic>> outputArray = [];
      int satoshiBalance = 0;

      for (int i = 0; i < utxoData.length; i++) {
        for (int j = 0; j < utxoData[i].length; j++) {
          int value = utxoData[i][j]["value"];
          satoshiBalance += value;

          final txn = await cachedElectrumXClient.getTransaction(
            tx_hash: utxoData[i][j]["tx_hash"],
            verbose: true,
            coinName: this.coinName,
            callOutSideMainIsolate: false,
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
      final currency = fetchPreferredCurrency();
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

  Future<void> fillAddresses(String suppliedMnemonic,
      {int PER_BATCH = 250, int NUMBER_OF_THREADS = 4}) async {
    if (NUMBER_OF_THREADS < 0) {
      NUMBER_OF_THREADS = 1;
    }
    final wallet = await Hive.openBox(this._walletId);
    var receiveDerivations = wallet.get('receiveDerivations');
    var changeDerivations = wallet.get('changeDerivations');
    int start = 0;
    if (receiveDerivations == null || changeDerivations == null) {
      receiveDerivations = {};
      changeDerivations = {};
    } else {
      start = receiveDerivations.length;
    }
    List<ReceivePort> ports = List.empty(growable: true);
    for (int i = 0; i < NUMBER_OF_THREADS; i++) {
      ReceivePort receivePort = await getIsolate({
        "function": "isolateDerive",
        "mnemonic": suppliedMnemonic,
        "from": start + i * PER_BATCH,
        "to": start + (i + 1) * PER_BATCH,
        "network": _network,
      });
      ports.add(receivePort);
    }
    for (int i = 0; i < NUMBER_OF_THREADS; i++) {
      ReceivePort receivePort = ports.elementAt(i);
      var message = await receivePort.first;
      if (message is String) {
        Logger.print("this is a string");
        stop(receivePort);
        throw Exception("isolateDerive isolate failed");
      }
      stop(receivePort);
      Logger.print('Closing isolateDerive!');
      receiveDerivations.addAll(message['receive']);
      changeDerivations.addAll(message['change']);
    }
    Logger.print("isolate derives");
    Logger.print(receiveDerivations);
    Logger.print(changeDerivations);
    wallet.put('receiveDerivations', receiveDerivations);
    wallet.put('changeDerivations', changeDerivations);
  }

  /// Generates a new internal or external chain address for the wallet using a BIP84 derivation path.
  /// [chain] - Use 0 for receiving (external), 1 for change (internal). Should not be any other value!
  /// [index] - This can be any integer >= 0
  Future<String> _generateAddressForChain(int chain, int index) async {
    final wallet = await Hive.openBox(this._walletId);
    final mnemonic = await _secureStore.read(key: '${this._walletId}_mnemonic');
    var derivations;
    if (chain == 0) {
      derivations = wallet.get('receiveDerivations');
    } else if (chain == 1) {
      derivations = wallet.get('changeDerivations');
    }

    if (derivations != null) {
      if (derivations[index] == null) {
        await fillAddresses(mnemonic,
            NUMBER_OF_THREADS:
                Platform.numberOfProcessors - isolates.length - 1);
        return _generateAddressForChain(chain, index);
      }
      return derivations[index]['address'];
    } else {
      final node = getBip32Node(chain, index, mnemonic, this._network);
      return P2PKH(
              network: _network, data: new PaymentData(pubkey: node.publicKey))
          .data
          .address;
    }
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

  /// wrapper for _recoverWalletFromBIP32SeedPhrase()
  @override
  Future<void> recoverFromMnemonic(String mnemonic) async {
    try {
      final features = await electrumXClient.getServerFeatures();
      print("features: $features");
      if (_networkType == FiroNetworkType.main) {
        if (features['genesis_hash'] != CampfireConstants.firoGenesisHash) {
          throw Exception("genesis hash does not match!");
        }
      } else if (_networkType == FiroNetworkType.test) {
        if (features['genesis_hash'] != CampfireConstants.firoTestGenesisHash) {
          throw Exception("genesis hash does not match!");
        }
      }
      await _recoverWalletFromBIP32SeedPhrase(mnemonic);
    } catch (e, s) {
      Logger.print("Exception rethrown from recoverFromMnemonic(): $e");
      Logger.print(s);
      throw e;
    }
  }

  bool longMutex = false;

  /// Recovers wallet from [suppliedMnemonic]. Expects a valid mnemonic.
  Future<void> _recoverWalletFromBIP32SeedPhrase(
      String suppliedMnemonic) async {
    longMutex = true;
    Logger.print("PROCESSORS ${Platform.numberOfProcessors}");
    try {
      final wallet = await Hive.openBox(this._walletId);
      final setDataMap = Map();
      final latestSetId = await getLatestSetId();
      for (var setId = 1; setId <= latestSetId; setId++) {
        final setData = getSetData(setId);
        setDataMap[setId] = setData;
      }
      final usedSerialNumbers = getUsedCoinSerials();

      List<String> receivingAddressArray = [];
      List<String> changeAddressArray = [];

      int receivingIndex = 0;
      int changeIndex = 0;

      // The gap limit will be capped at 20
      int receivingGapCounter = 0;
      int changeGapCounter = 0;

      await fillAddresses(suppliedMnemonic,
          NUMBER_OF_THREADS: Platform.numberOfProcessors - isolates.length - 1);

      var receiveDerivations = wallet.get('receiveDerivations');
      var changeDerivations = wallet.get('changeDerivations');

      // Deriving and checking for receiving addresses
      for (var i = 0; i < receiveDerivations.length; i++) {
        // Break out of loop when receivingGapCounter hits 20
        // Same gap limit for change as for receiving, breaks when it hits 20
        if (receivingGapCounter >= 20 && changeGapCounter >= 20) {
          break;
        }

        var receiveDerivation = receiveDerivations[i];
        final address = receiveDerivation['address'];

        var changeDerivation = changeDerivations[i];
        final _address = changeDerivation['address'];
        dynamic futureNumTxs = null;
        dynamic _futureNumTxs = null;
        if (receivingGapCounter < 20) {
          futureNumTxs = _getReceivedTxCount(address: address);
        }
        if (changeGapCounter < 20) {
          _futureNumTxs = _getReceivedTxCount(address: _address);
        }
        try {
          if (futureNumTxs != null) {
            int numTxs = await futureNumTxs;
            if (numTxs >= 1) {
              receivingIndex = i;
              receivingAddressArray.add(address);
            } else if (numTxs == 0) {
              receivingGapCounter += 1;
            }
          }
        } catch (e) {
          Logger.print(
              "Exception rethrown from recoverWalletFromBIP32SeedPhrase(): $e");
          throw e;
        }

        try {
          if (_futureNumTxs != null) {
            int numTxs = await _futureNumTxs;
            if (numTxs >= 1) {
              changeIndex = i;
              changeAddressArray.add(_address);
            } else if (numTxs == 0) {
              changeGapCounter += 1;
            }
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

      await wallet.put('receivingAddresses', receivingAddressArray);
      await wallet.put('changeAddresses', changeAddressArray);
      await wallet.put('receivingIndex', receivingIndex);
      await wallet.put('changeIndex', changeIndex);

      await _secureStore.write(
          key: '${this._walletId}_mnemonic', value: suppliedMnemonic.trim());
      for (int setId = 1; setId <= latestSetId; setId++) {
        setDataMap[setId] = await setDataMap[setId];
      }
      await _restore(latestSetId, setDataMap, await usedSerialNumbers);
      longMutex = false;
    } catch (e) {
      longMutex = false;
      Logger.print(
          "Exception rethrown from recoverWalletFromBIP32SeedPhrase(): $e");
      throw e;
    }
  }

  _restore(int latestSetId, Map setDataMap, dynamic usedSerialNumbers) async {
    final wallet = await Hive.openBox(this._walletId);
    final mnemonic = await _secureStore.read(key: '${this._walletId}_mnemonic');
    TransactionData data = await _txnData;
    final String currency = fetchPreferredCurrency();
    final Decimal currentPrice = await this._priceAPI.getPrice(
          ticker: this.coinTicker,
          baseCurrency: currency,
        );

    ReceivePort receivePort = await getIsolate({
      "function": "restore",
      "mnemonic": mnemonic,
      "transactionData": data,
      "currency": currency,
      "coinName": this.coinName,
      "latestSetId": latestSetId,
      "setDataMap": setDataMap,
      "usedSerialNumbers": usedSerialNumbers,
      "network": this._network,
      "cachedElectrumXClient": this.cachedElectrumXClient,
      "currentPrice": currentPrice,
    });

    var message = await receivePort.first;
    if (message is String) {
      Logger.print("restore() ->> this is a string");
      stop(receivePort);
      throw Exception("isolate restore failed.");
    }
    stop(receivePort);

    await wallet.put('mintIndex', message['mintIndex']);
    await wallet.put('_lelantus_coins', message['_lelantus_coins']);
    await wallet.put('jindex', message['jindex']);
    this._lelantusTransactionData = Future(() => message['newTxData']);

    await wallet.put('latest_lelantus_tx_model', message['newTxData']);
  }

  /// Changes the biometrics auth setting used on the lockscreen as an alternative
  /// to the pattern lock
  @override
  Future<void> updateBiometricsUsage(bool enabled) async {
    final wallet = await Hive.openBox(this._walletId);

    await wallet.put('use_biometrics', enabled);
    _useBiometrics = Future(() => enabled);
  }

  /// Switches preferred fiat currency for display and data fetching purposes
  void _changeCurrency(String newCurrency) {
    final wallet = Hive.box(this._walletId);
    wallet.put("preferredFiatCurrency", newCurrency);
    this._currency = newCurrency;
  }

  String fetchPreferredCurrency() {
    final wallet = Hive.box(this._walletId);
    final currency = wallet.get("preferredFiatCurrency");
    if (currency == null) {
      wallet.put("preferredFiatCurrency", "USD");
      return "USD";
    } else {
      return currency;
    }
  }

  Future<dynamic> _createJoinSplitTransaction(
      int spendAmount, String address, bool subtractFeeFromAmount) async {
    final price = await firoPrice;
    final wallet = await Hive.openBox(this._walletId);
    final mnemonic = await _secureStore.read(key: '${this._walletId}_mnemonic');
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
      "electrumXClient": this.electrumXClient,
      "cachedElectrumXClient": this.cachedElectrumXClient,
      "coinName": coinName,
      "network": _network,
    });
    var message = await receivePort.first;
    if (message is String) {
      Logger.print("Error in CreateJoinSplit: $message");
      stop(receivePort);
      return 3;
    }
    if (message is int) {
      stop(receivePort);
      return message;
    }
    stop(receivePort);
    Logger.print('Closing createJoinSplit!');
    return message;
  }

  Future<int> getLatestSetId() async {
    try {
      final id = await electrumXClient.getLatestCoinId();
      return id;
    } catch (e) {
      Logger.print("Exception rethrown in firo_wallet.dart: $e");
      throw e;
    }
  }

  Future<Map<String, dynamic>> getSetData(int setID) async {
    try {
      final response = await electrumXClient.getCoinsForRecovery(setId: setID);
      return response;
    } catch (e) {
      Logger.print("Exception rethrown in firo_wallet.dart: $e");
      throw e;
    }
  }

  Future<dynamic> getUsedCoinSerials() async {
    try {
      final response = await electrumXClient.getUsedCoinSerials();
      return response;
    } catch (e) {
      Logger.print("Exception rethrown in firo_wallet.dart: $e");
      throw e;
    }
  }

  @override
  Future<void> exit() async {
    _nodesChangedListener?.cancel();
    _nodesChangedListener = null;
    timer?.cancel();
    timer = null;
  }
}
