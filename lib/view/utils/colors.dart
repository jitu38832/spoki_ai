import 'package:flutter/material.dart';

class HexColor {
  static Color convertHexToColor(String hexColorCode) {
    if (hexColorCode.length != 7 || hexColorCode[0] != '#') {
      throw ArgumentError(
          "Invalid color code format. Expected format: #RRGGBB");
    }

    int red = int.parse(hexColorCode.substring(1, 3), radix: 16);
    int green = int.parse(hexColorCode.substring(3, 5), radix: 16);
    int blue = int.parse(hexColorCode.substring(5, 7), radix: 16);

    return Color.fromARGB(255, red, green, blue);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SPOKI AI — BRAND DESIGN TOKENS
//
//  Inspired by the Spoki AI logo: deep violet spirit + teal / mint book.
//  Use these tokens everywhere instead of hardcoded colors.
// ═══════════════════════════════════════════════════════════════════════════

/// Primary brand color — deep logo purple. Used for CTAs, app bar accents.
final Color appColor = HexColor.convertHexToColor('#6D3BBF');

/// Darker violet for pressed states, selected chips, shadows.
final Color appColorDark = HexColor.convertHexToColor('#6D3BBF');

/// Soft lavender for hover/secondary elements.
final Color appColorLight = HexColor.convertHexToColor('#6D3BBF');

/// Secondary brand color — teal / mint from the logo book.
/// Formerly `orangeColor` — kept the name for drop-in compatibility across
/// existing screens; the actual hue is now the brand mint.
final Color orangeColor = HexColor.convertHexToColor('#20C5A8');

/// Logo teal / mint (same hue as [orangeColor], semantic name).
final Color tealColor = HexColor.convertHexToColor('#20C5A8');

/// Darker teal for depth / selected states.
final Color tealDark = HexColor.convertHexToColor('#139E86');

/// Soft mint background pill.
final Color tealSoft = HexColor.convertHexToColor('#D6F6EE');

/// Secondary cool-accent color (used where primaryBlue was referenced).
/// Remapped to the mid-violet from the logo so the app stays on palette.
final Color primaryBlue = HexColor.convertHexToColor('#6D3BBF');

/// Neutral text grey.
final Color greyColor = HexColor.convertHexToColor('#6B6B85');

/// Subtle border / divider color for text fields and cards.
final Color textFieldBorderColor =
    HexColor.convertHexToColor('#D4D4D4').withOpacity(0.5);

// ─── Surfaces & backgrounds ─────────────────────────────────────────────────

/// Global soft lavender background (used behind most screens).
final Color surfaceBg = HexColor.convertHexToColor('#FAF8FF');

/// Ultra-light violet surface for section cards.
final Color surfaceSoft = HexColor.convertHexToColor('#F3EBFA');

/// Muted purple surface for disabled / inactive states.
final Color surfaceMuted = HexColor.convertHexToColor('#E9E1F5');

/// Warm white card surface.
final Color cardSurface = Colors.white;

// ─── Text ───────────────────────────────────────────────────────────────────

final Color textPrimary = HexColor.convertHexToColor('#1A1033');
final Color textSecondary = HexColor.convertHexToColor('#6C6B85');
final Color textMuted = HexColor.convertHexToColor('#9994AE');

// ─── Semantic status ────────────────────────────────────────────────────────

final Color successColor = HexColor.convertHexToColor('#20C5A8');
final Color warningColor = HexColor.convertHexToColor('#FFB547');
final Color errorColor = HexColor.convertHexToColor('#E85C7B');

// ─── Gradients ──────────────────────────────────────────────────────────────

/// Signature brand gradient: deep violet → soft mint.
/// Use on hero CTAs, banners, splash accents.
LinearGradient get brandGradient => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [appColor, tealColor],
    );

/// Violet-to-violet gradient for primary buttons (stays on-brand).
LinearGradient get purpleGradient => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [appColorLight, appColor],
    );

/// Deep violet hero gradient for top banners / splash overlays.
LinearGradient get heroGradient => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        HexColor.convertHexToColor('#6D3BBF'),
        HexColor.convertHexToColor('#6D3BBF'),
      ],
    );

/// Mint/teal gradient for success / secondary CTAs.
LinearGradient get tealGradient => LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [tealColor, tealDark],
    );

/// Soft lavender sheet gradient for screen backgrounds.
LinearGradient get backgroundSheetGradient => LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        HexColor.convertHexToColor('#FBF8FF'),
        HexColor.convertHexToColor('#F2E9FA'),
      ],
    );

// ─── Elevations / shadows ───────────────────────────────────────────────────

List<BoxShadow> brandShadow({double opacity = 0.18, double blur = 18}) => [
      BoxShadow(
        color: appColor.withOpacity(opacity),
        blurRadius: blur,
        offset: const Offset(0, 8),
      ),
    ];

List<BoxShadow> softCardShadow() => [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 14,
        offset: const Offset(0, 6),
      ),
    ];
