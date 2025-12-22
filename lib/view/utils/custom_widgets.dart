import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';
import 'custom_navigator.dart';

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
  Color? decorationColor
}) {
  return Text(
    text,
    style: GoogleFonts.inter(
        fontSize: fontSize ?? 27,
        fontWeight: fontWeight ?? FontWeight.w700,
        decoration: decoration??TextDecoration.none,
        decorationColor: decorationColor??Colors.transparent,
        color: color),


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
    style: GoogleFonts.roboto(
        fontSize: fontSize ?? 13,
        fontWeight: fontWeight ?? FontWeight.w400,
        color: color),
    textAlign: textAlign ?? TextAlign.center,
    overflow: TextOverflow.ellipsis,
    maxLines: maxLines ?? 2,
  );
}

Widget button({
  required BuildContext context, // Add context parameter
  required double width,
  required String title,
  required double fontSize,
  required FontWeight fontWeight,
  required VoidCallback? onPressed,
  required bool isLoading,
  Color? backgroundColor,
  Color? textColor,
  double? height,
}) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final dynamicBackgroundColor =
      isDarkMode ? const Color(0xFFFCDB66) : primaryBlue;
  final dynamicTextColor = isDarkMode ? Colors.white : Colors.black;

  return MaterialButton(
    minWidth: width,
    height: height ?? 52,
    color: backgroundColor ?? dynamicBackgroundColor,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    ),
    onPressed: isLoading ? null : onPressed,
    child: isLoading
        ? const CircularProgressIndicator(color: CupertinoColors.white)
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              textRoboto(
                text: title,
                fontSize: fontSize,
                fontWeight: fontWeight,
               color:    isDarkMode?Colors.black:Colors.white
              ),
            ],
          ),
  );
}

Widget TextFieldWidget(
    {required String title,
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
    required BuildContext context}) {
  bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Visibility(
        visible: isTitleVisible ?? true,
        child: Column(
          children: [
            textRoboto(
                text: title,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: isDarkMode?Colors.white:Colors.black,),
            SpaceWidget(height: 10)
          ],
        ),
      ),
      TextField(
        controller: controller,
        keyboardType: textInputType,
        obscureText: obsecure??false,
        onChanged: (value) {
          final cursorPosition = controller.selection.base.offset;
          controller.value = controller.value.copyWith(
            text: value,
            selection: TextSelection.collapsed(offset: cursorPosition),
          );
        },
        readOnly: isread == true && isread != null ? true : false,
        decoration: InputDecoration(
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: textFieldBorderColor, width: 1),
              borderRadius: BorderRadius.circular(borderRadius ?? 15),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: textFieldBorderColor, width: 1),
              borderRadius: BorderRadius.circular(borderRadius ?? 15),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: textFieldBorderColor, width: 1),
              borderRadius: BorderRadius.circular(borderRadius ?? 15),
            ),
            hintText: hint,
            hintStyle: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: isDarkMode?Colors.white:Colors.grey,
            ),
            contentPadding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
            alignLabelWithHint: true,
            label: null,
            helperMaxLines: 2,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon),
        maxLines: maxLines,
        style: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: isDarkMode?Colors.white:Colors.black,
        ),
        cursorHeight: 20,
        textAlignVertical: TextAlignVertical.top,
      )
    ],
  );
}

showToast({required BuildContext context, required String message,
  Color? buttonColor



}) {
  FToast().init(context).showToast(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            color:buttonColor?? Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: textInter(
              text: message,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white),
        ),
        toastDuration: const Duration(seconds: 3),
        gravity: ToastGravity.BOTTOM,
      );
}
