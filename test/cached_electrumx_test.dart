import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:paymint/electrumx_rpc/cached_electrumx.dart';
import 'package:paymint/electrumx_rpc/electrumx.dart';

import 'firo_wallet_test.mocks.dart';
import 'sample_data/get_anonymity_set_sample_data.dart';
import 'sample_data/transaction_data_samples.dart';

@GenerateMocks([ElectrumX])
void main() {
  group("tests using mock hive", () {
    setUp(() async {
      await setUpTestHive();
    });
    group("getAnonymitySet", () {
      test("empty cache call", () async {
        final client = MockElectrumX();
        when(
          client.getAnonymitySet(
            groupId: "1",
            blockhash: "",
          ),
        ).thenAnswer(
          (_) async => GetAnonymitySetSampleData.initialData,
        );

        final cachedClient = CachedElectrumX(electrumXClient: client);

        final result = await cachedClient.getAnonymitySet(
          groupId: "1",
          coinName: "Some coin name",
          callOutSideMainIsolate: false,
        );

        final expected = Map.from(GetAnonymitySetSampleData.initialData);
        expected["setId"] = "1";

        expect(result, expected);
      });

      test("use and update set cache call", () async {
        final storedData = Map.from(GetAnonymitySetSampleData.initialData);
        storedData["setId"] = "1";
        final box = await Hive.openBox('Some coinName_anonymitySetCache');
        await box.put("1", storedData);

        final client = MockElectrumX();
        when(
          client.getAnonymitySet(
            groupId: "1",
            blockhash: GetAnonymitySetSampleData.initialData["blockHash"],
          ),
        ).thenAnswer(
          (_) async => GetAnonymitySetSampleData.followUpData,
        );

        final cachedClient = CachedElectrumX(electrumXClient: client);

        final result = await cachedClient.getAnonymitySet(
          groupId: "1",
          coinName: "Some coinName",
          callOutSideMainIsolate: true,
        );

        final expected = Map.from(GetAnonymitySetSampleData.finalData);
        expected["setId"] = "1";

        expect(result, expected);
      });

      test("getAnonymitySet throws", () async {
        final client = MockElectrumX();
        when(
          client.getAnonymitySet(
            groupId: "1",
            blockhash: "",
          ),
        ).thenThrow(Exception());

        final cachedClient = CachedElectrumX(electrumXClient: client);

        expect(
            () async => await cachedClient.getAnonymitySet(
                  groupId: "1",
                  coinName: "Some coin name",
                  callOutSideMainIsolate: false,
                ),
            throwsA(isA<Exception>()));
      });
    });

    group("getTransaction", () {
      test("empty cache call - should save to txcache", () async {
        final client = MockElectrumX();
        when(
          client.getTransaction(
            tx_hash: SampleGetTransactionData.txHash0,
          ),
        ).thenAnswer(
          (_) async => SampleGetTransactionData.txData0,
        );

        final cachedClient = CachedElectrumX(electrumXClient: client);

        final result = await cachedClient.getTransaction(
          tx_hash: SampleGetTransactionData.txHash0,
          coinName: "Some coin name",
          callOutSideMainIsolate: false,
        );

        expect(result, SampleGetTransactionData.txData0);

        final txCache = await Hive.openBox('Some coin name_txCache');
        final cachedTx = await txCache.get(SampleGetTransactionData.txHash0);

        expect(cachedTx, result);
      });

      test("empty cache call - should not save to txcache", () async {
        final client = MockElectrumX();
        when(
          client.getTransaction(
            tx_hash: SampleGetTransactionData.txHash7,
          ),
        ).thenAnswer(
          (_) async => SampleGetTransactionData.txData7,
        );

        final cachedClient = CachedElectrumX(electrumXClient: client);

        final result = await cachedClient.getTransaction(
          tx_hash: SampleGetTransactionData.txHash7,
          coinName: "Some coin name",
          callOutSideMainIsolate: false,
        );

        expect(result, SampleGetTransactionData.txData7);

        final txCache = await Hive.openBox('Some coin name_txCache');
        final cachedTx = await txCache.get(SampleGetTransactionData.txHash0);

        expect(cachedTx, null);
      });

      test("use cached value", () async {
        final txCache = await Hive.openBox('Some coin name_txCache');
        await txCache.put(
            SampleGetTransactionData.txHash0, SampleGetTransactionData.txData0);

        final client = MockElectrumX();
        when(
          client.getTransaction(
            tx_hash: SampleGetTransactionData.txHash0,
          ),
        ).thenAnswer(
          (_) async => SampleGetTransactionData.txData0,
        );

        final cachedClient = CachedElectrumX(electrumXClient: client);

        final result = await cachedClient.getTransaction(
          tx_hash: SampleGetTransactionData.txHash0,
          coinName: "Some coin name",
          callOutSideMainIsolate: false,
        );

        expect(result, SampleGetTransactionData.txData0);

        verifyNever(client.getTransaction(
          tx_hash: SampleGetTransactionData.txHash0,
        ));
      });

      test("getTransaction throws", () async {
        final client = MockElectrumX();
        when(
          client.getTransaction(
            tx_hash: "some hash",
          ),
        ).thenThrow(Exception());

        final cachedClient = CachedElectrumX(electrumXClient: client);

        expect(
            () async => await cachedClient.getTransaction(
                  tx_hash: "some hash",
                  coinName: "Some coin name",
                  callOutSideMainIsolate: false,
                ),
            throwsA(isA<Exception>()));
      });
    });

    test("clearSharedTransactionCache", () async {
      final cachedClient = CachedElectrumX();

      await expectLater(
          () => cachedClient.clearSharedTransactionCache(coinName: "Some coin"),
          returnsNormally);
    });

    tearDown(() async {
      await tearDownTestHive();
    });
  });

  test("getTransaction invalid coinname", () async {
    final client = MockElectrumX();
    when(
      client.getTransaction(
        tx_hash: "some hash",
      ),
    ).thenAnswer(
      (_) async => SampleGetTransactionData.txData7,
    );

    final cachedClient = CachedElectrumX(electrumXClient: client);

    expect(
      () async => await cachedClient.getTransaction(
        tx_hash: "some hash",
        coinName: "",
        callOutSideMainIsolate: false,
      ),
      throwsA(isA<Exception>()),
    );
  });

  test("getAnonymitySet invalid coinname", () async {
    final client = MockElectrumX();
    when(
      client.getAnonymitySet(
        groupId: "1",
      ),
    ).thenAnswer(
      (_) async => GetAnonymitySetSampleData.initialData,
    );

    final cachedClient = CachedElectrumX(electrumXClient: client);

    expect(
      () async => await cachedClient.getAnonymitySet(
        groupId: "1",
        coinName: "",
        callOutSideMainIsolate: false,
      ),
      throwsA(isA<Exception>()),
    );
  });

  test(".from factory", () {
    final node = ElectrumXNode(
      address: "some address",
      port: 1,
      name: "some name",
      id: "some ID",
      useSSL: true,
    );

    final client = CachedElectrumX.from(node: node);

    expect(client, isA<CachedElectrumX>());
  });
}
