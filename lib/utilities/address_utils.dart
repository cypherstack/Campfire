import 'dart:convert';

class AddressUtils {
  static String condenseAddress(String address) {
    return address.substring(0, 5) +
        '...' +
        address.substring(address.length - 5);
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
