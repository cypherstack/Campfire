import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:paymint/electrumx_rpc/rpc.dart';
import 'package:paymint/utilities/misc_global_constants.dart';

void main() {
  test("REQUIRES INTERNET - JsonRPC.request success", () async {
    final jsonRPC = JsonRPC(
      address: CampfireConstants.defaultIpAddress,
      port: CampfireConstants.defaultPort,
      useSSL: true,
      connectionTimeout: Duration(seconds: 40),
    );

    final jsonRequestString =
        '{"jsonrpc": "2.0", "id": "some id","method": "server.ping","params": []}';
    final result = await jsonRPC.request(jsonRequestString);

    expect(result, {"jsonrpc": "2.0", "result": null, "id": "some id"});
  });

  test("JsonRPC.request fails due to SocketException", () async {
    final jsonRPC = JsonRPC(
      address: "some.bad.address.thingdsfsdfsdaf",
      port: 3000,
      connectionTimeout: Duration(seconds: 10),
    );

    final jsonRequestString =
        '{"jsonrpc": "2.0", "id": "some id","method": "server.ping","params": []}';

    expect(() => jsonRPC.request(jsonRequestString),
        throwsA(isA<SocketException>()));
  });

  test("JsonRPC.request fails due to connection timeout", () async {
    final jsonRPC = JsonRPC(
      address: "8.8.8.8",
      port: 3000,
      useSSL: false,
      connectionTimeout: Duration(seconds: 1),
    );

    final jsonRequestString =
        '{"jsonrpc": "2.0", "id": "some id","method": "server.ping","params": []}';

    expect(() => jsonRPC.request(jsonRequestString),
        throwsA(isA<SocketException>()));
  });
}
