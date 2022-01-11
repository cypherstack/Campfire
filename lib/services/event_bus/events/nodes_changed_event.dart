enum NodesChangedEventType {
  delete,
  edit,
  add,
  updatedCurrentNode,
}

class NodesChangedEvent {
  NodesChangedEventType type;

  NodesChangedEvent(this.type) {
    print("NodesChangedEvent fired with type: $type");
  }
}
