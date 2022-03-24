import 'package:flutter_test/flutter_test.dart';
import 'package:paymint/models/utxo_model.dart';

void main() {
  group("Status", () {
    test("Status constructor", () {
      final status = Status(
        confirmed: true,
        blockHash: "some block hash",
        blockHeight: 67254372,
        blockTime: 87263547764,
      );

      expect(status.toString(),
          "{confirmed: true, blockHash: some block hash, blockHeight: 67254372, blockTime: 87263547764}");
    });

    test("Status.fromJson factory", () {
      final status = Status.fromJson({
        "confirmed": true,
        "block_hash": "some block hash",
        "block_height": 67254372,
        "block_time": 87263547764,
      });

      expect(status.toString(),
          "{confirmed: true, blockHash: some block hash, blockHeight: 67254372, blockTime: 87263547764}");
    });
  });

  group("UtxoObject", () {
    test("UtxoObject constructor", () {
      final utxoObject = UtxoObject(
        txid: "some txid",
        vout: 1,
        value: 1000,
        fiatWorth: "2",
        status: Status(
          confirmed: true,
          blockHash: "some block hash",
          blockHeight: 67254372,
          blockTime: 87263547764,
        ),
      );

      expect(utxoObject.toString(),
          "{txid: some txid, vout: 1, value: 1000, fiat: 2}");
      expect(utxoObject.status.toString(),
          "{confirmed: true, blockHash: some block hash, blockHeight: 67254372, blockTime: 87263547764}");
    });

    test("UtxoObject.fromJson factory", () {
      final utxoObject = UtxoObject.fromJson({
        "txid": "some txid",
        "vout": 1,
        "value": 1000,
        "fiatWorth": "2",
        "status": {
          "confirmed": true,
          "block_hash": "some block hash",
          "block_height": 67254372,
          "block_time": 87263547764,
        }
      });

      expect(utxoObject.toString(),
          "{txid: some txid, vout: 1, value: 1000, fiat: 2}");
      expect(utxoObject.status.toString(),
          "{confirmed: true, blockHash: some block hash, blockHeight: 67254372, blockTime: 87263547764}");
    });
  });

  group("UtxoData", () {
    test("UtxoData constructor", () {
      final utxoData = UtxoData(
        totalUserCurrency: "100.0",
        satoshiBalance: 100000000,
        bitcoinBalance: "2",
        unspentOutputArray: [],
      );

      expect(utxoData.toString(),
          "{totalUserCurrency: 100.0, satoshiBalance: 100000000, bitcoinBalance: 2, unspentOutputArray: []}");
    });

    test("UtxoData.fromJson factory", () {
      final utxoData = UtxoData.fromJson({
        "total_user_currency": "100.0",
        "total_sats": 100000000,
        "total_btc": "1",
        "outputArray": [
          {
            "txid": "some txid",
            "vout": 1,
            "value": 1000,
            "fiatWorth": "2",
            "status": {
              "confirmed": true,
              "block_hash": "some block hash",
              "block_height": 67254372,
              "block_time": 87263547764,
            }
          },
          {
            "txid": "some txid2",
            "vout": 0,
            "value": 100,
            "fiatWorth": "1",
            "status": {
              "confirmed": false,
              "block_hash": "some block hash",
              "block_height": 2836375,
              "block_time": 5634236123,
            }
          }
        ],
      });

      expect(utxoData.toString(),
          "{totalUserCurrency: 100.0, satoshiBalance: 100000000, bitcoinBalance: 1, unspentOutputArray: [{txid: some txid, vout: 1, value: 1000, fiat: 2}, {txid: some txid2, vout: 0, value: 100, fiat: 1}]}");
    });
  });
}
