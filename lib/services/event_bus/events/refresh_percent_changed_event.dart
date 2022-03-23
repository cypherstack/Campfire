import 'package:paymint/utilities/logger.dart';

class RefreshPercentChangedEvent {
  double percent;

  RefreshPercentChangedEvent(this.percent) {
    Logger.print(
        "RefreshPercentChangedEvent fired with percent (range of 0.0-1.0)= $percent");
  }
}
