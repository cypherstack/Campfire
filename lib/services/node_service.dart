import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:paymint/services/event_bus/events/nodes_changed_event.dart';
import 'package:paymint/services/event_bus/global_event_bus.dart';
import 'package:paymint/utilities/misc_global_constants.dart';
import 'package:uuid/uuid.dart';

class ElectrumXNode {
  ElectrumXNode({this.address, this.port, this.name, this.id, this.useSSL});
  final String address;
  final int port;
  final String name;
  final String id;
  final bool useSSL;
}

class NodeService extends ChangeNotifier {
  String _walletId;

  String _activeNodeName;
  String get activeNodeName => _activeNodeName ??= _fetchActiveNodeName();

  ElectrumXNode _currentNode;
  ElectrumXNode get currentNode => _currentNode ??= _getCurrentNode();

  Map<String, dynamic> _nodes;
  Map<String, dynamic> get nodes => _nodes ??= _fetchNodes();

  NodeService() {
    _walletId = _getWalletId();
  }

  refresh() {
    _walletId = _getWalletId();
    _currentNode = _getCurrentNode();
    _nodes = _fetchNodes();
    _activeNodeName = _fetchActiveNodeName();
    notifyListeners();
  }

  String _fetchActiveNodeName() {
    final id = _walletId;
    final wallet = Hive.box(id);
    final name = wallet.get('activeNodeName');
    return name;
  }

  ElectrumXNode _getCurrentNode() {
    final id = _walletId;
    final wallet = Hive.box(id);
    final nodes = wallet.get('nodes');

    final name = activeNodeName;

    return ElectrumXNode(
      address: nodes[name]["ipAddress"],
      port: int.parse(nodes[name]["port"]),
      name: name,
      useSSL: nodes[name]["useSSL"],
    );
  }

  String _getWalletId() {
    final wallets = Hive.box('wallets');
    final names = wallets.get('names');
    final currentWallet = wallets.get('currentWalletName');
    return names[currentWallet];
  }

  Map<String, dynamic> _fetchNodes() {
    final id = _walletId;
    final wallet = Hive.box(id);
    final nodes = wallet.get('nodes');

    if (nodes == null || nodes.isEmpty) {
      createNode(
        name: CampfireConstants.defaultNodeName,
        ipAddress: CampfireConstants.defaultIpAddress,
        port: CampfireConstants.defaultPort.toString(),
        useSSL: CampfireConstants.defaultUseSSL,
      );
      return _fetchNodes();
    }

    return Map<String, dynamic>.from(nodes);
  }

  setCurrentNode(String nodeName) async {
    final id = _walletId;
    final wallet = Hive.box(id);

    await wallet.put('activeNodeName', nodeName);
    refresh();
    GlobalEventBus.instance
        .fire(NodesChangedEvent(NodesChangedEventType.updatedCurrentNode));
  }

  /// returns false if node with same name exists, true on success
  bool createNode({String name, String ipAddress, String port, bool useSSL}) {
    final id = _walletId;
    final wallet = Hive.box(id);
    var nodes = wallet.get('nodes');

    if (nodes == null) {
      nodes = <String, dynamic>{};
    }

    if (nodes.keys.contains(name)) {
      return false;
    }

    nodes[name] = {
      "id": Uuid().v1(),
      "ipAddress": ipAddress,
      "port": port,
      "useSSL": useSSL,
    };

    wallet.put('nodes', nodes);
    refresh();
    return true;
  }

  /// returns false if node with same name exists, true on successful edit
  bool editNode({
    String id,
    String originalName,
    String updatedName,
    String updatedIpAddress,
    String updatedPort,
    bool useSSL,
  }) {
    final id = _walletId;
    final wallet = Hive.box(id);
    final nodes = wallet.get('nodes');

    if (nodes.keys.contains(updatedName) && nodes[updatedName]['id'] != id) {
      // do not allow duplicate names
      return false;
    }

    final node = nodes.remove(originalName);
    node["ipAddress"] = updatedIpAddress;
    node["port"] = updatedPort;
    node["useSSL"] = useSSL;
    nodes[updatedName] = node;

    wallet.put('nodes', nodes);
    refresh();
    return true;
  }

  /// returns true if delete successful
  /// false if node with [name] does not exist
  Future<bool> deleteNode(String name) async {
    // extra sanity check
    // caller should check to make sure this doesn't fail
    assert(name != CampfireConstants.defaultNodeName);

    final id = _walletId;
    final wallet = Hive.box(id);
    final nodes = Map<String, dynamic>.from(wallet.get('nodes'));

    final removedNode = nodes.remove(name);
    await wallet.put('nodes', nodes);

    // connect to default node if active connected node is deleted
    if (_activeNodeName == name) {
      setCurrentNode(CampfireConstants.defaultNodeName);
    } else {
      // refresh here as setCurrentNode already call refresh on completion
      refresh();
    }

    return removedNode != null;
  }
}
