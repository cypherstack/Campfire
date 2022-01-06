import 'package:flutter/material.dart';
import 'package:paymint/utilities/cfcolors.dart';

class GradientCard extends StatefulWidget {
  const GradientCard(
      {Key key,
      this.child,
      @required this.gradient,
      this.backgroundColorForTransparentGradient = Colors.white,
      this.circularBorderRadius = 0.0})
      : super(key: key);

  final Widget child;
  final Gradient gradient;
  final Color backgroundColorForTransparentGradient;
  final double circularBorderRadius;

  @override
  _GradientCardState createState() => _GradientCardState();
}

class _GradientCardState extends State<GradientCard> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.backgroundColorForTransparentGradient,
      borderRadius: BorderRadius.circular(widget.circularBorderRadius),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: widget.gradient,
          borderRadius: BorderRadius.circular(widget.circularBorderRadius),
          boxShadow: [
            CFColors.standardBoxShadow,
          ],
        ),
        child: widget.child,
      ),
    );
  }
}
