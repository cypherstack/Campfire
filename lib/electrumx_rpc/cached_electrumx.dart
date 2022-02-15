import 'dart:developer';

import 'package:hive/hive.dart';
import 'package:paymint/utilities/logger.dart';

import 'electrumx.dart';

class CachedElectrumX {
  ElectrumX _client;
  String _hivePath;
  static const minCacheConfirms = 30;

  CachedElectrumX({String server, int port, String hivePath}) {
    _hivePath = hivePath;
    _client = ElectrumX(server: server, port: port);
  }

  /// Call electrumx getTransaction on a per coin basis, storing the result in local db if not already there.
  ///
  /// ElectrumX api only called if the tx does not exist in local db
  Future<Map<String, dynamic>> getTransaction(
      {String tx_hash, bool verbose: true, String coinName}) async {
    if (coinName == null || coinName.isEmpty) {
      throw Exception("Invalid argument: coinName cannot be empty!");
    }

    try {
      if (_hivePath != null) {
        Hive.init(_hivePath);
      }
      final txCache = await Hive.openBox('${coinName}_txCache');
      final cachedTx = await txCache.get(tx_hash);
      if (cachedTx == null) {
        final Map<String, dynamic> result =
            await _client.getTransaction(tx_hash: tx_hash, verbose: verbose);

        if (result["confirmations"] > minCacheConfirms) {
          await txCache.put(tx_hash, result);
        }

        log("using fetched result");
        return result;
      } else {
        log("using cached result");
        return Map<String, dynamic>.from(cachedTx);
      }
    } catch (e) {
      Logger.print("Failed to process CachedElectrumX.getTransaction(): $e");
      throw e;
    }
  }

  /// Clear all cached transactions for the specified coin
  Future<bool> clearSharedTransactionCache({String coinName}) async {
    try {
      await Hive.deleteBoxFromDisk('${coinName}_txCache');
      return true;
    } catch (e) {
      print("Clear transaction cache for coin $coinName failed.");
      return false;
    }
  }
}
