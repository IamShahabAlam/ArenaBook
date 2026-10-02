import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class ExpandableHtml extends StatefulWidget {
  const ExpandableHtml({
    super.key,
    required this.htmlData,
    this.style = const {},
    this.onLinkTap,
    this.maxLines = 3,
  });

  final String htmlData;
  final Map<String, Style> style;
  final OnTap? onLinkTap;
  final int maxLines;

  @override
  State<ExpandableHtml> createState() => _ExpandableHtmlState();
}

class _ExpandableHtmlState extends State<ExpandableHtml> {
  bool expanded = false;

  bool get _needsTruncation {
    final plainText = widget.htmlData.replaceAll(RegExp(r'<[^>]*>'), ' ').trim();
    final wordCount = plainText.isEmpty ? 0 : plainText.split(RegExp(r'\s+')).length;
    return wordCount > widget.maxLines * 8;
  }

  @override
  Widget build(BuildContext context) {
    final needsTruncation = _needsTruncation;
    final mergedStyle = Map<String, Style>.from(widget.style);
    if (!expanded && needsTruncation) {
      final bodyStyle = mergedStyle['body'] ?? Style();
      mergedStyle['body'] = bodyStyle.copyWith(maxLines: widget.maxLines, textOverflow: TextOverflow.ellipsis);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Html(data: widget.htmlData, onLinkTap: widget.onLinkTap, style: mergedStyle),
        if (needsTruncation)
          GestureDetector(
            onTap: () => setState(() => expanded = !expanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                expanded ? 'See less' : 'See more',
                style: const TextStyle(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }
}
