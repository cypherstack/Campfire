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
}
