import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:paymint/models/transactions_model.dart';
import 'package:paymint/models/utxo_model.dart';

import 'utxo_model_adapter_test.mocks.dart';

@GenerateMocks([BinaryReader, BinaryWriter])
void main() {
  group("UtxoDataAdapter", () {
    test("UtxoDataAdapter.read", () {
      final adapter = UtxoDataAdapter();
      final reader = MockBinaryReader();

      when(reader.readByte()).thenAnswer((_) => 4);

      when(reader.read()).thenAnswer((_) => "100");
      when(reader.read()).thenAnswer((_) => 100000000);
      when(reader.read()).thenAnswer((_) => "10");
      when(reader.read()).thenAnswer((_) => "some txid");

      final result = adapter.read(reader);

      verify(reader.read()).called(4);
      expect(result, isA<UtxoData>());
    });

    test("UtxoDataAdapter.write", () {
      final adapter = UtxoDataAdapter();
      final obj = UtxoData(
        totalUserCurrency: "10000",
        satoshiBalance: 10000000,
        bitcoinBalance: "1",
        unspentOutputArray: [],
      );
      final writer = MockBinaryWriter();

      for (int i = 0; i <= 4; i++) {
        when(writer.writeByte(i)).thenAnswer((_) {
          return;
        });
      }

      when(writer.write(obj.totalUserCurrency)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.satoshiBalance)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.bitcoinBalance)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.unspentOutputArray)).thenAnswer((_) {
        return;
      });

      adapter.write(writer, obj);

      verifyInOrder([
        writer.writeByte(4),
        writer.writeByte(0),
        writer.write(obj.totalUserCurrency),
        writer.writeByte(1),
        writer.write(obj.satoshiBalance),
        writer.writeByte(2),
        writer.write(obj.bitcoinBalance),
        writer.writeByte(3),
        writer.write(obj.unspentOutputArray),
      ]);
    });

    test("UtxoDataAdapter.hashcode", () {
      final adapter = UtxoDataAdapter();

      final result = adapter.hashCode;
      expect(result, 6);
    });

    group("UtxoDataAdapter compare operator", () {
      test("UtxoDataAdapter is equal one", () {
        final a = UtxoDataAdapter();
        final b = UtxoDataAdapter();

        final result = a == b;
        expect(result, true);
      });

      test("UtxoDataAdapter is equal two", () {
        final a = UtxoDataAdapter();
        final b = a;

        final result = a == b;
        expect(result, true);
      });

      test("UtxoDataAdapter is not equal one", () {
        final TypeAdapter a = UtxoDataAdapter();
        final TypeAdapter b = TransactionDataAdapter();

        final result = a == b;
        expect(result, false);
      });

      test("UtxoDataAdapter is not equal two", () {
        final a = UtxoDataAdapter();

        final result = a == 8;
        expect(result, false);
      });
    });
  });

  group("UtxoObjectAdapter", () {
    test("UtxoObjectAdapter.read", () {
      final adapter = UtxoObjectAdapter();
      final reader = MockBinaryReader();

      when(reader.readByte()).thenAnswer((_) => 7);

      when(reader.read()).thenAnswer((_) => "100");
      when(reader.read()).thenAnswer((_) => 1);
      when(reader.read()).thenAnswer((_) => Status());
      when(reader.read()).thenAnswer((_) => 100000);
      when(reader.read()).thenAnswer((_) => "123");
      when(reader.read()).thenAnswer((_) => "10");
      when(reader.read()).thenAnswer((_) => true);

      final result = adapter.read(reader);

      verify(reader.read()).called(7);
      expect(result, isA<UtxoObject>());
    });

    test("UtxoObjectAdapter.write", () {
      final adapter = UtxoObjectAdapter();
      final obj = UtxoObject(
        txid: "some txid",
        vout: 1,
        status: Status(),
        value: 10000,
        fiatWorth: "122",
        txName: "name",
        blocked: true,
      );
      final writer = MockBinaryWriter();

      for (int i = 0; i <= 7; i++) {
        when(writer.writeByte(i)).thenAnswer((_) {
          return;
        });
      }

      when(writer.write(obj.txid)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.vout)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.status)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.value)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.fiatWorth)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.txName)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.blocked)).thenAnswer((_) {
        return;
      });

      adapter.write(writer, obj);

      verifyInOrder([
        writer.writeByte(7),
        writer.writeByte(0),
        writer.write(obj.txid),
        writer.writeByte(1),
        writer.write(obj.vout),
        writer.writeByte(2),
        writer.write(obj.status),
        writer.writeByte(3),
        writer.write(obj.value),
        writer.writeByte(4),
        writer.write(obj.fiatWorth),
        writer.writeByte(5),
        writer.write(obj.txName),
        writer.writeByte(6),
        writer.write(obj.blocked),
      ]);
    });

    test("UtxoObjectAdapter.hashcode", () {
      final adapter = UtxoObjectAdapter();

      final result = adapter.hashCode;
      expect(result, 7);
    });

    group("UtxoObjectAdapter compare operator", () {
      test("UtxoObjectAdapter is equal one", () {
        final a = UtxoObjectAdapter();
        final b = UtxoObjectAdapter();

        final result = a == b;
        expect(result, true);
      });

      test("UtxoObjectAdapter is equal two", () {
        final a = UtxoObjectAdapter();
        final b = a;

        final result = a == b;
        expect(result, true);
      });

      test("UtxoObjectAdapter is not equal one", () {
        final TypeAdapter a = UtxoObjectAdapter();
        final TypeAdapter b = TransactionDataAdapter();

        final result = a == b;
        expect(result, false);
      });

      test("UtxoObjectAdapter is not equal two", () {
        final a = UtxoObjectAdapter();

        final result = a == 8;
        expect(result, false);
      });
    });
  });

  group("StatusAdapter", () {
    test("StatusAdapter.read", () {
      final adapter = StatusAdapter();
      final reader = MockBinaryReader();

      when(reader.readByte()).thenAnswer((_) => 4);

      when(reader.read()).thenAnswer((_) => true);
      when(reader.read()).thenAnswer((_) => "some blockhash");
      when(reader.read()).thenAnswer((_) => 4587364);
      when(reader.read()).thenAnswer((_) => 3476523434);

      final result = adapter.read(reader);

      verify(reader.read()).called(4);
      expect(result, isA<Status>());
    });

    test("StatusAdapter.write", () {
      final adapter = StatusAdapter();
      final obj = Status(
        confirmed: true,
        blockHash: "some block hash",
        blockHeight: 328746,
        blockTime: 2174381236,
      );
      final writer = MockBinaryWriter();

      for (int i = 0; i <= 4; i++) {
        when(writer.writeByte(i)).thenAnswer((_) {
          return;
        });
      }

      when(writer.write(obj.confirmed)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.blockHash)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.blockHeight)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.blockTime)).thenAnswer((_) {
        return;
      });

      adapter.write(writer, obj);

      verifyInOrder([
        writer.writeByte(4),
        writer.writeByte(0),
        writer.write(obj.confirmed),
        writer.writeByte(1),
        writer.write(obj.blockHash),
        writer.writeByte(2),
        writer.write(obj.blockHeight),
        writer.writeByte(3),
        writer.write(obj.blockTime),
      ]);
    });

    test("StatusAdapter.hashcode", () {
      final adapter = StatusAdapter();

      final result = adapter.hashCode;
      expect(result, 8);
    });

    group("StatusAdapter compare operator", () {
      test("StatusAdapter is equal one", () {
        final a = StatusAdapter();
        final b = StatusAdapter();

        final result = a == b;
        expect(result, true);
      });

      test("StatusAdapter is equal two", () {
        final a = StatusAdapter();
        final b = a;

        final result = a == b;
        expect(result, true);
      });

      test("StatusAdapter is not equal one", () {
        final TypeAdapter a = StatusAdapter();
        final TypeAdapter b = TransactionDataAdapter();

        final result = a == b;
        expect(result, false);
      });

      test("StatusAdapter is not equal two", () {
        final a = StatusAdapter();

        final result = a == 8;
        expect(result, false);
      });
    });
  });
}
