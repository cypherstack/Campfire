import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:paymint/electrumx_rpc/cached_electrumx.dart';
import 'package:paymint/electrumx_rpc/electrumx.dart';
import 'package:paymint/models/models.dart';
import 'package:paymint/services/coins/firo/firo_wallet.dart';
import 'package:paymint/services/price.dart';
import 'package:paymint/utilities/flutter_secure_storage_interface.dart';
import 'package:paymint/utilities/misc_global_constants.dart';

import 'firo_wallet_test_parameters.dart';
import 'firo_wallet_tests.mocks.dart';

@GenerateMocks([ElectrumX, CachedElectrumX, PriceAPI])
void main() {
  group("isolate functions", () {
    test("isolateDerive", () async {
      final result =
          await isolateDerive(IsolateDeriveParams.mnemonic, 0, 2, firoNetwork);
      expect(result, isA<Map<String, dynamic>>());
      expect(result.toString(), IsolateDeriveParams.expected);
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
      final node = getBip32Node(0, 3, Bip32TestParams.mnemonic, firoNetwork);
      expect(node.index, 3);
      expect(node.chainCode.toList(), Bip32TestParams.chainCodeList);
      expect(node.depth, 5);
      expect(node.toBase58(), Bip32TestParams.base58);
      expect(node.publicKey.toList(), Bip32TestParams.publicKeyList);
      expect(node.privateKey.toList(), Bip32TestParams.privateKeyList);
      expect(node.parentFingerprint, Bip32TestParams.parentFingerprint);
      expect(node.fingerprint.toList(), Bip32TestParams.fingerprintList);
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
      store.write(
          key: "some id_mnemonic", value: "some test mnemonic string of words");

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
        "some",
        "test",
        "mnemonic",
        "string",
        "of",
        "words",
      ]);
    });

    test("attempt fetch and convert non existent mnemonic to list of words",
        () async {
      final store = FakeSecureStorage();
      store.write(
          key: "some id_mnemonic", value: "some test mnemonic string of words");

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

  group("FiroWallet service class functions that depend on shared storage", () {
    final firoNetworkType = FiroNetworkType.main;
    final testWalletId = "testWalletID";
    final testWalletName = "Test Wallet";

    setUpAll(() async {
      await setUpTestHive();

      // Registering Transaction Model Adapters
      Hive.registerAdapter(TransactionDataAdapter());
      Hive.registerAdapter(TransactionChunkAdapter());
      Hive.registerAdapter(TransactionAdapter());
      Hive.registerAdapter(InputAdapter());
      Hive.registerAdapter(OutputAdapter());

      // Registering Utxo Model Adapters
      Hive.registerAdapter(UtxoDataAdapter());
      Hive.registerAdapter(UtxoObjectAdapter());
      Hive.registerAdapter(StatusAdapter());

      // Registering Lelantus Model Adapters
      Hive.registerAdapter(LelantusCoinAdapter());
      final wallets = await Hive.openBox('wallets');
      await wallets.put('currentWalletName', "");
      // await secureStore.write(key: "${testWalletId}_mnemonic", value: mnemonic);
    });

    test("initializeWallet", () async {
      final client = MockElectrumX();
      final cachedClient = MockCachedElectrumX();
      final secureStore = FakeSecureStorage();

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

      final List<Map<String, dynamic>> emptyList = [];

      when(client.getUTXOs(scripthash: anyNamed("scripthash")))
          .thenAnswer((_) async => emptyList);
      when(client.getHistory(scripthash: anyNamed("scripthash")))
          .thenAnswer((_) async => emptyList);

      final firo = FiroWallet(
        walletName: testWalletName,
        walletId: testWalletId,
        networkType: firoNetworkType,
        client: client,
        cachedClient: cachedClient,
        secureStore: secureStore,
      );

      await firo.initializeWallet();

      final wallet = await Hive.openBox(testWalletId);

      var result = await wallet.get("activeNodeName");
      expect(result, "Campfire default");

      result = await wallet.get("addressBookEntries");
      expect(result, {});

      result = await wallet.get("blocked_tx_hashes");
      expect(result, ["0xdefault"]);

      result = await wallet.get("changeAddresses");
      expect(result, isA<List<String>>());
      expect(result.length, 1);

      result = await wallet.get("changeIndex");
      expect(result, 0);

      result = await wallet.get("id");
      expect(result, testWalletId);

      result = await wallet.get("jindex");
      expect(result, []);

      result = await wallet.get("mintIndex");
      expect(result, 0);

      result = await wallet.get("nodes");
      expect(result.length, 1);
      expect(result[CampfireConstants.defaultNodeName]["ipAddress"],
          "electrumx-firo.cypherstack.com");
      expect(result[CampfireConstants.defaultNodeName]["port"], "50002");
      expect(result[CampfireConstants.defaultNodeName]["useSSL"], true);

      result = await wallet.get("preferredFiatCurrency");
      expect(result, "USD");

      result = await wallet.get("receivingAddresses");
      expect(result, isA<List<String>>());
      expect(result.length, 1);

      result = await wallet.get("receivingIndex");
      expect(result, 0);
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

    test("fillAddresses", () async {
      final client = MockElectrumX();
      final cachedClient = MockCachedElectrumX();
      final secureStore = FakeSecureStorage();
      final firo = FiroWallet(
        walletName: testWalletName,
        walletId: testWalletId,
        networkType: firoNetworkType,
        client: client,
        cachedClient: cachedClient,
        secureStore: secureStore,
      );

      await firo.fillAddresses(FillAddressesParams.mnemonic);
      final wallet = await Hive.openBox(testWalletId);
      final receiveDerivations = await wallet.get('receiveDerivations');
      final changeDerivations = await wallet.get('changeDerivations');

      expect(receiveDerivations.toString(),
          FillAddressesParams.expectedReceiveDerivationsString);

      expect(changeDerivations.toString(),
          FillAddressesParams.expectedChangeDerivationsString);
    });

    // the above test needs to pass in order for this test to pass
    test("buildMintTransaction", () async {
      List<UtxoObject> utxos = [
        UtxoObject(
            txid: BuildMintTxTestParams.utxoInfo["txid"],
            vout: BuildMintTxTestParams.utxoInfo["vout"],
            value: BuildMintTxTestParams.utxoInfo["value"])
      ];
      final sats = 9658;
      final client = MockElectrumX();
      final cachedClient = MockCachedElectrumX();
      final secureStore = FakeSecureStorage();

      when(cachedClient.getTransaction(
              tx_hash: BuildMintTxTestParams.utxoInfo["txid"],
              coinName: "Firo",
              callOutSideMainIsolate: false))
          .thenAnswer((_) async => BuildMintTxTestParams.cachedClientResponse);

      when(client.getBlockHeadTip()).thenAnswer(
          (_) async => {"height": 455873, "hex": "this value not used here"});

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

      // final List<Map<String, dynamic>> emptyList = [];
      //
      // when(client.getUTXOs(scripthash: anyNamed("scripthash")))
      //     .thenAnswer((_) async => emptyList);
      // when(client.getHistory(scripthash: anyNamed("scripthash")))
      //     .thenAnswer((_) async => emptyList);

      //TODO proper mock price api
      // final priceAPI = MockPriceAPI();
      // when(priceAPI.getPrice(ticker: "FIRO", baseCurrency: "USD")).thenAnswer((_) async => Decimal.fromInt(10));

      final firo = FiroWallet(
        walletName: testWalletName,
        walletId: testWalletId,
        networkType: firoNetworkType,
        client: client,
        cachedClient: cachedClient,
        secureStore: secureStore,
      );

      final wallet = await Hive.openBox(testWalletId);

      await wallet.put("mintIndex", 0);
      await wallet.put(
          'receiveDerivations', BuildMintTxTestParams.receiveDerivations);
      await wallet.put(
          'changeDerivations', BuildMintTxTestParams.changeDerivations);

      await secureStore.write(
          key: "${testWalletId}_mnemonic",
          value: BuildMintTxTestParams.mnemonic);

      final result = await firo.buildMintTransaction(utxos, sats);

      expect(result["txHex"], BuildMintTxTestParams.txHex);
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

    group("refresh", () {
      // todo build tests
    });

    group("send", () {
      // todo build send tests
    });

    group("exit", () {
      // todo build tests
    });

    tearDownAll(() async {
      await tearDownTestHive();
    });
  });
}
