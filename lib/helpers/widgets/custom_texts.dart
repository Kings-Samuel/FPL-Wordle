import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Text headingText({
  required String text,
  Color color = Colors.white,
  double fontSize = 22,
  int variation = 1,
}) {
  return Text(text,
      style: variation == 1
          ? GoogleFonts.ntr(color: color, fontSize: fontSize, fontWeight: FontWeight.bold)
          : variation == 2
              ? GoogleFonts.pacifico(color: color, fontSize: fontSize)
              : GoogleFonts.montserrat(
                  color: color,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  shadows: [
                    const Shadow(
                      blurRadius: 4.0,
                      color: Colors.black,
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ));
}

Text bodyText(
    {required String text,
    Color color = Colors.white,
    bool bold = false,
    double fontSize = 18,
    TextAlign textAlign = TextAlign.left}) {
  return Text(
    text,
    textAlign: textAlign,
    style: GoogleFonts.ntr(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.w500),
  );
}
