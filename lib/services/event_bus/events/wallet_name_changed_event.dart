import 'package:paymint/utilities/logger.dart';

class ActiveWalletNameChangedEvent {
  String currentWallet;

  ActiveWalletNameChangedEvent(this.currentWallet) {
    Logger.print(
        "ActiveWalletNameChangedEvent fired with arg currentWallet = $currentWallet");
  }
}
