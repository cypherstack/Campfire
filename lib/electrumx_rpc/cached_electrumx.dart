import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:paymint/utilities/logger.dart';

import 'electrumx.dart';

class CachedElectrumX {
  final ElectrumX electrumXClient;
  final String hivePath;

  final String server;
  final int port;
  final bool useSSL;

  static const minCacheConfirms = 30;

  const CachedElectrumX({
    this.server,
    this.port,
    this.useSSL,
    this.hivePath,
    this.electrumXClient,
  });

  factory CachedElectrumX.from(
          {@required ElectrumXNode node, String hivePath}) =>
      CachedElectrumX(
          server: node.address,
          port: node.port,
          useSSL: node.useSSL,
          hivePath: hivePath);

  Future<Map<String, dynamic>> getAnonymitySet(
      {@required String groupId,
      String blockhash = "",
      @required String coinName,
      @required bool callOutSideMainIsolate}) async {
    if (coinName == null || coinName.isEmpty) {
      throw Exception("Invalid argument: coinName cannot be empty!");
    }

    try {
      // hive must be initialized when this function is called outside of flutter main
      // such as within an isolate
      if (callOutSideMainIsolate) {
        Hive.init(hivePath);
      }
      final box = await Hive.openBox('${coinName}_anonymitySetCache');
      final cachedSet = await box.get(groupId);

      Map<String, dynamic> set;

      // null check to see if there is a cached set
      if (cachedSet == null) {
        set = {
          "setId": groupId,
          "blockHash": blockhash,
          "setHash": "",
          "coins": <dynamic>[],
        };
      } else {
        set = Map<String, dynamic>.from(cachedSet);
      }

      ElectrumX client = electrumXClient ??
          ElectrumX(
            server: this.server,
            port: this.port,
            useSSL: this.useSSL,
          );

      final newSet = await client.getAnonymitySet(
        groupId: groupId,
        blockhash: set["blockHash"] as String,
      );

      // update set with new data
      if (newSet["setHash"] != "" && set["setHash"] != newSet["setHash"]) {
        set["blockHash"] = base64ToReverseHex(newSet["blockHash"] as String);
        set["setHash"] = base64ToHex(newSet["setHash"] as String);

        for (int i = (newSet["coins"] as List).length - 1; i >= 0; i--) {
          dynamic newCoin = newSet["coins"][i];
          List translatedCoin = [];

          translatedCoin.add(base64ToHex(newCoin[0] as String));

          translatedCoin.add(base64ToReverseHex(newCoin[1] as String));

          if (newCoin[2] is int) {
            translatedCoin.add(newCoin[2] as int);
          } else {
            translatedCoin.add(base64ToHex(newCoin[2] as String));
          }

          translatedCoin.add(base64ToReverseHex(newCoin[3] as String));

          set["coins"].insert(0, translatedCoin);
        }
        // save set to db
        await box.put(groupId, set);
        Logger.print(
            "Updated currently anonymity set for $coinName with group ID $groupId");
      }

      return set;
    } catch (e, s) {
      Logger.print(
          "Failed to process CachedElectrumX.getAnonymitySet(): $e\n$s");
      throw e;
    }
  }

  /// Call electrumx getTransaction on a per coin basis, storing the result in local db if not already there.
  ///
  /// ElectrumX api only called if the tx does not exist in local db
  Future<Map<String, dynamic>> getTransaction(
      {@required String tx_hash,
      bool verbose: true,
      @required String coinName,
      @required bool callOutSideMainIsolate}) async {
    if (coinName == null || coinName.isEmpty) {
      throw Exception("Invalid argument: coinName cannot be empty!");
    }

    try {
      // hive must be initialized when this function is called outside of flutter main
      // such as within an isolate
      if (callOutSideMainIsolate) {
        Hive.init(hivePath);
      }
      final txCache = await Hive.openBox('${coinName}_txCache');
      final cachedTx = await txCache.get(tx_hash);
      if (cachedTx == null) {
        final client = electrumXClient ??
            ElectrumX(
              server: this.server,
              port: this.port,
              useSSL: this.useSSL,
            );
        final Map<String, dynamic> result =
            await client.getTransaction(tx_hash: tx_hash, verbose: verbose);

        result.remove("hex");
        result.remove("lelantusData");

        if (result["confirmations"] != null &&
            result["confirmations"] > minCacheConfirms) {
          await txCache.put(tx_hash, result);
        }

        Logger.print("using fetched result");
        return result;
      } else {
        Logger.print("using cached result");
        return Map<String, dynamic>.from(cachedTx);
      }
    } catch (e, s) {
      Logger.print(
          "Failed to process CachedElectrumX.getTransaction(): $e\n$s");
      throw e;
    }
  }

  Future<List<dynamic>> getUsedCoinSerials({
    @required String coinName,
    @required bool callOutSideMainIsolate,
    int startNumber,
  }) async {
    if (coinName == null || coinName.isEmpty) {
      throw Exception("Invalid argument: coinName cannot be empty!");
    }

    try {
      // hive must be initialized when this function is called outside of flutter main
      // such as within an isolate
      if (callOutSideMainIsolate) {
        Hive.init(hivePath);
      }
      final usedSerialsCache =
          await Hive.openBox('${coinName}_usedSerialsCache');
      List<dynamic> cachedSerials = await usedSerialsCache.get("serials");

      if (cachedSerials == null) {
        cachedSerials = [];
      }

      final startNumber = cachedSerials.length;

      final client = electrumXClient ??
          ElectrumX(
            server: this.server,
            port: this.port,
            useSSL: this.useSSL,
          );

      final serials = await client.getUsedCoinSerials(startNumber: startNumber);
      List newSerials = [];
      for (var element in (serials["serials"] as List)) {
        newSerials.add(base64ToHex(element));
      }
      cachedSerials.addAll(newSerials);

      await usedSerialsCache.put('${coinName}_usedSerialsCache', cachedSerials);

      return cachedSerials;
    } catch (e, s) {
      Logger.print(
          "Failed to process CachedElectrumX.getTransaction(): $e\n$s");
      throw e;
    }
  }

  /// Clear all cached transactions for the specified coin
  Future<void> clearSharedTransactionCache({String coinName}) async {
    final txCache = await Hive.openBox('${coinName}_txCache');
    await txCache.clear();
    final setCache = await Hive.openBox('${coinName}_anonymitySetCache');
    await setCache.clear();
    final usedSerialsCache = await Hive.openBox('${coinName}_usedSerialsCache');
    await usedSerialsCache.clear();
  }

  String base64ToHex(String source) =>
      base64Decode(LineSplitter.split(source).join())
          .map((e) => e.toRadixString(16).padLeft(2, '0'))
          .join();

  String base64ToReverseHex(String source) =>
      base64Decode(LineSplitter.split(source).join())
          .reversed
          .map((e) => e.toRadixString(16).padLeft(2, '0'))
          .join();
}
