import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path;
import 'package:paymint/models/models.dart';
import 'package:paymint/pages/loading_view.dart';
import 'package:paymint/pages/onboarding_view/onboarding_view.dart';
import 'package:paymint/pages/wallet_selection_view.dart';
import 'package:paymint/services/address_book_service.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/services/node_service.dart';
import 'package:paymint/services/notes_service.dart';
import 'package:paymint/services/notifications_api.dart';
import 'package:paymint/services/wallets_service.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/logger.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:provider/provider.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';

import 'route_generator.dart';

// main() is the entry point to the app. It initializes Hive (local database),
// runs the MyApp widget and checks for new users, caching the value in the
// miscellaneous box for later use
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDirectory = await path.getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDirectory.path);

  // Registering Transaction Model Adapters
  Hive.registerAdapter(TransactionDataAdapter());
  Hive.registerAdapter(TransactionChunkAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(InputAdapter());
  Hive.registerAdapter(OutputAdapter());

  // Registering Utxo Model Adapters
  Hive.registerAdapter(UtxoDataAdapter());
  Hive.registerAdapter(UtxoObjectAdapter());
  Hive.registerAdapter(StatusAdapter());

  // Registering Lelantus Model Adapters
  Hive.registerAdapter(LelantusCoinAdapter());
  final wallets = await Hive.openBox('wallets');
  await wallets.put('currentWalletName', "");

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom]);
  await NotificationApi.init();

  runApp(MyApp());
}

/// MyApp initialises relevant services with a MultiProvider
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return KeyboardDismisser(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => Manager(),
          ),
          ChangeNotifierProvider(
            create: (_) => WalletsService(),
          ),
          ChangeNotifierProvider(
            create: (_) => AddressBookService(),
          ),
          ChangeNotifierProvider(
            create: (_) => NodeService(),
          ),
          ChangeNotifierProvider(
            create: (_) => NotesService(),
          ),
        ],
        child: MaterialAppWithTheme(),
      ),
    );
  }
}

// Sidenote: MaterialAppWithTheme and InitView are only separated for clarity. No other reason.

class MaterialAppWithTheme extends StatefulWidget {
  const MaterialAppWithTheme({
    Key key,
  }) : super(key: key);

  @override
  _MaterialAppWithThemeState createState() => _MaterialAppWithThemeState();
}

class _MaterialAppWithThemeState extends State<MaterialAppWithTheme> {
  @override
  void initState() {
    super.initState();
  }

  /// Returns true if the user has never set up any wallets before
  Future<bool> _checkForWallets() async {
    final wallets = await Hive.openBox('wallets');
    Logger.print("wallets: ${wallets.toMap()}");
    if (wallets.isEmpty || wallets.length == 1) {
      return true;
    } else {
      return false;
    }
  }

  OutlineInputBorder _buildOutlineInputBorder(Color color) {
    return OutlineInputBorder(
      borderSide: BorderSide(
        width: 1,
        color: color,
      ),
      borderRadius: BorderRadius.circular(SizingUtilities.circularBorderRadius),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campfire',
      onGenerateRoute: RouteGenerator.generateRoute,
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: GoogleFonts.workSans().fontFamily,
        textTheme: GoogleFonts.workSansTextTheme(),
        primaryColor: CFColors.spark,
        primarySwatch: CFColors.createMaterialColor(CFColors.spark),
        checkboxTheme: CheckboxThemeData(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(SizingUtilities.checkboxBorderRadius),
          ),
          checkColor: MaterialStateColor.resolveWith(
            (state) {
              if (state.contains(MaterialState.selected)) {
                return CFColors.white;
              }
              return CFColors.fog;
            },
          ),
          fillColor: MaterialStateColor.resolveWith(
            (states) {
              if (states.contains(MaterialState.selected)) {
                return CFColors.spark;
              }
              return CFColors.dew;
            },
          ),
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          color: CFColors.starryNight,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          fillColor: CFColors.fog,
          filled: true,
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          hintStyle: GoogleFonts.workSans(
            color: CFColors.twilight,
            fontWeight: FontWeight.w400,
            fontSize: 16,
          ),
          enabledBorder: _buildOutlineInputBorder(CFColors.twilight),
          focusedBorder: _buildOutlineInputBorder(CFColors.focusedBorder),
          errorBorder: _buildOutlineInputBorder(CFColors.errorBorder),
          disabledBorder: _buildOutlineInputBorder(CFColors.twilight),
          focusedErrorBorder: _buildOutlineInputBorder(CFColors.errorBorder),
        ),
      ),
      home: FutureBuilder(
        future: _checkForWallets(),
        builder: (BuildContext context,
            AsyncSnapshot<bool> shouldRouteToOnboarding) {
          if (shouldRouteToOnboarding.connectionState == ConnectionState.done) {
            if (shouldRouteToOnboarding.data) {
              return OnboardingView();
            } else {
              return WalletSelectionView();
            }
          } else {
            return LoadingView();
          }
        },
      ),
    );
  }
}
