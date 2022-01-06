import 'package:flutter/material.dart';
import 'package:paymint/utilities/cfcolors.dart';

class AppBarIconButton extends StatelessWidget {
  const AppBarIconButton({
    Key key,
    @required this.icon,
    @required this.onPressed,
    this.color,
    this.circularBorderRadius,
    this.size = 36.0,
    this.shadows,
  }) : super(key: key);

  final Widget icon;
  final VoidCallback onPressed;
  final Color color;
  final double circularBorderRadius;
  final double size;
  final List<BoxShadow> shadows;

  List<BoxShadow> get _shadows =>
      shadows == null ? [CFColors.standardBoxShadow] : shadows;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(circularBorderRadius),
        color: color == null ? CFColors.white : color,
        boxShadow: _shadows,
      ),
      child: MaterialButton(
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(circularBorderRadius),
        ),
        child: icon,
        onPressed: onPressed,
      ),
    );
  }
}
