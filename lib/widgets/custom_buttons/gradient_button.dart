import 'package:flutter/material.dart';
import 'package:paymint/utilities/cfcolors.dart';

class GradientButton extends StatelessWidget {
  const GradientButton(
      {Key key, @required this.onTap, this.child, this.shadows, this.enabled})
      : super(key: key);

  final VoidCallback onTap;
  final Widget child;
  final List<BoxShadow> shadows;
  final bool enabled;

  final _shape = const StadiumBorder();

  List<BoxShadow> get _shadows => shadows == null
      ? [
          BoxShadow(
              color: CFColors.shadowColor, spreadRadius: 0.1, blurRadius: 1.5)
        ]
      : shadows;

  _buildEnabled() {
    if (enabled == null || enabled) {
      return MaterialButton(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: _shape,
        child: child,
        onPressed: onTap,
      );
    } else {
      return Container(
        decoration: ShapeDecoration(
          shape: _shape,
        ),
        child: Center(
          child: child,
        ),
      );
    }
  }

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
          gradient: (enabled == null || enabled)
              ? CFColors.fireGradientHorizontal
              : CFColors.fireGradientHorizontalDisabled,
        ),
        child: _buildEnabled(),
      ),
    );
  }
}
