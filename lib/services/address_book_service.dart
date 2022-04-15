import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:paymint/services/wallets_service.dart';
import 'package:paymint/utilities/logger.dart';

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
    Logger.print("Address book entries fetched: $entries");
    return entries == null
        ? <String, String>{}
        : Map<String, String>.from(entries);
  }

  /// search addressbook entries
  //TODO optimize addressbook search?
  Future<Map<String, String>> search(String text) async {
    if (text.isEmpty) return addressBookEntries;
    var results = Map<String, String>.from(await addressBookEntries);
    results.removeWhere(
        (key, value) => (!key.contains(text) && !value.contains(text)));
    return results;
  }

  /// check if address already used in address book
  Future<bool> containsAddress(String address) async {
    final _currentWallet = await currentWalletName;
    final wallet = await Hive.openBox(_currentWallet);
    final _entries = await wallet.get('addressBookEntries');
    final entries = _entries == null ? <String, String>{} : _entries;
    return entries.containsKey(address);
  }

  /// Add address book contact entry to db
  Future<void> addAddressBookEntry(String address, String name) async {
    final _currentWallet = await currentWalletName;
    final wallet = await Hive.openBox(_currentWallet);
    final _entries = await wallet.get('addressBookEntries');
    final entries = _entries == null ? <String, String>{} : _entries;

    if (entries.containsKey(address)) {
      throw Exception(
          "Address already exists in db. Overwriting not allowed! If you want to edit call the editAddressBookEntry() function.");
    }

    entries[address] = name;
    await wallet.put('addressBookEntries', entries);
    Logger.print("address book entry saved");
    await _refreshAddressBookEntries();
    // GlobalEventBus.instance.fire(AddressBookChangedEvent("entry added"));
  }

  /// Remove address book contact entry from db
  Future<void> removeAddressBookEntry(String address) async {
    final _currentWallet = await currentWalletName;
    final wallet = await Hive.openBox(_currentWallet);
    final entries = await wallet.get('addressBookEntries');
    if (entries.containsKey(address)) {
      entries.remove(address);
      await wallet.put('addressBookEntries', entries);
      Logger.print("address book entry removed");
      await _refreshAddressBookEntries();
    } else {
      throw Exception(
          "Cannot remove non existent address book entry for '$address'!");
    }
    // GlobalEventBus.instance.fire(AddressBookChangedEvent("entry removed"));
  }

  Future<void> _refreshAddressBookEntries() async {
    final newAddressBookEntries = await _fetchAddressBookEntries();
    this._addressBookEntries = Future(() => newAddressBookEntries);
    notifyListeners();
  }
}
