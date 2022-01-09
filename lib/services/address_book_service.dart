import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:paymint/services/wallets_service.dart';

class AddressBookService extends ChangeNotifier {
  Future<String> _currentWalletName;
  Future<String> get currentWalletName =>
      _currentWalletName ??= WalletsService().currentWalletName;

  /// Holds address book contact entries
  /// map of contact <address, name>
  /// address is used as key due to uniqueness
  Future<Map<String, String>> _addressBookEntries;
  Future<Map<String, String>> get addressBookEntries =>
      _addressBookEntries ??= _fetchAddressBookEntries();

// Load address book contact entries
  Future<Map<String, String>> _fetchAddressBookEntries() async {
    final _currentWallet = await currentWalletName;
    final wallet = await Hive.openBox(_currentWallet);
    final entries = await wallet.get('addressBookEntries');
    print("Address book entries fetched: $entries");
    return entries == null ? <String, String>{} : Map<String, String>.from(entries);
  }

  /// Add address book contact entry to db
  addAddressBookEntry(String address, String name) async {
    final _currentWallet = await currentWalletName;
    final wallet = await Hive.openBox(_currentWallet);
    final entries = await wallet.get('addressBookEntries');
    entries[address] = name;
    await wallet.put('addressBookEntries', entries);
    print("address book entry saved");
    await _refreshAddressBookEntries();
    // GlobalEventBus.instance.fire(AddressBookChangedEvent("entry added"));
  }

  /// Remove address book contact entry from db
  removeAddressBookEntry(String address) async {
    final _currentWallet = await currentWalletName;
    final wallet = await Hive.openBox(_currentWallet);
    final entries = await wallet.get('addressBookEntries');
    entries.remove(address);
    await wallet.put('addressBookEntries', entries);
    print("address book entry removed");
    await _refreshAddressBookEntries();
    // GlobalEventBus.instance.fire(AddressBookChangedEvent("entry removed"));
  }

  _refreshAddressBookEntries() async {
    final newAddressBookEntries = await _fetchAddressBookEntries();
    this._addressBookEntries = Future(() => newAddressBookEntries);
    notifyListeners();
  }
}
