enum NodeConnectionStatus { disconnected, connecting, synced, loading }

class NodeConnectionStatusChangedEvent {
  NodeConnectionStatus newStatus;

  NodeConnectionStatusChangedEvent(this.newStatus) {
    print("NodeConnectionStatusChangedEvent fired with arg currentWallet = $newStatus");
  }
}
