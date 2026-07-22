import 'package:flutter/material.dart';

/// Shared sizing policy for the authenticated application shell.
///
/// The shortest side is considered too: a phone in landscape should not gain a
/// dense desktop navigation merely because its width is larger than 600 px.
enum ShellLayout { narrowMobile, mobile, tablet, desktop }

extension ShellLayoutResolution on ShellLayout {
  bool get usesBottomNavigation =>
      this == ShellLayout.narrowMobile || this == ShellLayout.mobile;
  bool get usesExtendedRail => this == ShellLayout.desktop;

  static ShellLayout of(MediaQueryData mediaQuery) {
    final size = mediaQuery.size;
    final keyboardIsOpen = mediaQuery.viewInsets.bottom > 0;
    final usableHeight =
        size.height -
        mediaQuery.padding.vertical -
        mediaQuery.viewInsets.bottom;

    // Keyboard and a short landscape viewport need the same compact controls as
    // a phone; a rail would otherwise leave too little space for the content.
    if (keyboardIsOpen || usableHeight < 420) {
      return size.width < 360 ? ShellLayout.narrowMobile : ShellLayout.mobile;
    }
    if (size.width < 360) return ShellLayout.narrowMobile;
    if (size.width < 600) return ShellLayout.mobile;
    if (size.width < 1024) return ShellLayout.tablet;
    return ShellLayout.desktop;
  }

  static EdgeInsets contentPadding(
    MediaQueryData mediaQuery,
    ShellLayout layout,
  ) {
    final textScale = mediaQuery.textScaler.scale(1);
    final horizontal = switch (layout) {
      ShellLayout.narrowMobile => 8.0,
      ShellLayout.mobile => 12.0,
      ShellLayout.tablet => 12.0,
      ShellLayout.desktop => 20.0,
    };
    // Bigger text needs breathing room, but not a layout that becomes cramped.
    final vertical = textScale > 1.3 ? 8.0 : 12.0;
    return EdgeInsets.fromLTRB(horizontal, vertical, horizontal, vertical);
  }
}
