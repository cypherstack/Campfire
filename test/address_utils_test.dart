import 'package:flutter_test/flutter_test.dart';
import 'package:paymint/services/coins/firo/firo_wallet.dart';
import 'package:paymint/utilities/address_utils.dart';

void main() {
  final String firoAddress = "a6ESWKz7szru5syLtYAPRhHLdKvMq3Yt1j";

  test("generate scripthash from firo address", () {
    final hash = AddressUtils.convertToScriptHash(firoAddress, firoNetwork);
    expect(hash,
        "77090cea08e2b5accb185fac3cdc799b2b1d109e18c19c723011f4af2c0e5f76");
  });

  test("condense address", () {
    final condensedAddress = AddressUtils.condenseAddress(firoAddress);
    expect(condensedAddress, "a6ESW...3Yt1j");
  });

  test("parse a valid firo uri string A", () {
    final uri = "firo:$firoAddress?amount=50&label=eggs";
    final result = AddressUtils.parseFiroUri(uri);
    expect(result, {"address": firoAddress, "amount": "50", "label": "eggs"});
  });

  test("parse a valid firo uri string B", () {
    final uri = "firo:$firoAddress?amount=50&message=eggs+are+good";
    final result = AddressUtils.parseFiroUri(uri);
    expect(result,
        {"address": firoAddress, "amount": "50", "message": "eggs are good"});
  });

  test("parse a valid firo uri string C", () {
    final uri = "firo:$firoAddress?amount=50.1&message=eggs%20are%20good%21";
    final result = AddressUtils.parseFiroUri(uri);
    expect(result, {
      "address": firoAddress,
      "amount": "50.1",
      "message": "eggs are good!"
    });
  });

  test("parse an invalid firo uri string", () {
    final uri = "firo$firoAddress?amount=50&label=eggs";
    final result = AddressUtils.parseFiroUri(uri);
    expect(result, {});
  });

  test("parse an invalid firo uri string", () {
    final uri = "$firoAddress?amount=50&label=eggs";
    final result = AddressUtils.parseFiroUri(uri);
    expect(result, {});
  });

  test("parse an invalid firo uri string", () {
    final uri = ":::  8 \\ %23";
    expect(AddressUtils.parseFiroUri(uri), {});
  });

  test("encode a list of (mnemonic) words/strings as a json object", () {
    final List<String> list = [
      "hello",
      "word",
      "something",
      "who",
      "green",
      "seven"
    ];
    final result = AddressUtils.encodeQRSeedData(list);
    expect(result,
        '{"mnemonic":["hello","word","something","who","green","seven"]}');
  });

  test("decode a valid json string to Map<String, dynamic>", () {
    final jsonString =
        '{"mnemonic":["hello","word","something","who","green","seven"]}';
    final result = AddressUtils.decodeQRSeedData(jsonString);
    expect(result, {
      "mnemonic": ["hello", "word", "something", "who", "green", "seven"]
    });
  });

  test("decode an invalid json string to Map<String, dynamic>", () {
    final jsonString =
        '{"mnemonic":"hello","word","something","who","green","seven"]}';

    expect(AddressUtils.decodeQRSeedData(jsonString), {});
  });

  test("build a firo uri string with null params", () {
    expect(AddressUtils.buildFiroUriString(firoAddress, null),
        "firo:$firoAddress");
  });

  test("build a firo uri string with empty params", () {
    expect(
        AddressUtils.buildFiroUriString(firoAddress, {}), "firo:$firoAddress");
  });

  test("build a firo uri string with one param", () {
    expect(AddressUtils.buildFiroUriString(firoAddress, {"amount": "10.0123"}),
        "firo:$firoAddress?amount=10.0123");
  });

  test("build a firo uri string with some params", () {
    expect(
        AddressUtils.buildFiroUriString(firoAddress,
            {"amount": "10.0123", "message": "Some kind of message!"}),
        "firo:$firoAddress?amount=10.0123&message=Some+kind+of+message%21");
  });
}
