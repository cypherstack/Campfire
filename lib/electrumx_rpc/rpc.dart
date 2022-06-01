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
    this.connectionTimeout: const Duration(seconds: 60),
  });
  bool useSSL;
  String address;
  int port;
  Duration connectionTimeout;
  Duration aliveTimerDuration;

  Future<dynamic> request(String jsonRpcRequest) async {
    var socket;
    final completer = Completer();
    final List<int> responseData = [];

    void dataHandler(data) {
      responseData.addAll(data);

      // 0x0A is newline
      // https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-basics.html
      if (data.last == 0x0A) {
        try {
          final response = json.decode(String.fromCharCodes(responseData));
          completer.complete(response);
        } catch (e, s) {
          Logger.print("JsonRPC json.decode: $e\n$s");
          completer.completeError(e, s);
        } finally {
          socket?.destroy();
        }
      }
    }

    void errorHandler(error, StackTrace trace) {
      Logger.print("JsonRPC errorHandler: $error\n$trace");
      completer.completeError(error, trace);
      socket?.destroy();
    }

    void doneHandler() {
      socket?.destroy();
    }

    if (useSSL) {
      await SecureSocket.connect(this.address, this.port,
          timeout: connectionTimeout,
          onBadCertificate: (_) => true).then((Socket sock) {
        socket = sock;
        socket?.listen(dataHandler,
            onError: errorHandler, onDone: doneHandler, cancelOnError: true);
      }).catchError(errorHandler);
    } else {
      await Socket.connect(this.address, this.port, timeout: connectionTimeout)
          .then((Socket sock) {
        socket = sock;
        socket?.listen(dataHandler,
            onError: errorHandler, onDone: doneHandler, cancelOnError: true);
      }).catchError(errorHandler);
    }

    socket?.write('$jsonRpcRequest\r\n');

    return completer.future;
  }
}
