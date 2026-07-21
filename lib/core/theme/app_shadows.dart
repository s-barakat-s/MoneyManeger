import 'package:flutter/material.dart';

class AppShadows {
  const AppShadows._();

  static const soft = [
    BoxShadow(
      color: Color(0x0F1D1B2A),
      blurRadius: 22,
      offset: Offset(0, 10),
    ),
  ];

  static const medium = [
    BoxShadow(
      color: Color(0x171D1B2A),
      blurRadius: 32,
      offset: Offset(0, 16),
    ),
  ];
}
