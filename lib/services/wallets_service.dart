import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:paymint/services/coins/firo/firo_wallet.dart';
import 'package:paymint/services/event_bus/events/wallet_name_changed_event.dart';
import 'package:paymint/services/event_bus/global_event_bus.dart';
import 'package:paymint/utilities/flutter_secure_storage_interface.dart';
import 'package:paymint/utilities/logger.dart';
import 'package:uuid/uuid.dart';

class WalletsService extends ChangeNotifier {
  FlutterSecureStorageInterface _secureStore;

  Future<Map<String, String>> _walletNames;
  Future<Map<String, String>> get walletNames =>
      _walletNames ??= _fetchWalletNames();

  String _previousFetchedName;
  Future<String> _currentWalletName;
  Future<String> get currentWalletName =>
      _currentWalletName ??= _fetchCurrentWalletName();

  Future<String> get networkName async =>
      _getNetworkName(await currentWalletName);

  WalletsService({
    FlutterSecureStorageInterface secureStorageInterface =
        const SecureStorageWrapper(
      const FlutterSecureStorage(),
    ),
  }) {
    _secureStore = secureStorageInterface;
    _initialize(); //.whenComplete(() => _walletNames = _fetchWalletNames());
  }

  Future<void> _initialize() async {
    final wallets = await Hive.openBox('wallets');
    if (wallets.isEmpty) {
      final Map<String, String> names = {};
      wallets.put('names', names);
      wallets.put('currentWalletName', "");
    } else {
      // this._currentWalletName = _fetchCurrentWalletName();
    }
  }

  Future<String> _getNetworkName(String walletName) async {
    final wallets = await Hive.openBox('wallets');
    final names = await wallets.get('names');
    final walletId = names[walletName];
    final network = await wallets.get("${walletId}_network");
    if (network == null) {
      final mainnet = FiroNetworkType.main.name;
      await wallets.put("${walletId}_network", mainnet);
      return mainnet;
    } else {
      return network;
    }
  }

  Future<void> setCurrentWalletName(String name) async {
    final wallets = await Hive.openBox('wallets');
    final names = await wallets.get('names');

    if (!names.keys.contains(name)) {
      throw Exception(
          "Cannot set current wallet to '$name' which does not exist.");
    }

    await wallets.put('currentWalletName', name);
    final currentName = await _fetchCurrentWalletName();
    this._currentWalletName = Future(() => currentName);
    notifyListeners();
    // GlobalEventBus.instance.fire(ActiveWalletNameChangedEvent(currentName));
  }

  Future<bool> renameWallet({String toName}) async {
    final fromName = await currentWalletName;
    if (fromName == toName) {
      // fake real success as wallet name is not changing
      return true;
    }

    final wallets = await Hive.openBox('wallets');
    final names = await wallets.get('names');

    if (fromName != toName && names.keys.contains(toName)) {
      // name already exists
      Logger.print("wallet with name \"$toName\" already exists!");
      return false;
    }

    final wallet = names.remove(fromName);
    names[toName] = wallet;

    await wallets.put('names', names);
    await setCurrentWalletName(toName);
    await refreshWallets();
    return true;
  }

  Future<String> _fetchCurrentWalletName() async {
    final wallets = await Hive.openBox('wallets');
    final currentName = await wallets.get('currentWalletName');
    Logger.print("Fetched current name: $currentName");
    if (currentName != null && _previousFetchedName != currentName) {
      _previousFetchedName = currentName;
      GlobalEventBus.instance.fire(ActiveWalletNameChangedEvent(currentName));
    }
    return currentName;
  }

  Future<Map<String, String>> _fetchWalletNames() async {
    final wallets = await Hive.openBox('wallets');
    final names = await wallets.get('names');
    if (names == null) {
      Logger.print(
          "Fetched wallet 'names' returned null. Setting initializing 'names'");
      final newNames = Map<String, String>();
      await wallets.put('names', newNames);
      return newNames;
    }
    Logger.print("Fetched wallet names: ${names.keys}");
    return Map<String, String>.from(names);
  }

  Future<bool> addNewWalletName(String name, String networkName) async {
    final wallets = await Hive.openBox('wallets');
    final _names = await wallets.get('names');

    Map<String, String> names;
    if (_names == null) {
      names = {};
    } else {
      names = Map<String, String>.from(_names);
    }
    // Prevent overwriting or storing empty names
    if (name.isEmpty || names.keys.contains(name)) {
      return false;
    }
    final id = Uuid().v1() + name;
    names[name] = id;

    await wallets.put('names', names);
    await wallets.put("${id}_network", networkName);
    await setCurrentWalletName(name);
    await refreshWallets();
    return true;
  }

  Future<bool> checkForDuplicate(String name) async {
    final wallets = await Hive.openBox('wallets');
    final names = await wallets.get('names');
    if (names == null) {
      return false;
    }
    return names.keys.contains(name);
  }

  Future<String> getWalletId(String walletName) async {
    final wallets = await Hive.openBox('wallets');
    final names = await wallets.get('names');
    final id = names[walletName];
    return id;
  }
  // pin + mnemonic as well as anything else in secureStore

  Future<int> deleteWallet(String name) async {
    final wallets = await Hive.openBox('wallets');
    final names = await wallets.get('names');

    final id = names.remove(name);

    await _secureStore.delete(key: "${id}_pin");
    await _secureStore.delete(key: "${id}_mnemonic");

    await wallets.delete("${id}_network");

    await Hive.deleteBoxFromDisk(id);

    if (names.length == 0) {
      Hive.deleteBoxFromDisk('wallets');
      this._currentWalletName = Future(() => "No wallets found!");
      this._walletNames = Future(() => {});
      notifyListeners();
      return 2; // error code no wallets on device
    }

    await wallets.put('names', names);
    await setCurrentWalletName(names.keys.toList()[0]);
    await refreshWallets();
    return 0;
  }

  refreshWallets() async {
    final newNames = await _fetchWalletNames();
    this._walletNames = Future(() => newNames);
    notifyListeners();
  }
}
