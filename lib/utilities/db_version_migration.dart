import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:paymint/utilities/flutter_secure_storage_interface.dart';

class DbVersionMigrator {
  Future<void> migrate(
    int fromVersion, {
    FlutterSecureStorageInterface secureStore = const SecureStorageWrapper(
      const FlutterSecureStorage(),
    ),
  }) async {
    final wallets = await Hive.openBox('wallets');
    final names = Map<String, String>.from((await wallets.get("names")) ?? {});

    switch (fromVersion) {
      case 0:
        // migrate each
        for (final entry in names.entries) {
          final walletId = entry.value;
          final walletName = entry.key;

          // backup everything besides the derivations
          await _backupV0(walletId: walletId, walletName: walletName);

          // move main/test network to walletId based
          final network = await wallets.get("${walletName}_network");
          await wallets.put("${walletId}_network", network);

          final old = await Hive.openBox(walletName);
          final wallet = await Hive.openBox(walletId);

          // notes
          final oldNotes = await old.get("notes");
          await wallet.put("notes", oldNotes);

          // address book
          final addressBook = await old.get("addressBookEntries");
          await wallet.put("addressBookEntries", addressBook);

          // receiveDerivations
          Map<String, dynamic> newReceiveDerivations = {};
          final receiveDerivations = Map<int, dynamic>.from(
              (await wallet.get("receiveDerivations")) ?? {});

          for (int i = 0; i < receiveDerivations.length; i++) {
            receiveDerivations[i].remove("fingerprint");
            receiveDerivations[i].remove("identifier");
            receiveDerivations[i].remove("privateKey");
            newReceiveDerivations["$i"] = receiveDerivations[i];
          }
          final receiveDerivationsString = jsonEncode(newReceiveDerivations);

          await secureStore.write(
              key: "${walletId}_receiveDerivations",
              value: receiveDerivationsString);

          // changeDerivations
          Map<String, dynamic> newChangeDerivations = {};
          final changeDerivations = Map<int, dynamic>.from(
              (await wallet.get("changeDerivations")) ?? {});

          for (int i = 0; i < changeDerivations.length; i++) {
            changeDerivations[i].remove("fingerprint");
            changeDerivations[i].remove("identifier");
            changeDerivations[i].remove("privateKey");
            newChangeDerivations["$i"] = changeDerivations[i];
          }
          final changeDerivationsString = jsonEncode(newChangeDerivations);

          await secureStore.write(
              key: "${walletId}_changeDerivations",
              value: changeDerivationsString);

          // finally delete originals
          await wallets.delete("${walletName}_network");
          await old.delete("notes");
          await old.delete("addressBookEntries");
          await wallet.delete("changeDerivations");
          await wallet.delete("receiveDerivations");
        }

        // finally update version
        await wallets.put("db_version", 1);

        return;
      // not needed yet
      // return migrate(1);

      // case 1:
      //   return migrate(2);

      default:
        return;
    }
  }

  Future<void> _backupV0({String walletId, String walletName}) async {
    final wallets = await Hive.openBox('wallets');
    final old = await Hive.openBox(walletName);

    final network = await wallets.get("${walletName}_network");
    final oldNotes = await old.get("notes");
    final addressBook = await old.get("addressBookEntries");

    await wallets.put("${walletId}_backupV0", {
      "network": network,
      "notes": oldNotes,
      "addressBookEntries": addressBook,
    });
  }

  Future<void> _restoreV0({String walletId, String walletName}) async {
    final wallets = await Hive.openBox('wallets');
    final old = await Hive.openBox(walletName);

    final backup = await wallets.get("${walletId}_backupV0");

    await old.put("notes", backup["notes"]);
    await old.put("addressBookEntries", backup["addressBookEntries"]);
    await wallets.put("${walletName}_network", backup["network"]);
  }
}
