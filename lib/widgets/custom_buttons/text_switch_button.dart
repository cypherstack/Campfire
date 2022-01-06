import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum TextSwitchButtonState {
  available,
  full,
}

class TextSwitchButton extends StatefulWidget {
  const TextSwitchButton(
      {Key key, this.leftText, this.rightText, @required this.buttonStateChanged})
      : super(key: key);

  final String leftText;
  final String rightText;
  final Function(TextSwitchButtonState) buttonStateChanged;

  @override
  _TextSwitchButtonState createState() => _TextSwitchButtonState();
}

class _TextSwitchButtonState extends State<TextSwitchButton> {
  TextSwitchButtonState _state = TextSwitchButtonState.available;
  Color _leftColor = Colors.white;
  Color _rightColor = Colors.transparent;

  // TODO: dynamic sizing to handle larger text on button?
  // especially accessibility settings
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: constraints.maxHeight,
          width: constraints.maxWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(constraints.maxHeight / 2),
            color: Color(0xFFFFBABE),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () {
                  if (_state == TextSwitchButtonState.available) {
                    return;
                  }
                  setState(() {
                    _leftColor = Colors.white;
                    _rightColor = Colors.transparent;
                    _state = TextSwitchButtonState.available;
                  });
                  widget.buttonStateChanged(_state);
                },
                child: Container(
                  height: constraints.maxHeight - 4,
                  width: constraints.maxWidth / 2 - 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(constraints.maxHeight / 2),
                    color: _leftColor,
                  ),
                  child: Center(
                    child: FittedBox(
                      child: Text(
                        "AVAILABLE",
                        style: GoogleFonts.workSans(
                          color: Color(0xFFF27889),
                          fontSize: 8, // ScalingUtils.fontScaled(context, 8),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.25,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (_state == TextSwitchButtonState.full) {
                    return;
                  }
                  setState(() {
                    _leftColor = Colors.transparent;
                    _rightColor = Colors.white;
                    _state = TextSwitchButtonState.full;
                  });
                  widget.buttonStateChanged(_state);
                },
                child: Container(
                  height: constraints.maxHeight - 4,
                  width: constraints.maxWidth / 2 - 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(constraints.maxHeight / 2),
                    color: _rightColor,
                  ),
                  child: Center(
                    child: Text(
                      "FULL",
                      style: GoogleFonts.workSans(
                        color: Color(0xFFF27889),
                        fontSize: 8, // ScalingUtils.fontScaled(context, 8),
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.normal,
                        letterSpacing: 0.25,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
