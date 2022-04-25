import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:paymint/utilities/db_version_migration.dart';

void main() {
  setUp(() async {
    await setUpTestHive();
  });

  test("migrate from version null to version 1", () async {
    final wallets = await Hive.openBox('wallets');
    await wallets.put('names', {"My Firo Wallet": "wallet_id"});
    await wallets.put('currentWalletName', "My Firo Wallet");
    await wallets.put("My Firo Wallet_network", "main");

    final wallet = await Hive.openBox("My Firo Wallet");
    await wallet.put("notes", {"txid1": "note1", "txid2": "note2"});
    await wallet.put(
      "addressBookEntries",
      {
        "addressA": "john",
        "addressB": "jane",
      },
    );

    expect(await wallets.get("db_version"), null);

    await DbVersionMigrator().migrateToV1();

    expect(await wallets.get("db_version"), 1);

    expect(await wallets.get("My Firo Wallet_network"), null);
    expect(await wallets.get("wallet_id_network"), "main");

    final wallet2 = await Hive.openBox("wallet_id");

    expect(await wallet.get("notes"), null);
    expect(await wallet2.get("notes"), {"txid1": "note1", "txid2": "note2"});

    expect(await wallet.get("addressBookEntries"), null);
    expect(await wallet2.get("addressBookEntries"), {
      "addressA": "john",
      "addressB": "jane",
    });
  });

  tearDown(() async {
    await tearDownTestHive();
  });
}
