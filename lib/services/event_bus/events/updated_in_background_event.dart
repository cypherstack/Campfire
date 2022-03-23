import 'package:paymint/utilities/logger.dart';

class UpdatedInBackgroundEvent {
  String message;

  UpdatedInBackgroundEvent(this.message) {
    Logger.print("UpdatedInBackgroundEvent fired with message: $message");
  }
}
