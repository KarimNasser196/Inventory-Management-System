// lib/utils/responsive.dart - نظام Responsive متقدم

import 'package:flutter/material.dart';

class Responsive {
  static late MediaQueryData _mediaQuery;
  static late double _screenWidth;
  static late double _screenHeight;
  static late double _blockSizeHorizontal;
  static late double _blockSizeVertical;
  
  // أبعاد التصميم المرجعي
  static const double _designWidth = 1920.0;
  static const double _designHeight = 1080.0;

  static void init(BuildContext context) {
    _mediaQuery = MediaQuery.of(context);
    _screenWidth = _mediaQuery.size.width;
    _screenHeight = _mediaQuery.size.height;
    _blockSizeHorizontal = _screenWidth / 100;
    _blockSizeVertical = _screenHeight / 100;
  }

  // نوع الجهاز
  static bool isMobile(BuildContext context) => 
      MediaQuery.of(context).size.width < 600;
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1024;
  }
  
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  // حساب الأبعاد
  static double width(double inputWidth) {
    return (_screenWidth / _designWidth) * inputWidth;
  }

  static double height(double inputHeight) {
    return (_screenHeight / _designHeight) * inputHeight;
  }

  static double font(double inputFontSize) {
    final scaleFactor = _screenWidth / _designWidth;
    return inputFontSize * scaleFactor;
  }

  static double radius(double inputRadius) {
    return width(inputRadius);
  }

  static double icon(double inputSize) {
    return width(inputSize);
  }

  // Padding و Margin
  static EdgeInsets paddingAll(double value) {
    return EdgeInsets.all(width(value));
  }

  static EdgeInsets paddingSym({double h = 0, double v = 0}) {
    return EdgeInsets.symmetric(
      horizontal: width(h),
      vertical: height(v),
    );
  }

  static EdgeInsets paddingOnly({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return EdgeInsets.only(
      left: width(left),
      top: height(top),
      right: width(right),
      bottom: height(bottom),
    );
  }

  // كسور الشاشة
  static double get screenWidth => _screenWidth;
  static double get screenHeight => _screenHeight;
  
  static double widthPercent(double percent) => _screenWidth * (percent / 100);
  static double heightPercent(double percent) => _screenHeight * (percent / 100);

  // حجم النص المتجاوب
  static double textSize(BuildContext context, double size) {
    if (isMobile(context)) return size * 0.8;
    if (isTablet(context)) return size * 0.9;
    return size;
  }

  // SizedBox متجاوب
  static SizedBox hBox(double width) => SizedBox(width: Responsive.width(width));
  static SizedBox vBox(double height) => SizedBox(height: Responsive.height(height));

  // Grid Count متجاوب
  static int gridCount(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    return 3;
  }
}
