class ActiveWalletNameChangedEvent {
  String currentWallet;

  ActiveWalletNameChangedEvent(this.currentWallet) {
    print("ActiveWalletNameChangedEvent fired with arg currentWallet = $currentWallet");
  }
}
