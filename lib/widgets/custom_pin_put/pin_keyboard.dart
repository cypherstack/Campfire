import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/utilities/cfcolors.dart';

class NumberKey extends StatelessWidget {
  const NumberKey({
    Key key,
    @required this.number,
    this.onPressed,
  }) : super(key: key);

  final String number;
  final ValueSetter<String> onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: 56,
      decoration: ShapeDecoration(
        shape: StadiumBorder(),
        color: CFColors.fog,
        shadows: [
          BoxShadow(
            color: CFColors.shadowColor,
            spreadRadius: 0.5,
            blurRadius: 1,
            offset: Offset.fromDirection(1.5, 1),
          ),
        ],
      ),
      child: MaterialButton(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: StadiumBorder(),
        onPressed: () {
          onPressed?.call(number);
        },
        child: Container(
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.montserrat(
                color: CFColors.midnight,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BackspaceKey extends StatelessWidget {
  const BackspaceKey({
    Key key,
    this.onPressed,
  }) : super(key: key);

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: 56,
      decoration: ShapeDecoration(
        shape: StadiumBorder(),
        color: CFColors.fog,
        shadows: [
          BoxShadow(
            color: CFColors.shadowColor,
            spreadRadius: 0.5,
            blurRadius: 1,
            offset: Offset.fromDirection(1.5, 1),
          ),
        ],
      ),
      child: MaterialButton(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: StadiumBorder(),
        onPressed: () {
          onPressed?.call();
        },
        child: Container(
          child: Center(
            child: Icon(
              FeatherIcons.delete,
              color: CFColors.midnight,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class PinKeyboard extends StatelessWidget {
  const PinKeyboard({
    Key key,
    @required this.onNumberKeyPressed,
    @required this.onBackPressed,
    this.backgroundColor,
    this.width,
    this.height,
  }) : super(key: key);

  final ValueSetter<String> onNumberKeyPressed;
  final VoidCallback onBackPressed;
  final Color backgroundColor;
  final double width;
  final double height;

  void _backHandler() {
    onBackPressed.call();
  }

  void _numberHandler(String number) {
    onNumberKeyPressed.call(number);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: backgroundColor != null ? backgroundColor : Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              NumberKey(
                number: "1",
                onPressed: _numberHandler,
              ),
              NumberKey(
                number: "2",
                onPressed: _numberHandler,
              ),
              NumberKey(
                number: "3",
                onPressed: _numberHandler,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              NumberKey(
                number: "4",
                onPressed: _numberHandler,
              ),
              NumberKey(
                number: "5",
                onPressed: _numberHandler,
              ),
              NumberKey(
                number: "6",
                onPressed: _numberHandler,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              NumberKey(
                number: "7",
                onPressed: _numberHandler,
              ),
              NumberKey(
                number: "8",
                onPressed: _numberHandler,
              ),
              NumberKey(
                number: "9",
                onPressed: _numberHandler,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                height: 56,
                width: 56,
              ),
              NumberKey(
                number: "0",
                onPressed: _numberHandler,
              ),
              BackspaceKey(
                onPressed: _backHandler,
              )
            ],
          )
        ],
      ),
    );
  }
}
