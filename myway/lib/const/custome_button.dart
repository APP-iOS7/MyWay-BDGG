import 'package:flutter/material.dart';

ButtonStyle customTextButtonStyle() {
  return ButtonStyle(
    overlayColor: WidgetStateProperty.all(Colors.transparent),
    backgroundColor: WidgetStateProperty.all(Colors.transparent),
  );
}
