class UpdatedInBackgroundEvent {
  String message;

  UpdatedInBackgroundEvent(this.message) {
    print("UpdatedInBackgroundEvent fired with message: $message");
  }
}
