import 'package:paymint/utilities/logger.dart';

enum NodeConnectionStatus { disconnected, connecting, synced, loading }

class NodeConnectionStatusChangedEvent {
  NodeConnectionStatus newStatus;

  NodeConnectionStatusChangedEvent(this.newStatus) {
    Logger.print(
        "NodeConnectionStatusChangedEvent fired with arg newStatus = $newStatus");
  }
}
