import 'package:flutter/material.dart';

import '../../../app/config/arena_theme.dart';
import '../../../data/models/sport.dart';
import 'arena_widgets.dart';

/// All Courts / Cricket / Padel filter. `null` means all courts.
class SportFilter extends StatelessWidget {
  const SportFilter({super.key, required this.selected, required this.onChanged, this.withAvatars = false, this.longLabels = false});

  final Sport? selected;
  final ValueChanged<Sport?> onChanged;
  final bool withAvatars; // dark icon circles, as on the dashboard
  final bool longLabels; // "Indoor Cricket" instead of "Cricket"

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    Widget? avatar(IconData icon, Color color) => withAvatars
        ? Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: c.avatarBackground, shape: BoxShape.circle),
            child: Icon(icon, size: 13, color: color),
          )
        : null;

    return ArenaSegmented<Sport?>(
      selected: selected,
      onChanged: onChanged,
      dense: !withAvatars,
      options: [
        SegmentOption(null, 'All Courts', leading: avatar(Icons.grid_view_rounded, c.cricketOnAvatar)),
        for (final s in Sport.values) SegmentOption(s, longLabels ? s.label : s.shortLabel, leading: avatar(s.icon, s.onAvatar(c))),
      ],
    );
  }
}
