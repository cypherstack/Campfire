import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:paymint/utilities/flutter_secure_storage_interface.dart';

class DbVersionMigrator {
  Future<void> migrateToV1() async {
    final wallets = await Hive.openBox('wallets');
    final version = wallets.get("db_version");

    if (version == null) {
      final names =
          Map<String, String>.from((await wallets.get("names")) ?? {});

      // migrate each
      for (final entry in names.entries) {
        final walletId = entry.value;
        final walletName = entry.key;

        // move main/test network to walletId based
        final network = await wallets.get("${entry.key}_network");
        await wallets.put("${walletId}_network", network);
        await wallets.delete("${walletName}_network");

        final old = await Hive.openBox(walletName);
        final wallet = await Hive.openBox(walletId);

        // notes
        final oldNotes = await old.get("notes");
        await wallet.put("notes", oldNotes);
        await old.delete("notes");

        // address book
        final addressBook = await old.get("addressBookEntries");
        await wallet.put("addressBookEntries", addressBook);
        await old.put("addressBookEntries", null);
      }

      // finally update version
      await wallets.put("db_version", 1);
    }
  }

  Future<void> migrateToV2() async {
    final wallets = await Hive.openBox('wallets');
    final version = wallets.get("db_version");

    if (version == 1) {
      final names =
          Map<String, String>.from((await wallets.get("names")) ?? {});

      final secureStore = SecureStorageWrapper(FlutterSecureStorage());

      // migrate each
      for (final entry in names.entries) {
        final walletId = entry.value;
        final wallet = await Hive.openBox(walletId);

        // receiveDerivations
        Map<String, dynamic> newReceiveDerivations = {};
        final receiveDerivations =
            Map<int, dynamic>.from(await wallet.get("receiveDerivations"));

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

        await wallet.delete("receiveDerivations");

        // changeDerivations
        Map<String, dynamic> newChangeDerivations = {};
        final changeDerivations =
            Map<int, dynamic>.from(await wallet.get("changeDerivations"));

        for (int i = 0; i < receiveDerivations.length; i++) {
          changeDerivations[i].remove("fingerprint");
          changeDerivations[i].remove("identifier");
          changeDerivations[i].remove("privateKey");
          newChangeDerivations["$i"] = changeDerivations[i];
        }
        final changeDerivationsString = jsonEncode(newChangeDerivations);

        await secureStore.write(
            key: "${walletId}_changeDerivations",
            value: changeDerivationsString);

        await wallet.delete("changeDerivations");
      }

      // finally update version
      await wallets.put("db_version", 2);
    }
  }
}
