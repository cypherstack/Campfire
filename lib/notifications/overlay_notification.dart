import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/sizing_utilities.dart';

class OverlayNotification {
  static void showSuccess(
      BuildContext context, String message, Duration duration) async {
    return _showOverlay(
        context, CFColors.notificationSuccess, message, duration);
  }

  static void showInfo(
      BuildContext context, String message, Duration duration) async {
    return _showOverlay(context, CFColors.notificationInfo, message, duration);
  }

  static void showError(
      BuildContext context, String message, Duration duration) async {
    return _showOverlay(context, CFColors.notificationError, message, duration);
  }

  static OverlayState _state;
  static OverlayEntry _entry;

  static void _showOverlay(BuildContext context, Color backgroundColor,
      String message, Duration duration) async {
    _state = Overlay.of(context);
    _entry = OverlayEntry(
      builder: (context) => Positioned(
        top: SizingUtilities.getStatusBarHeight(context),
        left: 20,
        right: 20,
        child: Container(
          decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius:
                  BorderRadius.circular(SizingUtilities.circularBorderRadius),
              boxShadow: [
                BoxShadow(
                  color: CFColors.shadowColor,
                  spreadRadius: 0.5,
                  blurRadius: 1,
                  offset: Offset(0, 2),
                )
              ]),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: FittedBox(
                child: Text(
                  message,
                  style: GoogleFonts.workSans(
                    decoration: TextDecoration.none,
                    color: CFColors.dusk,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    _state.insert(_entry);
    await Future.delayed(
      duration,
      _entry.remove,
    );
  }
}
