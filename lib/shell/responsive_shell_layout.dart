import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive.dart';

export 'package:salud_dental_clinic_management/core/presentation/responsive.dart'
    show AppLayout, AppLayoutResolution;

/// The shell speaks in terms of `ShellLayout`, but the policy itself lives in
/// `core/presentation/responsive.dart` so content screens, forms and dialogs
/// resolve breakpoints exactly the same way the navigation does.
typedef ShellLayout = AppLayout;

abstract final class ShellLayoutResolution {
  static ShellLayout of(MediaQueryData mediaQuery) =>
      AppLayoutResolution.of(mediaQuery);

  static EdgeInsets contentPadding(
    MediaQueryData mediaQuery,
    ShellLayout layout,
  ) => AppLayoutResolution.contentPadding(mediaQuery, layout);
}
