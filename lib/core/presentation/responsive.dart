import 'package:flutter/material.dart';

/// Sizing policy shared by the whole application.
///
/// The shell established this policy for navigation (SD-129); content screens,
/// forms and dialogs resolve against the very same thresholds so a viewport
/// never renders a compact navigation next to a desktop-only layout.
///
/// The shortest side is considered too: a phone in landscape should not gain a
/// dense desktop layout merely because its width is larger than 600 px.
enum AppLayout { narrowMobile, mobile, tablet, desktop }

extension AppLayoutResolution on AppLayout {
  /// One column, sheets instead of side panels, cards instead of table rows.
  bool get isCompact =>
      this == AppLayout.narrowMobile || this == AppLayout.mobile;

  /// The tightest viewport we support (320 px class devices).
  bool get isNarrow => this == AppLayout.narrowMobile;

  bool get isTablet => this == AppLayout.tablet;
  bool get isDesktop => this == AppLayout.desktop;

  bool get usesBottomNavigation => isCompact;
  bool get usesExtendedRail => this == AppLayout.desktop;

  static AppLayout of(MediaQueryData mediaQuery) {
    final size = mediaQuery.size;
    final keyboardIsOpen = mediaQuery.viewInsets.bottom > 0;
    final usableHeight =
        size.height -
        mediaQuery.padding.vertical -
        mediaQuery.viewInsets.bottom;

    // Keyboard and a short landscape viewport need the same compact controls as
    // a phone; a rail would otherwise leave too little space for the content.
    if (keyboardIsOpen || usableHeight < 420) {
      return size.width < 360 ? AppLayout.narrowMobile : AppLayout.mobile;
    }
    if (size.width < 360) return AppLayout.narrowMobile;
    if (size.width < 600) return AppLayout.mobile;
    if (size.width < 1024) return AppLayout.tablet;
    return AppLayout.desktop;
  }

  /// Resolves the policy from a [BoxConstraints] width instead of the viewport.
  ///
  /// Useful inside a `LayoutBuilder` when a subtree only owns part of the
  /// screen (a workspace next to a rail, a card inside a grid).
  static AppLayout ofWidth(double width) {
    if (width < 360) return AppLayout.narrowMobile;
    if (width < 600) return AppLayout.mobile;
    if (width < 1024) return AppLayout.tablet;
    return AppLayout.desktop;
  }

  /// Horizontal breathing room a full-width page should keep at its edges.
  ///
  /// Desktop pages were written with a 28 px gutter; on a 320 px screen that
  /// spends 17 % of the viewport on empty margins, so it tightens as the
  /// viewport shrinks.
  double get pageGutter => switch (this) {
    AppLayout.narrowMobile => 12.0,
    AppLayout.mobile => 16.0,
    AppLayout.tablet => 20.0,
    AppLayout.desktop => 28.0,
  };

  static EdgeInsets contentPadding(
    MediaQueryData mediaQuery,
    AppLayout layout,
  ) {
    final textScale = mediaQuery.textScaler.scale(1);
    final horizontal = switch (layout) {
      AppLayout.narrowMobile => 8.0,
      AppLayout.mobile => 12.0,
      AppLayout.tablet => 12.0,
      AppLayout.desktop => 20.0,
    };
    // Bigger text needs breathing room, but not a layout that becomes cramped.
    final vertical = textScale > 1.3 ? 8.0 : 12.0;
    return EdgeInsets.fromLTRB(horizontal, vertical, horizontal, vertical);
  }
}

extension ResponsiveContext on BuildContext {
  /// The layout policy for the current viewport.
  AppLayout get appLayout => AppLayoutResolution.of(MediaQuery.of(this));

  /// Shorthand for the most common branch: one column or several.
  bool get isCompactLayout => appLayout.isCompact;

  /// Page padding whose horizontal gutter follows the viewport.
  ///
  /// Replaces the hard-coded 28 px gutter the desktop pages were written with.
  EdgeInsets pageInsets({double top = 0, double bottom = 0}) {
    final gutter = appLayout.pageGutter;
    return EdgeInsets.fromLTRB(gutter, top, gutter, bottom);
  }
}
