import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta tomada del logo: verde bosque + oro + negro.
class C {
  static const ink = Color(0xFF070A08);
  static const green950 = Color(0xFF071A11);
  static const green900 = Color(0xFF0B2418);
  static const green800 = Color(0xFF113221);
  static const green700 = Color(0xFF1A4630);
  static const gold = Color(0xFFD4A62A);
  static const gold300 = Color(0xFFF3D36B);
  static const gold200 = Color(0xFFF8E6A6);
  static const gold700 = Color(0xFF9C7310);
  static const cream = Color(0xFFF7F3E8);
  static const cream2 = Color(0xFFEFE8D6);
  static const line = Color(0xFFE4DFD1);
  static const text = Color(0xFF1A1F1C);
  static const muted = Color(0xFF5F6862);
  static const ok = Color(0xFF1F8A4C);
  static const warn = Color(0xFFC98A06);
  static const bad = Color(0xFFC0392B);

  static const sev = [ok, warn, bad];
  static const sevBg = [Color(0xFFE3F4EA), Color(0xFFFFF3D6), Color(0xFFFDE4E1)];

  /// Color por gravedad; -1 (no aplica) en gris.
  static Color sevColor(int sev) => sev < 0 ? muted : C.sev[sev];
  static Color sevBgColor(int sev) => sev < 0 ? cream2 : C.sevBg[sev];

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF8E6A6), Color(0xFFE3B93F), Color(0xFFB8860B), Color(0xFFF3D36B)],
    stops: [0, .35, .65, 1],
  );
}

TextStyle display(double size, {Color color = C.green950}) =>
    GoogleFonts.cinzel(fontSize: size, fontWeight: FontWeight.w700, color: color, height: 1.15);

ThemeData atlasTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: C.green800, primary: C.green900, secondary: C.gold, surface: Colors.white),
    scaffoldBackgroundColor: C.cream,
  );
  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(bodyColor: C.text, displayColor: C.text),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: C.gold300,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: C.line)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFFBFAF6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.gold, width: 2)),
      labelStyle: const TextStyle(color: C.muted),
    ),
  );
}

/// Botón dorado principal.
class GoldButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  const GoldButton(this.label, {super.key, this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? .45 : 1,
      child: Container(
        decoration: BoxDecoration(
          gradient: C.goldGradient,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [BoxShadow(color: C.gold.withValues(alpha: .45), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                if (icon != null) ...[Icon(icon, size: 20, color: C.ink), const SizedBox(width: 8)],
                Flexible(child: Text(label, style: const TextStyle(color: C.ink, fontWeight: FontWeight.w700, fontSize: 16))),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Etiqueta de estado con color según gravedad.
class SevPill extends StatelessWidget {
  final String label;
  final int sev;
  const SevPill(this.label, this.sev, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: C.sevBgColor(sev), borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: TextStyle(color: C.sevColor(sev), fontWeight: FontWeight.w700, fontSize: 12)),
      );
}

/// Formato de pesos chilenos: 450000 -> $450.000
String clp(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return '\$$b';
}
