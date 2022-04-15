abstract class CampfireConstants {
  static const bool roundedQrCode = true;

  static const int seedPhraseWordCount = 24;

  static const int satsPerCoin = 100000000;
  static const int decimalPlaces = 8;

  // current datastore version
  static const int currentDbVersion = 1;

  // network stuff
  static const String firoGenesisHash =
      "4381deb85b1b2c9843c222944b616d997516dcbd6a964e1eaf0def0830695233";
  static const String firoTestGenesisHash =
      "aa22adcc12becaf436027ffe62a8fb21b234c58c23865291e5dc52cf53f64fca";

  // default main net
  static const String defaultIpAddress = "electrumx-firo.cypherstack.com";
  static const int defaultPort = 50002;
  static const String defaultNodeName = "Campfire default";
  static const bool defaultUseSSL = true;

  // default testnet
  //todo add correct testnet server info
  static const String defaultIpAddressTestNet =
      "testnet.electrumx-firo.cypherstack.com";
  static const int defaultPortTestNet = 50002;
  static const String defaultNodeNameTestNet = "Campfire default testnet";
  static const bool defaultUseSSLTestNet = true;

  // enable testnet
  static const bool allowTestnets = false;

  // Enable Logger.print statements
  static const bool disableLogger = true;
}
