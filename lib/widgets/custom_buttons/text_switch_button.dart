import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum TextSwitchButtonState {
  available,
  full,
}

class TextSwitchButton extends StatefulWidget {
  const TextSwitchButton({
    Key key,
    this.leftText,
    this.rightText,
    @required this.onButtonStateChanged,
    @required this.fontSize,
  }) : super(key: key);

  final String leftText;
  final String rightText;
  final Function(TextSwitchButtonState) onButtonStateChanged;
  final double fontSize;

  @override
  _TextSwitchButtonState createState() => _TextSwitchButtonState();
}

class _TextSwitchButtonState extends State<TextSwitchButton> {
  TextSwitchButtonState _state = TextSwitchButtonState.available;
  Color _leftColor = Colors.white;
  Color _rightColor = Colors.transparent;

  double _dx = 0.0;

  // TODO: dynamic sizing to handle larger text on button?
  // especially accessibility settings
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onHorizontalDragEnd: (details) {
            if (_dx < 0.0) {
              _state = TextSwitchButtonState.available;
              setState(() {
                _leftColor = Colors.white;
                _rightColor = Colors.transparent;
              });
            } else if (_dx > 0.0) {
              _state = TextSwitchButtonState.full;
              setState(() {
                _leftColor = Colors.transparent;
                _rightColor = Colors.white;
              });
            }
            _dx = 0.0;
          },
          onHorizontalDragUpdate: (details) {
            _dx = details.delta.dx;
          },
          onTap: () {
            _state = _state == TextSwitchButtonState.available
                ? TextSwitchButtonState.full
                : TextSwitchButtonState.available;

            setState(() {
              _leftColor = _state == TextSwitchButtonState.full
                  ? Colors.transparent
                  : Colors.white;
              _rightColor = _state == TextSwitchButtonState.available
                  ? Colors.transparent
                  : Colors.white;
            });

            widget.onButtonStateChanged(_state);
          },
          child: Container(
            height: constraints.maxHeight,
            width: constraints.maxWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(constraints.maxHeight / 2),
              color: Color(0xFFFFBABE),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  height: constraints.maxHeight - 4,
                  width: constraints.maxWidth / 2 - 4,
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(constraints.maxHeight / 2),
                    color: _leftColor,
                  ),
                  child: Center(
                    child: FittedBox(
                      child: Text(
                        "AVAILABLE",
                        style: GoogleFonts.workSans(
                          color: Color(0xFFF27889),
                          fontSize: widget.fontSize,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.25,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: constraints.maxHeight - 4,
                  width: constraints.maxWidth / 2 - 4,
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(constraints.maxHeight / 2),
                    color: _rightColor,
                  ),
                  child: Center(
                    child: Text(
                      "FULL",
                      style: GoogleFonts.workSans(
                        color: Color(0xFFF27889),
                        fontSize: widget.fontSize,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.normal,
                        letterSpacing: 0.25,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
