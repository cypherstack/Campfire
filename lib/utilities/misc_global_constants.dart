import 'package:paymint/electrumx_rpc/electrumx.dart';

class CampfireConstants {
  static const bool roundedQrCode = true;

  static const int seedPhraseWordCount = 24;

  //network stuff
  static const String defaultIpAddress = ELECTRUMX_SERVER;
  static const int defaultPort = ELECTRUMX_PORT;
  static const String defaultNodeName = "Campfire default";
}
