class AddressBookChangedEvent {
  String message;

  AddressBookChangedEvent(this.message) {
    print("AddressBookChangedEvent fired with message: $message");
  }
}
