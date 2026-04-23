import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class SizedExreen {
  SizedExreen._();

  static final SizedExreen _instance = SizedExreen._();

  factory SizedExreen() {
    return _instance;
  }
  static double h(BuildContext context, num percentage) {
    assert(percentage >= 0 && percentage <= 100,
        'Percentage must be between 0 and 100.');
    return MediaQuery.of(context).size.height * (percentage / 100);
  }

  static Widget widthbox(BuildContext context, double s) {
    return SizedBox(
      width: w(context, s),
    );
  }

  static Widget heightbox(BuildContext context, double s) {
    return SizedBox(
      height: h(context, s),
    );
  }

  static double sp(BuildContext context, num percentage) {
    return percentage * (w(context, 100) / 3) / 100;
  }

  static double w(BuildContext context, num percentage) {
    assert(percentage >= 0 && percentage <= 100,
        'Percentage must be between 0 and 100.');
    return MediaQuery.of(context).size.width * (percentage / 100);
  }
}

Widget SpaceWidget({double? height, double? width, Widget? child}) =>
    SizedBox(height: height, width: width, child: child);

Widget textInter({
  required String text,
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  TextAlign? textAlign,
  int? maxLines,
  TextDecoration? decoration,
  Color? decorationColor,
}) {
  return Text(
    text,
    style: GoogleFonts.inter(
      fontSize: fontSize ?? 27,
      fontWeight: fontWeight ?? FontWeight.w700,
      decoration: decoration ?? TextDecoration.none,
      decorationColor: decorationColor ?? Colors.transparent,
      color: color ?? textPrimary,
      height: 1.25,
    ),
    textAlign: textAlign ?? TextAlign.center,
    overflow: TextOverflow.ellipsis,
    maxLines: maxLines ?? 2,
  );
}

Widget textRoboto({
  required String text,
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  TextAlign? textAlign,
  int? maxLines,
}) {
  return Text(
    text,
    style: GoogleFonts.inter(
      fontSize: fontSize ?? 13,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color ?? textSecondary,
      height: 1.35,
    ),
    textAlign: textAlign ?? TextAlign.center,
    overflow: TextOverflow.ellipsis,
    maxLines: maxLines ?? 2,
  );
}

/// Brand primary button. Gradient violet → violet with soft shadow.
Widget button({
  required BuildContext context,
  required double width,
  required String title,
  required double fontSize,
  required FontWeight fontWeight,
  required VoidCallback? onPressed,
  required bool isLoading,
  Color? backgroundColor,
  Color? textColor,
  double? height,
  IconData? icon,
}) {
  final effectiveHeight = height ?? 54.0;
  final bg = backgroundColor;

  return GestureDetector(
    onTap: (isLoading || onPressed == null) ? null : onPressed,
    child: Container(
      width: width,
      height: effectiveHeight,
      decoration: BoxDecoration(
        gradient: bg == null
            ? purpleGradient
            : LinearGradient(colors: [bg, bg]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: brandShadow(opacity: 0.22, blur: 16),
      ),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: CupertinoColors.white,
                  strokeWidth: 2.4,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: textColor ?? Colors.white, size: 20),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: fontSize,
                        fontWeight: fontWeight,
                        color: textColor ?? Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}

/// Secondary outline button — violet outline, transparent fill.
Widget outlineButton({
  required BuildContext context,
  required double width,
  required String title,
  required VoidCallback? onPressed,
  double? height,
  IconData? icon,
}) {
  return GestureDetector(
    onTap: onPressed,
    child: Container(
      width: width,
      height: height ?? 52,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: appColor, width: 1.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: appColor, size: 20),
              const SizedBox(width: 10),
            ],
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: appColor,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget TextFieldWidget({
  required String title,
  required TextEditingController controller,
  required Color textFieldBorderColor,
  required TextInputType textInputType,
  required String hint,
  required hintColor,
  int? maxLines,
  bool? isread,
  bool? obsecure,
  bool? isTitleVisible,
  Widget? prefixIcon,
  Widget? suffixIcon,
  double? borderRadius,
  Color? textColor,
  required BuildContext context,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Visibility(
        visible: isTitleVisible ?? true,
        child: Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius ?? 14),
          boxShadow: softCardShadow(),
        ),
        child: TextField(
          controller: controller,
          keyboardType: textInputType,
          obscureText: obsecure ?? false,
          readOnly: isread == true && isread != null ? true : false,
          onChanged: (value) {
            final cursorPosition = controller.selection.base.offset;
            controller.value = controller.value.copyWith(
              text: value,
              selection: TextSelection.collapsed(offset: cursorPosition),
            );
          },
          decoration: InputDecoration(
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: surfaceMuted, width: 1),
              borderRadius: BorderRadius.circular(borderRadius ?? 14),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: surfaceMuted, width: 1),
              borderRadius: BorderRadius.circular(borderRadius ?? 14),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: appColor, width: 1.4),
              borderRadius: BorderRadius.circular(borderRadius ?? 14),
            ),
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: textMuted,
            ),
            contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            alignLabelWithHint: true,
            filled: true,
            fillColor: Colors.white,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
          ),
          maxLines: maxLines,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor ?? textPrimary,
          ),
          cursorColor: appColor,
          cursorHeight: 20,
          textAlignVertical: TextAlignVertical.top,
        ),
      ),
    ],
  );
}

/// Soft section card used across the redesign — rounded, subtle lavender
/// outline, soft shadow. Drop-in replacement for hand-rolled containers.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
    this.backgroundColor,
    this.showShadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? backgroundColor;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: surfaceMuted.withOpacity(0.6), width: 1),
        boxShadow: showShadow ? softCardShadow() : null,
      ),
      child: child,
    );
  }
}

/// Brand gradient card — use for hero banners, featured step tiles.
class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.child,
    this.gradient,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = 22,
    this.onTap,
  });

  final Widget child;
  final Gradient? gradient;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Ink(
          padding: padding,
          decoration: BoxDecoration(
            gradient: gradient ?? brandGradient,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: brandShadow(opacity: 0.22, blur: 18),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Pill-style section label.
Widget sectionTitle(String text, {Color? color}) => Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: color ?? textPrimary,
        letterSpacing: 0.2,
      ),
    );

showToast({
  required BuildContext context,
  required String message,
  Color? buttonColor,
}) {
  final bg = buttonColor ?? errorColor;
  FToast().init(context).showToast(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: bg.withOpacity(0.3),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                bg == successColor
                    ? Icons.check_circle_rounded
                    : Icons.info_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        toastDuration: const Duration(seconds: 3),
        gravity: ToastGravity.BOTTOM,
      );
}

/// Small Spoki logo mark — draws the ghost + book using a Stack of icons.
/// Lightweight alternative to the raster logo for inline use in headers.
class SpokiLogoMark extends StatelessWidget {
  const SpokiLogoMark({super.key, this.size = 40});
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: brandGradient,
        shape: BoxShape.circle,
        boxShadow: brandShadow(opacity: 0.3, blur: 16),
      ),
      child: Center(
        child: Icon(
          Icons.auto_stories_rounded,
          color: Colors.white,
          size: size * 0.55,
        ),
      ),
    );
  }
}
