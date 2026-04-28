import 'package:flutter/material.dart';
import 'package:spokiai/view/utils/theme_controller.dart';

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
Color get appColor => HexColor.convertHexToColor('#6D3BBF');

/// Darker violet for pressed states, selected chips, shadows.
Color get appColorDark => HexColor.convertHexToColor('#6D3BBF');

/// Soft lavender for hover/secondary elements.
Color get appColorLight => HexColor.convertHexToColor('#6D3BBF');

/// Secondary brand color — teal / mint from the logo book.
/// Formerly `orangeColor` — kept the name for drop-in compatibility across
/// existing screens; the actual hue is now the brand mint.
Color get orangeColor => HexColor.convertHexToColor('#20C5A8');

/// Logo teal / mint (same hue as [orangeColor], semantic name).
Color get tealColor => HexColor.convertHexToColor('#20C5A8');

/// Darker teal for depth / selected states.
Color get tealDark => HexColor.convertHexToColor('#139E86');

/// Soft mint background pill.
Color get tealSoft => ThemeController.isDarkModeEnabled
    ? const Color(0xFF1F3A36)
    : HexColor.convertHexToColor('#D6F6EE');

/// Secondary cool-accent color (used where primaryBlue was referenced).
/// Remapped to the mid-violet from the logo so the app stays on palette.
Color get primaryBlue => HexColor.convertHexToColor('#6D3BBF');

/// Neutral text grey.
Color get greyColor => ThemeController.isDarkModeEnabled
    ? const Color(0xFFAAAAC0)
    : HexColor.convertHexToColor('#6B6B85');

/// Subtle border / divider color for text fields and cards.
Color get textFieldBorderColor => ThemeController.isDarkModeEnabled
    ? const Color(0xFF3A3A4A)
    : HexColor.convertHexToColor('#D4D4D4').withOpacity(0.5);

// ─── Surfaces & backgrounds ─────────────────────────────────────────────────

/// Global soft lavender background (used behind most screens).
Color get surfaceBg => ThemeController.isDarkModeEnabled
    ? const Color(0xFF121212)
    : HexColor.convertHexToColor('#FAF8FF');

/// Ultra-light violet surface for section cards.
Color get surfaceSoft => ThemeController.isDarkModeEnabled
    ? const Color(0xFF1D1D2A)
    : HexColor.convertHexToColor('#F3EBFA');

/// Muted purple surface for disabled / inactive states.
Color get surfaceMuted => ThemeController.isDarkModeEnabled
    ? const Color(0xFF2F2F3F)
    : HexColor.convertHexToColor('#E9E1F5');

/// Warm white card surface.
Color get cardSurface =>
    ThemeController.isDarkModeEnabled ? const Color(0xFF1E1E1E) : Colors.white;

// ─── Text ───────────────────────────────────────────────────────────────────

Color get textPrimary => ThemeController.isDarkModeEnabled
    ? const Color(0xFFE8E1F3)
    : HexColor.convertHexToColor('#1A1033');
Color get textSecondary => ThemeController.isDarkModeEnabled
    ? const Color(0xFFBBB6CC)
    : HexColor.convertHexToColor('#6C6B85');
Color get textMuted => ThemeController.isDarkModeEnabled
    ? const Color(0xFF8E8AA0)
    : HexColor.convertHexToColor('#9994AE');

// ─── Semantic status ────────────────────────────────────────────────────────

Color get successColor => HexColor.convertHexToColor('#20C5A8');
Color get warningColor => HexColor.convertHexToColor('#FFB547');
Color get errorColor => ThemeController.isDarkModeEnabled
    ? const Color(0xFFFF8A80)
    : HexColor.convertHexToColor('#E85C7B');

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
      colors: ThemeController.isDarkModeEnabled
          ? const [
              Color(0xFF121212),
              Color(0xFF181823),
            ]
          : [
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
