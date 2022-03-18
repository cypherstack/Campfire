import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:paymint/electrumx_rpc/electrumx.dart';
import 'package:paymint/electrumx_rpc/rpc.dart';

import 'electrumx_test.mocks.dart';
import 'sample_data/get_anonymity_set_sample_data.dart';
import 'sample_data/get_used_serials_sample_data.dart';
import 'sample_data/getcoinsforrecovery_sample_output.dart';
import 'sample_data/transaction_data_samples.dart';

@GenerateMocks([JsonRPC])
void main() {
  group("factory constructors and getters", () {
    test("electrumxnode .from factory", () {
      final nodeA = ElectrumXNode(
        address: "some address",
        port: 1,
        name: "some name",
        id: "some ID",
        useSSL: true,
      );

      final nodeB = ElectrumXNode.from(nodeA);

      expect(nodeB.toString(), nodeA.toString());
      expect(nodeA == nodeB, false);
    });

    test("electrumx .from factory", () {
      final node = ElectrumXNode(
        address: "some address",
        port: 1,
        name: "some name",
        id: "some ID",
        useSSL: true,
      );

      final client = ElectrumX.from(node: node);

      expect(client.useSSL, node.useSSL);
      expect(client.server, node.address);
      expect(client.port, node.port);
      expect(client.rpcClient, null);
    });
  });

  test("Server error", () {
    final mockClient = MockJsonRPC();
    final command = "blockchain.transaction.get";
    final jsonArgs = '[null,true]';
    when(
      mockClient.request(
          '{"jsonrpc": "2.0", "id": "some requestId","method": "$command","params": $jsonArgs}'),
    ).thenAnswer(
      (_) async => {
        "jsonrpc": "2.0",
        "error": {
          "code": 1,
          "message": "None should be a transaction hash",
        },
        "id": "some requestId",
      },
    );

    final client = ElectrumX(
        server: "some server", port: 0, useSSL: true, client: mockClient);

    expect(() => client.getTransaction(requestID: "some requestId"),
        throwsA(isA<Exception>()));
  });

  group("getBlockHeadTip", () {
    test("getBlockHeadTip success", () async {
      final mockClient = MockJsonRPC();
      final command = "blockchain.headers.subscribe";
      final jsonArgs = '[]';
      when(
        mockClient.request(
            '{"jsonrpc": "2.0", "id": "some requestId","method": "$command","params": $jsonArgs}'),
      ).thenAnswer(
        (_) async => {
          "jsonrpc": "2.0",
          "result": {"height": 520481, "hex": "some block hex string"},
          "id": "some requestId"
        },
      );

      final client = ElectrumX(
          server: "some server", port: 0, useSSL: true, client: mockClient);

      final result = await client.getBlockHeadTip(requestID: "some requestId");

      expect(result["height"], 520481);
    });

    test("getBlockHeadTip throws/fails", () {
      final mockClient = MockJsonRPC();
      final command = "blockchain.headers.subscribe";
      final jsonArgs = '[]';
      when(
        mockClient.request(
            '{"jsonrpc": "2.0", "id": "some requestId","method": "$command","params": $jsonArgs}'),
      ).thenThrow(Exception());

      final client = ElectrumX(
          server: "some server", port: 0, useSSL: true, client: mockClient);

      expect(() => client.getBlockHeadTip(requestID: "some requestId"),
          throwsA(isA<Exception>()));
    });
  });

  group("ping", () {
    test("ping success", () async {
      final mockClient = MockJsonRPC();
      final command = "server.ping";
      final jsonArgs = '[]';
      when(
        mockClient.request(
            '{"jsonrpc": "2.0", "id": "some requestId","method": "$command","params": $jsonArgs}'),
      ).thenAnswer(
        (_) async => {"jsonrpc": "2.0", "result": null, "id": "some requestId"},
      );

      final client = ElectrumX(
          server: "some server", port: 0, useSSL: true, client: mockClient);

      final result = await client.ping(requestID: "some requestId");

      expect(result, true);
    });

    test("ping throws/fails", () {
      final mockClient = MockJsonRPC();
      final command = "server.ping";
      final jsonArgs = '[]';
      when(
        mockClient.request(
            '{"jsonrpc": "2.0", "id": "some requestId","method": "$command","params": $jsonArgs}'),
      ).thenThrow(Exception());

      final client = ElectrumX(
          server: "some server", port: 0, useSSL: true, client: mockClient);

      expect(() => client.ping(requestID: "some requestId"),
          throwsA(isA<Exception>()));
    });
  });

  group("getServerFeatures", () {
    test("getServerFeatures success", () async {
      final mockClient = MockJsonRPC();
      final command = "server.features";
      final jsonArgs = '[]';
      when(
        mockClient.request(
            '{"jsonrpc": "2.0", "id": "some requestId","method": "$command","params": $jsonArgs}'),
      ).thenAnswer(
        (_) async => {
          "jsonrpc": "2.0",
          "result": {
            "genesis_hash":
                "000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943",
            "hosts": {
              "0.0.0.0": {"tcp_port": 51001, "ssl_port": 51002}
            },
            "protocol_max": "1.0",
            "protocol_min": "1.0",
            "pruning": null,
            "server_version": "ElectrumX 1.0.17",
            "hash_function": "sha256"
          },
          "id": "some requestId"
        },
      );

      final client = ElectrumX(
          server: "some server", port: 0, useSSL: true, client: mockClient);

      final result =
          await client.getServerFeatures(requestID: "some requestId");

      expect(result, {
        "genesis_hash":
            "000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943",
        "hosts": {
          "0.0.0.0": {"tcp_port": 51001, "ssl_port": 51002}
        },
        "protocol_max": "1.0",
        "protocol_min": "1.0",
        "pruning": null,
        "server_version": "ElectrumX 1.0.17",
        "hash_function": "sha256",
      });
    });

    test("getServerFeatures throws/fails", () {
      final mockClient = MockJsonRPC();
      final command = "server.features";
      final jsonArgs = '[]';
      when(
        mockClient.request(
            '{"jsonrpc": "2.0", "id": "some requestId","method": "$command","params": $jsonArgs}'),
      ).thenThrow(Exception());

      final client = ElectrumX(
          server: "some server", port: 0, useSSL: true, client: mockClient);

      expect(() => client.getServerFeatures(requestID: "some requestId"),
          throwsA(isA<Exception>()));
    });
  });

  group("broadcastTransaction", () {
    test("broadcastTransaction success", () async {
      final mockClient = MockJsonRPC();
      final command = "blockchain.transaction.broadcast";
      final jsonArgs = '["some raw transaction string"]';
      when(
        mockClient.request(
            '{"jsonrpc": "2.0", "id": "some requestId","method": "$command","params": $jsonArgs}'),
      ).thenAnswer(
        (_) async => {
          "jsonrpc": "2.0",
          "result": "the txid of the rawtx",
          "id": "some requestId"
        },
      );

      final client = ElectrumX(
          server: "some server", port: 0, useSSL: true, client: mockClient);

      final result = await client.broadcastTransaction(
          rawTx: "some raw transaction string", requestID: "some requestId");

      expect(result, "the txid of the rawtx");
    });

    test("broadcastTransaction throws/fails", () {
      final mockClient = MockJsonRPC();
      final command = "blockchain.transaction.broadcast";
      final jsonArgs = '["some raw transaction string"]';
      when(
        mockClient.request(
            '{"jsonrpc": "2.0", "id": "some requestId","method": "$command","params": $jsonArgs}'),
      ).thenThrow(Exception());

      final client = ElectrumX(
          server: "some server", port: 0, useSSL: true, client: mockClient);

      expect(
          () => client.broadcastTransaction(
              rawTx: "some raw transaction string",
              requestID: "some requestId"),
          throwsA(isA<Exception>()));
    });
  });

  group("getBalance", () {
    test("getBalance success", () async {
      final mockClient = MockJsonRPC();
      final command = "blockchain.scripthash.get_balance";
      final jsonArgs = '["dummy hash"]';
      when(
        mockClient.request(
            '{"jsonrpc": "2.0", "id": "some requestId","method": "$command","params": $jsonArgs}'),
      ).thenAnswer(
        (_) async => {
          "jsonrpc": "2.0",
          "result": {
            "confirmed": 103873966,
            "unconfirmed": 23684400,
          },
          "id": "some requestId"
        },
      );

      final client = ElectrumX(
          server: "some server", port: 0, useSSL: true, client: mockClient);

      final result = await client.getBalance(
          scripthash: "dummy hash", requestID: "some requestId");

      expect(result, {"confirmed": 103873966, "unconfirmed": 23684400});
    });

    test("getBalance throws/fails", () {
      final mockClient = MockJsonRPC();
      final command = "blockchain.scripthash.get_balance";
      final jsonArgs = '["dummy hash"]';
      when(
        mockClient.request(
            '{"jsonrpc": "2.0", "id": "some requestId","method": "$command","params": $jsonArgs}'),
      ).thenThrow(Exception());

      final client = ElectrumX(
          server: "some server", port: 0, useSSL: true, client: mockClient);

      expect(
          () => client.getBalance(
              scripthash: "dummy hash", requestID: "some requestId"),
          throwsA(isA<Exception>()));
    });
  });

  group("getHistory", () {
    test("getHistory success", () async {
      final mockClient = MockJsonRPC();
      final command = "blockchain.scripthash.get_history";
      final jsonArgs = '["dummy hash"]';
      when(
        mockClient.request(
            '{"jsonrpc": "2.0", "id": "some requestId","method": "$command","params": $jsonArgs}'),
      ).thenAnswer(
        (_) async => {
          "jsonrpc": "2.0",
          "result": [
            {
              "height": 200004,
              "tx_hash":
                  "acc3758bd2a26f869fcc67d48ff30b96464d476bca82c1cd6656e7d506816412"
            },
            {
              "height": 215008,
              "tx_hash":
                  "f3e1bf48975b8d6060a9de8884296abb80be618dc00ae3cb2f6cee3085e09403"
            }
          ],
          "id": "some requestId"
        },
      );

      final client = ElectrumX(
          server: "some server", port: 0, useSSL: true, client: mockClient);

      final result = await client.getHistory(
          scripthash: "dummy hash", requestID: "some requestId");

      expect(result, [
        {
          "height": 200004,
          "tx_hash":
              "acc3758bd2a26f869fcc67d48ff30b96464d476bca82c1cd6656e7d506816412"
        },
        {
          "height": 215008,
          "tx_hash":
              "f3e1bf48975b8d6060a9de8884296abb80be618dc00ae3cb2f6cee3085e09403"
        }
      ]);
    });

    test("getHistory throws/fails", () {
      final mockClient = MockJsonRPC();
      final command = "blockchain.scripthash.get_history";
      final jsonArgs = '["dummy hash"]';
      when(
        mockClient.request(
            '{"jsonrpc": "2.0", "id": "some requestId","method": "$command","params": $jsonArgs}'),
      ).thenThrow(Exception());

      final client = ElectrumX(
          server: "some server", port: 0, useSSL: true, client: mockClient);

      expect(
          () => client.getHistory(
              scripthash: "dummy hash", requestID: "some requestId"),
          throwsA(isA<Exception>()));
    });
  });

  group("getUTXOs", () {
    test("getUTXOs success", () async {
      final mockClient = MockJsonRPC();
      final command = "blockchain.scripthash.listunspent";
      final jsonArgs = '["dummy hash"]';
      when(
        mockClient.request(
            '{"jsonrpc": "2.0", "id": "some requestId","method": "$command","params": $jsonArgs}'),
      ).thenAnswer(
        (_) async => {
          "jsonrpc": "2.0",
          "result": [
            {
              "tx_pos": 0,
              "value": 45318048,
              "tx_hash":
                  "9f2c45a12db0144909b5db269415f7319179105982ac70ed80d76ea79d923ebf",
              "height": 437146
            },
            {
              "tx_pos": 0,
              "value": 919195,
              "tx_hash":
                  "3d2290c93436a3e964cfc2f0950174d8847b1fbe3946432c4784e168da0f019f",
              "height": 441696
            }
          ],
          "id": "some requestId"
        },
      );

      final client = ElectrumX(
          server: "some server", port: 0, useSSL: true, client: mockClient);

      final result = await client.getUTXOs(
          scripthash: "dummy hash", requestID: "some requestId");

      expect(result, [
        {
          "tx_pos": 0,
          "value": 45318048,
          "tx_hash":
              "9f2c45a12db0144909b5db269415f7319179105982ac70ed80d76ea79d923ebf",
          "height": 437146
        },
        {
          "tx_pos": 0,
          "value": 919195,
          "tx_hash":
              "3d2290c93436a3e964cfc2f0950174d8847b1fbe3946432c4784e168da0f019f",
          "height": 441696
        }
      ]);
    });

    test("getUTXOs throws/fails", () {
      final mockClient = MockJsonRPC();
      final command = "blockchain.scripthash.listunspent";
      final jsonArgs = '["dummy hash"]';
      when(
        mockClient.request(
            '{"jsonrpc": "2.0", "id": "some requestId","method": "$command","params": $jsonArgs}'),
      ).thenThrow(Exception());

      final client = ElectrumX(
          server: "some server", port: 0, useSSL: true, client: mockClient);

      expect(
          () => client.getUTXOs(
              scripthash: "dummy hash", requestID: "some requestId"),
          throwsA(isA<Exception>()));
    });
  });

  group("getTransaction", () {
    test("getTransaction success", () async {
      final mockClient = MockJsonRPC();
      final command = "blockchain.transaction.get";
      final jsonArgs = '["${SampleGetTransactionData.txHash0}",true]';
      when(
        mockClient.request(
            '{"jsonrpc": "2.0", "id": "some requestId","method": "$command","params": $jsonArgs}'),
      ).thenAnswer(
        (_) async => {
          "jsonrpc": "2.0",
          "result": SampleGetTransactionData.txData0,
          "id": "some requestId"
        },
      );

      final client = ElectrumX(
          server: "some server", port: 0, useSSL: true, client: mockClient);

      final result = await client.getTransaction(
          tx_hash: SampleGetTransactionData.txHash0,
          verbose: true,
          requestID: "some requestId");

      expect(result, SampleGetTransactionData.txData0);
    });

    test("getTransaction throws/fails", () {
      final mockClient = MockJsonRPC();
      final command = "blockchain.transaction.get";
      final jsonArgs = '["${SampleGetTransactionData.txHash0}",true]';
      when(
        mockClient.request(
            '{"jsonrpc": "2.0", "id": "some requestId","method": "$command","params": $jsonArgs}'),
      ).thenThrow(Exception());

      final client = ElectrumX(
          server: "some server", port: 0, useSSL: true, client: mockClient);

      expect(
          () => client.getTransaction(
              tx_hash: SampleGetTransactionData.txHash0,
              requestID: "some requestId"),
          throwsA(isA<Exception>()));
    });
  });

  group("getAnonymitySet", () {
    test("getAnonymitySet success", () async {
      final mockClient = MockJsonRPC();
      final command = "sigma.getanonymityset";
      final jsonArgs = '["1",""]';
      when(
        mockClient.request(
            '{"jsonrpc": "2.0", "id": "some requestId","method": "$command","params": $jsonArgs}'),
      ).thenAnswer(
        (_) async => {
          "jsonrpc": "2.0",
          "result": GetAnonymitySetSampleData.initialData,
          "id": "some requestId"
        },
      );

      final client = ElectrumX(
          server: "some server", port: 0, useSSL: true, client: mockClient);

      final result = await client.getAnonymitySet(
          groupId: "1", blockhash: "", requestID: "some requestId");

      expect(result, GetAnonymitySetSampleData.initialData);
    });

    test("getAnonymitySet throws/fails", () {
      final mockClient = MockJsonRPC();
      final command = "sigma.getanonymityset";
      final jsonArgs = '["1",""]';
      when(
        mockClient.request(
            '{"jsonrpc": "2.0", "id": "some requestId","method": "$command","params": $jsonArgs}'),
      ).thenThrow(Exception());

      final client = ElectrumX(
          server: "some server", port: 0, useSSL: true, client: mockClient);

      expect(
          () =>
              client.getAnonymitySet(groupId: "1", requestID: "some requestId"),
          throwsA(isA<Exception>()));
    });
  });

  group("getMintData", () {
    test("getMintData success", () async {
      final mockClient = MockJsonRPC();
      final command = "sigma.getmintmetadata";
      final jsonArgs = '["some mints"]';
      when(
        mockClient.request(
            '{"jsonrpc": "2.0", "id": "some requestId","method": "$command","params": $jsonArgs}'),
      ).thenAnswer(
        (_) async => {
          "jsonrpc": "2.0",
          "result": "mint meta data",
          "id": "some requestId"
        },
      );

      final client = ElectrumX(
          server: "some server", port: 0, useSSL: true, client: mockClient);

      final result = await client.getMintData(
          mints: "some mints", requestID: "some requestId");

      expect(result, "mint meta data");
    });

    test("getMintData throws/fails", () {
      final mockClient = MockJsonRPC();
      final command = "sigma.getmintmetadata";
      final jsonArgs = '["some mints"]';
      when(
        mockClient.request(
            '{"jsonrpc": "2.0", "id": "some requestId","method": "$command","params": $jsonArgs}'),
      ).thenThrow(Exception());

      final client = ElectrumX(
          server: "some server", port: 0, useSSL: true, client: mockClient);

      expect(
          () => client.getMintData(
              mints: "some mints", requestID: "some requestId"),
          throwsA(isA<Exception>()));
    });
  });

  group("getUsedCoinSerials", () {
    test("getUsedCoinSerials success", () async {
      final mockClient = MockJsonRPC();
      final command = "sigma.getusedcoinserials";
      final jsonArgs = '[]';
      when(
        mockClient.request(
            '{"jsonrpc": "2.0", "id": "some requestId","method": "$command","params": $jsonArgs}'),
      ).thenAnswer(
        (_) async => {
          "jsonrpc": "2.0",
          "result": GetUsedSerialsSampleData.serials,
          "id": "some requestId"
        },
      );

      final client = ElectrumX(
          server: "some server", port: 0, useSSL: true, client: mockClient);

      final result =
          await client.getUsedCoinSerials(requestID: "some requestId");

      expect(result, GetUsedSerialsSampleData.serials);
    });

    test("getUsedCoinSerials throws/fails", () {
      final mockClient = MockJsonRPC();
      final command = "sigma.getusedcoinserials";
      final jsonArgs = '[]';
      when(
        mockClient.request(
            '{"jsonrpc": "2.0", "id": "some requestId","method": "$command","params": $jsonArgs}'),
      ).thenThrow(Exception());

      final client = ElectrumX(
          server: "some server", port: 0, useSSL: true, client: mockClient);

      expect(() => client.getUsedCoinSerials(requestID: "some requestId"),
          throwsA(isA<Exception>()));
    });
  });

  group("getLatestCoinId", () {
    test("getLatestCoinId success", () async {
      final mockClient = MockJsonRPC();
      final command = "sigma.getlatestcoinid";
      final jsonArgs = '[]';
      when(
        mockClient.request(
            '{"jsonrpc": "2.0", "id": "some requestId","method": "$command","params": $jsonArgs}'),
      ).thenAnswer(
        (_) async => {"jsonrpc": "2.0", "result": 1, "id": "some requestId"},
      );

      final client = ElectrumX(
          server: "some server", port: 0, useSSL: true, client: mockClient);

      final result = await client.getLatestCoinId(requestID: "some requestId");

      expect(result, 1);
    });

    test("getLatestCoinId throws/fails", () {
      final mockClient = MockJsonRPC();
      final command = "sigma.getlatestcoinid";
      final jsonArgs = '[]';
      when(
        mockClient.request(
            '{"jsonrpc": "2.0", "id": "some requestId","method": "$command","params": $jsonArgs}'),
      ).thenThrow(Exception());

      final client = ElectrumX(
          server: "some server", port: 0, useSSL: true, client: mockClient);

      expect(() => client.getLatestCoinId(requestID: "some requestId"),
          throwsA(isA<Exception>()));
    });
  });

  group("getCoinsForRecovery", () {
    test("getCoinsForRecovery success", () async {
      final mockClient = MockJsonRPC();
      final command = "sigma.getcoinsforrecovery";
      final jsonArgs = '[1]';
      when(
        mockClient.request(
            '{"jsonrpc": "2.0", "id": "some requestId","method": "$command","params": $jsonArgs}'),
      ).thenAnswer(
        (_) async => {
          "jsonrpc": "2.0",
          "result": getCoinsForRecoveryResponse,
          "id": "some requestId"
        },
      );

      final client = ElectrumX(
          server: "some server", port: 0, useSSL: true, client: mockClient);

      final result = await client.getCoinsForRecovery(
          setId: 1, requestID: "some requestId");

      expect(result, getCoinsForRecoveryResponse);
    });

    test("getCoinsForRecovery throws/fails", () {
      final mockClient = MockJsonRPC();
      final command = "sigma.getcoinsforrecovery";
      final jsonArgs = '[1]';
      when(
        mockClient.request(
            '{"jsonrpc": "2.0", "id": "some requestId","method": "$command","params": $jsonArgs}'),
      ).thenThrow(Exception());

      final client = ElectrumX(
          server: "some server", port: 0, useSSL: true, client: mockClient);

      expect(
          () =>
              client.getCoinsForRecovery(setId: 1, requestID: "some requestId"),
          throwsA(isA<Exception>()));
    });
  });

  group("getFeeRate", () {
    test("getFeeRate success", () async {
      final mockClient = MockJsonRPC();
      final command = "blockchain.getfeerate";
      final jsonArgs = '[]';
      when(
        mockClient.request(
            '{"jsonrpc": "2.0", "id": "some requestId","method": "$command","params": $jsonArgs}'),
      ).thenAnswer(
        (_) async => {
          "jsonrpc": "2.0",
          "result": {
            "rate": 1000,
          },
          "id": "some requestId"
        },
      );

      final client = ElectrumX(
          server: "some server", port: 0, useSSL: true, client: mockClient);

      final result = await client.getFeeRate(requestID: "some requestId");

      expect(result, {"rate": 1000});
    });

    test("getFeeRate throws/fails", () {
      final mockClient = MockJsonRPC();
      final command = "blockchain.getfeerate";
      final jsonArgs = '[]';
      when(
        mockClient.request(
            '{"jsonrpc": "2.0", "id": "some requestId","method": "$command","params": $jsonArgs}'),
      ).thenThrow(Exception());

      final client = ElectrumX(
          server: "some server", port: 0, useSSL: true, client: mockClient);

      expect(() => client.getFeeRate(requestID: "some requestId"),
          throwsA(isA<Exception>()));
    });
  });

  test("rpcClient is null throws with bad server info", () {
    final client = ElectrumX(
      client: null,
      port: -10,
      server: "_ :sa  %",
      useSSL: false,
    );

    expect(() => client.getFeeRate(), throwsA(isA<Exception>()));
  });
}
