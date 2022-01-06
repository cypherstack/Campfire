import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

class WalletsService extends ChangeNotifier {
  Future<List<String>> _walletNames;
  Future<List<String>> get walletNames => _walletNames ??= _fetchWalletNames();

  Future<String> _currentWalletName;
  Future<String> get currentWalletName =>
      _currentWalletName ??= _fetchCurrentWalletName();

  WalletsService() {
    _initialize().whenComplete(() => _walletNames = _fetchWalletNames());
  }

  Future<void> _initialize() async {
    final wallets = await Hive.openBox('wallets');
    if (wallets.isEmpty) {
      final List<String> names = [];
      wallets.put('names', names);
      wallets.put('currentWalletName', "");
    } else {
      this._currentWalletName = _fetchCurrentWalletName();
    }
  }

  Future<void> setCurrentWalletName(String name) async {
    final wallets = await Hive.openBox('wallets');
    await wallets.put('currentWalletName', name);
    await refreshCurrentName();
  }

  Future<String> _fetchCurrentWalletName() async {
    final wallets = await Hive.openBox('wallets');
    final currentName = await wallets.get('currentWalletName');
    print("Fetched current name: $currentName");
    return currentName;
  }

  Future<List<String>> _fetchWalletNames() async {
    final wallets = await Hive.openBox('wallets');
    final names = await wallets.get('names');
    print("Fetched wallet names: $names");
    return List<String>.from(names);
  }

  Future<bool> addNewWalletName(String name) async {
    final wallets = await Hive.openBox('wallets');
    final names = await wallets.get('names');
    // Prevent overwriting or storing empty names
    if (name.isEmpty || names.contains(name)) {
      return false;
    }
    names.insert(0, name);
    await wallets.put('names', names);
    await setCurrentWalletName(name);
    return true;
  }

  Future<bool> checkForDuplicate(String name) async {
    final wallets = await Hive.openBox('wallets');
    final names = await wallets.get('names');
    return names.contains(name);
  }

  // pin + mnemonic as well as anything else in secureStore

  Future<void> deleteWallet(String name) async {
    final wallets = await Hive.openBox('wallets');
    final names = await wallets.get('names');

    if (names.length == 0) {
      throw Exception("Cannot delete last wallet!");
    }

    names.remove(name);

    final store = new FlutterSecureStorage();
    await store.delete(key: "${name}_pin");
    await store.delete(key: "${name}_mnemonic");

    await Hive.deleteBoxFromDisk(name);

    await wallets.put('names', names);

    await setCurrentWalletName(names[0]);
  }

  refreshCurrentName() async {
    final currentName = await _fetchCurrentWalletName();
    this._currentWalletName = Future(() => currentName);
    notifyListeners();
  }

  refreshWallets() async {
    final newNames = await _fetchWalletNames();
    this._walletNames = Future(() => newNames);
    notifyListeners();
  }
}
