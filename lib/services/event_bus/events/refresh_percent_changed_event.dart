class RefreshPercentChangedEvent {
  double percent;

  RefreshPercentChangedEvent(this.percent) {
    print(
        "RefreshPercentChangedEvent fired with percent (range of 0.0-1.0)= $percent");
  }
}
