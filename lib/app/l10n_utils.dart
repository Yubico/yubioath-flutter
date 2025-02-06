import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Creates [RichText] from [text] where the keys of [urls] are replaced
/// with clickable links.
RichText injectLinksInText(String text, Map<String, Uri> urls,
    {TextStyle? textStyle, TextStyle? linkStyle}) {
  final keys = urls.keys.toList();
  // Split text by keys and keep the keys
  final pattern =
      RegExp(r'(?=(' + keys.join('|') + r'))|(?<=(' + keys.join('|') + r'))');
  final parts = text.split(pattern);

  List<TextSpan> spans = [];
  int index = 0;
  for (var part in parts) {
    if (keys.contains(part)) {
      spans.add(
        TextSpan(
          text: part,
          style: linkStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              await launchUrl(urls[part]!,
                  mode: LaunchMode.externalApplication);
            },
          children: [
            if (index == parts.length - 1)
              // without this the recognizer takes over whole row
              TextSpan(text: ' ')
          ],
        ),
      );
    } else {
      spans.add(TextSpan(text: part));
    }
    index += 1;
  }
  return RichText(
    text: TextSpan(
      style: textStyle,
      children: spans,
    ),
  );
}
