import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/pages/settings_view/helpers/builders.dart';
import 'package:paymint/pages/transaction_subviews/transaction_search_results_view.dart';
import 'package:paymint/services/address_book_service.dart';
import 'package:paymint/services/notes_service.dart';
import 'package:paymint/services/utils/currency_utils.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/shared_utilities.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:paymint/widgets/custom_buttons/simple_button.dart';
import 'package:provider/provider.dart';

class TransactionSearchView extends StatefulWidget {
  const TransactionSearchView({Key key}) : super(key: key);

  @override
  _TransactionSearchViewState createState() => _TransactionSearchViewState();
}

class _TransactionSearchViewState extends State<TransactionSearchView> {
  final _amountTextEditingController = TextEditingController();
  final _keywordTextEditingController = TextEditingController();

  final _labelStyle = GoogleFonts.workSans(
    color: CFColors.twilight,
    fontWeight: FontWeight.w500,
    fontSize: 12,
  );

  bool _isActiveReceivedCheckbox = false;
  bool _isActiveSentCheckbox = false;

  String _fromDateString = "";
  String _toDateString = "";

  // The following two getters are not required if the
  // date fields are to remain unclearable.
  get _dateFromText {
    final isDateSelected = _fromDateString.isEmpty;
    return Text(
      isDateSelected ? "from..." : _fromDateString,
      style: GoogleFonts.workSans(
        color: isDateSelected ? CFColors.twilight : CFColors.dusk,
        fontWeight: FontWeight.w400,
        fontSize: 16,
      ),
    );
  }

  get _dateToText {
    final isDateSelected = _toDateString.isEmpty;
    return Text(
      isDateSelected ? "to..." : _toDateString,
      style: GoogleFonts.workSans(
        color: isDateSelected ? CFColors.twilight : CFColors.dusk,
        fontWeight: FontWeight.w400,
        fontSize: 16,
      ),
    );
  }

  var _selectedFromDate = DateTime(2007);
  var _selectedToDate = DateTime.now();
  bool _dateSelected = false;

  final _datePickerTextStyleBase = GoogleFonts.workSans(
    color: CFColors.dusk,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
  );

  _buildDatePickerStyle() {
    return MaterialRoundedDatePickerStyle(
      paddingMonthHeader: EdgeInsets.only(top: 11),
      colorArrowNext: CFColors.twilight,
      colorArrowPrevious: CFColors.twilight,
      textStyleButtonNegative: _datePickerTextStyleBase.copyWith(
          fontSize: 16, fontWeight: FontWeight.w600),
      textStyleButtonPositive: _datePickerTextStyleBase.copyWith(
          fontSize: 16, fontWeight: FontWeight.w600),
      textStyleCurrentDayOnCalendar: _datePickerTextStyleBase.copyWith(
        color: CFColors.spark,
      ),
      textStyleDayHeader: _datePickerTextStyleBase.copyWith(
        color: CFColors.starryNight,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      textStyleDayOnCalendar: _datePickerTextStyleBase,
      textStyleDayOnCalendarDisabled: _datePickerTextStyleBase.copyWith(
        color: CFColors.dew,
      ),
      textStyleDayOnCalendarSelected: _datePickerTextStyleBase.copyWith(
        color: CFColors.white,
      ),
      textStyleMonthYearHeader: _datePickerTextStyleBase.copyWith(
        color: CFColors.twilight,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      textStyleYearButton: _datePickerTextStyleBase.copyWith(
        color: CFColors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      textStyleButtonAction: GoogleFonts.workSans(),
    );
  }

  _buildYearPickerStyle() {
    return MaterialRoundedYearPickerStyle(
      textStyleYear: _datePickerTextStyleBase.copyWith(
        color: CFColors.dusk,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      textStyleYearSelected: _datePickerTextStyleBase.copyWith(
        color: CFColors.spark,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
    );
  }

  _buildDateRangePicker() {
    final middleSeparatorPadding = 2.0;
    final middleSeparatorWidth = 12.0;
    final width = (MediaQuery.of(context).size.width -
            (middleSeparatorWidth +
                (2 * middleSeparatorPadding) +
                (2 * SizingUtilities.standardPadding))) /
        2;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          // TODO custom date picker
          onTap: () async {
            final date = await showRoundedDatePicker(
              // This doesn't change statusbar color...
              // background: CFColors.starryNight.withOpacity(0.8),
              context: context,
              initialDate: DateTime.now(),
              height: MediaQuery.of(context).size.height * 0.5,
              theme: ThemeData(
                primarySwatch: CFColors.createMaterialColor(CFColors.spark),
              ),
              //TODO pick a better initial date
              // 2007 chosen as that is just before bitcoin launched
              firstDate: DateTime(2007),
              lastDate: DateTime.now(),
              borderRadius: SizingUtilities.circularBorderRadius * 2,

              textPositiveButton: "SELECT",

              styleDatePicker: _buildDatePickerStyle(),
              styleYearPicker: _buildYearPickerStyle(),
            );
            if (date != null && date != _selectedFromDate) {
              _selectedFromDate = date;

              // flag for search
              _dateSelected = true;

              // flag to adjust date so from date is always before to date
              final flag = !_selectedFromDate.isBefore(_selectedToDate);
              if (flag) {
                _selectedToDate = DateTime.fromMillisecondsSinceEpoch(
                    _selectedFromDate.millisecondsSinceEpoch);
              }

              setState(() {
                if (flag) {
                  _toDateString = Utilities.formatDate(_selectedToDate);
                }
                _fromDateString = Utilities.formatDate(_selectedFromDate);
              });
            }
          },
          child: Container(
            width: width,
            decoration: BoxDecoration(
              color: CFColors.fog,
              borderRadius:
                  BorderRadius.circular(SizingUtilities.circularBorderRadius),
              border: Border.all(
                color: CFColors.smoke,
                width: 1,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  SvgPicture.asset(
                    "assets/svg/calendar.svg",
                    height: 20,
                    width: 20,
                    color: CFColors.twilight,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      child: _dateFromText,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: middleSeparatorPadding),
          child: Container(
            width: middleSeparatorWidth,
            height: 1,
            color: CFColors.smoke,
          ),
        ),
        GestureDetector(
          onTap: () async {
            final date = await showRoundedDatePicker(
              // This doesn't change statusbar color...
              // background: CFColors.starryNight.withOpacity(0.8),
              context: context,
              height: MediaQuery.of(context).size.height * 0.5,
              theme: ThemeData(
                primarySwatch: CFColors.createMaterialColor(CFColors.spark),
              ),
              //TODO pick a better initial date
              // 2007 chosen as that is just before bitcoin launched
              initialDate: DateTime.now(),
              firstDate: DateTime(2007),
              lastDate: DateTime.now(),
              borderRadius: SizingUtilities.circularBorderRadius * 2,

              textPositiveButton: "SELECT",

              styleDatePicker: _buildDatePickerStyle(),
              styleYearPicker: _buildYearPickerStyle(),
            );
            if (date != null && date != _selectedFromDate) {
              _selectedToDate = date;

              // flag for search
              _dateSelected = true;

              // flag to adjust date so from date is always before to date
              final flag = !_selectedToDate.isAfter(_selectedFromDate);
              if (flag) {
                _selectedFromDate = DateTime.fromMillisecondsSinceEpoch(
                    _selectedToDate.millisecondsSinceEpoch);
              }

              setState(() {
                if (flag) {
                  _fromDateString = Utilities.formatDate(_selectedFromDate);
                }
                _toDateString = Utilities.formatDate(_selectedToDate);
              });
            }
          },
          child: Container(
            width: width,
            decoration: BoxDecoration(
              color: CFColors.fog,
              borderRadius:
                  BorderRadius.circular(SizingUtilities.circularBorderRadius),
              border: Border.all(
                color: CFColors.smoke,
                width: 1,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  SvgPicture.asset(
                    "assets/svg/calendar.svg",
                    height: 20,
                    width: 20,
                    color: CFColors.twilight,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      child: _dateToText,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildSettingsAppBar(
        context,
        "Transaction Search",
        disableBackButton: true,
        rightButton: Padding(
          padding: EdgeInsets.only(
            top: 10,
            bottom: 10,
            right: 20,
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: AppBarIconButton(
              size: 36,
              icon: SvgPicture.asset(
                "assets/svg/x.svg",
                color: CFColors.twilight,
                width: 24,
                height: 24,
              ),
              circularBorderRadius: 8,
              onPressed: () async {
                FocusScope.of(context).unfocus();
                await Future.delayed(Duration(milliseconds: 50));
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SizingUtilities.standardPadding,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 10,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          child: Text(
                            "Transactions",
                            style: _labelStyle,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      Row(
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: Checkbox(
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              value: _isActiveReceivedCheckbox,
                              onChanged: (newValue) {
                                setState(() {
                                  _isActiveReceivedCheckbox = newValue;
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            width: 14,
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FittedBox(
                              child: Text(
                                "Received",
                                style: GoogleFonts.workSans(
                                  color: CFColors.dusk,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      Row(
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: Checkbox(
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              value: _isActiveSentCheckbox,
                              onChanged: (newValue) {
                                setState(() {
                                  _isActiveSentCheckbox = newValue;
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            width: 14,
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FittedBox(
                              child: Text(
                                "Sent",
                                style: GoogleFonts.workSans(
                                  color: CFColors.dusk,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                      SizedBox(
                        height: 24,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          child: Text(
                            "Date",
                            style: _labelStyle,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      _buildDateRangePicker(),
                      SizedBox(
                        height: 24,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          child: Text(
                            "Amount (${CurrencyUtilities.coinName})",
                            style: _labelStyle,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      TextField(
                        controller: _amountTextEditingController,
                      ),
                      SizedBox(
                        height: 24,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          child: Text(
                            "Keyword",
                            style: _labelStyle,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      TextField(
                        controller: _keywordTextEditingController,
                      ),
                      Spacer(),
                      SizedBox(
                        height: 20,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: SimpleButton(
                                  onTap: () async {
                                    FocusScope.of(context).unfocus();
                                    await Future.delayed(
                                        Duration(milliseconds: 50));
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    "Cancel",
                                    style: CFTextStyles.button.copyWith(
                                      color: CFColors.dusk,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 16,
                            ),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: GradientButton(
                                  child: Text(
                                    "Apply",
                                    style: CFTextStyles.button,
                                  ),
                                  onTap: () {
                                    _onApplyPressed();
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  _onApplyPressed() async {
    final notesService = Provider.of<NotesService>(context, listen: false);
    final addressBookService =
        Provider.of<AddressBookService>(context, listen: false);
    final notes = await notesService.notes;
    final contacts = await addressBookService.addressBookEntries;
    Navigator.push(context, CupertinoPageRoute(builder: (_) {
      return TransactionSearchResultsView(
        start: _dateSelected ? _selectedFromDate : null,
        end: _dateSelected ? _selectedToDate : null,
        sent: _isActiveSentCheckbox,
        received: _isActiveReceivedCheckbox,
        amount: double.tryParse(_amountTextEditingController.text),
        keyword: _keywordTextEditingController.text,
        notes: notes,
        contacts: contacts,
      );
    }));
  }
}
