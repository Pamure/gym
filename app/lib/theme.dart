import 'package:flutter/material.dart';

/// IronForge design system — "Clear Motion".
///
/// A calm navy canvas keeps the gym floor content readable, while teal marks
/// primary actions and coral is reserved for progress/highlight states. The
/// palette deliberately avoids red/orange text on near-black backgrounds: WCAG
/// guidance recommends at least 4.5:1 contrast for normal text.
class T {
  // Surfaces: deep navy, not pure black.
  static const bg = Color(0xFF0B1220);
  static const surface = Color(0xFF121C2D);
  static const surface2 = Color(0xFF1B2940);
  static const surface3 = Color(0xFF253754);
  static const border = Color(0xFF30435F);

  // Text.
  static const text = Color(0xFFF4F7FB);
  static const dim = Color(0xFFB8C4D6);
  static const faint = Color(0xFF8190A6);

  // Primary and highlight accents.
  static const teal = Color(0xFF49D6C2);
  static const tealDeep = Color(0xFF1D5960);
  static const coral = Color(0xFFFF9A76);
  static const coralDeep = Color(0xFF633B3A);

  // Semantic colors.
  static const green = Color(0xFF6DDBA4);
  static const amber = Color(0xFFFFD166);
  static const red = Color(0xFFFF8585);
  static const blue = Color(0xFF80B5FF);

  // Streak ramp: teal gives meaning without turning the whole screen orange.
  static const streakRamp = [
    Color(0xFF1B2940),
    Color(0xFF17444B),
    Color(0xFF207267),
    Color(0xFF35A995),
    Color(0xFF49D6C2),
  ];

  static const gradient = LinearGradient(
    colors: [Color(0xFF18324A), Color(0xFF142A3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientEmber = LinearGradient(
    colors: [Color(0xFF3E2D3B), Color(0xFF263A50)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientGreen = LinearGradient(
    colors: [Color(0xFF123A3A), Color(0xFF183A42)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Compatibility aliases used by existing screens.
  static const indigo = teal;
  static const pink = coral;
  static const ember = teal;
  static const emberHot = coral;
  static const emberDeep = tealDeep;

  static ThemeData theme() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      splashColor: teal.withValues(alpha: 0.10),
      highlightColor: teal.withValues(alpha: 0.06),
      colorScheme: base.colorScheme.copyWith(
        primary: teal,
        secondary: coral,
        surface: surface,
        error: red,
        onPrimary: bg,
      ),
      // Keep normal UI text on the platform sans-serif. Applying an emoji
      // font as a global fallback made some Android/web builds render body
      // copy with odd spacing. Emoji remain local glyphs where used.
      textTheme: base.textTheme.apply(bodyColor: text, displayColor: text),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        labelStyle: const TextStyle(color: dim),
        hintStyle: const TextStyle(color: faint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: teal, width: 1.5),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surface2,
        side: const BorderSide(color: border),
        labelStyle: const TextStyle(color: text, fontSize: 12),
      ),
      dividerColor: border,
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: teal),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: surface2,
        contentTextStyle: TextStyle(color: text),
      ),
    );
  }
}

/// A restrained header card: calm navy surface with a readable teal edge.
class GradientCard extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  const GradientCard({
    super.key,
    required this.child,
    this.gradient = T.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: T.tealDeep.withValues(alpha: 0.75), width: 1),
      ),
      child: child,
    );
  }
}
