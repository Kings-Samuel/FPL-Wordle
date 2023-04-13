import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Text headingText({
  required String text,
  Color color = Colors.black,
  double fontSize = 22,
}) {
  return Text(
    text,
    style: GoogleFonts.ntr(color: color, fontSize: fontSize, fontWeight: FontWeight.w500),
  );
}

Text bodyText(
    {required String text,
    Color color = Colors.black,
    bool bold = false,
    double fontSize = 14,
    TextAlign textAlign = TextAlign.left}) {
  return Text(
    text,
    textAlign: textAlign,
    style:
        GoogleFonts.ntr(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.w500 : FontWeight.normal),
  );
}

Text bodyText2({required String text, Color color = Colors.black, bool bold = false, double fontSize = 14}) {
  return Text(
    text,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style:
        GoogleFonts.ntr(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.w500 : FontWeight.normal),
  );
}

Text bodyText3({required String text, Color color = Colors.black, bool bold = false, double fontSize = 12}) {
  return Text(
    text,
    maxLines: 3,
    overflow: TextOverflow.ellipsis,
    style:
        GoogleFonts.ntr(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.w500 : FontWeight.normal),
  );
}