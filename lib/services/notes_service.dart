import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:paymint/services/wallets_service.dart';
import 'package:paymint/utilities/logger.dart';

class NotesService extends ChangeNotifier {
  // current wallet name
  // TODO find a better way of passing around current wallet
  Future<String> _currentWalletName;
  Future<String> get currentWalletName =>
      _currentWalletName ??= WalletsService().currentWalletName;

  /// Holds transaction notes
  /// map of contact <txid, note>
  /// txid is used as key due to uniqueness
  Future<Map<String, String>> _notes;
  Future<Map<String, String>> get notes => _notes ??= _fetchNotes();

  // fetch notes map
  Future<Map<String, String>> _fetchNotes() async {
    final _currentWallet = await currentWalletName;
    final wallet = await Hive.openBox(_currentWallet);
    final notes = await wallet.get('notes');
    Logger.print("Transaction notes fetched: $notes");
    return notes == null ? <String, String>{} : Map<String, String>.from(notes);
  }

  /// search notes
  //TODO optimize notes search?
  Future<Map<String, String>> search(String text) async {
    if (text.isEmpty) return _notes;
    var results = Map<String, String>.from(await _notes);
    results.removeWhere(
        (key, value) => (!key.contains(text) && !value.contains(text)));
    return results;
  }

  /// fetch note given a transaction ID
  Future<String> getNoteFor({String txid}) async {
    final note = (await notes)[txid];
    return note == null ? "" : note;
  }

  // add note to db
  addNote({String txid, String note}) async {
    final walletName = await currentWalletName;
    final wallet = await Hive.openBox(walletName);
    final _notes = await wallet.get('notes');
    final notes = _notes == null ? <String, String>{} : _notes;

    if (notes.containsKey(txid)) {
      throw Exception(
          "A note for txid: $txid already exists. Overwriting not allowed!");
    }

    notes[txid] = note;
    await wallet.put('notes', notes);
    Logger.print("addNote: tx note saved");
    await _refreshNotes();
  }

  // edit or add new note
  editOrAddNote({String txid, String note}) async {
    final walletName = await currentWalletName;
    final wallet = await Hive.openBox(walletName);
    final _notes = await wallet.get('notes');
    final notes = _notes == null ? <String, String>{} : _notes;

    notes[txid] = note;
    await wallet.put('notes', notes);
    Logger.print("editOrAddNote: tx note saved");
    await _refreshNotes();
  }

  /// Remove note from db
  removeNote({String txid}) async {
    final _currentWallet = await currentWalletName;
    final wallet = await Hive.openBox(_currentWallet);
    final entries = await wallet.get('notes');
    entries.remove(txid);
    await wallet.put('notes', entries);
    Logger.print("tx note removed");
    await _refreshNotes();
    // GlobalEventBus.instance.fire(AddressBookChangedEvent("entry removed"));
  }

  _refreshNotes() async {
    final newNotes = await _fetchNotes();
    this._notes = Future(() => newNotes);
    notifyListeners();
  }
}
