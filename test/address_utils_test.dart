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

  test("parse a valid firo uri string", () {
    final uri = "firo:$firoAddress?amount=50&label=eggs";
    final result = AddressUtils.parseFiroUri(uri);
    expect(result, {"address": firoAddress, "amount": "50", "label": "eggs"});
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
    final uri = "$firoAddress?amount=50&label";
    final result = AddressUtils.parseFiroUri(uri);
    expect(result, {});
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
}
