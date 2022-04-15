import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:paymint/services/address_book_service.dart';

void main() {
  setUp(() async {
    await setUpTestHive();
    final wallets = await Hive.openBox('wallets');
    await wallets.put('currentWalletName', "My Firo Wallet");

    final wallet = await Hive.openBox("My Firo Wallet");
    await wallet.put(
      "addressBookEntries",
      {
        "addressA": "john",
        "addressB": "jane",
      },
    );
  });

  test("get current wallet name", () async {
    final service = AddressBookService();
    var name = await service.currentWalletName;
    expect(name, "My Firo Wallet");
  });

  test("get address empty book entries", () async {
    final service = AddressBookService();
    final wallet = await Hive.openBox("My Firo Wallet");
    await wallet.put("addressBookEntries", null);
    expect(await service.addressBookEntries, <String, String>{});
  });

  test("get address some book entries", () async {
    final service = AddressBookService();
    expect(await service.addressBookEntries,
        {"addressA": "john", "addressB": "jane"});
  });

  test("search contacts", () async {
    final service = AddressBookService();
    var results = await service.search("j");
    expect(results, {"addressA": "john", "addressB": "jane"});

    results = await service.search("ja");
    expect(results, {"addressB": "jane"});

    results = await service.search("jo");
    expect(results, {"addressA": "john"});

    results = await service.search("po");
    expect(results, {});
  });

  test("check if address book contains a given address", () async {
    final service = AddressBookService();
    expect(await service.containsAddress("addressC"), false);
    expect(await service.containsAddress("addressB"), true);
    expect(await service.containsAddress("adfasdfsadfasdf"), false);
    expect(await service.containsAddress("addressA"), true);
  });

  test("add new contact", () async {
    final service = AddressBookService();
    expect((await service.addressBookEntries).length, 2);
    await service.addAddressBookEntry("addressC", "jim");
    expect(await service.containsAddress("addressC"), true);
    expect(await service.search("jim"), {"addressC": "jim"});
    expect((await service.addressBookEntries).length, 3);
  });

  test("attempt to add duplicate address", () async {
    final service = AddressBookService();
    expect(service.addAddressBookEntry("addressB", "mike"),
        throwsA(isA<Exception>()));
  });

  test("remove contact succeeds", () async {
    final service = AddressBookService();
    expect((await service.addressBookEntries).length, 2);
    await service.removeAddressBookEntry("addressA");
    expect((await service.addressBookEntries).length, 1);
  });

  test("remove contact throws", () async {
    final service = AddressBookService();
    expect((await service.addressBookEntries).length, 2);
    expect(
        service.removeAddressBookEntry("addressC"), throwsA(isA<Exception>()));
    expect((await service.addressBookEntries).length, 2);
  });

  tearDown(() async {
    await tearDownTestHive();
  });
}
