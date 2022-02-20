import 'package:paymint/electrumx_rpc/electrumx.dart';

class CampfireConstants {
  static const bool roundedQrCode = true;

  static const int seedPhraseWordCount = 24;

  static const int satsPerCoin = 100000000;
  static const int decimalPlaces = 8;

  //network stuff
  static const String defaultIpAddress = ELECTRUMX_SERVER;
  static const int defaultPort = ELECTRUMX_PORT;
  static const String defaultNodeName = "Campfire default";
  static const String defaultIpAddressTestNet = ELECTRUMX_SERVER;
  static const int defaultPortTestNet = ELECTRUMX_PORT;
  static const String defaultNodeNameTestNet = "Campfire default testnet";

  // enable testnet
  static const bool allowTestnets = true;
}
