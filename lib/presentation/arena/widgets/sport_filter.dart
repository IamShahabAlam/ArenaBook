import 'package:flutter/material.dart';

import '../../../app/config/arena_theme.dart';
import '../../../data/models/sport.dart';
import 'arena_widgets.dart';

/// All Courts + one segment per offered sport. `null` means all courts. Hidden when only one sport is offered.
class SportFilter extends StatelessWidget {
  const SportFilter({super.key, required this.selected, required this.onChanged, this.withAvatars = false, this.longLabels = false, this.gap = 0});

  final Sport? selected;
  final ValueChanged<Sport?> onChanged;
  final bool withAvatars; // dark icon circles, as on the dashboard
  final bool longLabels; // "Indoor Cricket" instead of "Cricket"
  final double gap; // space below; disappears with the filter

  @override
  Widget build(BuildContext context) {
    final sports = Sport.offered;
    if (sports.length < 2) return const SizedBox.shrink(); // nothing to filter
    final long = longLabels && sports.length <= 2; // long names only fit with two sports
    final c = context.arena;
    Widget? avatar(IconData icon, Color color) => withAvatars
        ? Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: c.avatarBackground, shape: BoxShape.circle),
            child: Icon(icon, size: 13, color: color),
          )
        : null;

    return Padding(
      padding: EdgeInsets.only(bottom: gap),
      child: ArenaSegmented<Sport?>(
        selected: selected,
        onChanged: onChanged,
        dense: !withAvatars,
        options: [
          SegmentOption(null, 'All Courts', leading: avatar(Icons.grid_view_rounded, c.cricketOnAvatar)),
          for (final s in sports) SegmentOption(s, long ? s.label : s.shortLabel, leading: avatar(s.symbol, s.onAvatar(c))),
        ],
      ),
    );
  }
}
