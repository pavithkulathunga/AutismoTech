import 'package:flutter/material.dart';
import 'colors.dart';

const TextStyle textStyle = TextStyle(
  fontFamily: 'Lato',
  fontWeight: FontWeight.w400,
  fontSize: 24,
  letterSpacing: 0,
  color: AppColors.textColor,
);

const TextStyle loadingTextStyle = TextStyle(
  fontFamily: 'Lato',
  fontWeight: FontWeight.w400,
  fontSize: 24,
  letterSpacing: 0,
  color: AppColors.darkBlue,
);

final ThemeData appTheme = ThemeData(
  primarySwatch: Colors.blue,
  fontFamily: 'Lato',
  scaffoldBackgroundColor: AppColors.backgroundColor,
);