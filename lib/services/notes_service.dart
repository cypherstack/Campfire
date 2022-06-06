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
    final wallet = await Hive.openBox(await _getWalletId());
    final notes = await wallet.get('notes');
    Logger.print("Transaction notes fetched: $notes");
    return notes == null ? <String, String>{} : Map<String, String>.from(notes);
  }

  Future<String> _getWalletId() async {
    final wallets = await Hive.openBox('wallets');
    final names = await wallets.get('names');
    final currentWallet = await currentWalletName;
    return names[currentWallet];
  }

  /// search notes
  //TODO optimize notes search?
  Future<Map<String, String>> search(String text) async {
    if (text == null || text.isEmpty) return notes;
    var results = Map<String, String>.from(await notes);
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
  Future<void> addNote({String txid, String note}) async {
    final wallet = await Hive.openBox(await _getWalletId());
    final _notes = await notes;

    if (_notes.containsKey(txid)) {
      throw Exception(
          "A note for txid: $txid already exists. Overwriting not allowed!");
    }

    _notes[txid] = note;
    await wallet.put('notes', _notes);
    Logger.print("addNote: tx note saved");
    await _refreshNotes();
  }

  // edit or add new note
  Future<void> editOrAddNote({String txid, String note}) async {
    final wallet = await Hive.openBox(await _getWalletId());
    final _notes = await notes;

    _notes[txid] = note;
    await wallet.put('notes', _notes);
    Logger.print("editOrAddNote: tx note saved");
    await _refreshNotes();
  }

  /// Remove note from db
  Future<void> removeNote({String txid}) async {
    final wallet = await Hive.openBox(await _getWalletId());
    final entries = await wallet.get('notes');
    entries.remove(txid);
    await wallet.put('notes', entries);
    Logger.print("tx note removed");
    await _refreshNotes();
    // GlobalEventBus.instance.fire(AddressBookChangedEvent("entry removed"));
  }

  Future<void> _refreshNotes() async {
    final newNotes = await _fetchNotes();
    this._notes = Future(() => newNotes);
    notifyListeners();
  }
}
