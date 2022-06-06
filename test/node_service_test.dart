import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:paymint/services/event_bus/events/nodes_changed_event.dart';
import 'package:paymint/services/event_bus/global_event_bus.dart';
import 'package:paymint/services/node_service.dart';

void main() {
  setUp(() async {
    await setUpTestHive();
    final wallets = await Hive.openBox('wallets');
    await wallets.put('names', {"My Firo Wallet": "wallet_id"});
    await wallets.put('currentWalletName', "My Firo Wallet");
    final wallet = await Hive.openBox("wallet_id");
    await wallet.put("activeNodeName", "My Node");
    await wallet.put("nodes", {
      "My Node": {
        "id": "node id",
        "ipAddress": "node address",
        "port": "9000",
        "useSSL": true,
      },
      "My Node2": {
        "id": "node id2",
        "ipAddress": "node address2",
        "port": "90002",
        "useSSL": true,
      }
    });
  });

  test("get active node name", () async {
    final service = NodeService();
    expect(service.activeNodeName, "My Node");
  });

  test("get current node", () async {
    final service = NodeService();
    final node = service.currentNode;

    expect(node.address, "node address");
    expect(node.name, "My Node");
    expect(node.port, 9000);
    expect(node.useSSL, true);
  });

  test("get nodes", () async {
    final service = NodeService();
    expect(service.nodes, {
      "My Node": {
        "id": "node id",
        "ipAddress": "node address",
        "port": "9000",
        "useSSL": true,
      },
      "My Node2": {
        "id": "node id2",
        "ipAddress": "node address2",
        "port": "90002",
        "useSSL": true,
      }
    });
  });

  test("reInit", () async {
    final service = NodeService();
    expect(() async => await service.reInit(), returnsNormally);
  });

  test("set current node succeeds", () async {
    final service = NodeService();
    int count = 0;
    GlobalEventBus.instance.on<NodesChangedEvent>().listen((event) => count++);

    await service.setCurrentNode("My Node2");
    // wait for possible event to propagate
    await Future.delayed(Duration(milliseconds: 500));
    expect(count, 1);
    expect(service.activeNodeName, "My Node2");
  });

  test("set current node fails", () async {
    final service = NodeService();
    int count = 0;
    GlobalEventBus.instance.on<NodesChangedEvent>().listen((event) => count++);

    expect(service.setCurrentNode("some non existent node name"),
        throwsA(isA<Exception>()));

    // wait for possible event to propagate
    await Future.delayed(Duration(milliseconds: 500));
    expect(count, 0);
    expect(service.activeNodeName, "My Node");
  });

  test("create new node", () async {
    final service = NodeService();
    expect(service.nodes.length, 2);
    final result = await service.createNode(
      name: "name2",
      ipAddress: "ipAddress",
      port: "9000",
      useSSL: false,
      shouldNotifyListeners: false,
    );
    expect(result, true);
    expect(service.nodes.length, 3);
    expect(service.activeNodeName, "My Node");
  });

  test("create initial node", () async {
    final service = NodeService();
    final wallet = await Hive.openBox("wallet_id");
    await wallet.put("nodes", {});
    expect(service.nodes.length, 0);
    final result = await service.createNode(
      name: "name2",
      ipAddress: "ipAddress",
      port: "9000",
      useSSL: false,
      shouldNotifyListeners: false,
    );
    expect(result, true);
    expect(service.nodes.length, 1);
    expect(service.activeNodeName, "name2");
  });

  test("create duplicate named node", () async {
    final service = NodeService();
    expect(service.nodes.length, 2);
    final result = await service.createNode(
      name: "My Node",
      ipAddress: "ipAddress",
      port: "9000",
      useSSL: false,
      shouldNotifyListeners: false,
    );
    expect(result, false);
    expect(service.nodes.length, 2);
  });

  test("create node fails due to empty name", () async {
    final service = NodeService();
    expect(
        service.createNode(
          name: "",
          ipAddress: "ipAddress",
          port: "9000",
          useSSL: false,
        ),
        throwsA(isA<Exception>()));
  });

  test("create node fails due to null name", () async {
    final service = NodeService();
    expect(
        service.createNode(
          name: null,
          ipAddress: "ipAddress",
          port: "9000",
          useSSL: false,
        ),
        throwsA(isA<Exception>()));
  });

  test("edit node succeeds", () async {
    final service = NodeService();
    final wallet = await Hive.openBox("wallet_id");
    await wallet.put("activeNodeName", "My Node2");
    expect(service.nodes, {
      "My Node": {
        "id": "node id",
        "ipAddress": "node address",
        "port": "9000",
        "useSSL": true,
      },
      "My Node2": {
        "id": "node id2",
        "ipAddress": "node address2",
        "port": "90002",
        "useSSL": true,
      }
    });
    final result = await service.editNode(
      id: "node id2",
      originalName: "My Node2",
      updatedName: "My Node new",
      useSSL: true,
      updatedPort: "90",
      updatedIpAddress: "new address",
    );

    expect(result, true);
    expect(service.nodes, {
      "My Node": {
        "id": "node id",
        "ipAddress": "node address",
        "port": "9000",
        "useSSL": true,
      },
      "My Node new": {
        "id": "node id2",
        "ipAddress": "new address",
        "port": "90",
        "useSSL": true,
      }
    });

    expect(service.activeNodeName, "My Node new");
  });

  test("edit node fails", () async {
    final service = NodeService();
    final wallet = await Hive.openBox("wallet_id");
    await wallet.put("activeNodeName", "My Node2");
    expect(service.nodes, {
      "My Node": {
        "id": "node id",
        "ipAddress": "node address",
        "port": "9000",
        "useSSL": true,
      },
      "My Node2": {
        "id": "node id2",
        "ipAddress": "node address2",
        "port": "90002",
        "useSSL": true,
      }
    });
    final result = await service.editNode(
      id: "node id2",
      originalName: "My Node2",
      updatedName: "My Node",
      useSSL: true,
      updatedPort: "90",
      updatedIpAddress: "new address",
    );

    expect(result, false);
    expect(service.nodes, {
      "My Node": {
        "id": "node id",
        "ipAddress": "node address",
        "port": "9000",
        "useSSL": true,
      },
      "My Node2": {
        "id": "node id2",
        "ipAddress": "node address2",
        "port": "90002",
        "useSSL": true,
      }
    });

    expect(service.activeNodeName, "My Node2");
  });

  test("delete a node succeeds", () async {
    final service = NodeService();
    expect(service.nodes, {
      "My Node": {
        "id": "node id",
        "ipAddress": "node address",
        "port": "9000",
        "useSSL": true,
      },
      "My Node2": {
        "id": "node id2",
        "ipAddress": "node address2",
        "port": "90002",
        "useSSL": true,
      }
    });
    final result = await service.deleteNode("My Node2");
    expect(result, true);

    expect(service.nodes, {
      "My Node": {
        "id": "node id",
        "ipAddress": "node address",
        "port": "9000",
        "useSSL": true,
      },
    });
  });

  test("delete a node fails as no match for name", () async {
    final service = NodeService();
    expect(service.nodes, {
      "My Node": {
        "id": "node id",
        "ipAddress": "node address",
        "port": "9000",
        "useSSL": true,
      },
      "My Node2": {
        "id": "node id2",
        "ipAddress": "node address2",
        "port": "90002",
        "useSSL": true,
      }
    });
    final result = await service.deleteNode("My Node 5");
    expect(result, false);

    expect(service.nodes, {
      "My Node": {
        "id": "node id",
        "ipAddress": "node address",
        "port": "9000",
        "useSSL": true,
      },
      "My Node2": {
        "id": "node id2",
        "ipAddress": "node address2",
        "port": "90002",
        "useSSL": true,
      }
    });
  });

  test("delete active node succeeds", () async {
    final service = NodeService();
    final wallet = await Hive.openBox("wallet_id");
    await wallet.put("nodes", {
      "My Node": {
        "id": "node id",
        "ipAddress": "node address",
        "port": "9000",
        "useSSL": true,
      },
      "My Node2": {
        "id": "node id2",
        "ipAddress": "node address2",
        "port": "90002",
        "useSSL": true,
      },
      "Campfire default": {
        "id": "node id3",
        "ipAddress": "electrumx-firo.cypherstack.com",
        "port": "50002",
        "useSSL": true,
      },
    });
    expect(service.nodes, {
      "My Node": {
        "id": "node id",
        "ipAddress": "node address",
        "port": "9000",
        "useSSL": true,
      },
      "My Node2": {
        "id": "node id2",
        "ipAddress": "node address2",
        "port": "90002",
        "useSSL": true,
      },
      "Campfire default": {
        "id": "node id3",
        "ipAddress": "electrumx-firo.cypherstack.com",
        "port": "50002",
        "useSSL": true,
      },
    });
    expect(service.activeNodeName, "My Node");
    final result = await service.deleteNode("My Node");
    expect(result, true);

    expect(service.nodes, {
      "My Node2": {
        "id": "node id2",
        "ipAddress": "node address2",
        "port": "90002",
        "useSSL": true,
      },
      "Campfire default": {
        "id": "node id3",
        "ipAddress": "electrumx-firo.cypherstack.com",
        "port": "50002",
        "useSSL": true,
      },
    });
    expect(service.activeNodeName, "Campfire default");
  });

  tearDown(() async {
    await tearDownTestHive();
  });
}
