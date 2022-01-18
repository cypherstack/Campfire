import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:firo_flutter/firo_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:lelantus/lelantus.dart';
import 'package:paymint/models/models.dart';
import 'package:paymint/models/models.dart' as models;
import 'package:paymint/services/event_bus/events/refresh_percent_changed_event.dart';
import 'package:paymint/services/event_bus/events/wallet_name_changed_event.dart';
import 'package:paymint/services/event_bus/global_event_bus.dart';
import 'package:paymint/services/globals.dart';
import 'package:paymint/services/utils/currency_utils.dart';
import 'package:paymint/services/wallets_service.dart';
import 'package:paymint/utilities/misc_global_constants.dart';
import 'package:uuid/uuid.dart';

import '../models/lelantus_coin.dart';
import 'event_bus/events/nodes_changed_event.dart';
import 'events.dart';

const JMINT_INDEX = 5;
const MINT_INDEX = 2;
const TRANSACTION_LELANTUS = 8;
const ANONYMITY_SET_EMPTY_ID = 0;
const MIDDLE_SERVER = 'https://marcomiddle.cypherstack.com';

class FeeData {
  int changeToMint;
  int fee;
  List<int> spendCoinIndexes;
  FeeData(this.changeToMint, this.fee, this.spendCoinIndexes);
}

class BitcoinService extends ChangeNotifier {
  /// Holds final balances, all utxos under control
  Future<UtxoData> _utxoData;
  Future<UtxoData> get utxoData => _utxoData;

  /// Holds wallet transaction data
  Future<TransactionData> _transactionData;
  Future<TransactionData> get transactionData => _transactionData;

  /// Holds wallet lelantus transaction data
  Future<TransactionData> _lelantusTransactionData;
  Future<TransactionData> get lelantusTransactionData =>
      _lelantusTransactionData;

  /// Holds the max fee that can be sent
  Future<FeeData> _maxFee;
  Future<FeeData> get maxFee => _maxFee;

  /// Holds the current balance data
  Future<List<String>> _balance;
  Future<List<String>> get balance => _balance;

  /// Holds all outputs for wallet, used for displaying utxos in app security view
  List<UtxoObject> _outputsList = [];
  List<UtxoObject> get allOutputs => _outputsList;

  // Hold the current price of Bitcoin in the currency specified in parameter below
  Future<dynamic> _bitcoinPrice;
  Future<dynamic> get bitcoinPrice => _bitcoinPrice ??= getBitcoinPrice();

  Future<FeeObject> _feeObject;
  Future<FeeObject> get fees => _feeObject ??= getFees();

  Future<String> _marketInfo;
  Future<String> get marketInfo => _marketInfo ??= getMarketInfo();

  /// Holds preferred fiat currency
  Future<String> _currency;
  Future<String> get currency =>
      _currency ??= CurrencyUtilities.fetchPreferredCurrency();

  /// Holds updated receiving address
  Future<String> _currentReceivingAddress;
  Future<String> get currentReceivingAddress => _currentReceivingAddress;

  Future<bool> _useBiometrics;
  Future<bool> get useBiometrics => _useBiometrics;

  Future<String> _currentWalletName;
  Future<String> get currentWalletName =>
      _currentWalletName ??= _fetchCurrentWalletName();

  clearWalletData() async {
    Future<UtxoData> _utxoData;
    Future<TransactionData> _transactionData;
    Future<TransactionData> _lelantusTransactionData;
    Future<FeeData> _maxFee;
    Future<List<String>> _balance;
    List<UtxoObject> _outputsList = [];
    Future<dynamic> _bitcoinPrice;
    Future<FeeObject> _feeObject;
    Future<String> _marketInfo;
    Future<String> _currency;
    Future<String> _currentReceivingAddress;
    Future<bool> _useBiometrics;
    Future<String> _currentWalletName;
    this._utxoData = _utxoData;
    this._transactionData = _transactionData;
    this._lelantusTransactionData = _lelantusTransactionData;
    this._maxFee = _maxFee;
    this._balance = _balance;
    this._outputsList = _outputsList;
    this._bitcoinPrice = _bitcoinPrice;
    this._feeObject = _feeObject;
    this._marketInfo = _marketInfo;
    this._currency = _currency;
    this._currentReceivingAddress = _currentReceivingAddress;
    this._useBiometrics = _useBiometrics;
    this._currentWalletName = _currentWalletName;
  }

  final firo = new NetworkType(
      messagePrefix: '\x18Zcoin Signed Message:\n',
      bech32: 'bc',
      bip32: new Bip32Type(public: 0x0488b21e, private: 0x0488ade4),
      pubKeyHash: 0x52,
      scriptHash: 0x07,
      wif: 0xd2);

  final firoNetworkType = new bip32.NetworkType(
      wif: 0xd2,
      bip32: new bip32.Bip32Type(public: 0x0488b21e, private: 0x0488ade4));

  BitcoinService() {
    final wallets = Hive.box('wallets');
    final String currentName = wallets.get('currentWalletName');
    if (currentName == null || currentName.isEmpty) {
      return;
    }
    // add listener for active wallet changed
    GlobalEventBus.instance.on<ActiveWalletNameChangedEvent>().listen((event) {
      _currentWalletName = Future(() => event.currentWallet);
    });

    // add listener for nodes changed
    GlobalEventBus.instance.on<NodesChangedEvent>().listen((event) {
      refreshWalletData();
    });

    _currency = CurrencyUtilities.fetchPreferredCurrency();

    _initializeBitcoinWallet().whenComplete(() {
      _utxoData = _fetchUtxoData();
      _transactionData = _fetchTransactionData();
      // DevUtilities.checkReceivingAndChangeArrays();
    }).whenComplete(() => checkReceivingAddressForTransactions());
  }

  Future<String> _fetchCurrentWalletName() async {
    final wallets = await Hive.openBox('wallets');
    final currentName = await wallets.get('currentWalletName');
    return currentName;
  }

  bool validateFiroAddress(String address) {
    return Address.validateAddress(address, firo);
  }

  // TODO cache this
  Future<String> _getWalletId() async {
    final _currentWallet = await currentWalletName;
    final wallets = await Hive.openBox('wallets');
    final names = await wallets.get('names');
    final id = names[_currentWallet];
    return id;
  }

  Future<List<String>> getMnemonicList() async {
    final id = await _getWalletId();
    final secureStore = new FlutterSecureStorage();
    final mnemonicString = await secureStore.read(key: '${id}_mnemonic');
    final List<String> data = mnemonicString.split(' ');
    return data;
  }

  /// Initializes the user's wallet and sets class getters. Will create a wallet if one does not
  /// already exist.
  Future<void> _initializeBitcoinWallet() async {
    final id = await _getWalletId();
    final wallet = await Hive.openBox(id);

    if (wallet.isEmpty) {
      // Triggers for new users automatically. Generates new wallet
      await _generateNewWallet(wallet);
      wallet.put("id", id);
      _lelantusTransactionData = getLelantusTransactionData();
    } else {
      // Wallet already exists, triggers for a returning user
      _lelantusTransactionData = getLelantusTransactionData();
      this._currentReceivingAddress = _getCurrentAddressForChain(0);
      this._useBiometrics = Future(
        () async => await wallet.get('use_biometrics'),
      );
    }
  }

  /// Initializes the wallet [name], set [currentWalletName] and sets class getters. Will create a wallet if one does not
  /// already exist.
  Future<void> initializeWallet(String name) async {
    print("initializeBitcoinWallet called manually");
    this._currentWalletName = Future(() => name);
    await _initializeBitcoinWallet();
  }

  Future<TransactionData> getLelantusTransactionData() async {
    final id = await _getWalletId();
    final wallet = await Hive.openBox(id);

    final latestModel = await wallet.get('latest_lelantus_tx_model');

    if (latestModel == null) {
      final emptyModel = {"dateTimeChunks": []};
      return TransactionData.fromJson(emptyModel);
    } else {
      print("Old transaction model located");
      return latestModel;
    }
  }

  /// Generates initial wallet values such as mnemonic, chain (receive/change) arrays and indexes.
  Future<void> _generateNewWallet(Box<dynamic> wallet) async {
    final id = await _getWalletId();
    final secureStore = new FlutterSecureStorage();
    await secureStore.write(
        key: '${id}_mnemonic', value: bip39.generateMnemonic(strength: 256));
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
        "port": "",
      }
    });
    await wallet.put('nodes', nodes);
    await wallet.put('jindex', []);
    await wallet.put('activeNodeName', CampfireConstants.defaultNodeName);
    // Generate and add addresses to relevant arrays
    final initialReceivingAddress = await generateAddressForChain(0, 0);
    final initialChangeAddress = await generateAddressForChain(1, 0);
    await addToAddressesArrayForChain(initialReceivingAddress, 0);
    await addToAddressesArrayForChain(initialChangeAddress, 1);
    this._currentReceivingAddress = Future(() => initialReceivingAddress);
    this._useBiometrics = Future(
      () async => await wallet.get('use_biometrics'),
    );
  }

  Future<bool> _fetchUseBiometrics() async {
    final id = await _getWalletId();
    final wallet = await Hive.openBox(id);
    final useBiometrics = await wallet.get('use_biometrics');
    return useBiometrics;
  }

  /// Refreshes display data for the wallet
  refreshWalletData() async {
    GlobalEventBus.instance
        .fire(NodeConnectionStatusChangedEvent(NodeConnectionStatus.loading));

    GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.0));

    final UtxoData newUtxoData = await _fetchUtxoData();
    GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.05));

    final TransactionData newTxData = await _fetchTransactionData();
    GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.1));

    final dynamic newBtcPrice = await getBitcoinPrice();
    GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.15));

    final FeeObject feeObj = await getFees();
    GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.2));

    final String currentName = await WalletsService().currentWalletName;
    GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.30));

    await checkReceivingAddressForTransactions();
    GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.40));

    final useBiometrics = await _fetchUseBiometrics();
    GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.50));

    this._currentWalletName = Future(() => currentName);
    this._utxoData = Future(() => newUtxoData);
    this._transactionData = Future(() => newTxData);
    this._bitcoinPrice = Future(() => newBtcPrice);
    this._feeObject = Future(() => feeObj);
    this._marketInfo = Future(() => marketInfo);
    this._useBiometrics = Future(() => useBiometrics);
    GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.60));

    final id = await _getWalletId();
    GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.70));

    final wallet = await Hive.openBox(id);
    GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.80));

    final Map _lelantus_coins = await wallet.get('_lelantus_coins');
    GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.90));

    logPrint(_lelantus_coins);

    await _refreshLelantusData();
    GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.93));

    await autoMint();
    GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.95));

    var balance = await getFullBalance();
    GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.97));

    final maxFees = await estimateJoinSplitFee(
        (double.parse(balance[0]) * 100000000).toInt(), true);
    GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.99));

    this._maxFee = Future(() => maxFees);
    balance.add((double.parse(balance[0]) - (maxFees.fee / 100000000))
        .toStringAsFixed(8));
    this._balance = Future(() => balance);

    GlobalEventBus.instance.fire(RefreshPercentChangedEvent(1.0));

    GlobalEventBus.instance
        .fire(NodeConnectionStatusChangedEvent(NodeConnectionStatus.synced));
    notifyListeners();
  }

  /// Generates a new internal or external chain address for the wallet using a BIP84 derivation path.
  /// [chain] - Use 0 for receiving (external), 1 for change (internal). Should not be any other value!
  /// [index] - This can be any integer >= 0
  Future<String> generateAddressForChain(int chain, int index) async {
    final id = await _getWalletId();
    final secureStore = new FlutterSecureStorage();
    final mnemonic = await secureStore.read(key: '${id}_mnemonic');
    final seed = bip39.mnemonicToSeed(mnemonic);
    final root = bip32.BIP32.fromSeed(seed);
    final node = root.derivePath("m/44'/136'/0'/$chain/$index");

    return P2PKH(network: firo, data: new PaymentData(pubkey: node.publicKey))
        .data
        .address;
  }

  /// Increases the index for either the internal or external chain, depending on [chain].
  /// [chain] - Use 0 for receiving (external), 1 for change (internal). Should not be any other value!
  Future<void> incrementAddressIndexForChain(int chain) async {
    final id = await _getWalletId();
    final wallet = await Hive.openBox(id);
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
  Future<void> addToAddressesArrayForChain(String address, int chain) async {
    final id = await _getWalletId();
    final wallet = await Hive.openBox(id);
    String chainArray = '';
    if (chain == 0) {
      chainArray = 'receivingAddresses';
    } else {
      chainArray = 'changeAddresses';
    }

    final addressArray = wallet.get(chainArray);
    if (addressArray == null) {
      print('Attempting to add the following to array for chain $chain:' +
          [address].toString());
      await wallet.put(chainArray, [address]);
    } else {
      // Make a deep copy of the exisiting list
      final newArray = [];
      addressArray.forEach((_address) => newArray.add(_address));
      newArray.add(address); // Add the address passed into the method
      await wallet.put(chainArray, newArray);
    }
  }

  /// Returns the latest receiving/change (external/internal) address for the wallet depending on [chain]
  /// [chain] - Use 0 for receiving (external), 1 for change (internal). Should not be any other value!
  Future<String> _getCurrentAddressForChain(int chain) async {
    final id = await _getWalletId();
    final wallet = await Hive.openBox(id);
    if (chain == 0) {
      final externalChainArray = await wallet.get('receivingAddresses');
      return externalChainArray.last;
    } else {
      // Here, we assume that chain == 1
      final internalChainArray = await wallet.get('changeAddresses');
      return internalChainArray.last;
    }
  }

  void blockOutput(String txid) {
    for (var i = 0; i < allOutputs.length; i++) {
      if (allOutputs[i].txid == txid) {
        allOutputs[i].blocked = true;
        notifyListeners();
      }
    }
  }

  void unblockOutput(String txid) {
    for (var i = 0; i < allOutputs.length; i++) {
      if (allOutputs[i].txid == txid) {
        allOutputs[i].blocked = false;
        notifyListeners();
      }
    }
  }

  void renameOutput(String txid, String newName) {
    for (var i = 0; i < allOutputs.length; i++) {
      if (allOutputs[i].txid == txid) {
        allOutputs[i].txName = newName;
        notifyListeners();
      }
    }
  }

  /// Changes the biometrics auth setting used on the lockscreen as an alternative
  /// to the pattern lock
  updateBiometricsUsage(bool enabled) async {
    final id = await _getWalletId();
    final wallet = await Hive.openBox(id);

    await wallet.put('use_biometrics', enabled);
    _useBiometrics = Future(() => enabled);

    notifyListeners();
  }

  /// Switches preferred fiat currency for display and data fetching purposes
  changeCurrency(String newCurrency) async {
    final prefs = await Hive.openBox('prefs');
    await prefs.put('currency', newCurrency);
    this._currency = Future(() => newCurrency);
    notifyListeners();
  }

  /// Takes in a list of UtxoObjects and adds a name (dependent on object index within list)
  /// and checks for the txid associated with the utxo being blocked and marks it accordingly.
  /// Now also checks for output labeling.
  _sortOutputs(List<UtxoObject> utxos) async {
    final id = await _getWalletId();
    final wallet = await Hive.openBox(id);
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
    notifyListeners();
  }

  /// The coinselection algorithm decides whether or not the user is eligible to make the transaction
  /// with [satoshiAmountToSend] and [selectedTxFee]. If so, it will call buildTrasaction() and return
  /// a map containing the tx hex along with other important information. If not, then it will return
  /// an integer (1 or 2)
  dynamic coinSelection(int satoshiAmountToSend, dynamic selectedTxFee,
      String _recipientAddress) async {
    return 1;
    final List<UtxoObject> availableOutputs = this.allOutputs;
    final List<UtxoObject> spendableOutputs = [];
    int spendableSatoshiValue = 0;

    // Build list of spendable outputs and totaling their satoshi amount
    for (var i = 0; i < availableOutputs.length; i++) {
      if (availableOutputs[i].blocked == false &&
          availableOutputs[i].status.confirmed == true) {
        spendableOutputs.add(availableOutputs[i]);
        spendableSatoshiValue += availableOutputs[i].value;
      }
    }

    // If the amount the user is trying to send is smaller than the amount that they have spendable,
    // then return 1, which indicates that they have an insufficient balance.
    if (spendableSatoshiValue < satoshiAmountToSend) {
      return 1;
      // If the amount the user wants to send is exactly equal to the amount they can spend, then return
      // 2, which indicates that they are not leaving enough over to pay the transaction fee
    } else if (spendableSatoshiValue == satoshiAmountToSend) {
      return 2;
    }
    // If neither of these statements pass, we assume that the user has a spendable balance greater
    // than the amount they're attempting to send. Note that this value still does not account for
    // the added transaction fee, which may require an extra input and will need to be checked for
    // later on.

    // Possible situation right here
    int satoshisBeingUsed = 0;
    int inputsBeingConsumed = 0;
    List<UtxoObject> utxoObjectsToUse = [];

    for (var i = 0; satoshisBeingUsed <= satoshiAmountToSend; i++) {
      utxoObjectsToUse.add(spendableOutputs[i]);
      satoshisBeingUsed += spendableOutputs[i].value;
      inputsBeingConsumed += 1;
    }

    // numberOfOutputs' length must always be equal to that of recipientsArray and recipientsAmtArray
    List<String> recipientsArray = [_recipientAddress];
    List<int> recipientsAmtArray = [satoshiAmountToSend];

    // https://bitcoin.stackexchange.com/questions/1195/how-to-calculate-transaction-size-before-sending-legacy-non-segwit-p2pkh-p2sh/3011#3011
    // Assume 1 output, only for recipient and no change
    final feeForOneOutput =
        ((((inputsBeingConsumed * 180 + 1 * 34 + 10 + inputsBeingConsumed) /
                        1024.0) *
                    selectedTxFee) *
                100000000)
            .ceil();
    // Assume 2 outputs, one for recipient and one for change
    final feeForTwoOutputs =
        ((((inputsBeingConsumed * 180 + 2 * 34 + 10 + inputsBeingConsumed) /
                        1024.0) *
                    selectedTxFee) *
                100000000)
            .ceil();

    if (satoshisBeingUsed - satoshiAmountToSend > feeForOneOutput) {
      if (satoshisBeingUsed - satoshiAmountToSend > feeForOneOutput + 293) {
        // Here, we know that theoretically, we may be able to include another output(change) but we first need to
        // factor in the value of this output in satoshis.
        int changeOutputSize =
            satoshisBeingUsed - satoshiAmountToSend - feeForTwoOutputs;
        // We check to see if the user can pay for the new transaction with 2 outputs instead of one. Iff they can and
        // the second output's size > 293 satoshis, we perform the mechanics required to properly generate and use a new
        // change address.
        if (changeOutputSize > 293 &&
            satoshisBeingUsed - satoshiAmountToSend - changeOutputSize ==
                feeForTwoOutputs) {
          await incrementAddressIndexForChain(1);
          final id = await _getWalletId();
          final wallet = await Hive.openBox(id);
          final int changeIndex = await wallet.get('changeIndex');
          final String newChangeAddress =
              await generateAddressForChain(1, changeIndex);
          await addToAddressesArrayForChain(newChangeAddress, 1);
          recipientsArray.add(newChangeAddress);
          recipientsAmtArray.add(changeOutputSize);
          // At this point, we have the outputs we're going to use, the amounts to send along with which addresses
          // we intend to send these amounts to. We have enough to send instructions to build the transaction.
          print('2 outputs in tx');
          print('Input size: $satoshisBeingUsed');
          print('Recipient output size: $satoshiAmountToSend');
          print('Change Output Size: $changeOutputSize');
          dynamic hex = await buildTransaction(
              utxoObjectsToUse, recipientsArray, recipientsAmtArray);
          Map<String, dynamic> transactionObject = {
            "hex": hex,
            "recipient": recipientsArray[0],
            "recipientAmt": recipientsAmtArray[0],
            "fee": satoshisBeingUsed - satoshiAmountToSend - changeOutputSize
          };
          return transactionObject;
        } else {
          // Something went wrong here. It either overshot or undershot the estimated fee amount or the changeOutputSize
          // is smaller than or equal to 293. Revert to single output transaction.
          print('1 output in tx');
          print('Input size: $satoshisBeingUsed');
          print('Recipient output size: $satoshiAmountToSend');
          print('Difference (fee being paid): ' +
              (satoshisBeingUsed - satoshiAmountToSend).toString() +
              ' sats');
          print('Actual fee: $feeForOneOutput');
          dynamic hex = await buildTransaction(
              utxoObjectsToUse, recipientsArray, recipientsAmtArray);
          Map<String, dynamic> transactionObject = {
            "hex": hex,
            "recipient": recipientsArray[0],
            "recipientAmt": recipientsAmtArray[0],
            "fee": satoshisBeingUsed - satoshiAmountToSend
          };
          return transactionObject;
        }
      } else {
        // No additional outputs needed since adding one would mean that it'd be smaller than 293 sats
        // which makes it uneconomical to add to the transaction. Here, we pass data directly to instruct
        // the wallet to begin crafting the transaction that the user requested.
        print('1 output in tx');
        print('Input size: $satoshisBeingUsed');
        print('Recipient output size: $satoshiAmountToSend');
        print('Difference (fee being paid): ' +
            (satoshisBeingUsed - satoshiAmountToSend).toString() +
            ' sats');
        print('Actual fee: $feeForOneOutput');
        dynamic hex = await buildTransaction(
            utxoObjectsToUse, recipientsArray, recipientsAmtArray);
        Map<String, dynamic> transactionObject = {
          "hex": hex,
          "recipient": recipientsArray[0],
          "recipientAmt": recipientsAmtArray[0],
          "fee": satoshisBeingUsed - satoshiAmountToSend
        };
        return transactionObject;
      }
    } else if (satoshisBeingUsed - satoshiAmountToSend == feeForOneOutput) {
      // In this scenario, no additional change output is needed since inputs - outputs equal exactly
      // what we need to pay for fees. Here, we pass data directly to instruct the wallet to begin
      // crafting the transaction that the user requested.
      print('1 output in tx');
      print('Input size: $satoshisBeingUsed');
      print('Recipient output size: $satoshiAmountToSend');
      print('Fee being paid: ' +
          (satoshisBeingUsed - satoshiAmountToSend).toString() +
          ' sats');
      dynamic hex = await buildTransaction(
          utxoObjectsToUse, recipientsArray, recipientsAmtArray);
      Map<String, dynamic> transactionObject = {
        "hex": hex,
        "recipient": recipientsArray[0],
        "recipientAmt": recipientsAmtArray[0],
        "fee": feeForOneOutput
      };
      return transactionObject;
    } else {
      // Remember that returning 2 indicates that the user does not have a sufficient balance to
      // pay for the transaction fee. Ideally, at this stage, we should check if the user has any
      // additional outputs they're able to spend and then recalculate fees.
      print('Cannot pay tx fee - cancelling transaction');
      return 2;
    }
  }

  /// Builds and signs a transaction
  Future<dynamic> buildTransaction(List<UtxoObject> utxosToUse,
      List<String> recipients, List<int> satoshisPerRecipient) async {
    List<String> addressesToDerive = [];

    // Populating the addresses to derive
    for (var i = 0; i < utxosToUse.length; i++) {
      List<dynamic> lookupData = [utxosToUse[i].txid, utxosToUse[i].vout];
      Map<String, dynamic> requestBody = {
        "url": await getEsploraUrl(),
        "lookupData": lookupData,
      };

      final response = await http.post(
        Uri.parse('$MIDDLE_SERVER/voutLookup'),
        body: json.encode(requestBody),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        addressesToDerive.add(json.decode(response.body));
      } else {
        throw Exception('Something happened: ' +
            response.statusCode.toString() +
            response.body);
      }
    }

    final id = await _getWalletId();
    final secureStore = new FlutterSecureStorage();
    final seed =
        bip39.mnemonicToSeed(await secureStore.read(key: '${id}_mnemonic'));

    final root = bip32.BIP32.fromSeed(seed, firoNetworkType);

    List<ECPair> elipticCurvePairArray = [];
    List<Uint8List> outputDataArray = [];

    for (var i = 0; i < addressesToDerive.length; i++) {
      final addressToCheckFor = addressesToDerive[i];

      // TODO: where does '2000' come from?
      for (var i = 0; i < 2000; i++) {
        final nodeReceiving = root.derivePath("m/44'/136'/0'/0/$i");
        final nodeChange = root.derivePath("m/44'/136'/0'/1/$i");

        if (P2PKH(
                    network: firo,
                    data: new PaymentData(pubkey: nodeReceiving.publicKey))
                .data
                .address ==
            addressToCheckFor) {
          print('Receiving found on loop $i');
          elipticCurvePairArray
              .add(ECPair.fromWIF(nodeReceiving.toWIF(), network: firo));
          outputDataArray.add(P2PKH(
                  network: firo,
                  data: new PaymentData(pubkey: nodeReceiving.publicKey))
              .data
              .output);
          break;
        }
        if (P2PKH(
                    network: firo,
                    data: new PaymentData(pubkey: nodeChange.publicKey))
                .data
                .address ==
            addressToCheckFor) {
          print('Change found on loop $i');
          elipticCurvePairArray
              .add(ECPair.fromWIF(nodeChange.toWIF(), network: firo));

          outputDataArray.add(P2PKH(
                  network: firo,
                  data: new PaymentData(pubkey: nodeChange.publicKey))
              .data
              .output);
          break;
        }
      }
    }

    final txb = new TransactionBuilder(network: firo);
    // TODO should I set to version 2?
    txb.setVersion(1);

    // Add transaction inputs
    for (var i = 0; i < utxosToUse.length; i++) {
      txb.addInput(
          utxosToUse[i].txid, utxosToUse[i].vout, null, outputDataArray[i]);
    }
    // Add transaction outputs
    for (var i = 0; i < recipients.length; i++) {
      txb.addOutput(recipients[i], satoshisPerRecipient[i]);
    }

    // Sign the transaction accordingly
    for (var i = 0; i < utxosToUse.length; i++) {
      txb.sign(
        vin: i,
        keyPair: elipticCurvePairArray[i],
        witnessValue: utxosToUse[i].value,
      );
    }
    String builtHex = txb.build().toHex();
    print(builtHex);
    return builtHex;
  }

  Future<String> getEsploraUrl() async {
    final id = await _getWalletId();
    final wallet = await Hive.openBox(id);
    final String url = await wallet.get('esplora_url');

    if (url == null) {
      // final blockstreamUrl = 'https://marco.cypherstack.com/api/FIRO/mainnet/';
      print('Using blockstream for esplora server');
      await wallet.put('esplora_url', CampfireConstants.defaultNodeUrl);
      return CampfireConstants.defaultNodeUrl;
    } else {
      return url;
    }
  }

  Future<bool> submitLelantusToNetwork(dynamic transactionInfo) async {
    final success = await submitHexToNetwork(transactionInfo['txHex']);
    if (success) {
      final id = await _getWalletId();
      final wallet = await Hive.openBox(id);
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
        logPrint(newTxData.txChunks);
        // TODO uncomment this
        await wallet.put('latest_lelantus_tx_model', newTxData);
        var ldata = await wallet.get('latest_lelantus_tx_model');
        _lelantusTransactionData = Future(() => ldata);
      } else {
        // This is a mint
        print("this is a mint");

        LelantusCoin mint = LelantusCoin(index, transactionInfo['value'],
            transactionInfo['publicCoin'], transactionInfo['txid'], 1, false);
        if (mint.value > 0) {
          coins[mint.txId] = mint;
          //TODO uncomment this
          await wallet.put('mintIndex', index + 1);
        }
        logPrint(coins);
        // TODO uncomment this
        await wallet.put('_lelantus_coins', coins);
      }
      //TODO change to true
      return true;
    } else {
      print("Failed to send to network");
      return false;
    }
  }

  Future<bool> submitHexToNetwork(String hex) async {
    final Map<String, dynamic> obj = {
      "url": await getEsploraUrl(),
      "rawTx": hex,
    };

    final res = await http.post(
      Uri.parse('$MIDDLE_SERVER/pushtx'),
      body: jsonEncode(obj),
      headers: {'Content-Type': 'application/json'},
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      print(res.body.toString());
      if (res.body.toString().contains("error") ||
          res.body.toString().contains("Error")) {
        return false;
      }
      return true;
    } else {
      print(res.body.toString());
      return false;
    }
  }

  Future<UtxoData> _fetchUtxoData() async {
    final id = await _getWalletId();
    final wallet = await Hive.openBox(id);
    final List<String> allAddresses = [];
    final String currency = await CurrencyUtilities.fetchPreferredCurrency();
    print('currency: ' + currency);
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

    final Map<String, dynamic> requestBody = {
      "currency": currency,
      "allAddresses": allAddresses,
      "url": await getEsploraUrl(),
    };

    try {
      final response = await http.post(
        Uri.parse('$MIDDLE_SERVER/outputData'),
        body: jsonEncode(requestBody),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Outputs fetched');
        final List<UtxoObject> allOutputs =
            UtxoData.fromJson(json.decode(response.body)).unspentOutputArray;
        print(allOutputs);
        await _sortOutputs(allOutputs);
        await wallet.put(
            'latest_utxo_model', UtxoData.fromJson(json.decode(response.body)));
        notifyListeners();
        // print(json.decode(response.body));
        return UtxoData.fromJson(json.decode(response.body));
      } else {
        print("Output fetch unsuccessful");
        final latestTxModel = await wallet.get('latest_utxo_model');

        if (latestTxModel == null) {
          final currency = await CurrencyUtilities.fetchPreferredCurrency();
          final currencySymbol = currencyMap[currency];

          final emptyModel = {
            "total_user_currency": "${currencySymbol}0.00",
            "total_sats": 0,
            "total_btc": 0,
            "outputArray": []
          };
          return UtxoData.fromJson(emptyModel);
        } else {
          print("Old output model located");
          return latestTxModel;
        }
      }
    } catch (e) {
      print("Output fetch unsuccessful");
      print(e);
      final latestTxModel = await wallet.get('latest_utxo_model');
      final currency = await CurrencyUtilities.fetchPreferredCurrency();
      final currencySymbol = currencyMap[currency];

      if (latestTxModel == null) {
        final emptyModel = {
          "total_user_currency": "${currencySymbol}0.00",
          "total_sats": 0,
          "total_btc": 0,
          "outputArray": []
        };
        return UtxoData.fromJson(emptyModel);
      } else {
        print("Old output model located");
        return latestTxModel;
      }
    }
  }

  Future<TransactionData> _fetchTransactionData() async {
    final id = await _getWalletId();
    final wallet = await Hive.openBox(id);
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

    final Map<String, dynamic> requestBody = {
      "currency": currency,
      "allAddresses": allAddresses,
      "changeAddresses": changeAddresses,
      "url": await getEsploraUrl()
    };

    try {
      final response = await http.post(
        Uri.parse('$MIDDLE_SERVER/txData'),
        body: jsonEncode(requestBody),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Transactions fetched');
        notifyListeners();
        await wallet.put('latest_tx_model',
            TransactionData.fromJson(json.decode(response.body)));
        return TransactionData.fromJson(json.decode(response.body));
      } else {
        print("Transaction fetch unsuccessful");
        final latestModel = await wallet.get('latest_tx_model');

        if (latestModel == null) {
          final emptyModel = {"dateTimeChunks": []};
          return TransactionData.fromJson(emptyModel);
        } else {
          print("Old transaction model located");
          print(response.body);
          return latestModel;
        }
      }
    } catch (e) {
      print("error $e");
      print("Transaction fetch unsuccessful");
      final latestModel = await wallet.get('latest_tx_model');

      if (latestModel == null) {
        final emptyModel = {"dateTimeChunks": []};
        return TransactionData.fromJson(emptyModel);
      } else {
        print("Old transaction model located");
        return latestModel;
      }
    }
  }

  Future<dynamic> getBitcoinPrice() async {
    final String currency = await CurrencyUtilities.fetchPreferredCurrency();

    final Map<String, String> requestBody = {"currency": currency};

    final response = await http.post(
      Uri.parse('$MIDDLE_SERVER/currentBitcoinPrice'),
      body: jsonEncode(requestBody),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      notifyListeners();
      print('Current BTC Price: ' + response.body.toString());
      print(
          "response.body.toString().isEmpty: ${response.body.toString().isEmpty}");
      if (response.body.toString().isEmpty) {
        // TODO change this (nice descriptive todo, i know)
        return 1;
        // throw Exception('Something happened: ' +
        //     response.statusCode.toString() +
        //     " response.body is empty!");
      }
      //TODO randomly get a json parse error here (due to empty response body)
      // E/flutter (16131): [ERROR:flutter/lib/ui/ui_dart_state.cc(209)] Unhandled Exception: FormatException: Unexpected end of input (at character 1)
      final result = json.decode(response.body);
      print("json bitcoin price result: $result");
      return result;
    } else {
      throw Exception('Something happened: ' +
          response.statusCode.toString() +
          response.body);
    }
  }

  Future<void> checkReceivingAddressForTransactions() async {
    final String currentExternalAddr = await this._getCurrentAddressForChain(0);
    final Map<String, String> requestBody = {
      "address": currentExternalAddr,
      "url": await getEsploraUrl()
    };

    final response = await http.post(
      Uri.parse('$MIDDLE_SERVER/txCount'),
      body: json.encode(requestBody),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final int numtxs = json.decode(response.body);
      print('Number of txs for current receiving addr: ' + numtxs.toString());

      if (numtxs >= 1) {
        final id = await _getWalletId();
        final wallet = await Hive.openBox(id);

        await incrementAddressIndexForChain(
            0); // First increment the receiving index
        final newReceivingIndex =
            await wallet.get('receivingIndex'); // Check the new receiving index
        final newReceivingAddress = await generateAddressForChain(0,
            newReceivingIndex); // Use new index to derive a new receiving address
        await addToAddressesArrayForChain(newReceivingAddress,
            0); // Add that new receiving address to the array of receiving addresses
        this._currentReceivingAddress = Future(() =>
            newReceivingAddress); // Set the new receiving address that the service
        notifyListeners();
      }
    } else {
      throw Exception('Something happened: ' +
          response.statusCode.toString() +
          response.body);
    }
  }

  Future<FeeObject> getFees() async {
    final Map<String, dynamic> requestBody = {"url": await getEsploraUrl()};

    final response = await http.post(
      Uri.parse('$MIDDLE_SERVER/fees'),
      body: jsonEncode(requestBody),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final FeeObject feeObj = FeeObject.fromJson(json.decode(response.body));
      return feeObj;
    } else {
      throw Exception('Something happened: ' +
          response.statusCode.toString() +
          response.body);
    }
  }

  Future<String> getMarketInfo() async {
    final currency = await CurrencyUtilities.fetchPreferredCurrency();

    final Map<String, String> requestBody = {"currency": currency};

    final response = await http.post(
      Uri.parse('$MIDDLE_SERVER/getMarketInfo'),
      body: json.encode(requestBody),
      headers: {'Content-Type': 'application/json'},
    ).catchError((error) => Future(() => 'Unable to fetch market data'));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      return Future(() => 'Unable to fetch market data');
    }
  }

  Future<dynamic> getAnonymitySet() async {
    final Map<String, dynamic> requestBody = {
      "url": await getEsploraUrl(),
    };

    final response = await http.post(
      Uri.parse('$MIDDLE_SERVER/getanonymityset'),
      body: jsonEncode(requestBody),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      var tod = json.decode(response.body);
      tod['serializedCoins'] = tod['serializedCoins'].cast<String>();

      return tod;
    } else {
      throw Exception('Something happened: ' +
          response.statusCode.toString() +
          response.body);
    }
  }

  Future<int> getBlockHead() async {
    final Map<String, dynamic> requestBody = {"url": await getEsploraUrl()};

    final response = await http.post(
      Uri.parse('$MIDDLE_SERVER/getblockhead'),
      body: jsonEncode(requestBody),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      var tod = json.decode(response.body);
      return tod;
    } else {
      throw Exception('Something happened: ' +
          response.statusCode.toString() +
          response.body);
    }
  }

  Future<int> getLatestSetId() async {
    final Map<String, dynamic> requestBody = {"url": await getEsploraUrl()};

    final response = await http.post(
      Uri.parse('$MIDDLE_SERVER/getlatestcoinid'),
      body: jsonEncode(requestBody),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      var tod = json.decode(response.body);
      return tod;
    } else {
      throw Exception('Something happened: ' +
          response.statusCode.toString() +
          response.body);
    }
  }

  Future<Map<String, dynamic>> getSetData(int setID) async {
    final Map<String, dynamic> requestBody = {"url": await getEsploraUrl()};

    final response = await http.post(
      Uri.parse('$MIDDLE_SERVER/getcoinsforrecovery'),
      body: jsonEncode(requestBody),
      headers: {'Content-Type': 'application/json'},
    ).timeout(Duration(minutes: 3));

    if (response.statusCode == 200 || response.statusCode == 201) {
      var tod = json.decode(response.body);

      return tod;
    } else {
      throw Exception('Something happened: ' +
          response.statusCode.toString() +
          response.body);
    }
  }

  Future<dynamic> getUsedCoinSerials() async {
    final Map<String, dynamic> requestBody = {"url": await getEsploraUrl()};

    final response = await http.post(
      Uri.parse('$MIDDLE_SERVER/getusedcoinserials'),
      body: jsonEncode(requestBody),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      var tod = json.decode(response.body);

      return tod;
    } else {
      throw Exception('Something happened: ' +
          response.statusCode.toString() +
          response.body);
    }
  }

  Future<TransactionData> _refreshLelantusData() async {
    final id = await _getWalletId();
    final wallet = await Hive.openBox(id);
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

    // Grab the most recent information on all the joinsplits
    final updatedJSplit = await getJMintTransactions(joinsplits);
    print(updatedJSplit);

    // update all of joinsplits that are now confirmed.
    for (final tx in updatedJSplit) {
      final currenttx = listLelantusTxData[tx.txid];
      if (currenttx == null) {
        // this send was accidentally not included in the list
        listLelantusTxData[tx.txid] = tx;
        continue;
      }
      if (currenttx.confirmedStatus != tx.confirmedStatus) {
        print("not equal");
        listLelantusTxData[tx.txid] = tx;
      }
    }

    final txData = await transactionData;
    if (txData == null) {
      return null;
    }
    logPrint(txData.txChunks);
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
    print("break ----------------");

    // update the _lelantusTransactionData
    final TransactionData newTxData =
        TransactionData.fromMap(listLelantusTxData);
    logPrint(newTxData.txChunks);
    this._lelantusTransactionData = Future(() => newTxData);
    await wallet.put('latest_lelantus_tx_model', newTxData);
  }

  Future<List<models.Transaction>> getJMintTransactions(
      List transactions) async {
    final String currency = await CurrencyUtilities.fetchPreferredCurrency();
    final Map<String, dynamic> requestBody = {
      "url": await getEsploraUrl(),
      "currency": currency,
      "hashes": transactions,
    };

    final response = await http.post(
      Uri.parse('$MIDDLE_SERVER/getjminttransactions'),
      body: jsonEncode(requestBody),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      var tod = json.decode(response.body);

      List<models.Transaction> txs = [];
      for (var i = 0; i < tod.length; i++) {
        tod[i]['subType'] = "join";
        txs.add(models.Transaction.fromLelantusJson(tod[i]));
      }

      return txs;
    } else {
      throw Exception('Something happened: ' +
          response.statusCode.toString() +
          response.body);
    }
  }

  createJoinSplitTransaction(
      int spendAmount, String address, bool subtractFeeFromAmount) async {
    final getanonymityset = await getAnonymitySet();

    var lelantusEntries = await this._getLelantusEntry();

    final estimateJoinSplitFee = await this.estimateJoinSplitFee(
      spendAmount,
      subtractFeeFromAmount,
    );
    var chageToMint = estimateJoinSplitFee.changeToMint;
    var fee = estimateJoinSplitFee.fee;
    var spendCoinIndexes = estimateJoinSplitFee.spendCoinIndexes;
    print("$chageToMint $fee $spendCoinIndexes");
    if (spendCoinIndexes.isEmpty) {
      print("Error, Not enough funds.");
      return 1;
    }

    final tx = new TransactionBuilder(network: firo);
    int locktime = await getBlockHead();
    tx.setLockTime(locktime);

    tx.setVersion(3 | (TRANSACTION_LELANTUS << 16));

    tx.addInput(
      '0000000000000000000000000000000000000000000000000000000000000000',
      4294967295,
      4294967295,
      Uint8List(0),
    );

    final id = await _getWalletId();
    final wallet = await Hive.openBox(id);
    final index = await wallet.get('mintIndex');
    final jmintKeyPair = await _getNode(MINT_INDEX, index);

    final String jmintprivatekey = uint8listToString(jmintKeyPair.privateKey);

    final keyPath = getMintKeyPath(chageToMint, jmintprivatekey, index);

    final aesKeyPair = await _getNode(JMINT_INDEX, keyPath);
    final aesPrivateKey = uint8listToString(aesKeyPair.privateKey);
    if (aesPrivateKey == null) {
      print(
        'firo_walvar:createLelantusSpendTx key pair is undefined',
      );
      return 3;
    }

    final jmintData = createJMintScript(
      chageToMint,
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

    final finalTx = new TransactionBuilder(network: firo);
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
    logPrint("$txHex");
    final price = await bitcoinPrice;
    return {
      "txid": txId,
      "txHex": txHex,
      "value": amount,
      "fees": fee / 100000000.0,
      "jmintValue": chageToMint,
      "publicCoin": "jmintData.publicCoin",
      "spendCoinIndexes": spendCoinIndexes,
      "height": locktime,
      "txType": "Sent",
      "confirmed_status": false,
      "amount": amount / 100000000.0,
      "worthNow": num.parse((amount / 100000000 * price).toStringAsFixed(2)),
      "address": address,
      "timestamp": DateTime.now().millisecondsSinceEpoch ~/ 1000,
      "subType": "join",
    };
  }

  Future<FeeData> estimateJoinSplitFee(
      int spendAmount, bool subtractFeeFromAmount) async {
    final List<DartLelantusEntry> lelantusEntries =
        await this._getLelantusEntry();

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

    final estimateFeeData = FeeData(changeToMint[0], fee, spendCoinIndexes);
    return estimateFeeData;
  }

  Future<bip32.BIP32> _getNode(int chain, int index) async {
    final id = await _getWalletId();
    final secureStore = new FlutterSecureStorage();
    final seed =
        bip39.mnemonicToSeed(await secureStore.read(key: '${id}_mnemonic'));
    final root = bip32.BIP32.fromSeed(seed);

    final node = root.derivePath("m/44'/136'/0'/$chain/$index");
    return node;
  }

  _getUnspentCoins() async {
    final id = await _getWalletId();
    final wallet = await Hive.openBox(id);
    final Map _lelantus_coins = await wallet.get('_lelantus_coins');
    List jindexes = await wallet.get('jindex');
    final data = await transactionData;
    List<LelantusCoin> coins = [];
    if (_lelantus_coins == null) {
      return coins;
    }
    _lelantus_coins.forEach((key, value) {
      final tx = data.findTransaction(value.txId);
      bool isUnconfirmed = tx == null ? false : !tx.confirmedStatus;
      if (!jindexes.contains(value.index) && tx == null) {
        isUnconfirmed = true;
      }
      if (!value.isUsed &&
          value.anonymitySetId != ANONYMITY_SET_EMPTY_ID &&
          !isUnconfirmed) {
        print(value);
        coins.add(value);
      }
    });
    return coins;
  }

  Future<List<DartLelantusEntry>> _getLelantusEntry() async {
    final List<LelantusCoin> lelantusCoins = await _getUnspentCoins();
    final waitLelantusEntries = lelantusCoins.map((coin) async {
      final keyPair = await _getNode(MINT_INDEX, coin.index);
      final String privateKey = uint8listToString(keyPair.privateKey);
      if (privateKey == null) {
        print("error bad key");
        return DartLelantusEntry(1, 0, 0, 0, 0, '');
      }
      return DartLelantusEntry(coin.isUsed ? 1 : 0, 0, coin.anonymitySetId,
          coin.value, coin.index, privateKey);
    }).toList();

    final lelantusEntries = await Future.wait(waitLelantusEntries);

    return lelantusEntries;
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

  getMintHex(int amount, int index) async {
    final mintKeyPair = await _getNode(MINT_INDEX, index);
    String keydata = uint8listToString(mintKeyPair.privateKey);
    String seedID = uint8listToString(mintKeyPair.identifier);
    String mintHex = getMintScript(amount, keydata, index, seedID);
    return mintHex;
  }

  dynamic autoMint() async {
    try {
      var mintResult = await mintSelection();
      if (mintResult == null || mintResult is String) {
        print("nothing to mint");
        return;
      }
      submitLelantusToNetwork(mintResult);
    } catch (e) {
      print(e);
      print("could not automint");
    }
  }

  /// Returns the mint transaction hex to mint all of the available funds.
  dynamic mintSelection() async {
    final List<UtxoObject> availableOutputs = this.allOutputs;
    final List<UtxoObject> spendableOutputs = [];

    // Build list of spendable outputs and totaling their satoshi amount
    for (var i = 0; i < availableOutputs.length; i++) {
      if (availableOutputs[i].blocked == false &&
          availableOutputs[i].status.confirmed == true) {
        spendableOutputs.add(availableOutputs[i]);
      }
    }

    print(spendableOutputs);

    final id = await _getWalletId();
    final wallet = await Hive.openBox(id);
    final Map _lelantus_coins = await wallet.get('_lelantus_coins');
    final data = await transactionData;
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
              print(element);
              print(value);
              spendableOutputs
                  .removeWhere((output) => output.txid == element.txid);
            }
          });
        }
      });
    }
    print(spendableOutputs);

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
    int firoFee = (vsize * feesObject.fast * (1 / 1000.0) * 100000000).ceil();
    print("vsize $vsize");
    print("mintfee $firoFee");
    if (firoFee < vsize) {
      firoFee = vsize + 1;
    }
    firoFee = firoFee + 10;
    int satoshiAmountToSend = satoshisBeingUsed - firoFee;

    print('Input size: $satoshisBeingUsed');
    print('Recipient output size: $satoshiAmountToSend');
    print('Fee being paid: ' +
        (satoshisBeingUsed - satoshiAmountToSend).toString() +
        ' sats');
    dynamic transaction =
        await buildMintTransaction(utxoObjectsToUse, satoshiAmountToSend);
    transaction['transaction'] = "";
    logPrint(transaction.toString());
    logPrint(transaction['txHex']);
    return transaction;
  }

  /// Builds and signs a transaction
  Future<dynamic> buildMintTransaction(
      List<UtxoObject> utxosToUse, int satoshisPerRecipient) async {
    List<String> addressesToDerive = [];

    // Populating the addresses to derive
    for (var i = 0; i < utxosToUse.length; i++) {
      List<dynamic> lookupData = [utxosToUse[i].txid, utxosToUse[i].vout];
      Map<String, dynamic> requestBody = {
        "url": await getEsploraUrl(),
        "lookupData": lookupData,
      };

      final response = await http.post(
        Uri.parse('$MIDDLE_SERVER/voutLookup'),
        body: json.encode(requestBody),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        addressesToDerive.add(json.decode(response.body));
      } else {
        throw Exception('Something happened: ' +
            response.statusCode.toString() +
            response.body);
      }
    }

    final id = await _getWalletId();
    final secureStore = new FlutterSecureStorage();
    final seed =
        bip39.mnemonicToSeed(await secureStore.read(key: '${id}_mnemonic'));

    final root = bip32.BIP32.fromSeed(seed, firoNetworkType);

    List<ECPair> elipticCurvePairArray = [];
    List<Uint8List> outputDataArray = [];

    for (var i = 0; i < addressesToDerive.length; i++) {
      final addressToCheckFor = addressesToDerive[i];

      for (var i = 0; i < 2000; i++) {
        final nodeReceiving = root.derivePath("m/44'/136'/0'/0/$i");
        final nodeChange = root.derivePath("m/44'/136'/0'/1/$i");

        if (P2PKH(
                    network: firo,
                    data: new PaymentData(pubkey: nodeReceiving.publicKey))
                .data
                .address ==
            addressToCheckFor) {
          print('Receiving found on loop $i');
          elipticCurvePairArray
              .add(ECPair.fromWIF(nodeReceiving.toWIF(), network: firo));
          outputDataArray.add(P2PKH(
                  network: firo,
                  data: new PaymentData(pubkey: nodeReceiving.publicKey))
              .data
              .output);
          break;
        }
        if (P2PKH(
                    network: firo,
                    data: new PaymentData(pubkey: nodeChange.publicKey))
                .data
                .address ==
            addressToCheckFor) {
          print('Change found on loop $i');
          elipticCurvePairArray
              .add(ECPair.fromWIF(nodeChange.toWIF(), network: firo));

          outputDataArray.add(P2PKH(
                  network: firo,
                  data: new PaymentData(pubkey: nodeChange.publicKey))
              .data
              .output);
          break;
        }
      }
    }

    final txb = new TransactionBuilder(network: firo);
    txb.setVersion(2);
    int height = await getBlockHead();
    txb.setLockTime(height);
    int amount = 0;
    // Add transaction inputs
    for (var i = 0; i < utxosToUse.length; i++) {
      txb.addInput(
          utxosToUse[i].txid, utxosToUse[i].vout, null, outputDataArray[i]);
      amount += utxosToUse[i].value;
    }

    final wallet = await Hive.openBox(id);
    final index = await wallet.get('mintIndex');
    print("index of mint $index");

    Uint8List mintu8 =
        stringToUint8List(await getMintHex(satoshisPerRecipient, index));

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

    final price = await bitcoinPrice;
    var builtHex = txb.build();
    // return builtHex;
    return {
      "transaction": builtHex,
      "txid": txId,
      "txHex": txHex,
      "value": amount - fee,
      "fees": fee / 100000000,
      "publicCoin": "",
      "height": height,
      "txType": "Sent",
      "confirmed_status": false,
      "amount": amount / 100000000,
      "worthNow": num.parse((amount / 100000000 * price).toStringAsFixed(2)),
      "timestamp": DateTime.now().millisecondsSinceEpoch ~/ 1000,
      "subType": "mint",
    };
  }

  /// Recovers wallet from [suppliedMnemonic]. Expects a valid mnemonic.
  dynamic recoverWalletFromBIP32SeedPhrase(String suppliedMnemonic) async {
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
      print(currentNode.toBase58());
      print(currentNode.toWIF());
      print(currentNode.publicKey);
      print(currentNode.privateKey);
      final address = P2PKH(
              network: firo,
              data: new PaymentData(pubkey: currentNode.publicKey))
          .data
          .address;
      print(address);
      final Map<String, String> requestBody = {
        "address": address,
        "url": await getEsploraUrl()
      };

      final response = await http.post(
        Uri.parse('$MIDDLE_SERVER/txCount'),
        body: json.encode(requestBody),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final int numTxs = json.decode(response.body);
        if (numTxs >= 1) {
          receivingIndex = i;
          receivingAddressArray.add(address);
        } else if (numTxs == 0) {
          receivingGapCounter += 1;
        }
      } else {
        throw Exception('Something happened: ' +
            response.statusCode.toString() +
            response.body);
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
              network: firo,
              data: new PaymentData(pubkey: currentNode.publicKey))
          .data
          .address;
      final Map<String, String> requestBody = {
        "address": address,
        "url": await getEsploraUrl()
      };

      final response = await http.post(
        Uri.parse('$MIDDLE_SERVER/txCount'),
        body: json.encode(requestBody),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final int numTxs = json.decode(response.body);
        if (numTxs >= 1) {
          changeIndex = i;
          changeAddressArray.add(address);
        } else if (numTxs == 0) {
          changeGapCounter += 1;
        }
      } else {
        throw Exception(
          'Something happened: ' +
              response.statusCode.toString() +
              response.body,
        );
      }
    }

    // If restoring a wallet that never received any funds, then set receivingArray manually
    // If we didn't do this, it'd store an empty array
    if (receivingIndex == 0) {
      final String receivingAddress =
          await generateAddressForChain(0, receivingIndex);
      receivingAddressArray.add(receivingAddress);
    }

    // If restoring a wallet that never sent any funds with change, then set changeArray
    // manually. If we didn't do this, it'd store an empty array.
    if (changeIndex == 0) {
      final String changeAddress =
          await generateAddressForChain(1, changeIndex);
      changeAddressArray.add(changeAddress);
    }

    final id = await _getWalletId();

    final wallet = await Hive.openBox(id);
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
        "port": "",
      }
    });
    await wallet.put('nodes', nodes);
    await wallet.put('activeNodeName', CampfireConstants.defaultNodeName);

    final secureStore = new FlutterSecureStorage();
    await secureStore.write(
        key: '${id}_mnemonic', value: suppliedMnemonic.trim());
    notifyListeners();
    await restore();
    notifyListeners();
  }

  restore() async {
    final id = await _getWalletId();
    final wallet = await Hive.openBox(id);
    List<int> jindexes = [];
    Map<dynamic, LelantusCoin> _lelantus_coins = Map();
    final setDataMap = Map();
    final latestSetId = await getLatestSetId();
    for (var setId = 1; setId <= latestSetId; setId++) {
      final setData = await getSetData(setId);
      setDataMap[setId] = setData;
    }

    final usedSerialNumbers = (await getUsedCoinSerials())['serials'];
    Set usedSerialNumbersSet = Set();
    for (int ind = 0; ind < usedSerialNumbers.length; ind++) {
      usedSerialNumbersSet.add(usedSerialNumbers[ind]);
    }

    final spendTxIds = List.empty(growable: true);

    var lastFoundIndex = 0;
    var currentIndex = 0;
    while (currentIndex < lastFoundIndex + 20) {
      final mintKeyPair = await _getNode(MINT_INDEX, currentIndex);
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
            final aesKeyPair = await _getNode(JMINT_INDEX, keyPath);
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
    print("mints $_lelantus_coins");
    print("jmints $spendTxIds");

    await wallet.put('mintIndex', lastFoundIndex + 1);
    await wallet.put('_lelantus_coins', _lelantus_coins);
    await wallet.put('jindex', jindexes);

    // Edit the receive transactions with the mint fees.
    _transactionData = _fetchTransactionData();
    TransactionData data = await _transactionData;
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
    final spendTxs = await getJMintTransactions(spendTxIds);
    print(spendTxs);
    spendTxs.forEach((element) {
      transactionMap[element.txid] = element;
    });

    final TransactionData newTxData = TransactionData.fromMap(transactionMap);
    this._lelantusTransactionData = Future(() => newTxData);

    await wallet.put('latest_lelantus_tx_model', newTxData);
  }

  static void logPrint(Object object) async {
    int defaultPrintLength = 1020;
    if (object == null || object.toString().length <= defaultPrintLength) {
      print(object);
    } else {
      String log = object.toString();
      int start = 0;
      int endIndex = defaultPrintLength;
      int logLength = log.length;
      int tmpLogLength = log.length;
      while (endIndex < logLength) {
        print(log.substring(start, endIndex));
        endIndex += defaultPrintLength;
        start += defaultPrintLength;
        tmpLogLength -= defaultPrintLength;
      }
      if (tmpLogLength > 0) {
        print(log.substring(start, logLength));
      }
    }
  }

  // index 0 and 1 for the funds available to spend.
  // index 2 and 3 for all the funds in the wallet (including the undependable ones)
  Future<dynamic> getFullBalance() async {
    final id = await _getWalletId();
    final wallet = await Hive.openBox(id);
    final Map _lelantus_coins = await wallet.get('_lelantus_coins');
    final utxos = await utxoData;
    final price = await bitcoinPrice;
    final data = await transactionData;
    List jindexes = await wallet.get('jindex');
    double lelantusBalance = 0;
    double unconfirmedLelantusBalance = 0;
    if (_lelantus_coins != null && data != null) {
      _lelantus_coins.forEach((key, value) {
        final tx = data.findTransaction(value.txId);
        if (!jindexes.contains(value.index) && tx == null) {
          // This coin is not confirmed and may be replaced
        } else if (!value.isUsed &&
            (tx == null ? true : tx.confirmedStatus != false)) {
          lelantusBalance += value.value / 100000000;
        }
        // else if (tx != null && tx.confirmedStatus == false) {
        //   unconfirmedLelantusBalance += value.value / 100000000;
        // }
      });
    }
    final utxosValue = utxos == null ? 0 : utxos.bitcoinBalance;
    List<String> balances = List.empty(growable: true);
    balances.add(lelantusBalance.toStringAsFixed(8));
    balances.add((lelantusBalance * price).toStringAsFixed(2));
    balances.add((lelantusBalance + utxosValue + unconfirmedLelantusBalance)
        .toStringAsFixed(8));
    balances.add(
        ((lelantusBalance + utxosValue + unconfirmedLelantusBalance) * price)
            .toStringAsFixed(2));
    return balances;
  }
}
