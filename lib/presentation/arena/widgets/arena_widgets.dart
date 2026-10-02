import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/config/arena_theme.dart';
import '../../../data/models/sport.dart';

/// Visual identity per sport (icons + token colours).
extension SportVisuals on Sport {
  IconData get icon => switch (this) {
    Sport.cricket => Icons.sports_cricket_rounded,
    Sport.padel => Icons.sports_tennis_rounded,
  };

  Color fill(ArenaColors c) => switch (this) {
    Sport.cricket => c.cricket,
    Sport.padel => c.padel,
  };

  Color text(ArenaColors c) => switch (this) {
    Sport.cricket => c.cricketText,
    Sport.padel => c.padelText,
  };

  Color onAvatar(ArenaColors c) => switch (this) {
    Sport.cricket => c.cricketOnAvatar,
    Sport.padel => c.padelOnAvatar,
  };
}

/// Rounded card used everywhere (the prototype's `.glass-card`).
class ArenaCard extends StatelessWidget {
  const ArenaCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.borderColor, this.gradient, this.onTap, this.radius = 18});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor ?? c.border),
    );
    return Material(
      color: gradient == null ? c.surface : Colors.transparent,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: gradient == null ? null : BoxDecoration(gradient: gradient),
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }

  /// Soft accent gradient used by the banner cards (emerald / amber tint into the surface).
  static Gradient tint(BuildContext context, Color accent) {
    final c = context.arena;
    return LinearGradient(colors: [Color.alphaBlend(accent.withValues(alpha: 0.14), c.surface), c.surface, c.surface]);
  }
}

/// Sport icon on a dark circle; stays dark in light mode for contrast (spec).
class SportAvatar extends StatelessWidget {
  const SportAvatar({super.key, required this.sport, this.size = 36, this.bordered = false});

  final Sport sport;
  final double size;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.avatarBackground,
        shape: BoxShape.circle,
        border: Border.all(color: bordered ? sport.fill(c).withValues(alpha: 0.45) : Colors.transparent),
      ),
      child: Icon(sport.icon, size: size * 0.5, color: sport.onAvatar(c)),
    );
  }
}

class SegmentOption<T> {
  const SegmentOption(this.value, this.label, {this.leading});
  final T value;
  final String label;
  final Widget? leading;
}

/// Pill segmented control (sport filters, timeline toggle, slot mode).
class ArenaSegmented<T> extends StatelessWidget {
  const ArenaSegmented({super.key, required this.options, required this.selected, required this.onChanged, this.dense = false});

  final List<SegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(dense ? 12 : 16),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: _Segment(option: o, active: o.value == selected, dense: dense, onTap: () => onChanged(o.value)),
            ),
        ],
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({required this.option, required this.active, required this.dense, required this.onTap});

  final SegmentOption<T> option;
  final bool active;
  final bool dense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    final radius = BorderRadius.circular(dense ? 9 : 12);
    return Semantics(
      selected: active,
      button: true,
      child: Material(
        color: active ? c.cricket : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: dense ? 7 : 8, horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (option.leading != null) ...[option.leading!, const SizedBox(width: 6)],
                Flexible(
                  child: Text(
                    option.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelMedium?.copyWith(color: active ? c.onAccent : c.textSecondary, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Emerald → lime gradient call-to-action.
class GradientButton extends StatelessWidget {
  const GradientButton({super.key, required this.label, required this.onPressed, this.icon, this.expanded = true, this.compact = false, this.loading = false});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final bool compact;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    final radius = BorderRadius.circular(compact ? 12 : 16);
    final enabled = onPressed != null && !loading;
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: ArenaColors.ctaGradient,
          borderRadius: radius,
          boxShadow: [BoxShadow(color: ArenaColors.emerald.withValues(alpha: 0.28), blurRadius: 18)],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: enabled ? onPressed : null,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 18, vertical: compact ? 9 : 15),
              child: Row(
                mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (loading)
                    SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2, color: c.onAccent))
                  else if (icon != null)
                    Icon(icon, size: compact ? 16 : 18, color: c.onAccent),
                  if (loading || icon != null) const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: (compact ? context.text.labelMedium : context.text.titleMedium)?.copyWith(color: c.onAccent, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum SoftTone { neutral, success, warning, danger, info }

/// Low-emphasis tinted button (Invoice, Repeat, Edit, Cancel, Mark Paid ...).
class SoftButton extends StatelessWidget {
  const SoftButton({super.key, required this.onPressed, this.label, this.icon, this.tone = SoftTone.neutral, this.solid = false, this.tooltip});

  final VoidCallback? onPressed;
  final String? label;
  final IconData? icon;
  final SoftTone tone;
  final bool solid; // filled with the tone colour (e.g. the primary "Mark Paid")
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    final (fill, fg) = switch (tone) {
      SoftTone.neutral => (c.textSecondary, c.textPrimary),
      SoftTone.success => (c.cricket, c.cricketText),
      SoftTone.warning => (c.warning, c.warningText),
      SoftTone.danger => (c.danger, c.dangerText),
      SoftTone.info => (c.padel, c.padelText),
    };
    final background = solid ? fill : (tone == SoftTone.neutral ? c.surfaceMuted : fill.withValues(alpha: 0.12));
    final foreground = solid ? (tone == SoftTone.danger || tone == SoftTone.info ? Colors.white : c.onAccent) : fg;
    final border = solid ? fill : (tone == SoftTone.neutral ? c.border : fill.withValues(alpha: 0.4));
    final radius = BorderRadius.circular(12);

    Widget button = Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: border),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: label == null ? 11 : 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) Icon(icon, size: 15, color: foreground),
              if (icon != null && label != null) const SizedBox(width: 6),
              if (label != null)
                Flexible(
                  child: Text(
                    label!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelMedium?.copyWith(color: foreground, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (tooltip != null) button = Tooltip(message: tooltip!, child: button);
    return button;
  }
}

/// Square icon button used in the header.
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({super.key, required this.icon, required this.onPressed, required this.tooltip, this.accent = false});

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    final radius = BorderRadius.circular(12);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: accent ? c.cricket.withValues(alpha: 0.12) : c.surfaceMuted,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: accent ? c.cricket.withValues(alpha: 0.4) : c.border),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onPressed,
          child: SizedBox.square(dimension: 40, child: Icon(icon, size: 19, color: accent ? c.cricketText : c.textPrimary)),
        ),
      ),
    );
  }
}

/// Small pill label (status badges, "New Entry", "Editing").
class ArenaBadge extends StatelessWidget {
  const ArenaBadge({super.key, required this.label, required this.color, this.textColor});

  final String label;
  final Color color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.text.labelSmall?.copyWith(color: textColor ?? color, fontWeight: FontWeight.w800, letterSpacing: 0.3),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, required this.icon, this.iconColor, this.trailing});

  final String title;
  final IconData icon;
  final Color? iconColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor ?? c.cricketText),
        const SizedBox(width: 6),
        Expanded(
          child: Text(title.toUpperCase(), style: context.text.labelSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.8)),
        ),
        ?trailing,
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.icon = Icons.inbox_outlined, this.title, this.action});

  final String message;
  final String? title;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    return ArenaCard(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: c.cricket.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: c.cricketText, size: 22),
          ),
          const SizedBox(height: 10),
          if (title != null) Text(title!, style: context.text.titleSmall, textAlign: TextAlign.center),
          Text(
            message,
            style: context.text.bodySmall?.copyWith(color: c.textMuted),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}

/// Label above a form field.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: context.text.labelMedium?.copyWith(color: context.arena.textSecondary)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
