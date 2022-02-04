import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:paymint/utilities/logger.dart';

// hacky fix to receive large jsonrpc responses
class JsonRPC {
  JsonRPC({
    this.address,
    this.port,
    this.useSSL: false,
    this.connectionTimeout: const Duration(seconds: 5),
    this.aliveTimerDuration: const Duration(seconds: 2),
  });
  bool useSSL;
  String address;
  int port;
  Duration connectionTimeout;
  Duration aliveTimerDuration;

  Future<dynamic> request(String jsonRpcRequest) async {
    var socket;
    final _data = <int>[];

    DateTime timeSinceLastChunk;

    void dataHandler(data) {
      timeSinceLastChunk = DateTime.now();
      _data.addAll(data);
    }

    //TODO handle error better
    void errorHandler(error, StackTrace trace) {
      Logger.print(error);
    }

    void doneHandler() {
      socket?.destroy();
    }

    if (useSSL) {
      await SecureSocket.connect(
          this.address ?? "electrumx.firo.org", this.port ?? 50002,
          onBadCertificate: (_) => true).then((Socket sock) {
        socket = sock;
        socket?.listen(dataHandler,
            onError: errorHandler, onDone: doneHandler, cancelOnError: true);
      }).catchError((e) {
        Logger.print("Unable to connect: $e");
        socket?.destroy();
      });
    } else {
      await Socket.connect(
              this.address ?? "electrumx.firo.org", this.port ?? 50001)
          .then((Socket sock) {
        socket = sock;
        socket?.listen(dataHandler,
            onError: errorHandler, onDone: doneHandler, cancelOnError: true);
      }).catchError((e) {
        Logger.print("Unable to connect: $e");
        socket?.destroy();
      });
    }

    socket?.write('$jsonRpcRequest\r\n');

    // wait for call to complete and data starts coming back
    while (timeSinceLastChunk == null) {
      // wait before checking again
      await Future.delayed(Duration(milliseconds: 100));
    }

    final int millisecondTimeout = 500;

    /// wait while data comes back and only continue when time between receiving
    /// chunks of data is greater than millisecondTimeout
    while (DateTime.now().millisecondsSinceEpoch -
            timeSinceLastChunk.millisecondsSinceEpoch <
        millisecondTimeout) {
      // wait before checking again
      await Future.delayed(Duration(milliseconds: 100));
    }

    socket?.destroy();
    try {
      final String jsonString = String.fromCharCodes(_data);
      final jsonObject = json.decode(jsonString);
      return jsonObject;
    } catch (e) {
      throw e;
    }
  }

  Future<String> request2(String jsonRpc) async {
    var socket;
    String jsonString = "";
    String result;

    void dataHandler(data) {
      jsonString += String.fromCharCodes(data);
      try {
        json.decode(jsonString);
        // json succeeded
        socket?.destroy();
        result = jsonString;
      } on FormatException catch (_) {
        // continue reading socket
      } catch (e) {
        print(e);
      }
    }

    //TODO handle error better
    void errorHandler(error, StackTrace trace) {
      print(error);
    }

    void doneHandler() {
      socket?.destroy();
    }

    if (useSSL) {
      await SecureSocket.connect(
          this.address ?? "electrumx.firo.org", this.port ?? 50002,
          onBadCertificate: (_) => true).then((Socket sock) {
        socket = sock;
        socket?.listen(dataHandler,
            onError: errorHandler, onDone: doneHandler, cancelOnError: true);
      }).catchError((e) {
        print("Unable to connect: $e");
        socket?.destroy();
      });
    } else {
      await Socket.connect(
              this.address ?? "electrumx.firo.org", this.port ?? 50001)
          .then((Socket sock) {
        socket = sock;
        socket?.listen(dataHandler,
            onError: errorHandler, onDone: doneHandler, cancelOnError: true);
      }).catchError((e) {
        print("Unable to connect: $e");
        socket?.destroy();
      });
    }

    socket?.write('$jsonRpc\r\n');

    // wait for call to complete and return result
    while (result == null) {
      // sleep
      await Future.delayed(Duration(milliseconds: 100));
    }
    return result;
  }

  void request1(String jsonRpc, Function(String) callback) async {
    var socket;
    String jsonString = "";

    void dataHandler(data) {
      jsonString += String.fromCharCodes(data);

      try {
        json.decode(jsonString);
        // json succeeded
        socket?.destroy();
        callback(jsonString);
      } on FormatException catch (_) {
        // continue reading socket
      } catch (e) {
        print(e);
      }
    }

    //TODO handle error better
    void errorHandler(error, StackTrace trace) {
      print(error);
    }

    void doneHandler() {
      socket?.destroy();
    }

    if (useSSL) {
      await SecureSocket.connect(
          this.address ?? "electrumx.firo.org", this.port ?? 50002,
          onBadCertificate: (_) => true).then((Socket sock) {
        socket = sock;
        socket?.listen(dataHandler,
            onError: errorHandler, onDone: doneHandler, cancelOnError: false);
      }).catchError((e) {
        print("Unable to connect: $e");
        socket?.destroy();
      });
    } else {
      await Socket.connect(
              this.address ?? "electrumx.firo.org", this.port ?? 50001)
          .then((Socket sock) {
        socket = sock;
        socket?.listen(dataHandler,
            onError: errorHandler, onDone: doneHandler, cancelOnError: false);
      }).catchError((e) {
        print("Unable to connect: $e");
        socket?.destroy();
      });
    }

    socket?.write('$jsonRpc\r\n');
  }
}
