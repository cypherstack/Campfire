import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/models/transactions_model.dart';
import 'package:paymint/notifications/modal_popup_dialog.dart';
import 'package:paymint/notifications/overlay_notification.dart';
import 'package:paymint/pages/address_book_view/subviews/edit_address_book_entry_view.dart';
import 'package:paymint/services/address_book_service.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/clipboard_interface.dart';
import 'package:paymint/utilities/logger.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:paymint/widgets/custom_buttons/simple_button.dart';
import 'package:paymint/widgets/transaction_card.dart';
import 'package:provider/provider.dart';

import '../../main_view.dart';

class AddressBookEntryDetailsView extends StatefulWidget {
  const AddressBookEntryDetailsView({
    Key key,
    @required this.name,
    @required this.address,
    this.clipboard = const ClipboardWrapper(),
  }) : super(key: key);

  final String name, address;
  final ClipboardInterface clipboard;

  @override
  _AddressBookEntryDetailsViewState createState() =>
      _AddressBookEntryDetailsViewState();
}

class _AddressBookEntryDetailsViewState
    extends State<AddressBookEntryDetailsView> {
  final _addressTextEditingController = TextEditingController();

  String _name, _address;

  final TextStyle _titleStyle = GoogleFonts.workSans(
    color: CFColors.dusk,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  AddressBookService addressBookService;
  ClipboardInterface clipboard;

  @override
  initState() {
    addressBookService =
        Provider.of<AddressBookService>(context, listen: false);
    clipboard = widget.clipboard;
    _name = widget.name;
    _address = widget.address;
    _addressTextEditingController.text = _address;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<Manager>(context);

    return Scaffold(
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Container(
          color: CFColors.white,
          height: SizingUtilities.getBodyHeight(context),
          child: Padding(
            padding: const EdgeInsets.only(
              top: 10,
              left: SizingUtilities.standardPadding,
              right: SizingUtilities.standardPadding,
              bottom: SizingUtilities.standardPadding,
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Address",
                    style: GoogleFonts.workSans(
                      color: CFColors.twilight,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(
                  height: 8,
                ),
                TextField(
                  readOnly: true,
                  controller: _addressTextEditingController,
                  decoration: InputDecoration(
                      suffixIcon: UnconstrainedBox(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Row(
                        children: [
                          GestureDetector(
                            key: Key(
                                "addressBookEntryDetailsCopyAddressButtonKey"),
                            child: SvgPicture.asset(
                              "assets/svg/copy-2.svg",
                              color: CFColors.twilight,
                              height: 20,
                              width: 20,
                            ),
                            onTap: () {
                              clipboard.setData(ClipboardData(
                                  text: _addressTextEditingController.text));
                              OverlayNotification.showInfo(
                                context,
                                "Address copied to clipboard",
                                Duration(seconds: 2),
                              );
                            },
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          GestureDetector(
                            key: Key(
                                "addressBookEntryDetailsEditEntryButtonKey"),
                            child: SvgPicture.asset(
                              "assets/svg/edit-4.svg",
                              color: CFColors.twilight,
                              height: 20,
                              width: 20,
                            ),
                            onTap: () {
                              Logger.print("edit address tapped");
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) {
                                    return EditAddressBookEntryView(
                                        name: _name, address: _address);
                                  },
                                ),
                              );
                            },
                          )
                        ],
                      ),
                    ),
                  )),
                ),
                SizedBox(
                  height: 8,
                ),
                _buildSendButton(context),
                SizedBox(
                  height: 40,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Transaction History",
                    style: GoogleFonts.workSans(
                      color: CFColors.twilight,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(
                  height: 14,
                ),
                Expanded(
                  child: FutureBuilder(
                    future: manager.transactionData,
                    builder:
                        (context, AsyncSnapshot<TransactionData> snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (!snapshot.hasError) {
                          final txData = snapshot.data;
                          if (txData == null || txData.txChunks.length == 0) {
                            return _buildNoTransactionsFound();
                          }

                          final results = txData.txChunks
                              .expand((element) => element.transactions)
                              .toList();

                          results.removeWhere(
                              (tx) => tx.address != widget.address);

                          if (results.length == 0) {
                            return _buildNoTransactionsFound();
                          } else {
                            return ListView.builder(
                              itemCount: results.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: EdgeInsets.all(
                                    SizingUtilities.listItemSpacing / 2,
                                  ),
                                  child: TransactionCard(
                                    transaction: results[index],
                                  ),
                                );
                              },
                            );
                          }
                        }
                      }
                      return Center(
                        child: SpinKitThreeBounce(
                          color: CFColors.spark,
                          size: MediaQuery.of(context).size.width * 0.1,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: SizingUtilities.standardPadding,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  _buildNoTransactionsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Spacer(
            flex: 1,
          ),
          SvgPicture.asset(
            "assets/svg/empty-tx-list.svg",
            width: MediaQuery.of(context).size.width * 0.52,
          ),
          SizedBox(
            height: 8,
          ),
          Text(
            "NO TRANSACTIONS FOUND",
            style: GoogleFonts.workSans(
              color: CFColors.dew,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.25,
            ),
          ),
          Spacer(
            flex: 2,
          ),
        ],
      ),
    );
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: CFColors.white,
      title: Text(
        _name,
        style: _titleStyle,
      ),
      leadingWidth: 36.0 + 20.0,
      // account for 20 padding

      leading: Padding(
        padding: EdgeInsets.only(
          top: 10,
          bottom: 10,
          left: 20,
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: AppBarIconButton(
            key: Key("addressBookDetailsBackButtonKey"),
            size: 36,
            onPressed: () async {
              FocusScope.of(context).unfocus();
              await Future.delayed(Duration(milliseconds: 50));

              Navigator.pop(context);
            },
            circularBorderRadius: 8,
            icon: SvgPicture.asset(
              "assets/svg/chevronLeft.svg",
              color: CFColors.twilight,
              width: 24,
              height: 24,
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(
            top: 10,
            bottom: 10,
            right: 20,
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: AppBarIconButton(
              key: Key("addressBookDetailsDeleteButtonKey"),
              size: 36,
              icon: SvgPicture.asset(
                "assets/svg/more-vertical.svg",
                color: CFColors.twilight,
                width: 24,
                height: 24,
              ),
              circularBorderRadius: 8,
              onPressed: () async {
                FocusScope.of(context).unfocus();
                await Future.delayed(Duration(milliseconds: 50));

                showDialog(
                  barrierColor: Colors.transparent,
                  context: context,
                  builder: (context) {
                    return _buildPopupMenu(context);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  _buildPopupMenu(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: SizingUtilities.getStatusBarHeight(context) + 9,
          right: SizingUtilities.standardPadding,
          child: Container(
            decoration: BoxDecoration(
              color: CFColors.white,
              borderRadius:
                  BorderRadius.circular(SizingUtilities.circularBorderRadius),
              boxShadow: [CFColors.standardBoxShadow],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  key: Key("addressBookDetailsContextMenuDeleteButtonKey"),
                  onTap: () async {
                    showDialog(
                      useSafeArea: false,
                      barrierColor: Colors.transparent,
                      barrierDismissible: false,
                      context: context,
                      builder: (context) => DeleteContactConfirmationDialog(
                        address: widget.address,
                        name: widget.name,
                        addressBookService: addressBookService,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 10,
                      left: 12,
                      right: 12,
                      bottom: 10,
                    ),
                    child: Text(
                      "Delete address",
                      style: GoogleFonts.workSans(
                        decoration: TextDecoration.none,
                        color: CFColors.midnight,
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  _buildSendButton(BuildContext context) {
    return SizedBox(
      height: SizingUtilities.standardButtonHeight,
      width: MediaQuery.of(context).size.width -
          (SizingUtilities.standardPadding * 2),
      child: GradientButton(
        child: FittedBox(
          child: Text(
            "SEND",
            style: CFTextStyles.button,
          ),
        ),
        onTap: () {
          Logger.print("SEND button pressed");
          Navigator.pushAndRemoveUntil(
            context,
            CupertinoPageRoute(
              builder: (context) {
                return MainView(
                  pageIndex: 0, // 0 for send page index
                  args: {
                    "addressBookEntry": {
                      "name": _name,
                      "address": _address,
                    },
                  },
                  disableRefreshOnInit: true,
                );
              },
              settings: RouteSettings(name: "/mainview"),
            ),
            ModalRoute.withName("/"),
          );
        },
      ),
    );
  }
}

class DeleteContactConfirmationDialog extends StatelessWidget {
  const DeleteContactConfirmationDialog({
    Key key,
    @required this.address,
    @required this.name,
    @required this.addressBookService,
  }) : super(key: key);

  final String address;
  final String name;
  final AddressBookService addressBookService;

  @override
  Widget build(BuildContext context) {
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
            child: Text(
              "Do you want to delete $name?",
              style: GoogleFonts.workSans(
                color: CFColors.dusk,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(SizingUtilities.standardPadding),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: SizingUtilities.standardButtonHeight,
                    child: SimpleButton(
                      key:
                          Key("deleteContactConfirmationDialogCancelButtonKey"),
                      child: FittedBox(
                        child: Text(
                          "CANCEL",
                          style: CFTextStyles.button.copyWith(
                            color: CFColors.dusk,
                          ),
                        ),
                      ),
                      onTap: () {
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        navigator.pop();
                      },
                    ),
                  ),
                ),
                SizedBox(
                  width: 16,
                ),
                Expanded(
                  child: SizedBox(
                    height: SizingUtilities.standardButtonHeight,
                    child: GradientButton(
                      key:
                          Key("deleteContactConfirmationDialogDeleteButtonKey"),
                      child: FittedBox(
                        child: Text(
                          "DELETE",
                          style: CFTextStyles.button,
                        ),
                      ),
                      onTap: () async {
                        await addressBookService
                            .removeAddressBookEntry(address);
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        navigator.pop();
                        navigator.pop();
                      },
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
