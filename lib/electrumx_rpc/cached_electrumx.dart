import 'package:hive/hive.dart';
import 'package:paymint/utilities/logger.dart';

import 'electrumx.dart';

class CachedElectrumX {
  ElectrumX _client;

  static const minCacheConfirms = 30;

  CachedElectrumX({String server, int port}) {
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
      final txCache = await Hive.openBox('${coinName}_txCache');
      final cachedTx = await txCache.get(tx_hash);
      if (cachedTx == null) {
        final result =
            await _client.getTransaction(tx_hash: tx_hash, verbose: verbose);

        if (result["confirmations"] > minCacheConfirms) {
          await txCache.put(tx_hash, result);
        }

        return result;
      } else {
        return cachedTx;
      }
    } catch (e) {
      Logger.print("Failed to process CachedElectrumX.getTransaction(): $e");
      throw e;
    }
  }
}
