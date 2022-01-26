import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/notifications/campfire_alert.dart';
import 'package:paymint/notifications/modal_popup_dialog.dart';
import 'package:paymint/notifications/overlay_notification.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/services/notes_service.dart';
import 'package:paymint/utilities/biometrics.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/logger.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/widgets/custom_pin_put/custom_pin_put.dart';
import 'package:provider/provider.dart';

class ConfirmSendView extends StatefulWidget {
  const ConfirmSendView({
    Key key,
    @required this.address,
    @required this.note,
    @required this.amount,
    @required this.fee,
  }) : super(key: key);

  final String address;
  final String note;
  final double amount;
  final double fee;

  @override
  _ConfirmSendViewState createState() => _ConfirmSendViewState();
}

class _ConfirmSendViewState extends State<ConfirmSendView> {
  _checkUseBiometrics() async {
    final manager = Provider.of<Manager>(context, listen: false);

    if (await manager.useBiometrics &&
        await Biometrics.authenticate(
          cancelButtonText: "CANCEL",
          localizedReason: "Confirm transaction",
          title: manager.walletName,
        )) {
      Navigator.pushReplacementNamed(context, '/mainview');
    }
  }

  @override
  void initState() {
    _checkUseBiometrics();
    super.initState();
  }

  BoxDecoration get _pinPutDecoration {
    return BoxDecoration(
      color: CFColors.fog,
      border: Border.all(width: 1, color: CFColors.smoke),
      borderRadius: BorderRadius.circular(6),
    );
  }

  final _pinTextController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    // final WalletsService walletsService = Provider.of<WalletsService>(context);

    return Container(
      height: MediaQuery.of(context).size.height,
      color: CFColors.midnight.withOpacity(0.8),
      child: Column(
        children: [
          // Spacer(),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          ),
          Material(
            color: CFColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft:
                    Radius.circular(SizingUtilities.circularBorderRadius * 2),
                topRight:
                    Radius.circular(SizingUtilities.circularBorderRadius * 2),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 43,
                ),
                Center(
                  child: FittedBox(
                    child: Text(
                      "Confirm transaction",
                      style: GoogleFonts.workSans(
                        color: CFColors.spark,
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                Center(
                  child: FittedBox(
                    child: Text(
                      "Enter PIN",
                      style: GoogleFonts.workSans(
                        color: CFColors.dusk,
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        letterSpacing: 0.25,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 28,
                ),
                CustomPinPut(
                  fieldsCount: 4,
                  eachFieldHeight: 12,
                  eachFieldWidth: 12,
                  textStyle: GoogleFonts.workSans(
                    fontSize: 1,
                  ),
                  focusNode: _pinFocusNode,
                  controller: _pinTextController,
                  useNativeKeyboard: false,
                  obscureText: "",
                  inputDecoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    fillColor: CFColors.white,
                    counterText: "",
                  ),
                  submittedFieldDecoration: _pinPutDecoration.copyWith(
                    color: CFColors.spark,
                    border: Border.all(width: 1, color: CFColors.spark),
                  ),
                  selectedFieldDecoration: _pinPutDecoration,
                  followingFieldDecoration: _pinPutDecoration,
                  onSubmit: (String pin) async {
                    final manager =
                        Provider.of<Manager>(context, listen: false);

                    final store = new FlutterSecureStorage();
                    final storedPin =
                        await store.read(key: '${manager.walletId}_pin');

                    if (storedPin == pin) {
                      // show sending dialog
                      showDialog(
                        useSafeArea: false,
                        barrierDismissible: false,
                        context: context,
                        builder: (_) => _buildSendingDialog(),
                      );

                      print("widget.amount: ${widget.amount}");
                      print("widget.address: ${widget.address}");

                      try {
                        final String txid = await manager.send(
                            toAddress: widget.address, amount: widget.amount);

                        final notesService = Provider.of<NotesService>(
                          context,
                          listen: false,
                        );
                        notesService.addNote(txid: txid, note: widget.note);
                        OverlayNotification.showSuccess(
                          context,
                          "Transaction sent",
                          Duration(milliseconds: 2700),
                        );
                        await Future.delayed(Duration(milliseconds: 100))
                            .then((value) {
                          manager.refresh();
                          final navigator = Navigator.of(context);
                          navigator.pop();
                          navigator.pop();
                        });
                      } catch (e) {
                        Logger.print(e);
                        showDialog(
                          useSafeArea: false,
                          barrierDismissible: false,
                          context: context,
                          builder: (_) => CampfireAlert(message: e.toString()),
                        ).then((value) {
                          final navigator = Navigator.of(context);
                          navigator.pop();
                          navigator.pop();
                        });
                        OverlayNotification.showError(
                          context,
                          "Transaction failed.",
                          Duration(milliseconds: 2000),
                        );
                      }

                      // Navigator.pop(context);
                    } else {
                      OverlayNotification.showError(
                        context,
                        "Incorrect PIN. Transaction cancelled.",
                        Duration(milliseconds: 1500),
                      );

                      await Future.delayed(Duration(milliseconds: 500));
                      _pinTextController.text = '';
                    }
                  },
                ),
                SizedBox(
                  height: 74,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _buildSendingDialog() {
    return ModalPopupDialog(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 28,
              left: 24,
              right: 24,
              bottom: 12,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: Text(
                "Sending transaction...",
                style: GoogleFonts.workSans(
                  color: CFColors.dusk,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          SizedBox(
            height: SizingUtilities.standardPadding,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(SizingUtilities.standardPadding),
              child: Container(
                width: 98,
                height: 98,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(49),
                  border: Border.all(
                    color: CFColors.dew,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Container(
                    height: 40,
                    width: 40,
                    child: CircularProgressIndicator(
                      color: CFColors.spark,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 50,
          )
        ],
      ),
    );
  }
}
