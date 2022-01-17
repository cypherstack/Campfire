import 'package:flutter/material.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/sizing_utilities.dart';

class ModalPopupDialog extends StatelessWidget {
  const ModalPopupDialog({Key key, this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CFColors.starryNight.withOpacity(0.8),
      child: Column(
        children: [
          Spacer(),
          Padding(
            padding: EdgeInsets.all(SizingUtilities.standardPadding),
            child: Container(
              decoration: BoxDecoration(
                color: CFColors.white,
                borderRadius: BorderRadius.circular(
                    SizingUtilities.circularBorderRadius * 2),
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
