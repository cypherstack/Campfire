import 'package:flutter/material.dart';
import 'package:paymint/utilities/cfcolors.dart';

class SimpleButton extends StatelessWidget {
  const SimpleButton({
    Key key,
    @required this.onTap,
    @required this.child,
    this.color,
    this.shadows,
    this.enabled = true,
  }) : super(key: key);

  final VoidCallback onTap;
  final Widget child;
  final Color color;
  final List<BoxShadow> shadows;
  final bool enabled;

  final _shape = const StadiumBorder();

  List<BoxShadow> get _shadows => shadows == null
      ? [
          BoxShadow(
            color: CFColors.shadowColor,
            spreadRadius: 0.1,
            blurRadius: 1.5,
          )
        ]
      : shadows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: color == null ? CFColors.white : color,
        shape: _shape,
        shadows: _shadows,
      ),
      child: (enabled)
          ? MaterialButton(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: _shape,
              child: child,
              onPressed: onTap,
            )
          : Container(
              decoration: ShapeDecoration(
                shape: _shape,
              ),
              child: Center(
                child: child,
              ),
            ),
    );
  }
}
