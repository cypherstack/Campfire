import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firo_flutter/firo_flutter.dart';

class AddressUtils {
  static String condenseAddress(String address) {
    return address.substring(0, 5) +
        '...' +
        address.substring(address.length - 5);
  }

  /// attempts to convert a string to a valid scripthash
  ///
  /// Returns the scripthash or throws an exception on invalid firo address
  static String convertToScriptHash(String firoAddress, NetworkType network) {
    try {
      final output = Address.addressToOutputScript(firoAddress, network);
      final hash = sha256.convert(output.toList(growable: false)).toString();

      final chars = hash.split("");
      final reversedPairs = <String>[];
      // TODO find a better/faster way to do this?
      var i = chars.length - 1;
      while (i > 0) {
        reversedPairs.add(chars[i - 1]);
        reversedPairs.add(chars[i]);
        i -= 2;
      }
      return reversedPairs.join("");
    } catch (e) {
      throw e;
    }
  }

  /// parse a firo address uri
  /// returns an empty map if the input string does not begin with "firo:"
  static Map<String, String> parseFiroUri(String uri) {
    Map<String, String> result = {};
    try {
      final u = Uri.parse(uri);
      if (u.hasScheme && u.scheme == "firo") {
        result["address"] = u.path;
        result.addAll(u.queryParameters);
      }
    } catch (e) {
      print(e);
    }
    return result;
  }

  /// returns empty if bad data
  static Map<String, dynamic> decodeQRSeedData(String data) {
    Map<String, dynamic> result = {};
    try {
      result = jsonDecode(data);
    } catch (e) {
      print("Exception caught in parseQRSeedData($data): $e");
    }
    return result;
  }

  /// encode mnemonic words to qrcode formatted string
  static String encodeQRSeedData(List<String> words) {
    String result = "";
    try {
      result = jsonEncode({"mnemonic": words});
    } catch (e) {
      print("Exception caught in encodeQRSeedData: $e");
    }
    return result;
  }
}
