import 'package:decimal/decimal.dart';
import 'package:hive/hive.dart';
import 'package:paymint/utilities/misc_global_constants.dart';

part 'type_adaptors/transactions_model.g.dart';

String extractDateFromTimestamp(int timestamp) {
  if (timestamp == 0 || timestamp == null) {
    return 'Now...';
  }

  final int day = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).day;
  final int month = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).month;
  final int year = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).year;

  return '$year${month < 10 ? "0" + month.toString() : month.toString()}${day < 10 ? "0" + day.toString() : day.toString()}';
}

// @HiveType(typeId: 1)
class TransactionData {
  // @HiveField(0)
  final List<TransactionChunk> txChunks;

  TransactionData({this.txChunks});

  factory TransactionData.fromJson(Map<String, dynamic> json) {
    var dateTimeChunks = json['dateTimeChunks'] as List;
    List<TransactionChunk> chunksList = dateTimeChunks
        .map((txChunk) => TransactionChunk.fromJson(txChunk))
        .toList();

    return TransactionData(txChunks: chunksList);
  }

  factory TransactionData.fromMap(Map<String, Transaction> transactions) {
    Map<String, List<Transaction>> chunks = Map();
    transactions.forEach((key, value) {
      String date = extractDateFromTimestamp(value.timestamp);
      if (!chunks.containsKey(date)) {
        chunks[date] = [];
      }
      chunks[date].add(value);
    });
    List<TransactionChunk> chunksList = [];
    chunks.forEach((key, value) {
      value.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      chunksList.add(
          TransactionChunk(timestamp: value[0].timestamp, transactions: value));
    });
    chunksList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return TransactionData(txChunks: chunksList);
  }

  Transaction findTransaction(String txid) {
    for (var i = 0; i < txChunks.length; i++) {
      var txChunk = txChunks[i].transactions;
      for (var j = 0; j < txChunk.length; j++) {
        var tx = txChunk[j];
        if (tx.txid == txid) {
          return tx;
        }
      }
    }
    return null;
  }

  Map<String, Transaction> getAllTransactions() {
    Map<String, Transaction> transactions = Map();
    for (var i = 0; i < txChunks.length; i++) {
      var txChunk = txChunks[i].transactions;
      for (var j = 0; j < txChunk.length; j++) {
        var tx = txChunk[j];
        transactions[tx.txid] = tx;
      }
    }
    return transactions;
  }
}

// @HiveType(typeId: 2)
class TransactionChunk {
  // @HiveField(0)
  final int timestamp;
  // @HiveField(1)
  final List<Transaction> transactions;

  TransactionChunk({this.timestamp, this.transactions});

  factory TransactionChunk.fromJson(Map<String, dynamic> json) {
    var txArray = json['transactions'] as List;
    List<Transaction> txList =
        txArray.map((tx) => Transaction.fromJson(tx)).toList();

    return TransactionChunk(timestamp: json['timestamp'], transactions: txList);
  }

  String toString() {
    String transaction = "timestamp: $timestamp transactions: [\n";
    for (final tx in transactions) {
      transaction += "    $tx \n";
    }
    transaction += "]";

    return transaction;
  }
}

// @HiveType(typeId: 3)
class Transaction {
  // @HiveField(0)
  final String txid;
  // @HiveField(1)
  final bool confirmedStatus;
  // @HiveField(2)
  final int timestamp;
  // @HiveField(3)
  final String txType;
  // @HiveField(4)
  final int amount;
  // @HiveField(5)
  final List aliens;

  /// Keep worthNow as dynamic
  // @HiveField(6)
  final dynamic worthNow;

  /// worthAtBlockTimestamp has to be dynamic in case the server fucks up the price quote and returns null instead of a double
  // @HiveField(7)
  final dynamic worthAtBlockTimestamp;
  // @HiveField(8)
  final int fees;
  // @HiveField(9)
  final int inputSize;
  // @HiveField(10)
  final int outputSize;
  // @HiveField(11)
  final List<Input> inputs;
  // @HiveField(12)
  final List<Output> outputs;
  // @HiveField(13)
  final String address;
  // @HiveField(14)
  final int height;
  // @HiveField(15)
  final String subType;

  Transaction(
      {this.txid,
      this.confirmedStatus,
      this.timestamp,
      this.txType,
      this.amount,
      this.aliens,
      this.worthNow,
      this.worthAtBlockTimestamp,
      this.fees,
      this.inputSize,
      this.outputSize,
      this.inputs,
      this.outputs,
      this.address,
      this.height,
      this.subType});

  factory Transaction.fromJson(Map<String, dynamic> json) {
    var inputArray = json['inputs'] as List;
    var outputArray = json['outputs'] as List;

    List<Input> inputList = inputArray
        .map((input) => Input.fromJson(Map<String, dynamic>.from(input)))
        .toList();
    List<Output> outputList = outputArray
        .map((output) => Output.fromJson(Map<String, dynamic>.from(output)))
        .toList();

    return Transaction(
        txid: json['txid'],
        confirmedStatus: json['confirmed_status'],
        timestamp: json['timestamp'],
        txType: json['txType'],
        amount: json['amount'],
        aliens: json['aliens'],
        worthNow: json['worthNow'],
        worthAtBlockTimestamp: json['worthAtBlockTimestamp'],
        fees: json['fees'],
        inputSize: json['inputSize'],
        outputSize: json['outputSize'],
        inputs: inputList,
        outputs: outputList,
        address: json['address'],
        height: json['height'],
        subType: json["subType"]);
  }

  factory Transaction.fromLelantusJson(Map<String, dynamic> json) {
    return Transaction(
        txid: json['txid'],
        confirmedStatus: json['confirmed_status'],
        timestamp: json['timestamp'],
        txType: json['txType'],
        amount: (Decimal.parse(json["amount"].toString()) *
                Decimal.fromInt(CampfireConstants.satsPerCoin))
            .toBigInt()
            .toInt(),
        aliens: [],
        worthNow: json['worthNow'],
        worthAtBlockTimestamp: json['worthAtBlockTimestamp'],
        fees: (Decimal.parse(json["fees"].toString()) *
                Decimal.fromInt(CampfireConstants.satsPerCoin))
            .toBigInt()
            .toInt(),
        inputSize: json['inputSize'],
        outputSize: json['outputSize'],
        inputs: [],
        outputs: [],
        address: json["address"],
        height: json["height"],
        subType: json["subType"]);
  }

  bool get isMinting {
    if (this.subType is String && this.subType.toLowerCase() == "mint") {
      return this.confirmedStatus is bool && !this.confirmedStatus;
    }
    return false;
  }

  copyWith(
      {txid: null,
      confirmedStatus: null,
      timestamp: null,
      txType: null,
      amount: null,
      aliens: null,
      worthNow: null,
      worthAtBlockTimestamp: null,
      fees: null,
      inputSize: null,
      outputSize: null,
      inputs: null,
      outputs: null,
      address: null,
      height: null,
      subType: null}) {
    return Transaction(
      txid: txid ?? this.txid,
      confirmedStatus: confirmedStatus ?? this.confirmedStatus,
      timestamp: timestamp ?? this.timestamp,
      txType: txType ?? this.txType,
      amount: amount ?? this.amount,
      aliens: aliens ?? this.aliens,
      worthNow: worthNow ?? this.worthNow,
      worthAtBlockTimestamp:
          worthAtBlockTimestamp ?? this.worthAtBlockTimestamp,
      fees: fees ?? this.fees,
      inputSize: inputSize ?? this.inputSize,
      outputSize: outputSize ?? this.outputSize,
      inputs: inputs ?? this.inputs,
      outputs: outputs ?? this.outputs,
      address: address ?? this.address,
      height: height ?? this.height,
      subType: subType ?? this.subType,
    );
  }

  String toString() {
    String transaction =
        "{txid: $txid, type: $txType, subType: $subType, value: $amount, fee: $fees, height: $height, confirm: $confirmedStatus, address: $address, timestamp: $timestamp, worthNow: $worthNow, inputs: $inputs }";
    return transaction;
  }
}

// @HiveType(typeId: 4)
class Input {
  // @HiveField(0)
  final String txid;
  // @HiveField(1)
  final int vout;
  // @HiveField(2)
  final Output prevout;
  // @HiveField(3)
  final String scriptsig;
  // @HiveField(4)
  final String scriptsigAsm;
  // @HiveField(5)
  final List<dynamic> witness;
  // @HiveField(6)
  final bool isCoinbase;
  // @HiveField(7)
  final int sequence;
  // @HiveField(8)
  final String innerRedeemscriptAsm;

  Input(
      {this.txid,
      this.vout,
      this.prevout,
      this.scriptsig,
      this.scriptsigAsm,
      this.witness,
      this.isCoinbase,
      this.sequence,
      this.innerRedeemscriptAsm});

  factory Input.fromJson(Map<String, dynamic> json) {
    bool iscoinBase = json['coinbase'] != null;
    return Input(
      txid: json['txid'],
      vout: json['vout'],
      // electrumx calls do not return prevout so we set this to null for now
      prevout: null, //Output.fromJson(json['prevout']),
      scriptsig: iscoinBase ? "" : json['scriptSig']['hex'] as String,
      scriptsigAsm: iscoinBase ? "" : json['scriptSig']['asm'] as String,
      witness: json['witness'],
      isCoinbase: iscoinBase ? iscoinBase : json['is_coinbase'] as bool,
      sequence: json['sequence'],
      innerRedeemscriptAsm: json['innerRedeemscriptAsm'] as String ?? "",
    );
  }

  String toString() {
    String transaction = "{txid: $txid}";
    return transaction;
  }
}

// @HiveType(typeId: 5)
class Output {
  // @HiveField(0)
  final String scriptpubkey;
  // @HiveField(1)
  final String scriptpubkeyAsm;
  // @HiveField(2)
  final String scriptpubkeyType;
  // @HiveField(3)
  final String scriptpubkeyAddress;
  // @HiveField(4)
  final int value;

  Output(
      {this.scriptpubkey,
      this.scriptpubkeyAsm,
      this.scriptpubkeyType,
      this.scriptpubkeyAddress,
      this.value});

  factory Output.fromJson(Map<String, dynamic> json) {
    // TODO determine if any of this code is needed.
    final address = json["scriptPubKey"]["addresses"] == null
        ? json['scriptPubKey']['type']
        : json["scriptPubKey"]["addresses"][0];
    return Output(
      scriptpubkey: json['scriptPubKey']['hex'],
      scriptpubkeyAsm: json['scriptPubKey']['asm'],
      scriptpubkeyType: json['scriptPubKey']['type'],
      scriptpubkeyAddress: address,
      value: (Decimal.parse(json["value"].toString()) *
              Decimal.fromInt(CampfireConstants.satsPerCoin))
          .toBigInt()
          .toInt(),
    );
  }
}
