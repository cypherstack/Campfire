import 'dart:async';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
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

import 'firo_wallet_test.mocks.dart';
import 'firo_wallet_test_parameters.dart';
import 'getcoinsforrecovery_sample_output.dart';
import 'gethistory_samples.dart';
import 'transaction_data_samples.dart';

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

    group("getJMintTransactions", () {
      test(
          "getJMintTransactions throws Error due to some invalid transactions passed to this function",
          () {
        final cachedClient = MockCachedElectrumX();
        final priceAPI = MockPriceAPI();

        // mock price calls
        when(priceAPI.getPrice(ticker: "FIRO", baseCurrency: "USD"))
            .thenAnswer((_) async => Decimal.fromInt(10));

        // mock transaction calls
        when(cachedClient.getTransaction(
                tx_hash: SampleGetTransactionData.txHash0,
                coinName: "Firo",
                callOutSideMainIsolate: false))
            .thenAnswer((_) async => SampleGetTransactionData.txData0);
        when(cachedClient.getTransaction(
                tx_hash: SampleGetTransactionData.txHash1,
                coinName: "Firo",
                callOutSideMainIsolate: false))
            .thenAnswer((_) async => SampleGetTransactionData.txData1);
        when(cachedClient.getTransaction(
                tx_hash: SampleGetTransactionData.txHash2,
                coinName: "Firo",
                callOutSideMainIsolate: false))
            .thenAnswer((_) async => SampleGetTransactionData.txData2);
        when(cachedClient.getTransaction(
                tx_hash: SampleGetTransactionData.txHash3,
                coinName: "Firo",
                callOutSideMainIsolate: false))
            .thenAnswer((_) async => SampleGetTransactionData.txData3);
        when(cachedClient.getTransaction(
                tx_hash: SampleGetTransactionData.txHash4,
                coinName: "Firo",
                callOutSideMainIsolate: false))
            .thenAnswer((_) async => SampleGetTransactionData.txData4);
        when(cachedClient.getTransaction(
                tx_hash: SampleGetTransactionData.txHash5,
                coinName: "Firo",
                callOutSideMainIsolate: false))
            .thenAnswer((_) async => SampleGetTransactionData.txData5);

        final transactions = [
          SampleGetTransactionData.txHash0,
          SampleGetTransactionData.txHash1,
          SampleGetTransactionData.txHash2,
          SampleGetTransactionData.txHash3,
          SampleGetTransactionData.txHash4,
          SampleGetTransactionData.txHash5,
        ];

        expect(
            () async => await getJMintTransactions(
                cachedClient, transactions, "USD", "Firo", false, priceAPI),
            throwsA(isA<Error>()));
      });

      test("getJMintTransactions success", () async {
        final cachedClient = MockCachedElectrumX();
        final priceAPI = MockPriceAPI();

        // mock price calls
        when(priceAPI.getPrice(ticker: "FIRO", baseCurrency: "USD"))
            .thenAnswer((_) async => Decimal.fromInt(10));

        // mock transaction calls
        when(cachedClient.getTransaction(
                tx_hash: SampleGetTransactionData.txHash0,
                coinName: "Firo",
                callOutSideMainIsolate: false))
            .thenAnswer((_) async => SampleGetTransactionData.txData0);

        when(cachedClient.getTransaction(
                tx_hash: SampleGetTransactionData.txHash2,
                coinName: "Firo",
                callOutSideMainIsolate: false))
            .thenAnswer((_) async => SampleGetTransactionData.txData2);

        when(cachedClient.getTransaction(
                tx_hash: SampleGetTransactionData.txHash4,
                coinName: "Firo",
                callOutSideMainIsolate: false))
            .thenAnswer((_) async => SampleGetTransactionData.txData4);

        when(cachedClient.getTransaction(
                tx_hash: SampleGetTransactionData.txHash6,
                coinName: "Firo",
                callOutSideMainIsolate: false))
            .thenAnswer((_) async => SampleGetTransactionData.txData6);

        final transactions = [
          SampleGetTransactionData.txHash0,
          SampleGetTransactionData.txHash2,
          SampleGetTransactionData.txHash4,
          SampleGetTransactionData.txHash6,
        ];

        final result = await getJMintTransactions(
            cachedClient, transactions, "USD", "Firo", false, priceAPI);

        expect(result, isA<List<Transaction>>());
        expect(result.length, 4);
      });
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
        priceAPI: MockPriceAPI(),
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
        priceAPI: MockPriceAPI(),
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
        priceAPI: MockPriceAPI(),
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
        priceAPI: MockPriceAPI(),
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
        priceAPI: MockPriceAPI(),
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
        priceAPI: MockPriceAPI(),
      );

      expect(firo.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), false);
    });
  });

  group("testNetworkConnection", () {
    test("attempted connection fails due to server error", () async {
      final client = MockElectrumX();
      when(client.getBlockHeadTip()).thenAnswer((_) async => null);

      final firo = FiroWallet(
        walletName: 'unit test',
        walletId: 'some id',
        networkType: FiroNetworkType.main,
        client: MockElectrumX(),
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
        priceAPI: MockPriceAPI(),
      );
      final bool result = await firo.testNetworkConnection(client);

      expect(result, false);
    });

    test("attempted connection fails due to exception", () async {
      final client = MockElectrumX();
      when(client.getBlockHeadTip()).thenThrow(Exception);

      final firo = FiroWallet(
        walletName: 'unit test',
        walletId: 'some id',
        networkType: FiroNetworkType.main,
        client: MockElectrumX(),
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
        priceAPI: MockPriceAPI(),
      );
      final bool result = await firo.testNetworkConnection(client);

      expect(result, false);
    });

    test("attempted connection test success", () async {
      final client = MockElectrumX();
      when(client.getBlockHeadTip()).thenAnswer(
          (_) async => {"height": 455873, "hex": "this value not used here"});

      final firo = FiroWallet(
        walletName: 'unit test',
        walletId: 'some id',
        networkType: FiroNetworkType.test,
        client: MockElectrumX(),
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
        priceAPI: MockPriceAPI(),
      );
      final bool result = await firo.testNetworkConnection(client);

      expect(result, true);
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
        priceAPI: MockPriceAPI(),
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
        priceAPI: MockPriceAPI(),
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
      final priceAPI = MockPriceAPI();
      when(priceAPI.getPrice(ticker: "FIRO", baseCurrency: "USD"))
          .thenAnswer((_) async => Decimal.fromInt(10));

      when(client.getServerFeatures()).thenAnswer((_) async => {
            "hosts": {},
            "pruning": null,
            "server_version": "Unit tests",
            "protocol_min": "1.4",
            "protocol_max": "1.4.2",
            "genesis_hash": CampfireConstants.firoGenesisHash,
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
        walletId: testWalletId + "initializeWallet",
        networkType: firoNetworkType,
        client: client,
        cachedClient: cachedClient,
        secureStore: secureStore,
        priceAPI: priceAPI,
      );

      await firo.initializeWallet();

      final wallet = await Hive.openBox(testWalletId + "initializeWallet");

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
      expect(result, testWalletId + "initializeWallet");

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

    test("getAllTxsToWatch", () async {
      final client = MockElectrumX();
      final cachedClient = MockCachedElectrumX();
      final secureStore = FakeSecureStorage();
      final priceAPI = MockPriceAPI();

      final firo = FiroWallet(
        walletName: testWalletName,
        walletId: testWalletId + "getAllTxsToWatch",
        networkType: firoNetworkType,
        client: client,
        cachedClient: cachedClient,
        secureStore: secureStore,
        priceAPI: priceAPI,
      );

      await firo.getAllTxsToWatch(txData, lTxData);

      expect(firo.unconfirmedTxs, {
        "51576e2230c2911a508aabb85bb50045f04b8dc958790ce2372986c3ebbe7d3e",
        "f4217364cbe6a81ef7ecaaeba0a6d6b576a9850b3e891fa7b88ed4927c505218"
      });
    });

    group("refreshIfThereIsNewData", () {
      test("refreshIfThereIsNewData with no unconfirmed transactions",
          () async {
        final client = MockElectrumX();
        final cachedClient = MockCachedElectrumX();
        final secureStore = FakeSecureStorage();
        final priceAPI = MockPriceAPI();

        // mock price calls
        when(priceAPI.getPrice(ticker: "FIRO", baseCurrency: "USD"))
            .thenAnswer((_) async => Decimal.fromInt(10));

        // mock history calls
        when(client.getHistory(scripthash: SampleGetHistoryData.scripthash0))
            .thenAnswer((_) async => SampleGetHistoryData.data0);
        when(client.getHistory(scripthash: SampleGetHistoryData.scripthash1))
            .thenAnswer((_) async => SampleGetHistoryData.data1);
        when(client.getHistory(scripthash: SampleGetHistoryData.scripthash2))
            .thenAnswer((_) async => SampleGetHistoryData.data2);
        when(client.getHistory(scripthash: SampleGetHistoryData.scripthash3))
            .thenAnswer((_) async => SampleGetHistoryData.data3);

        // mock transaction calls
        when(cachedClient.getTransaction(
                tx_hash: SampleGetTransactionData.txHash0,
                coinName: "Firo",
                callOutSideMainIsolate: false))
            .thenAnswer((_) async => SampleGetTransactionData.txData0);
        when(cachedClient.getTransaction(
                tx_hash: SampleGetTransactionData.txHash1,
                coinName: "Firo",
                callOutSideMainIsolate: false))
            .thenAnswer((_) async => SampleGetTransactionData.txData1);
        when(cachedClient.getTransaction(
                tx_hash: SampleGetTransactionData.txHash2,
                coinName: "Firo",
                callOutSideMainIsolate: false))
            .thenAnswer((_) async => SampleGetTransactionData.txData2);
        when(cachedClient.getTransaction(
                tx_hash: SampleGetTransactionData.txHash3,
                coinName: "Firo",
                callOutSideMainIsolate: false))
            .thenAnswer((_) async => SampleGetTransactionData.txData3);
        when(cachedClient.getTransaction(
                tx_hash: SampleGetTransactionData.txHash4,
                coinName: "Firo",
                callOutSideMainIsolate: false))
            .thenAnswer((_) async => SampleGetTransactionData.txData4);
        when(cachedClient.getTransaction(
                tx_hash: SampleGetTransactionData.txHash5,
                coinName: "Firo",
                callOutSideMainIsolate: false))
            .thenAnswer((_) async => SampleGetTransactionData.txData5);
        when(cachedClient.getTransaction(
                tx_hash: SampleGetTransactionData.txHash6,
                coinName: "Firo",
                callOutSideMainIsolate: false))
            .thenAnswer((_) async => SampleGetTransactionData.txData6);

        final firo = FiroWallet(
          walletName: testWalletName,
          walletId: testWalletId + "refreshIfThereIsNewData",
          networkType: firoNetworkType,
          client: client,
          cachedClient: cachedClient,
          secureStore: secureStore,
          priceAPI: priceAPI,
        );

        firo.unconfirmedTxs = {};

        final wallet =
            await Hive.openBox(testWalletId + "refreshIfThereIsNewData");
        await wallet.put('receivingAddresses', [
          "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg",
          "aPjLWDTPQsoPHUTxKBNRzoebDALj3eTcfh",
          "aKmXfS7nEZdqWBGRdAXcyMoEoKhZQDPBoq",
        ]);

        await wallet.put('changeAddresses', [
          "a5V5r6We6mNZzWJwGwEeRML3mEYLjvK39w",
        ]);

        final result = await firo.refreshIfThereIsNewData();
        expect(result, false);
      });

      test("refreshIfThereIsNewData with two unconfirmed transactions",
          () async {
        final client = MockElectrumX();
        final cachedClient = MockCachedElectrumX();
        final secureStore = FakeSecureStorage();
        final priceAPI = MockPriceAPI();

        when(client.getTransaction(tx_hash: SampleGetTransactionData.txHash6))
            .thenAnswer((_) async => SampleGetTransactionData.txData6);

        when(client.getTransaction(
                tx_hash:
                    "f4217364cbe6a81ef7ecaaeba0a6d6b576a9850b3e891fa7b88ed4927c505218"))
            .thenAnswer((_) async => SampleGetTransactionData.txData7);

        final firo = FiroWallet(
          walletName: testWalletName,
          walletId: testWalletId + "refreshIfThereIsNewData",
          networkType: firoNetworkType,
          client: client,
          cachedClient: cachedClient,
          secureStore: secureStore,
          priceAPI: priceAPI,
        );

        await firo.getAllTxsToWatch(txData, lTxData);

        final result = await firo.refreshIfThereIsNewData();

        expect(result, true);
      });
    });

    test("submitHexToNetwork", () async {
      final client = MockElectrumX();
      final cachedClient = MockCachedElectrumX();
      final secureStore = FakeSecureStorage();
      final priceAPI = MockPriceAPI();

      when(client.broadcastTransaction(
              rawTx:
                  "0200000001ddba3ce3a3ab07d342183fa6743d3b620149c1db26efa239323384d82f9e2859010000006a47304402207d4982586eb4b0de17ee88f8eae4aaf7bc68590ae048e67e75932fe84a73f7f3022011392592558fb39d8c132234ad34a2c7f5071d2dab58d8c9220d343078413497012102f123ab9dbd627ab572de7cd77eda6e3781213a2ef4ab5e0d6e87f1c0d944b2caffffffff01e42e000000000000a5c5bc76bae786dc3a7d939757c34e15994d403bdaf418f9c9fa6eb90ac6e8ffc3550100772ad894f285988789669acd69ba695b9485c90141d7833209d05bcdad1b898b0000f5cba1a513dd97d81f89159f2be6eb012e987335fffa052c1fbef99550ba488fb6263232e7a0430c0a3ca8c728a5d8c8f2f985c8b586024a0f488c73130bd5ec9e7c23571f23c2d34da444ecc2fb65a12cee2ad3b8d3fcc337a2c2a45647eb43cff50600"))
          .thenAnswer((_) async =>
              "b36161c6e619395b3d40a851c45c1fef7a5c541eed911b5524a66c5703a689c9");

      final firo = FiroWallet(
        walletName: testWalletName,
        walletId: testWalletId + "submitHexToNetwork",
        networkType: firoNetworkType,
        client: client,
        cachedClient: cachedClient,
        secureStore: secureStore,
        priceAPI: priceAPI,
      );

      final txid = await firo.submitHexToNetwork(
          "0200000001ddba3ce3a3ab07d342183fa6743d3b620149c1db26efa239323384d82f9e2859010000006a47304402207d4982586eb4b0de17ee88f8eae4aaf7bc68590ae048e67e75932fe84a73f7f3022011392592558fb39d8c132234ad34a2c7f5071d2dab58d8c9220d343078413497012102f123ab9dbd627ab572de7cd77eda6e3781213a2ef4ab5e0d6e87f1c0d944b2caffffffff01e42e000000000000a5c5bc76bae786dc3a7d939757c34e15994d403bdaf418f9c9fa6eb90ac6e8ffc3550100772ad894f285988789669acd69ba695b9485c90141d7833209d05bcdad1b898b0000f5cba1a513dd97d81f89159f2be6eb012e987335fffa052c1fbef99550ba488fb6263232e7a0430c0a3ca8c728a5d8c8f2f985c8b586024a0f488c73130bd5ec9e7c23571f23c2d34da444ecc2fb65a12cee2ad3b8d3fcc337a2c2a45647eb43cff50600");

      expect(txid,
          "b36161c6e619395b3d40a851c45c1fef7a5c541eed911b5524a66c5703a689c9");
    });

    test("fillAddresses", () async {
      final client = MockElectrumX();
      final cachedClient = MockCachedElectrumX();
      final secureStore = FakeSecureStorage();
      final priceAPI = MockPriceAPI();

      final firo = FiroWallet(
        walletName: testWalletName,
        walletId: testWalletId + "fillAddresses",
        networkType: firoNetworkType,
        client: client,
        cachedClient: cachedClient,
        secureStore: secureStore,
        priceAPI: priceAPI,
      );

      await firo.fillAddresses(FillAddressesParams.mnemonic);
      final wallet = await Hive.openBox(testWalletId + "fillAddresses");
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

      await secureStore.write(
          key: "${testWalletId}buildMintTransaction_mnemonic",
          value: BuildMintTxTestParams.mnemonic);

      when(cachedClient.getTransaction(
              tx_hash: BuildMintTxTestParams.utxoInfo["txid"],
              coinName: "Firo",
              callOutSideMainIsolate: false))
          .thenAnswer((_) async => BuildMintTxTestParams.cachedClientResponse);

      when(client.getBlockHeadTip()).thenAnswer(
          (_) async => {"height": 455873, "hex": "this value not used here"});

      final priceAPI = MockPriceAPI();
      when(priceAPI.getPrice(ticker: "FIRO", baseCurrency: "USD"))
          .thenAnswer((_) async => Decimal.fromInt(10));

      final firo = FiroWallet(
        walletName: testWalletName,
        walletId: testWalletId + "buildMintTransaction",
        networkType: firoNetworkType,
        client: client,
        cachedClient: cachedClient,
        secureStore: secureStore,
        priceAPI: priceAPI,
      );

      final wallet = await Hive.openBox(testWalletId + "buildMintTransaction");

      await wallet.put("mintIndex", 0);
      await wallet.put(
          'receiveDerivations', BuildMintTxTestParams.receiveDerivations);
      await wallet.put(
          'changeDerivations', BuildMintTxTestParams.changeDerivations);

      final result = await firo.buildMintTransaction(utxos, sats);

      expect(result["txHex"], BuildMintTxTestParams.txHex);
    });

    test("recoverFromMnemonic", () {
      // todo build tests
      expect(0, 1);
    });

    test("updateBiometricsUsage", () async {
      final firo = FiroWallet(
        walletId: testWalletId + "updateBiometricsUsage",
        walletName: testWalletName,
        networkType: firoNetworkType,
        client: MockElectrumX(),
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
        priceAPI: MockPriceAPI(),
      );
      await firo.updateBiometricsUsage(true);
      expect(await firo.useBiometrics, true);

      await firo.updateBiometricsUsage(false);
      expect(await firo.useBiometrics, false);
    });

    test("changeFiatCurrency", () async {
      final firo = FiroWallet(
        walletId: testWalletId + "changeFiatCurrency",
        walletName: testWalletName,
        networkType: firoNetworkType,
        client: MockElectrumX(),
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
        priceAPI: MockPriceAPI(),
      );

      final wallet = await Hive.openBox(testWalletId + "changeFiatCurrency");
      var currentCurrency = await wallet.get("preferredFiatCurrency");
      expect(currentCurrency, null);
      expect(() => firo.changeFiatCurrency("USD"), returnsNormally);

      currentCurrency = await wallet.get("preferredFiatCurrency");
      expect(currentCurrency, "USD");
    });

    test("fetchPreferredCurrency", () async {
      final firo = FiroWallet(
        walletId: testWalletId + "fetchPreferredCurrency",
        walletName: testWalletName,
        networkType: firoNetworkType,
        client: MockElectrumX(),
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
        priceAPI: MockPriceAPI(),
      );

      final wallet =
          await Hive.openBox(testWalletId + "fetchPreferredCurrency");
      expect(wallet.isEmpty, true);
      expect(firo.fetchPreferredCurrency(), "USD");

      await wallet.put("preferredFiatCurrency", "CAD");
      expect(firo.fetchPreferredCurrency(), "CAD");
    });

    test("getLatestSetId", () async {
      final client = MockElectrumX();

      when(client.getLatestCoinId()).thenAnswer((_) async => 1);

      final firo = FiroWallet(
        walletId: testWalletId + "exit",
        walletName: testWalletName,
        networkType: firoNetworkType,
        client: client,
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
        priceAPI: MockPriceAPI(),
      );

      final setId = await firo.getLatestSetId();
      expect(setId, 1);
    });

    test("getSetData", () async {
      final client = MockElectrumX();

      when(client.getCoinsForRecovery(setId: 1))
          .thenAnswer((_) async => getCoinsForRecoveryResponse);

      final firo = FiroWallet(
        walletId: testWalletId + "exit",
        walletName: testWalletName,
        networkType: firoNetworkType,
        client: client,
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
        priceAPI: MockPriceAPI(),
      );

      final setData = await firo.getSetData(1);
      expect(setData, getCoinsForRecoveryResponse);
    });

    test("getUsedCoinSerials", () {
      // todo build tests
      expect(0, 1);
    });

    test("refresh", () {
      // todo build tests
      expect(0, 1);
    });

    test("send", () {
      // todo build send tests
      expect(0, 1);
    });

    test("exit", () {
      final firo = FiroWallet(
        walletId: testWalletId + "exit",
        walletName: testWalletName,
        networkType: firoNetworkType,
        client: MockElectrumX(),
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
        priceAPI: MockPriceAPI(),
      );

      firo.timer = Timer(Duration(seconds: 2), () {});

      expectLater(() => firo.exit(), returnsNormally)
          .then((_) => expect(firo.timer, null));
    });

    tearDownAll(() async {
      await tearDownTestHive();
    });
  });
}
