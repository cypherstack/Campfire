class CampfireConstants {
  static const bool roundedQrCode = true;

  static const int seedPhraseWordCount = 24;

  static const int satsPerCoin = 100000000;
  static const int decimalPlaces = 8;

  // network stuff
  // default mainnet
  // todo replace with cypherstack server info
  static const String defaultIpAddress = "electrumx.firo.org";
  // static const String defaultIpAddress = "electrumx-firo.cypherstack.com";
  static const int defaultPort = 50002;
  static const String defaultNodeName = "Campfire default";
  static const bool defaultUseSSL = true;

  // default testnet
  //todo add correct testnet server info
  static const String defaultIpAddressTestNet =
      "electrumx-firo.cypherstack.com";
  static const int defaultPortTestNet = 50002;
  static const String defaultNodeNameTestNet = "Campfire default testnet";
  static const bool defaultUseSSLTestNet = false;

  // enable testnet
  static const bool allowTestnets = false;
}
