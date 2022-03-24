import 'package:paymint/utilities/logger.dart';

enum NodesChangedEventType {
  delete,
  edit,
  add,
  updatedCurrentNode,
}

class NodesChangedEvent {
  NodesChangedEventType type;

  NodesChangedEvent(this.type) {
    Logger.print("NodesChangedEvent fired with type: $type");
  }
}
