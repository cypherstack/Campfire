import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/utilities/cfcolors.dart';

class CFTextStyles {
  static final TextStyle button = GoogleFonts.workSans(
    color: CFColors.white,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    letterSpacing: 0.5,
  );

  static final TextStyle pinkHeader = GoogleFonts.workSans(
    color: CFColors.spark,
    fontWeight: FontWeight.w600,
    fontSize: 20,
  );

  static final TextStyle textField = GoogleFonts.workSans(
    color: CFColors.dusk,
    fontWeight: FontWeight.w400,
    fontSize: 16,
  );

  static final TextStyle textFieldHint = GoogleFonts.workSans(
    color: CFColors.twilight,
    fontWeight: FontWeight.w400,
    fontSize: 16,
  );
}
