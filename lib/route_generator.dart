import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:paymint/pages/address_book_view/address_book_view.dart';
import 'package:paymint/pages/address_book_view/subviews/add_address_book_entry_view.dart';
import 'package:paymint/pages/main_view.dart';
import 'package:paymint/pages/settings_view/settings_subviews/network_settings_subviews/add_custom_node_view.dart';
import 'package:paymint/pages/settings_view/settings_subviews/wallet_backup_view.dart';
import 'package:paymint/pages/settings_view/settings_subviews/wallet_settings_subviews/change_pin_view.dart';
import 'package:paymint/pages/settings_view/settings_subviews/wallet_settings_subviews/delete_wallet_warning_view.dart';
import 'package:paymint/pages/wallet_view/receive_view.dart';
import 'package:paymint/pages/wallet_view/send_view.dart';

class RouteGenerator {
  // This functions handles all top level routes in the app. Subrouting is handled individually
  // inside relevant widgets
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Getting arguments passed into Navigator.pushNamed
    // final args = settings.arguments;

    switch (settings.name) {
      case '/mainview':
        return CupertinoPageRoute(builder: (_) => MainView());
      case '/receive':
        return CupertinoPageRoute(builder: (_) => ReceiveView());
      case '/send':
        return CupertinoPageRoute(builder: (_) => SendView());
      case '/addressbook':
        return CupertinoPageRoute(builder: (_) => AddressBookView());
      case '/addaddressbookentry':
        return CupertinoPageRoute(builder: (_) => AddAddressBookEntryView());
      case '/settings/walletbackup':
        return CupertinoPageRoute(builder: (_) => WalletBackUpView());
      case '/settings/deletewalletwarningview':
        return CupertinoPageRoute(builder: (_) => DeleteWalletWarningView());
      case '/settings/changepinview':
        return CupertinoPageRoute(builder: (_) => ChangePinView());
      case '/settings/addcustomnode':
        return CupertinoPageRoute(builder: (_) => AddCustomNodeView());

      default:
        return _routeError();
    }
  }
}

Route createSlideTransitionRoute(Widget viewToInsert) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => viewToInsert,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      var begin = Offset(0.0, 1.0);
      var end = Offset.zero;
      var curve = Curves.easeInOut;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}

Route<dynamic> _routeError() {
  // Replace with robust ErrorView page
  Widget errorView = Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.black,
      title: Text('Navigation error'),
    ),
    body: Center(
      child: Text(
          'Error handling route, this is not supposed to happen. Try restarting the app.'),
    ),
  );

  return CupertinoPageRoute(builder: (_) => errorView);
}
