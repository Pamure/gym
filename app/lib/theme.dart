import 'package:flutter/material.dart';

/// IronForge design system — "Forge" theme.
///
/// Design language (research: WHOOP / Strong / Hevy, 2026 dark-UI standard):
///   - near-black surfaces, NEVER pure #000 (halation on OLED, eye strain)
///   - ONE signature accent (ember orange #FF5A1F) — heat/fire/forge identity.
///     Purple→pink gradients are banned: they say "generic crypto app", not gym.
///   - oversized glanceable numerals for the data that matters (gym floor use)
///   - color is INFORMATION only: green = success/logged, amber = warning,
///     red = destructive, orange = the brand + primary actions
class T {
  // ── Surfaces ─────────────────────────────────────────────
  static const bg = Color(0xFF0A0A0B); // app background (near-black)
  static const surface = Color(0xFF131316); // cards
  static const surface2 = Color(0xFF1C1C21); // inputs, chips, pressed
  static const surface3 = Color(0xFF26262C); // hover / separators fill
  static const border = Color(0xFF26262C); // hairline borders

  // ── Text ─────────────────────────────────────────────────
  static const text = Color(0xFFF2F2F3);
  static const dim = Color(0xFF9C9CA6); // secondary
  static const faint = Color(0xFF5C5C66); // tertiary / placeholders

  // ── Accent (the brand) ───────────────────────────────────
  static const ember = Color(0xFFFF5A1F); // signature orange
  static const emberHot = Color(0xFFFF8A5C); // lighter, for highlights
  static const emberDeep = Color(0xFF7A2A0C); // dark ember, subtle fills

  // ── Semantic (informational only) ────────────────────────
  static const green = Color(0xFF4ADE80);
  static const amber = Color(0xFFFBBF24);
  static const red = Color(0xFFF87171);
  static const blue = Color(0xFF60A5FA); // check-in / info dots

  // ── Streak heatmap ramp (GitHub-style, single-hue ember) ─
  static const streakRamp = [
    Color(0xFF1C1C21), // 0 — no activity
    Color(0xFF3D1E0D), // 1 — faint ember
    Color(0xFF7A2A0C), // 2
    Color(0xFFC23F12), // 3
    Color(0xFFFF5A1F), // 4 — full blaze
  ];

  // ── Gradients (restrained; surfaces, not decoration) ─────
  static const gradient = LinearGradient(
    colors: [Color(0xFF2A1409), Color(0xFF171009)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientEmber = LinearGradient(
    colors: [emberDeep, Color(0xFF3D1E0D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientGreen = LinearGradient(
    colors: [Color(0xFF0E2A1A), Color(0xFF122A1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Legacy aliases (screens keep compiling; same visual now) ──
  static const indigo = ember;
  static const pink = emberHot;

  static ThemeData theme() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      splashColor: ember.withValues(alpha: 0.08),
      highlightColor: ember.withValues(alpha: 0.05),
      colorScheme: base.colorScheme.copyWith(
        primary: ember,
        secondary: emberHot,
        surface: surface,
        error: red,
      ),
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ember, width: 1.5),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surface2,
        side: const BorderSide(color: border),
        labelStyle: const TextStyle(color: text, fontSize: 12),
      ),
      dividerColor: border,
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: ember),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: surface2,
        contentTextStyle: TextStyle(color: text),
      ),
    );
  }
}

/// Header card — restrained dark ember surface with a hairline ember edge,
/// not a loud gradient. The "forge glow" is a surface treatment, not neon.
class GradientCard extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  const GradientCard({super.key, required this.child, this.gradient = T.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: T.emberDeep.withValues(alpha: 0.55), width: 1),
      ),
      child: child,
    );
  }
}
