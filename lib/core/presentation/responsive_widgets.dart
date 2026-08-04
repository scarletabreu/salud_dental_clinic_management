import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive.dart';

/// An [AlertDialog] whose width is a preference, not a requirement.
///
/// Dialogs used to hard-code their width (380, 480, 510 px), which cut content
/// off on phones. Here the preferred width is only honoured while it fits; the
/// dialog also trims its inset on compact viewports so a 320 px screen still
/// gets a usable content box, and the body scrolls instead of overflowing when
/// the keyboard is open or the text is scaled up.
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    this.title,
    required this.content,
    this.actions = const [],
    this.preferredWidth = 480,
    this.maxHeight = 620,
    this.backgroundColor,
    this.shape,
    this.scrollable = true,
    this.actionsPadding,
  });

  final Widget? title;
  final Widget content;
  final List<Widget> actions;

  /// Width used when the viewport can afford it.
  final double preferredWidth;

  /// Cap on the content box height.
  ///
  /// `AlertDialog` never overflows — it bounds its content to the viewport —
  /// but on a tall screen that bound is the whole screen, and a form grew to
  /// 1200 px of unbroken fields that nobody can scan. Past this height the
  /// content scrolls instead of stretching. The cap is only ever lowered by
  /// the viewport, never raised above it.
  final double maxHeight;

  final Color? backgroundColor;
  final ShapeBorder? shape;

  /// Set to `false` when [content] already provides its own scrolling.
  final bool scrollable;

  final EdgeInsetsGeometry? actionsPadding;

  /// Horizontal padding [AlertDialog] applies around its content.
  static const double _contentInset = 48;

  /// Rough vertical budget for the dialog's own title and action rows.
  static const double _altoTituloYAcciones = 140;

  /// Identifies the sized content box, so tests can assert on it directly.
  static const Key contentKey = ValueKey('app-dialog-content');

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final layout = AppLayoutResolution.of(mediaQuery);
    final inset = layout.isCompact ? 16.0 : 40.0;

    final available = mediaQuery.size.width - inset * 2 - _contentInset;
    final width = math.max(0.0, math.min(preferredWidth, available));

    // Lo que queda de alto una vez descontados los insets, el título y las
    // acciones. Sobre pantallas bajas manda el viewport; sobre altas, el tope.
    final alturaLibre = mediaQuery.size.height - 48 - _altoTituloYAcciones;
    final alto = math.max(120.0, math.min(maxHeight, alturaLibre));

    return AlertDialog(
      backgroundColor: backgroundColor,
      shape:
          shape ??
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(horizontal: inset, vertical: 24),
      title: title,
      // `AlertDialog` hands its content a bounded height, so a scroll view here
      // is enough to survive the keyboard and enlarged text.
      content: ConstrainedBox(
        key: contentKey,
        constraints: BoxConstraints(
          minWidth: width,
          maxWidth: width,
          maxHeight: alto,
        ),
        child: scrollable ? SingleChildScrollView(child: content) : content,
      ),
      actions: actions.isEmpty ? null : actions,
      actionsPadding: actionsPadding,
      actionsOverflowButtonSpacing: 8,
    );
  }
}

/// Lays fields out side by side when there is room and stacks them otherwise.
///
/// Every child gets an equal share of the row; on compact viewports the row
/// becomes a single column, which is what a form needs on a phone.
class AppFormRow extends StatelessWidget {
  const AppFormRow({
    super.key,
    required this.children,
    this.spacing = 12,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final List<Widget> children;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // A row only pays off once each field keeps a workable width; below
        // that the fields turn into unreadable slivers.
        final fitsSideBySide =
            constraints.maxWidth.isFinite &&
            constraints.maxWidth / children.length >= 180 &&
            !AppLayoutResolution.of(MediaQuery.of(context)).isCompact;

        if (!fitsSideBySide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: spacing),
                children[i],
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: crossAxisAlignment,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(width: spacing),
              Expanded(child: children[i]),
            ],
          ],
        );
      },
    );
  }
}
