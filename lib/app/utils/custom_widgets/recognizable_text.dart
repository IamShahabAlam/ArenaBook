// ignore_for_file: must_be_immutable

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../custom_functions/logger.dart';
import 'custom_toast.dart';

class RecognizableTextWidget extends StatelessWidget {
  RecognizableTextWidget({super.key, required this.text, this.textStyle});

  final String text;
  TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    textStyle ??= GoogleFonts.robotoFlex(color: context.theme.colorScheme.onSecondary);
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: text));
        MyToast.snackToast('Copied to Clipboard', 2);
      },
      child: SelectableText.rich(
        TextSpan(children: _buildTextSpans(text), style: textStyle),
      ),
    );
  }

  List<TextSpan> _buildTextSpans(String text) {
    final List<TextSpan> textSpans = [];
// Link pattern
    final RegExp linkRegExp =
        RegExp(r'\b((https?|HTTP|HTTPS):\/\/)?(?![\w.%+-]+@)[\w-]+(\.[\w-]+)+([\/\w.,?^=%&:~+#-]*[\w@?^=%&/~+#-])?', caseSensitive: false);
    // Email pattern
    final RegExp emailRegExp = RegExp(
      r'[\w.%+-]+@[\w.-]+\.[\w]{2,4}',
    );
    // Phone pattern
    final RegExp phoneRegExp = RegExp(
      r'[\d-]{9,}',
    );
    // Combined pattern for all three
    final RegExp combinedRegExp = RegExp(
      r'\b((https?|HTTP|HTTPS):\/\/)?(?![\w.%+-]+@)[\w-]+(\.[\w-]+)+([\/\w.,?^=%&:~+#-]*[\w@?^=%&/~+#-])?|'
      r'[\w.%+-]+@[\w.-]+\.[\w]{2,4}|' // Email pattern
      r'[\d-]{9,}', // Phone pattern
      // caseSensitive: false
    );
    text.splitMapJoin(
      combinedRegExp,
      onMatch: (Match match) {
        // if text part is matched with our pattern
        // this method is ommited and add new TextSpan to the list.
        textSpans.add(
          TextSpan(
            text: match[0],
            style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                if (emailRegExp.hasMatch(match[0] ?? '')) {
                  final Uri emailLaunchUri = Uri(
                    scheme: 'mailto',
                    path: '${match[0]}',
                  );
                  await launchUrl(emailLaunchUri);
                } else if (linkRegExp.hasMatch(match[0] ?? '')) {
                  var url = match[0] ?? '';
                  if (!url.startsWith(RegExp(r'https?://', caseSensitive: false))) {
                    url = 'http://$url';
                  }
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    Logger.logs('Could not launch $url');
                  }
                  // await launchUrl(Uri.parse(match[0]!), mode: LaunchMode.externalApplication);
                } else if (phoneRegExp.hasMatch(match[0] ?? '')) {
                  final Uri phoneLaunchUri = Uri(
                    scheme: 'tel',
                    path: '${match[0]}',
                  );
                  await launchUrl(phoneLaunchUri);
                }
              },
          ),
        );
        return '';
      },
      onNonMatch: (String nonMatch) {
        // if text part is not matched with our pattern
        // this method is ommited and add new TextSpan to the list
        // to combine all text part with different style
        textSpans.add(TextSpan(text: nonMatch));
        return nonMatch;
      },
    );

    return textSpans;
  }
}

// Credits:
// https://medium.com/@abied.abiad/how-to-detect-urls-phone-numbers-and-emails-in-a-text-in-your-flutter-app-a39eef72eacc

class ExpandableRecognizableText extends StatefulWidget {
  const ExpandableRecognizableText({super.key, required this.text, this.textStyle, this.maxLines = 3});

  final String text;
  final TextStyle? textStyle;
  final int maxLines;

  @override
  State<ExpandableRecognizableText> createState() => _ExpandableRecognizableTextState();
}

class _ExpandableRecognizableTextState extends State<ExpandableRecognizableText> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final style = widget.textStyle ?? GoogleFonts.robotoFlex(color: context.theme.colorScheme.onSecondary);

    return LayoutBuilder(builder: (context, constraints) {
      final textPainter = TextPainter(
        text: TextSpan(text: widget.text, style: style),
        maxLines: widget.maxLines,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: constraints.maxWidth);

      if (!textPainter.didExceedMaxLines) {
        return RecognizableTextWidget(text: widget.text, textStyle: style);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          expanded
              ? RecognizableTextWidget(text: widget.text, textStyle: style)
              : Text(widget.text, maxLines: widget.maxLines, overflow: TextOverflow.ellipsis, style: style),
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
    });
  }
}
