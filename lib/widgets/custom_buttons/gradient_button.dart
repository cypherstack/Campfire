import 'package:flutter/material.dart';
import 'package:paymint/utilities/cfcolors.dart';

class GradientButton extends StatelessWidget {
  const GradientButton({
    Key key,
    @required this.onTap,
    this.child,
    this.shadows,
    this.enabled = true,
  }) : super(key: key);

  final VoidCallback onTap;
  final Widget child;
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
        shape: _shape,
        color: CFColors.white,
        shadows: _shadows,
      ),
      child: Container(
        decoration: ShapeDecoration(
          // color: CFColors.white,
          shape: _shape,
          gradient: enabled
              ? CFColors.fireGradientHorizontal
              : CFColors.fireGradientHorizontalDisabled,
        ),
        child: enabled
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
      ),
    );
  }
}
