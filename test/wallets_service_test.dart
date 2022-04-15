import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:paymint/services/event_bus/events/wallet_name_changed_event.dart';
import 'package:paymint/services/event_bus/global_event_bus.dart';
import 'package:paymint/services/wallets_service.dart';
import 'package:paymint/utilities/flutter_secure_storage_interface.dart';

import 'wallets_service_test.mocks.dart';

@GenerateMocks([SecureStorageWrapper])
void main() {
  setUp(() async {
    await setUpTestHive();
    final wallets = await Hive.openBox('wallets');
    await wallets
        .put('names', {"My Firo Wallet": "wallet_id", "wallet2": "wallet_id2"});
    await wallets.put('currentWalletName', "My Firo Wallet");
    await wallets.put("wallet_id_network", "test");
  });

  test("get walletNames", () async {
    final service = WalletsService();
    expect(await service.walletNames,
        {"My Firo Wallet": "wallet_id", "wallet2": "wallet_id2"});
  });

  test("get null wallet names", () async {
    final wallets = await Hive.openBox('wallets');
    await wallets.put('names', null);
    final service = WalletsService();
    expect(await service.walletNames, {});
  });

  test("get current wallet name", () async {
    int count = 0;
    GlobalEventBus.instance
        .on<ActiveWalletNameChangedEvent>()
        .listen((_) => count++);
    final service = WalletsService();

    expect(await service.currentWalletName, "My Firo Wallet");
    // wait some short time for possible event to propagate
    await Future.delayed(Duration(milliseconds: 100));
    expect(count, 1);

    expect(await service.currentWalletName, "My Firo Wallet");
    // wait some short time for possible event to propagate
    await Future.delayed(Duration(milliseconds: 100));
    expect(count, 1);
  });

  test("get stored network name", () async {
    final service = WalletsService();
    expect(await service.networkName, "test");
  });

  test("get null network name", () async {
    final wallets = await Hive.openBox('wallets');
    await wallets.put("wallet_id_network", null);
    final service = WalletsService();
    expect(await service.networkName, "main");
  });

  test("set valid current wallet name", () async {
    int count = 0;
    GlobalEventBus.instance
        .on<ActiveWalletNameChangedEvent>()
        .listen((_) => count++);
    final service = WalletsService();

    await service.setCurrentWalletName("wallet2");
    // wait some short time for possible event to propagate
    await Future.delayed(Duration(milliseconds: 100));
    expect(count, 1);

    expect(await service.currentWalletName, "wallet2");
    // wait some short time for possible event to propagate
    await Future.delayed(Duration(milliseconds: 100));
    expect(count, 1);
  });

  test("set invalid current wallet name", () async {
    int count = 0;
    GlobalEventBus.instance
        .on<ActiveWalletNameChangedEvent>()
        .listen((_) => count++);
    final service = WalletsService();

    expect(() => service.setCurrentWalletName("hmmmmmm"),
        throwsA(isA<Exception>()));
    // wait some short time for possible event to propagate
    await Future.delayed(Duration(milliseconds: 1000));
    expect(count, 0);

    expect(await service.currentWalletName, "My Firo Wallet");
    // wait some short time for possible event to propagate
    await Future.delayed(Duration(milliseconds: 100));
    expect(count, 1);
  });

  test("rename wallet to same name", () async {
    final service = WalletsService();
    expect(await service.renameWallet(toName: "My Firo Wallet"), true);
  });

  test("rename wallet to new name", () async {
    final service = WalletsService();
    expect(await service.renameWallet(toName: "My New Wallet"), true);
    expect(await service.currentWalletName, "My New Wallet");
    expect(await service.walletNames,
        {"My New Wallet": "wallet_id", "wallet2": "wallet_id2"});
  });

  test("attempt rename wallet to another existing name", () async {
    final service = WalletsService();
    expect(await service.renameWallet(toName: "wallet2"), false);
    expect(await service.currentWalletName, "My Firo Wallet");
    expect(await service.walletNames,
        {"My Firo Wallet": "wallet_id", "wallet2": "wallet_id2"});
  });

  test("add new wallet name", () async {
    final service = WalletsService();
    expect(await service.addNewWalletName("wallet3", "test"), true);
    expect(await service.networkName, "test");
    expect((await service.walletNames).length, 3);
  });

  test("add duplicate wallet name fails", () async {
    final service = WalletsService();
    expect(
        await service.addNewWalletName("wallet2", "some network name"), false);
    expect(await service.networkName, "test");
    expect((await service.walletNames).length, 2);
  });

  test("check for duplicates when null names", () async {
    final wallets = await Hive.openBox('wallets');
    await wallets.put('names', null);
    final service = WalletsService();
    expect(await service.checkForDuplicate("anything"), false);
  });

  test("check for duplicates when some names with no matches", () async {
    final service = WalletsService();
    expect(await service.checkForDuplicate("anything"), false);
  });

  test("check for duplicates when some names with a match", () async {
    final service = WalletsService();
    expect(await service.checkForDuplicate("wallet2"), true);
  });

  test("check for duplicates when some names with a null string", () async {
    final service = WalletsService();
    expect(await service.checkForDuplicate(null), false);
  });

  test("get existing wallet id", () async {
    final service = WalletsService();
    expect(await service.getWalletId("wallet2"), "wallet_id2");
  });

  test("get non existent wallet id", () async {
    final service = WalletsService();
    expect(await service.getWalletId("wallet 99"), null);
  });

  test("delete a wallet", () async {
    final secureStore = MockSecureStorageWrapper();

    when(secureStore.delete(key: "wallet_id_pin")).thenAnswer((_) async {});
    when(secureStore.delete(key: "wallet_id_mnemonic"))
        .thenAnswer((_) async {});

    final service = WalletsService(secureStorageInterface: secureStore);

    expect(await service.deleteWallet("My Firo Wallet"), 0);
    expect(await service.currentWalletName, "wallet2");
    expect((await service.walletNames).length, 1);

    verify(secureStore.delete(key: "wallet_id_pin")).called(1);
    verify(secureStore.delete(key: "wallet_id_mnemonic")).called(1);

    verifyNoMoreInteractions(secureStore);
  });

  test("delete last wallet", () async {
    final wallets = await Hive.openBox('wallets');
    await wallets.put('names', {"My Firo Wallet": "wallet_id"});
    final secureStore = MockSecureStorageWrapper();

    when(secureStore.delete(key: "wallet_id_pin")).thenAnswer((_) async {});
    when(secureStore.delete(key: "wallet_id_mnemonic"))
        .thenAnswer((_) async {});

    final service = WalletsService(secureStorageInterface: secureStore);

    expect(await service.deleteWallet("My Firo Wallet"), 2);
    expect(await service.currentWalletName, "No wallets found!");
    expect((await service.walletNames).length, 0);

    verify(secureStore.delete(key: "wallet_id_pin")).called(1);
    verify(secureStore.delete(key: "wallet_id_mnemonic")).called(1);

    verifyNoMoreInteractions(secureStore);
  });

  test("get", () async {
    final service = WalletsService();
  });

  tearDown(() async {
    await tearDownTestHive();
  });
}
