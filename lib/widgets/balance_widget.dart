// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:paymint/models/models.dart';
// import 'package:paymint/services/bitcoin_service.dart';
// import 'package:paymint/services/utils/cfcolors.dart';
// import 'package:paymint/services/utils/currency_utils.dart';
// import 'package:paymint/services/utils/sizing_utilities.dart';
// import 'package:paymint/widgets/gradient_card.dart';
// import 'package:paymint/widgets/text_switch_button.dart';
// import 'package:provider/provider.dart';
//
// class BalanceView extends StatefulWidget {
//   const BalanceView({Key key}) : super(key: key);
//
//   @override
//   _BalanceViewState createState() => _BalanceViewState();
// }
//
// class _BalanceViewState extends State<BalanceView> {
//   @override
//   Widget build(BuildContext context) {
//     final BitcoinService bitcoinService = Provider.of<BitcoinService>(context);
//
//     // _showOverlay(context, bitcoinService);
//
//     return GradientCard(
//       circularBorderRadius: ScalingUtils.circularBorderRadius,
//       gradient: CFColors.fireGradientVerticalLight,
//       child: Stack(
//         children: [
//           FutureBuilder(
//             future: bitcoinService.utxoData,
//             builder: (BuildContext context, AsyncSnapshot<UtxoData> utxoData) {
//               if (utxoData.connectionState == ConnectionState.done) {
//                 if (utxoData == null || utxoData.hasError) {
//                   return _buildBalance(
//                     balance: "...",
//                     fiatBalance: "...",
//                   );
//                   // return Container(
//                   //   child: Center(
//                   //     child: Text(
//                   //       // TODO: implement could not connect overlay
//                   //       'Unable to fetch balance data.\nPlease check connection',
//                   //       style: TextStyle(color: Colors.blue),
//                   //     ),
//                   //   ),
//                   // );
//                 }
//
//                 return _buildBalance(
//                   fiatBalance: utxoData.data.totalUserCurrency,
//                   balance: utxoData.data.bitcoinBalance.toString(),
//                 );
//               } else {
//                 // TODO: Implement synchronising progress at top of safe area
//                 // return buildBalanceInformationLoadingWidget();
//
//                 return _buildBalance(
//                   balance: "...",
//                   fiatBalance: "...",
//                 );
//               }
//             },
//           ),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.end,
//             children: [
//               Opacity(
//                 opacity: 0.5,
//                 child: SvgPicture.asset(
//                   "assets/svg/groupLogo.svg",
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// Widget _buildBalance({String fiatBalance, String balance}) {
//   return Padding(
//     padding: const EdgeInsets.all(20.0),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           height: 18,
//           width: 126,
//           child: TextSwitchButton(
//             buttonStateChanged: (state) {
//               print("balance switch button changed to: $state");
//             },
//           ),
//         ),
//         SizedBox(
//           height: 14,
//         ),
//         FittedBox(
//           child: Text(
//             "$balance ${CurrencyUtilities.coinName}",
//             style: GoogleFonts.workSans(
//               color: CFColors.white,
//               fontSize: 28, // ScalingUtils.fontScaled(context, 28),
//               fontWeight: FontWeight.w600,
//               letterSpacing: -0.5,
//             ),
//           ),
//         ),
//         SizedBox(
//           height: 5,
//         ),
//         FittedBox(
//           child: Text(
//             fiatBalance,
//             style: GoogleFonts.workSans(
//               color: CFColors.white,
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//       ],
//     ),
//   );
// }
//
