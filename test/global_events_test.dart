import 'package:flutter_test/flutter_test.dart';
import 'package:paymint/services/event_bus/events/address_book_changed_event.dart';
import 'package:paymint/services/event_bus/events/node_connection_status_changed_event.dart';
import 'package:paymint/services/event_bus/events/nodes_changed_event.dart';
import 'package:paymint/services/event_bus/events/refresh_percent_changed_event.dart';
import 'package:paymint/services/event_bus/events/updated_in_background_event.dart';
import 'package:paymint/services/event_bus/events/wallet_name_changed_event.dart';
import 'package:paymint/services/event_bus/global_event_bus.dart';

void main() {
  test("AddressBookChangedEvent", () async {
    final listener =
        GlobalEventBus.instance.on<AddressBookChangedEvent>().listen((event) {
      expect(event.message, "AddressBookChangedEvent");
    });
    expect(
        () => GlobalEventBus.instance
            .fire(AddressBookChangedEvent("AddressBookChangedEvent")),
        returnsNormally);
    listener.cancel();
  });

  test("NodeConnectionStatusChangedEvent", () async {
    final listener = GlobalEventBus.instance
        .on<NodeConnectionStatusChangedEvent>()
        .listen((event) {
      expect(event.newStatus, NodeConnectionStatus.loading);
    });
    expect(
        () => GlobalEventBus.instance.fire(
            NodeConnectionStatusChangedEvent(NodeConnectionStatus.loading)),
        returnsNormally);
    listener.cancel();
  });

  test("NodesChangedEvent", () async {
    final listener =
        GlobalEventBus.instance.on<NodesChangedEvent>().listen((event) {
      expect(event.type, NodesChangedEventType.updatedCurrentNode);
    });
    expect(
        () => GlobalEventBus.instance
            .fire(NodesChangedEvent(NodesChangedEventType.updatedCurrentNode)),
        returnsNormally);
    listener.cancel();
  });

  test("RefreshPercentChangedEvent", () async {
    final listener = GlobalEventBus.instance
        .on<RefreshPercentChangedEvent>()
        .listen((event) {
      expect(event.percent, 0.5);
    });
    expect(() => GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.5)),
        returnsNormally);
    listener.cancel();
  });

  test("UpdatedInBackgroundEvent", () async {
    final listener =
        GlobalEventBus.instance.on<UpdatedInBackgroundEvent>().listen((event) {
      expect(event.message, "UpdatedInBackgroundEvent");
    });
    expect(
        () => GlobalEventBus.instance
            .fire(UpdatedInBackgroundEvent("UpdatedInBackgroundEvent")),
        returnsNormally);
    listener.cancel();
  });

  test("ActiveWalletNameChangedEvent", () async {
    final listener = GlobalEventBus.instance
        .on<ActiveWalletNameChangedEvent>()
        .listen((event) {
      expect(event.currentWallet, "ActiveWalletNameChangedEvent");
    });
    expect(
        () => GlobalEventBus.instance
            .fire(ActiveWalletNameChangedEvent("ActiveWalletNameChangedEvent")),
        returnsNormally);
    listener.cancel();
  });
}
