import 'package:hive/hive.dart';

class DbVersionMigrator {
  Future<bool> migrateToV1() async {
    final wallets = await Hive.openBox('wallets');
    final version = wallets.get("db_version");

    if (version == null) {
      final names = Map<String, String>.from(await wallets.get("names"));

      // migrate each
      for (final entry in names.entries) {
        // move main/test network to walletId based
        final network = await wallets.get("${entry.key}_network");
        await wallets.put("${entry.value}_network", network);
        await wallets.delete("${entry.key}_network");

        final old = await Hive.openBox(entry.key);
        final wallet = await Hive.openBox(entry.value);

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

    return true;
  }
}
