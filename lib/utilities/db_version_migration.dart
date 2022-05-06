import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

class DbVersionMigrator {
  Future<void> migrate(int fromVersion) async {
    final wallets = await Hive.openBox('wallets');
    final names = Map<String, String>.from((await wallets.get("names")) ?? {});

    switch (fromVersion) {
      case 0:
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

          final secureStore = FlutterSecureStorage();

          // receiveDerivations
          Map<String, dynamic> newReceiveDerivations = {};
          final receiveDerivations = Map<int, dynamic>.from(
              await wallet.get("receiveDerivations") ?? {});

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
          final changeDerivations = Map<int, dynamic>.from(
              await wallet.get("changeDerivations") ?? {});

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
}
