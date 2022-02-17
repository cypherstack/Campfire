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

  Future<dynamic> request1(String jsonRpcRequest) async {
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
      await SecureSocket.connect(this.address, this.port,
          onBadCertificate: (_) => true).then((Socket sock) {
        socket = sock;
        socket?.listen(dataHandler,
            onError: errorHandler, onDone: doneHandler, cancelOnError: true);
      }).catchError((e) {
        Logger.print("Unable to connect: $e");
        socket?.destroy();
      });
    } else {
      await Socket.connect(this.address, this.port).then((Socket sock) {
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

    final int millisecondTimeout = 1000;

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

  Future<dynamic> request(String jsonRpcRequest) async {
    var socket;
    dynamic result;
    final chunks = <String>[];
    int openBracketCount = 0;

    void dataHandler(data) {
      final jsonString = String.fromCharCodes(data);
      chunks.add(jsonString);
      for (int i = 0; i < jsonString.length; i++) {
        if (jsonString[i] == "{" || jsonString[i] == "[") {
          openBracketCount += 1;
        } else if (jsonString[i] == "}" || jsonString[i] == "]") {
          openBracketCount -= 1;
        }
      }

      // complete/valid json so we attempt to parse and return
      if (openBracketCount == 0) {
        try {
          result = json.decode(chunks.join());
        } catch (e, s) {
          print(e);
          print(s);
          throw e;
        } finally {
          socket?.destroy();
        }
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
      await SecureSocket.connect(this.address, this.port,
          onBadCertificate: (_) => true).then((Socket sock) {
        socket = sock;
        socket?.listen(dataHandler,
            onError: errorHandler, onDone: doneHandler, cancelOnError: true);
      }).catchError((e) {
        print("Unable to connect: $e");
        socket?.destroy();
      });
    } else {
      await Socket.connect(this.address, this.port).then((Socket sock) {
        socket = sock;
        socket?.listen(dataHandler,
            onError: errorHandler, onDone: doneHandler, cancelOnError: true);
      }).catchError((e) {
        print("Unable to connect: $e");
        socket?.destroy();
      });
    }

    socket?.write('$jsonRpcRequest\r\n');

    // wait for call to complete and return result
    while (result == null) {
      // sleep
      await Future.delayed(Duration(milliseconds: 100));
    }
    return result;
  }

  Future<dynamic> request2(String jsonRpcRequest) async {
    var socket;
    dynamic result;
    String jsonString = "";

    void dataHandler(data) {
      jsonString += String.fromCharCodes(data);

      try {
        final jsonObject = json.decode(jsonString);

        socket?.destroy();
        result = jsonObject;
      } on FormatException catch (e) {
        // do nothing
      } catch (e, s) {
        print(e);
        print(s);
        throw e;
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
      await SecureSocket.connect(this.address, this.port,
          onBadCertificate: (_) => true).then((Socket sock) {
        socket = sock;
        socket?.listen(dataHandler,
            onError: errorHandler, onDone: doneHandler, cancelOnError: true);
      }).catchError((e) {
        print("Unable to connect: $e");
        socket?.destroy();
      });
    } else {
      await Socket.connect(this.address, this.port).then((Socket sock) {
        socket = sock;
        socket?.listen(dataHandler,
            onError: errorHandler, onDone: doneHandler, cancelOnError: true);
      }).catchError((e) {
        print("Unable to connect: $e");
        socket?.destroy();
      });
    }

    socket?.write('$jsonRpcRequest\r\n');

    // wait for call to complete and return result
    while (result == null) {
      // sleep
      await Future.delayed(Duration(milliseconds: 100));
    }
    return result;
  }
}
