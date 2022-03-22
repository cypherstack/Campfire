import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:paymint/models/lelantus_coin.dart';
import 'package:paymint/models/transactions_model.dart';

import 'transactions_model_adapter_test.mocks.dart';

@GenerateMocks([BinaryReader, BinaryWriter])
void main() {
  group("TransactionDataAdapter", () {
    test("TransactionDataAdapter.read", () {
      final adapter = TransactionDataAdapter();
      final reader = MockBinaryReader();

      when(reader.readByte()).thenAnswer((_) => 1);

      when(reader.read()).thenAnswer((_) => []);

      final result = adapter.read(reader);

      verify(reader.read()).called(1);
      expect(result, isA<TransactionData>());
    });

    test("TransactionDataAdapter.write", () {
      final adapter = TransactionDataAdapter();
      final obj = TransactionData();
      final writer = MockBinaryWriter();

      when(writer.writeByte(1)).thenAnswer((_) {
        return;
      });
      when(writer.writeByte(0)).thenAnswer((_) {
        return;
      });

      when(writer.write(obj.txChunks)).thenAnswer((_) {
        return;
      });

      adapter.write(writer, obj);

      verifyInOrder([
        writer.writeByte(1),
        writer.writeByte(0),
        writer.write(obj.txChunks),
      ]);
    });

    test("TransactionDataAdapter.hashcode", () {
      final adapter = TransactionDataAdapter();

      final result = adapter.hashCode;
      expect(result, 1);
    });

    group("TransactionDataAdapter compare operator", () {
      test("TransactionDataAdapter is equal one", () {
        final a = TransactionDataAdapter();
        final b = TransactionDataAdapter();

        final result = a == b;
        expect(result, true);
      });

      test("TransactionDataAdapter is equal two", () {
        final a = TransactionDataAdapter();
        final b = a;

        final result = a == b;
        expect(result, true);
      });

      test("TransactionDataAdapter is not equal one", () {
        final TypeAdapter a = TransactionDataAdapter();
        final TypeAdapter b = LelantusCoinAdapter();

        final result = a == b;
        expect(result, false);
      });

      test("TransactionDataAdapter is not equal two", () {
        final a = TransactionDataAdapter();

        final result = a == 8;
        expect(result, false);
      });
    });
  });

  group("TransactionChunkAdapter", () {
    test("TransactionChunkAdapter.read", () {
      final adapter = TransactionChunkAdapter();
      final reader = MockBinaryReader();

      when(reader.readByte()).thenAnswer((_) => 2);

      when(reader.read()).thenAnswer((_) => 3426523234);
      when(reader.read()).thenAnswer((_) => []);

      final result = adapter.read(reader);

      verify(reader.read()).called(2);
      expect(result, isA<TransactionChunk>());
    });

    test("TransactionChunkAdapter.write", () {
      final adapter = TransactionChunkAdapter();
      final obj = TransactionChunk(timestamp: 389475684, transactions: []);
      final writer = MockBinaryWriter();

      for (int i = 0; i <= 2; i++) {
        when(writer.writeByte(i)).thenAnswer((_) {
          return;
        });
      }

      when(writer.write(obj.timestamp)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.transactions)).thenAnswer((_) {
        return;
      });

      adapter.write(writer, obj);

      verifyInOrder([
        writer.writeByte(2),
        writer.writeByte(0),
        writer.write(obj.timestamp),
        writer.writeByte(1),
        writer.write(obj.transactions),
      ]);
    });

    test("TransactionChunkAdapter.hashcode", () {
      final adapter = TransactionChunkAdapter();

      final result = adapter.hashCode;
      expect(result, 2);
    });

    group("TransactionChunkAdapter compare operator", () {
      test("TransactionChunkAdapter is equal one", () {
        final a = TransactionChunkAdapter();
        final b = TransactionChunkAdapter();

        final result = a == b;
        expect(result, true);
      });

      test("TransactionChunkAdapter is equal two", () {
        final a = TransactionChunkAdapter();
        final b = a;

        final result = a == b;
        expect(result, true);
      });

      test("TransactionChunkAdapter is not equal one", () {
        final TypeAdapter a = TransactionChunkAdapter();
        final TypeAdapter b = TransactionDataAdapter();

        final result = a == b;
        expect(result, false);
      });

      test("TransactionChunkAdapter is not equal two", () {
        final a = TransactionChunkAdapter();

        final result = a == 8;
        expect(result, false);
      });
    });
  });

  group("TransactionAdapter", () {
    test("TransactionAdapter.read", () {
      final adapter = TransactionAdapter();
      final reader = MockBinaryReader();

      when(reader.readByte()).thenAnswer((_) => 16);

      when(reader.read()).thenAnswer((_) => "some txid");
      when(reader.read()).thenAnswer((_) => true);
      when(reader.read()).thenAnswer((_) => 872346534);
      when(reader.read()).thenAnswer((_) => "Received");
      when(reader.read()).thenAnswer((_) => 10000000);
      when(reader.read()).thenAnswer((_) => []);
      when(reader.read()).thenAnswer((_) => "122");
      when(reader.read()).thenAnswer((_) => "122");
      when(reader.read()).thenAnswer((_) => 3794);
      when(reader.read()).thenAnswer((_) => 3794);
      when(reader.read()).thenAnswer((_) => 4);
      when(reader.read()).thenAnswer((_) => [Input(), Input()]);
      when(reader.read()).thenAnswer((_) => [Output(), Output()]);
      when(reader.read()).thenAnswer((_) => "some address");
      when(reader.read()).thenAnswer((_) => 458734);
      when(reader.read()).thenAnswer((_) => "mint");

      final result = adapter.read(reader);

      verify(reader.read()).called(16);
      expect(result, isA<Transaction>());
    });

    test("TransactionAdapter.write", () {
      final adapter = TransactionAdapter();
      final obj = Transaction();
      final writer = MockBinaryWriter();

      for (int i = 0; i <= 16; i++) {
        when(writer.writeByte(i)).thenAnswer((_) {
          return;
        });
      }

      when(writer.write(obj.txid)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.confirmedStatus)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.timestamp)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.txType)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.amount)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.aliens)).thenAnswer((_) {
        return;
      });

      when(writer.write(obj.worthNow)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.worthAtBlockTimestamp)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.fees)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.inputSize)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.outputSize)).thenAnswer((_) {
        return;
      });

      when(writer.write(obj.inputs)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.outputs)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.address)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.height)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.subType)).thenAnswer((_) {
        return;
      });

      adapter.write(writer, obj);

      verifyInOrder([
        writer.writeByte(16),
        writer.writeByte(0),
        writer.write(obj.txid),
        writer.writeByte(1),
        writer.write(obj.confirmedStatus),
        writer.writeByte(2),
        writer.write(obj.timestamp),
        writer.writeByte(3),
        writer.write(obj.txType),
        writer.writeByte(4),
        writer.write(obj.amount),
        writer.writeByte(5),
        writer.write(obj.aliens),
        writer.writeByte(6),
        writer.write(obj.worthNow),
        writer.writeByte(7),
        writer.write(obj.worthAtBlockTimestamp),
        writer.writeByte(8),
        writer.write(obj.fees),
        writer.writeByte(9),
        writer.write(obj.inputSize),
        writer.writeByte(10),
        writer.write(obj.outputSize),
        writer.writeByte(11),
        writer.write(obj.inputs),
        writer.writeByte(12),
        writer.write(obj.outputs),
        writer.writeByte(13),
        writer.write(obj.address),
        writer.writeByte(14),
        writer.write(obj.height),
        writer.writeByte(15),
        writer.write(obj.subType),
      ]);
    });

    test("TransactionAdapter.hashcode", () {
      final adapter = TransactionAdapter();

      final result = adapter.hashCode;
      expect(result, 3);
    });

    group("TransactionAdapter compare operator", () {
      test("TransactionAdapter is equal one", () {
        final a = TransactionAdapter();
        final b = TransactionAdapter();

        final result = a == b;
        expect(result, true);
      });

      test("TransactionAdapter is equal two", () {
        final a = TransactionAdapter();
        final b = a;

        final result = a == b;
        expect(result, true);
      });

      test("TransactionAdapteris not equal one", () {
        final TypeAdapter a = TransactionAdapter();
        final TypeAdapter b = TransactionDataAdapter();

        final result = a == b;
        expect(result, false);
      });

      test("TransactionAdapter is not equal two", () {
        final a = TransactionAdapter();

        final result = a == 8;
        expect(result, false);
      });
    });
  });

  group("InputAdapter", () {
    test("InputAdapter.read", () {
      final adapter = InputAdapter();
      final reader = MockBinaryReader();

      when(reader.readByte()).thenAnswer((_) => 9);

      when(reader.read()).thenAnswer((_) => "some txid");
      when(reader.read()).thenAnswer((_) => 1);
      when(reader.read()).thenAnswer((_) => Output());
      when(reader.read()).thenAnswer((_) => "some script sig");
      when(reader.read()).thenAnswer((_) => "some script sig asm");
      when(reader.read()).thenAnswer((_) => []);
      when(reader.read()).thenAnswer((_) => true);
      when(reader.read()).thenAnswer((_) => 1);
      when(reader.read()).thenAnswer((_) => "some script");

      final result = adapter.read(reader);

      verify(reader.read()).called(9);
      expect(result, isA<Input>());
    });

    test("InputAdapter.write", () {
      final adapter = InputAdapter();
      final obj = Input();
      final writer = MockBinaryWriter();

      for (int i = 0; i <= 9; i++) {
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
      when(writer.write(obj.prevout)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.scriptsig)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.scriptsigAsm)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.witness)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.isCoinbase)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.sequence)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.innerRedeemscriptAsm)).thenAnswer((_) {
        return;
      });

      adapter.write(writer, obj);

      verifyInOrder([
        writer.writeByte(9),
        writer.writeByte(0),
        writer.write(obj.txid),
        writer.writeByte(1),
        writer.write(obj.vout),
        writer.writeByte(2),
        writer.write(obj.prevout),
        writer.writeByte(3),
        writer.write(obj.scriptsig),
        writer.writeByte(4),
        writer.write(obj.scriptsigAsm),
        writer.writeByte(5),
        writer.write(obj.witness),
        writer.writeByte(6),
        writer.write(obj.isCoinbase),
        writer.writeByte(7),
        writer.write(obj.sequence),
        writer.writeByte(8),
        writer.write(obj.innerRedeemscriptAsm),
      ]);
    });

    test("InputAdapter.hashcode", () {
      final adapter = InputAdapter();

      final result = adapter.hashCode;
      expect(result, 4);
    });

    group("InputAdapter compare operator", () {
      test("InputAdapter is equal one", () {
        final a = InputAdapter();
        final b = InputAdapter();

        final result = a == b;
        expect(result, true);
      });

      test("InputAdapter is equal two", () {
        final a = InputAdapter();
        final b = a;

        final result = a == b;
        expect(result, true);
      });

      test("InputAdapter is not equal one", () {
        final TypeAdapter a = InputAdapter();
        final TypeAdapter b = TransactionDataAdapter();

        final result = a == b;
        expect(result, false);
      });

      test("InputAdapter is not equal two", () {
        final a = InputAdapter();

        final result = a == 8;
        expect(result, false);
      });
    });
  });

  group("OutputAdapter", () {
    test("OutputAdapter.read", () {
      final adapter = OutputAdapter();
      final reader = MockBinaryReader();

      when(reader.readByte()).thenAnswer((_) => 5);

      when(reader.read()).thenAnswer((_) => "some scriptpubkey");
      when(reader.read()).thenAnswer((_) => "some scriptpubkey asm");
      when(reader.read()).thenAnswer((_) => "some scriptpubkey type");
      when(reader.read()).thenAnswer((_) => "some scriptpubkey address");
      when(reader.read()).thenAnswer((_) => 10000);

      final result = adapter.read(reader);

      verify(reader.read()).called(5);
      expect(result, isA<Output>());
    });

    test("OutputAdapter.write", () {
      final adapter = OutputAdapter();
      final obj = Output();
      final writer = MockBinaryWriter();

      for (int i = 0; i <= 5; i++) {
        when(writer.writeByte(i)).thenAnswer((_) {
          return;
        });
      }

      when(writer.write(obj.scriptpubkey)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.scriptpubkeyAsm)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.scriptpubkeyType)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.scriptpubkeyAddress)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.value)).thenAnswer((_) {
        return;
      });

      adapter.write(writer, obj);

      verifyInOrder([
        writer.writeByte(5),
        writer.writeByte(0),
        writer.write(obj.scriptpubkey),
        writer.writeByte(1),
        writer.write(obj.scriptpubkeyAsm),
        writer.writeByte(2),
        writer.write(obj.scriptpubkeyType),
        writer.writeByte(3),
        writer.write(obj.scriptpubkeyAddress),
        writer.writeByte(4),
        writer.write(obj.value),
      ]);
    });

    test("OutputAdapter.hashcode", () {
      final adapter = OutputAdapter();

      final result = adapter.hashCode;
      expect(result, 5);
    });

    group("OutputAdapter compare operator", () {
      test("OutputAdapter is equal one", () {
        final a = OutputAdapter();
        final b = OutputAdapter();

        final result = a == b;
        expect(result, true);
      });

      test("OutputAdapter is equal two", () {
        final a = OutputAdapter();
        final b = a;

        final result = a == b;
        expect(result, true);
      });

      test("OutputAdapter is not equal one", () {
        final TypeAdapter a = OutputAdapter();
        final TypeAdapter b = TransactionDataAdapter();

        final result = a == b;
        expect(result, false);
      });

      test("OutputAdapter is not equal two", () {
        final a = OutputAdapter();

        final result = a == 8;
        expect(result, false);
      });
    });
  });
}
