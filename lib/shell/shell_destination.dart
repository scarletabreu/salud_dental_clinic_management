import 'package:flutter/material.dart';

class ShellDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final WidgetBuilder builder;

  const ShellDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.builder,
  });
}
