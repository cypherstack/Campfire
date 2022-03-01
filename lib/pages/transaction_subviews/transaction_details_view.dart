import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/models/models.dart';
import 'package:paymint/pages/settings_view/helpers/builders.dart';
import 'package:paymint/services/address_book_service.dart';
import 'package:paymint/services/notes_service.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/shared_utilities.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:provider/provider.dart';

class TransactionDetailsView extends StatefulWidget {
  const TransactionDetailsView({
    Key key,
    @required this.transaction,
    @required this.note,
  }) : super(key: key);

  final Transaction transaction;
  final note;

  @override
  _TransactionDetailsViewState createState() => _TransactionDetailsViewState();
}

class _TransactionDetailsViewState extends State<TransactionDetailsView> {
  Transaction _transaction;
  FocusNode _focusNode = FocusNode();

  final _noteController = TextEditingController();

  @override
  void initState() {
    this._transaction = widget.transaction;
    _noteController.text = widget.note;
    _focusNode.addListener(_onNoteFocusChanged);
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onNoteFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  _onNoteFocusChanged() {
    if (!_focusNode.hasFocus) {
      final notesService = Provider.of<NotesService>(context, listen: false);
      notesService.editOrAddNote(
          txid: _transaction.txid, note: _noteController.text);
    }
  }

  Color _txTypeColor() {
    if (_transaction.txType == "Received") {
      return CFColors.success;
    } else if (_transaction.txType == "Sent") {
      return CFColors.spark;
    } else {
      // Are there any other txTypes strings?
      // Maybe use enum for this
      // unknown edge cases
      return CFColors.warning;
    }
  }

  String _getTitle() {
    if (_transaction.txType == "Received") {
      if (_transaction.isMinting) {
        return "Minting (~10 min)";
      } else if (_transaction.confirmedStatus) {
        return "Received";
      } else {
        return "Receiving (~10 min)";
      }
    } else if (_transaction.txType == "Sent") {
      if (_transaction.confirmedStatus) {
        return "Sent";
      } else {
        return "Sending (~10 min)";
      }
    } else {
      // Are there any other txTypes strings?
      // Maybe use enum for this
      // unknown edge cases
      return "Unknown";
    }
  }

  get _labelStyle => GoogleFonts.workSans(
        color: CFColors.twilight,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      );
  get _contentStyle => GoogleFonts.workSans(
        color: CFColors.midnight,
        fontWeight: FontWeight.w400,
        fontSize: 14,
      );

  _buildSentToItem(BuildContext context) {
    final addressService =
        Provider.of<AddressBookService>(context, listen: false);
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            child: Text(
              "Sent to:",
              style: _labelStyle,
            ),
          ),
        ),
        SizedBox(
          height: 8,
        ),
        FutureBuilder(
          future: addressService.addressBookEntries,
          builder: (BuildContext context,
              AsyncSnapshot<Map<String, String>> snapshot) {
            String text = _transaction.address;

            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.data[_transaction.address] != null) {
                text = snapshot.data[_transaction.address];
              }
            }

            return Align(
              alignment: Alignment.centerLeft,
              child: SelectableText(
                text,
                style: _contentStyle,
              ),
            );
          },
        )
      ],
    );
  }

  _buildSeparator() {
    return SizedBox(
      height: 25,
      child: Center(
        child: Container(
          color: CFColors.fog,
          height: 1,
          width: double.infinity,
        ),
      ),
    );
  }

  _buildItem(String label, String content, int lines) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            child: Text(
              label,
              style: _labelStyle,
            ),
          ),
        ),
        SizedBox(
          height: 8,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: SelectableText(
            content,
            style: _contentStyle,
            maxLines: lines,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CFColors.white,
      appBar: buildSettingsAppBar(
        context,
        "Transaction Details",
      ),
      body: Container(
        color: CFColors.white,
        height: SizingUtilities.getBodyHeight(context),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SizingUtilities.standardPadding,
          ),
          child: Column(
            // crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 10,
              ),
              Container(
                height: SizingUtilities.standardButtonHeight,
                decoration: BoxDecoration(
                  color: CFColors.fog,
                  borderRadius: BorderRadius.circular(
                      SizingUtilities.circularBorderRadius),
                ),
                child: Center(
                  child: FittedBox(
                    child: Text(
                      _getTitle(),
                      style: GoogleFonts.workSans(
                        color: _txTypeColor(),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: SizingUtilities.standardPadding,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildNoteItem(context),
                      if (_transaction.txType == "Sent")
                        _buildSentToItem(context),
                      if (_transaction.txType == "Sent") _buildSeparator(),
                      if (_transaction.txType == "Received")
                        _buildItem(
                          "Received on:",
                          _transaction.address,
                          1,
                        ),
                      if (_transaction.txType == "Received") _buildSeparator(),
                      _buildItem(
                        "Amount:",
                        // _transaction.confirmedStatus
                        // ?
                        Utilities.satoshiAmountToPrettyString(
                            _transaction.amount),
                        // : "Pending",
                        1,
                      ),
                      _buildSeparator(),
                      _buildItem(
                          "Fee:",
                          _transaction.confirmedStatus
                              ? Utilities.satoshiAmountToPrettyString(
                                  _transaction.fees)
                              : "Pending",
                          1),
                      _buildSeparator(),
                      _buildItem(
                        "Date:",
                        Utilities.extractDateFrom(_transaction.timestamp),
                        1,
                      ),
                      _buildSeparator(),
                      _buildItem(
                        "Transaction ID:",
                        _transaction.txid,
                        2,
                      ),
                      _buildSeparator(),
                      _buildItem(
                        "Block Height:",
                        _transaction.confirmedStatus
                            ? _transaction.height.toString()
                            : "Pending",
                        1,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: SizingUtilities.standardPadding,
              ),
            ],
          ),
        ),
      ),
    );
  }

  _buildNoteItem(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            child: Text(
              "Note:",
              style: _labelStyle,
            ),
          ),
        ),
        TextField(
          focusNode: _focusNode,
          controller: _noteController,
          style: _contentStyle,
          decoration: InputDecoration(
            hintText: "Type something...",
            hintStyle: GoogleFonts.workSans(
              color: CFColors.dew,
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
            contentPadding: EdgeInsets.all(0),
            fillColor: Colors.transparent,
            border: InputBorder.none,
            focusColor: CFColors.fog,
            disabledBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
          ),
        ),
        SizedBox(
          height: 5,
          child: Center(
            child: Container(
              color: CFColors.fog,
              height: 1,
              width: double.infinity,
            ),
          ),
        ),
        SizedBox(
          height: 8,
        ),
      ],
    );
  }
}
