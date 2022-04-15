import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:paymint/services/notes_service.dart';

void main() {
  setUp(() async {
    await setUpTestHive();
    final wallets = await Hive.openBox('wallets');
    await wallets.put('names', {"My Firo Wallet": "wallet_id"});
    await wallets.put('currentWalletName', "My Firo Wallet");
    final wallet = await Hive.openBox("wallet_id");
    await wallet.put("notes", {"txid1": "note1", "txid2": "note2"});
  });

  test("get currentWallet name", () async {
    final service = NotesService();
    expect(await service.currentWalletName, "My Firo Wallet");
  });

  test("get null notes", () async {
    final service = NotesService();
    final wallet = await Hive.openBox("wallet_id");
    await wallet.put("notes", null);
    expect(await service.notes, {});
  });

  test("get empty notes", () async {
    final service = NotesService();
    final wallet = await Hive.openBox("wallet_id");
    await wallet.put("notes", {});
    expect(await service.notes, {});
  });

  test("get some notes", () async {
    final service = NotesService();
    expect(await service.notes, {"txid1": "note1", "txid2": "note2"});
  });

  test("search finds none", () async {
    final service = NotesService();
    expect(await service.search("some"), {});
  });

  test("empty search", () async {
    final service = NotesService();
    expect(await service.search(""), {"txid1": "note1", "txid2": "note2"});
  });

  test("null search", () async {
    final service = NotesService();
    expect(await service.search(null), {"txid1": "note1", "txid2": "note2"});
  });

  test("search finds some", () async {
    final service = NotesService();
    expect(await service.search("note"), {"txid1": "note1", "txid2": "note2"});
  });

  test("search finds one", () async {
    final service = NotesService();
    expect(await service.search("2"), {"txid2": "note2"});
  });

  test("get note for existing txid", () async {
    final service = NotesService();
    expect(await service.getNoteFor(txid: "txid1"), "note1");
  });

  test("get note for non existing txid", () async {
    final service = NotesService();
    expect(await service.getNoteFor(txid: "txid"), "");
  });

  test("add new note", () async {
    final service = NotesService();
    await service.addNote(txid: "txid3", note: "note3");
    expect(await service.notes,
        {"txid1": "note1", "txid2": "note2", "txid3": "note3"});
  });

  test("attempt add duplicate txid", () async {
    final service = NotesService();
    expectLater(
            () async =>
                await service.addNote(txid: "txid2", note: "some new note"),
            throwsA(isA<Exception>()))
        .then((value) async =>
            expect(await service.notes, {"txid1": "note1", "txid2": "note2"}));
  });

  test("add or overwrite note for new txid", () async {
    final service = NotesService();
    await service.editOrAddNote(txid: "txid3", note: "note3");
    expect(await service.notes,
        {"txid1": "note1", "txid2": "note2", "txid3": "note3"});
  });

  test("add or overwrite note for existing txid", () async {
    final service = NotesService();
    await service.editOrAddNote(txid: "txid2", note: "note3");
    expect(await service.notes, {"txid1": "note1", "txid2": "note3"});
  });

  test("delete existing note", () async {
    final service = NotesService();
    await service.removeNote(txid: "txid2");
    expect(await service.notes, {"txid1": "note1"});
  });

  test("delete non existing note", () async {
    final service = NotesService();
    await service.removeNote(txid: "txid5");
    expect(await service.notes, {"txid1": "note1", "txid2": "note2"});
  });

  tearDown(() async {
    await tearDownTestHive();
  });
}
