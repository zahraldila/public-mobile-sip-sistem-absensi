import 'package:flutter/material.dart';

class ColorHelper {
  ColorHelper._();

  /// Mengonversi string HEX (contoh: "#0891B2" atau "0891B2") menjadi Objek Color Flutter
  static Color parseHexColor(
    String? hexString, {
    Color defaultColor = const Color(0xFF0891B2),
  }) {
    if (hexString == null || hexString.trim().isEmpty) return defaultColor;

    String cleanHex = hexString.replaceAll('#', '').trim();
    if (cleanHex.length == 6) {
      cleanHex = 'FF$cleanHex';
    } else if (cleanHex.length != 8) {
      return defaultColor;
    }

    try {
      return Color(int.parse(cleanHex, radix: 16));
    } catch (_) {
      return defaultColor;
    }
  }

  /// Menghasilkan warna gradasi kedua yang sedikit lebih gelap/terang
  static Color getDarkerColor(Color color, [double factor = 0.85]) {
    return Color.fromARGB(
      color.alpha,
      (color.red * factor).round().clamp(0, 255),
      (color.green * factor).round().clamp(0, 255),
      (color.blue * factor).round().clamp(0, 255),
    );
  }
}
