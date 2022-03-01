import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_test/hive_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:paymint/electrumx_rpc/cached_electrumx.dart';
import 'package:paymint/electrumx_rpc/electrumx.dart';
import 'package:paymint/services/coins/firo/firo_wallet.dart';
import 'package:paymint/services/price.dart';
import 'package:paymint/utilities/flutter_secure_storage_interface.dart';
import 'package:paymint/utilities/misc_global_constants.dart';

import 'firo_wallet_tests.mocks.dart';

const TEST_MNEMONIC =
    "remove veteran gauge wink fatigue cabbage better hello wave resist hybrid cigar middle can weasel enemy skirt insane helmet enter error circle fringe elder";

@GenerateMocks([ElectrumX, CachedElectrumX, PriceAPI])
void main() {
  group("isolate functions", () {
    test("isolateDerive", () async {
      final String expected =
          "{receive: {0: {publicKey: 028a6fa0dcf5314a30dffa52359ddb5aaccbbf688be1dfc80d1f50965063a2f3bd, wif: Y89ZczwBXGsZRRqkEwCg6VuYxGBi7WE3t3YSUbBj6dpHGjsjtAQn, fingerprint: 554cc019, identifier: 554cc01944a2348d9d50ad82ac228e21ca9d5c25, privateKey: 64e7db4d1cbdc3d42486ad22b4a82107b37b00fd34e4dcb7c1cb96dd3d5d08b1, address: a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg}, 1: {publicKey: 03bd5fa496a7d0f6a03226c8a1b409a8cf8592c80a5fdd6be3898be252198b1a1b, wif: Y69vfLprpkMSggL2f7nuLeFzuUzXLfWTdT86Yd4QE5NVZhpKL7et, fingerprint: fc7544c6, identifier: fc7544c6de770f98566e5dec658739ea75b6f5c0, privateKey: 296ae266cab52ccab7d319d3f4e6c1f6809718ef1d81d46357aa7f2e5aa776ee, address: aPjLWDTPQsoPHUTxKBNRzoebDALj3eTcfh}}, change: {0: {publicKey: 02a836833368f4aa4d816885d040bcef272df17b15699d91eb518247bf5f5a63cd, wif: Y72goAZiXHPC44z8MofZx9J4YXYUkZ2vmQkfXTSpAguKR2H1YtL5, fingerprint: 3450f222, identifier: 3450f222ab3cb69839a924d273cffa6a5c88425c, privateKey: 4387e71d6cbbb9b3b637c6b691d128e2a42535231d67a8bdc0eb423f726d4a69, address: a5V5r6We6mNZzWJwGwEeRML3mEYLjvK39w}, 1: {publicKey: 0300a1c74a8fd1160b72408b487cd8e6ec0724233a959b9a088d6ea49a9b9d329f, wif: YBEtVRmn3Ya4j4UmNy9mRCEHFJe5KctG1paXwGK13zNp8LnArnzH, fingerprint: 5e9eda13, identifier: 5e9eda137c30ba672e7d8ab5d1c257ea6b4f6ea2, privateKey: c1284d986be87475c4bfaf94c54798cfd5719445020bb54afca67115070ef4e9, address: a9LmZA6xgyijdCx8UZKJahHeAuUoHrCY1T}}}";
      final result = await isolateDerive(TEST_MNEMONIC, 0, 2, firoNetwork);
      expect(result, isA<Map<String, dynamic>>());
      expect(result.toString(), expected);
    });

    test("isolateRestore", () {
      // TODO extremely large data set parameters
      expect(1, 0);
    });

    test("isolateCreateJoinSplitTransaction", () {
      // TODO extremely large data set parameters
      expect(1, 0);
    });

    test("isolateEstimateJoinSplitFee", () {
      // TODO extremely large data set parameters
      expect(1, 0);
    });

    test("isolateCreateJoinSplitTransaction", () {
      // TODO extremely large data set parameters
      expect(1, 0);
    });
  });

  group("Other standalone functions in firo_wallet.dart", () {
    test("stringToUint8List", () {
      final Uint8List expected = Uint8List.fromList([
        2,
        138,
        111,
        160,
        220,
        245,
        49,
        74,
        48,
        223,
        250,
        82,
        53,
        157,
        219,
        90,
        172,
        203,
        191,
        104,
        139,
        225,
        223,
        200,
        13,
        31,
        80,
        150,
        80,
        99,
        162,
        243,
        189
      ]);

      final result = stringToUint8List(
          "028a6fa0dcf5314a30dffa52359ddb5aaccbbf688be1dfc80d1f50965063a2f3bd");
      expect(result, expected);
    });

    test("uint8listToString", () {
      final String expected =
          "028a6fa0dcf5314a30dffa52359ddb5aaccbbf688be1dfc80d1f50965063a2f3bd";
      final result = uint8listToString(Uint8List.fromList([
        2,
        138,
        111,
        160,
        220,
        245,
        49,
        74,
        48,
        223,
        250,
        82,
        53,
        157,
        219,
        90,
        172,
        203,
        191,
        104,
        139,
        225,
        223,
        200,
        13,
        31,
        80,
        150,
        80,
        99,
        162,
        243,
        189
      ]));

      expect(result, expected);
    });

    test("Firo main net parameters", () {
      expect(firoNetwork.messagePrefix, '\x18Zcoin Signed Message:\n');
      expect(firoNetwork.bech32, 'bc');
      expect(firoNetwork.bip32.private, 0x0488ade4);
      expect(firoNetwork.bip32.public, 0x0488b21e);
      expect(firoNetwork.pubKeyHash, 0x52);
      expect(firoNetwork.scriptHash, 0x07);
      expect(firoNetwork.wif, 0xd2);
    });

    test("Firo test net parameters", () {
      expect(firoTestNetwork.messagePrefix, '\x18Zcoin Signed Message:\n');
      expect(firoTestNetwork.bech32, 'bc');
      expect(firoTestNetwork.bip32.private, 0x04358394);
      expect(firoTestNetwork.bip32.public, 0x043587cf);
      expect(firoTestNetwork.pubKeyHash, 0x41);
      expect(firoTestNetwork.scriptHash, 0xb2);
      expect(firoTestNetwork.wif, 0xb9);
    });

    test("getBip32Node", () {
      final node = getBip32Node(0, 3, TEST_MNEMONIC, firoNetwork);
      expect(node.index, 3);
      expect(node.chainCode.toList(), [
        4,
        103,
        117,
        199,
        205,
        216,
        252,
        240,
        107,
        103,
        248,
        128,
        251,
        137,
        43,
        118,
        33,
        225,
        210,
        142,
        10,
        11,
        151,
        246,
        139,
        3,
        180,
        163,
        114,
        140,
        219,
        139
      ]);
      expect(node.depth, 5);
      expect(node.toBase58(),
          "xprvA2UUyZWw4nzpGJgmwqGPQs48EaWhmvoSTHpsPetjAkzEVhhMi5HY3KBQkieADMZXn3mxQF86LC7FgB4wh1d2NrSfsBg3KF7dp1jhMVWWfoH");
      expect(node.publicKey.toList(), [
        3,
        69,
        153,
        139,
        34,
        11,
        240,
        39,
        195,
        11,
        59,
        81,
        2,
        72,
        234,
        177,
        159,
        234,
        89,
        142,
        115,
        196,
        209,
        190,
        175,
        136,
        142,
        12,
        121,
        225,
        242,
        213,
        196
      ]);
      expect(node.privateKey.toList(), [
        88,
        198,
        166,
        119,
        116,
        42,
        91,
        186,
        229,
        100,
        126,
        149,
        189,
        155,
        172,
        58,
        246,
        56,
        87,
        62,
        242,
        46,
        16,
        195,
        127,
        37,
        137,
        72,
        4,
        247,
        198,
        58
      ]);
      expect(node.parentFingerprint, 110000429);
      expect(node.fingerprint.toList(), [16, 167, 198, 127]);
    });

    test("getJMintTransactions", () {
      // TODO extremely large data set parameters
      expect(1, 0);
    });

    test("getAnonymitySet", () async {
      final cachedClient = MockCachedElectrumX();
      when(cachedClient.getAnonymitySet(
              groupId: "1", coinName: "Firo", callOutSideMainIsolate: false))
          .thenAnswer((_) async => {
                "blockHash":
                    "c8e0ee6b8f7c1c85973e2b09321dc8644483f19dd7677ab0f33f7ffb1c6a0ec1",
                "setHash":
                    "3d67502ae9e9d21d452dbbad1d961c6fcf594a3e44e9ca7b874f991a4c0e2f2d",
                "serializedCoins": [
                  "388b82fdc27fd4a64c3290578d00b210bf9aa0bd9e4b08be1913bf95877bead00100",
                  "a554e4b700c161adefbe7933c6e2784cc029a590d75c7ad35407323e7579e8680100",
                  "162ec5f41380f590462514615fae016ff674e3e07513039d16f90161d88d83220000",
                  "... ~50000 more strings ...",
                  "6482f50f21b38246f3f9f074cbf61b00ad175b63a946467a85bd22fe1a89825b0100",
                  "7a9e57560d4abc384a48bf850a12df94e83d33496bb456aad26e7317921845330000",
                  "a7a8ddf79fdaf6846c0c19eb00ba7a95713a1a62df91761cb74b122606385fb80000"
                ]
              });

      final result = await getAnonymitySet(cachedClient, false, "Firo");

      expect(result, isA<Map<String, dynamic>>());
      expect(result["blockHash"],
          "c8e0ee6b8f7c1c85973e2b09321dc8644483f19dd7677ab0f33f7ffb1c6a0ec1");
      expect(result["setHash"],
          "3d67502ae9e9d21d452dbbad1d961c6fcf594a3e44e9ca7b874f991a4c0e2f2d");
      expect(result["serializedCoins"], isA<List<String>>());
    });

    test("getBlockHead", () async {
      final client = MockElectrumX();
      when(client.getBlockHeadTip()).thenAnswer(
          (_) async => {"height": 4359032, "hex": "... some block hex ..."});

      int result = await getBlockHead(client);
      expect(result, 4359032);
    });
  });

  group("validate firo addresses", () {
    setUp(() async {
      await setUpTestHive();
    });

    test("check valid firo main net address", () async {
      final firo = FiroWallet(
        walletName: 'unit test',
        walletId: 'some id',
        networkType: FiroNetworkType.main,
        client: MockElectrumX(),
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
      );

      expect(firo.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), true);
    });

    test("check invalid firo main net address", () async {
      final firo = FiroWallet(
        walletName: 'unit test',
        walletId: 'some id',
        networkType: FiroNetworkType.main,
        client: MockElectrumX(),
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
      );

      expect(firo.validateAddress("sDda3fsd4af"), false);
    });

    test("check valid firo test net address against main net", () async {
      final firo = FiroWallet(
        walletName: 'unit test',
        walletId: 'some id',
        networkType: FiroNetworkType.main,
        client: MockElectrumX(),
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
      );

      expect(firo.validateAddress("THqfkegzJjpF4PQFAWPhJWMWagwHecfqva"), false);
    });

    test("check valid firo test net address", () async {
      final firo = FiroWallet(
        walletName: 'unit test',
        walletId: 'some id',
        networkType: FiroNetworkType.test,
        client: MockElectrumX(),
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
      );

      expect(firo.validateAddress("THqfkegzJjpF4PQFAWPhJWMWagwHecfqva"), true);
    });

    test("check invalid firo test net address", () async {
      final firo = FiroWallet(
        walletName: 'unit test',
        walletId: 'some id',
        networkType: FiroNetworkType.test,
        client: MockElectrumX(),
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
      );

      expect(firo.validateAddress("sDda3fsd4af"), false);
    });

    test("check valid firo address against test net", () async {
      final firo = FiroWallet(
        walletName: 'unit test',
        walletId: 'some id',
        networkType: FiroNetworkType.test,
        client: MockElectrumX(),
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
      );

      expect(firo.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), false);
    });

    tearDown(() async {
      await tearDownTestHive();
    });
  });

  group("testNetworkConnection", () {
    test("try connecting to main net server when configured to use main net",
        () async {
      final client = MockElectrumX();
      when(client.getServerFeatures()).thenAnswer((_) async => {
            "hosts": {},
            "pruning": null,
            "server_version": "Unit tests",
            "protocol_min": "1.4",
            "protocol_max": "1.4.2",
            "genesis_hash": FiroGenesisHash,
            "hash_function": "sha256",
            "services": []
          });
      final firo = FiroWallet(
        walletName: 'unit test',
        walletId: 'some id',
        networkType: FiroNetworkType.main,
        client: client,
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
      );
      final bool result = await firo.testNetworkConnection(
        CampfireConstants.defaultIpAddress,
        CampfireConstants.defaultPort,
        CampfireConstants.defaultUseSSL,
      );

      expect(result, true);
    });

    test("try connecting to test net server when configured to use test net",
        () async {
      final client = MockElectrumX();
      when(client.getServerFeatures()).thenAnswer((_) async => {
            "hosts": {},
            "pruning": null,
            "server_version": "Unit tests",
            "protocol_min": "1.4",
            "protocol_max": "1.4.2",
            "genesis_hash": FiroTestGenesisHash,
            "hash_function": "sha256",
            "services": []
          });
      final firo = FiroWallet(
        walletName: 'unit test',
        walletId: 'some id',
        networkType: FiroNetworkType.test,
        client: client,
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
      );
      final bool result = await firo.testNetworkConnection(
        CampfireConstants.defaultIpAddressTestNet,
        CampfireConstants.defaultPortTestNet,
        CampfireConstants.defaultUseSSLTestNet,
      );

      expect(result, true);
    });

    test("try connecting to test net server when configured to use main net",
        () async {
      final client = MockElectrumX();
      when(client.getServerFeatures()).thenAnswer((_) async => {
            "hosts": {},
            "pruning": null,
            "server_version": "Unit tests",
            "protocol_min": "1.4",
            "protocol_max": "1.4.2",
            "genesis_hash": FiroTestGenesisHash,
            "hash_function": "sha256",
            "services": []
          });
      final firo = FiroWallet(
        walletName: 'unit test',
        walletId: 'some id',
        networkType: FiroNetworkType.main,
        client: client,
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
      );
      final bool result = await firo.testNetworkConnection(
        CampfireConstants.defaultIpAddressTestNet,
        CampfireConstants.defaultPortTestNet,
        CampfireConstants.defaultUseSSLTestNet,
      );

      expect(result, false);
    });

    test("try connecting to main net server when configured to use test net",
        () async {
      final client = MockElectrumX();
      when(client.getServerFeatures()).thenAnswer((_) async => {
            "hosts": {},
            "pruning": null,
            "server_version": "Unit tests",
            "protocol_min": "1.4",
            "protocol_max": "1.4.2",
            "genesis_hash": FiroGenesisHash,
            "hash_function": "sha256",
            "services": []
          });
      final firo = FiroWallet(
        walletName: 'unit test',
        walletId: 'some id',
        networkType: FiroNetworkType.test,
        client: client,
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
      );
      final bool result = await firo.testNetworkConnection(
        CampfireConstants.defaultIpAddress,
        CampfireConstants.defaultPort,
        CampfireConstants.defaultUseSSL,
      );

      expect(result, false);
    });
  });

  group("getMnemonicList", () {
    test("fetch and convert properly stored mnemonic to list of words",
        () async {
      final store = FakeSecureStorage();
      store.write(key: "some id_mnemonic", value: TEST_MNEMONIC);

      final firo = FiroWallet(
        walletName: 'unit test',
        walletId: 'some id',
        networkType: FiroNetworkType.test,
        client: MockElectrumX(),
        cachedClient: MockCachedElectrumX(),
        secureStore: store,
      );
      final List<String> result = await firo.getMnemonicList();

      expect(result, [
        "remove",
        "veteran",
        "gauge",
        "wink",
        "fatigue",
        "cabbage",
        "better",
        "hello",
        "wave",
        "resist",
        "hybrid",
        "cigar",
        "middle",
        "can",
        "weasel",
        "enemy",
        "skirt",
        "insane",
        "helmet",
        "enter",
        "error",
        "circle",
        "fringe",
        "elder"
      ]);
    });

    test("attempt fetch and convert non existent mnemonic to list of words",
        () async {
      final store = FakeSecureStorage();
      store.write(key: "some id_mnemonic", value: TEST_MNEMONIC);

      final firo = FiroWallet(
        walletName: 'unit test',
        walletId: 'some other id',
        networkType: FiroNetworkType.test,
        client: MockElectrumX(),
        cachedClient: MockCachedElectrumX(),
        secureStore: store,
      );
      expectLater(
          () => firo.getMnemonicList(), throwsA(isA<NoSuchMethodError>()));
    });
  });

  group("send", () {
    // todo build send tests
  });

  group("initializeWallet", () {
    // todo build tests
  });

  group("refreshIfThereIsNewData", () {
    // todo build tests
  });

  group("getAllTxsToWatch", () {
    // todo build tests
  });

  group("submitHexToNetwork", () {
    // todo build tests
  });

  group("buildMintTransaction", () {
    // todo build tests
  });

  group("fillAddresses", () {
    // todo build tests
  });

  group("recoverFromMnemonic", () {
    // todo build tests
  });

  group("updateBiometricsUsage", () {
    // todo build tests
  });

  group("changeCurrency", () {
    // todo build tests
  });

  group("getLatestSetId", () {
    // todo build tests
  });

  group("getSetData", () {
    // todo build tests
  });

  group("getUsedCoinSerials", () {
    // todo build tests
  });

  group("exit", () {
    // todo build tests
  });

  group("refresh", () {
    // todo build tests
  });
}
