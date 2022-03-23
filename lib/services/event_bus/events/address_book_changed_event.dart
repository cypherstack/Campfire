import 'package:paymint/utilities/logger.dart';

class AddressBookChangedEvent {
  String message;

  AddressBookChangedEvent(this.message) {
    Logger.print("AddressBookChangedEvent fired with message: $message");
  }
}
