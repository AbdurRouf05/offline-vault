/// Hashtag helpers for notes. A tag is `#word` (letters, digits, `_`, `-`)
/// inside a line, e.g. `1. Konosuba ⭐ #isekai #comedy`. A line that starts
/// with `#` followed by a space (`## Watched`) is a heading, not a tag.
library;

final _tagPattern = RegExp(
  r'(?<![\p{L}\p{N}_#])#([\p{L}\p{N}_-]+)',
  unicode: true,
);
final _headingPattern = RegExp(r'^#{1,6}\s+');

/// Unique tags in [content], lowercased, sorted alphabetically.
List<String> extractTags(String content) {
  final tags = {
    for (final m in _tagPattern.allMatches(content)) m.group(1)!.toLowerCase(),
  };
  return tags.toList()..sort();
}

/// Number of lines that carry each tag.
Map<String, int> countTags(String content) {
  final counts = <String, int>{};
  for (final line in content.split('\n')) {
    for (final tag in _lineTags(line)) {
      counts[tag] = (counts[tag] ?? 0) + 1;
    }
  }
  return counts;
}

bool isHeading(String line) => _headingPattern.hasMatch(line);

/// Heading text without the leading `#`s.
String headingText(String line) => line.replaceFirst(_headingPattern, '');

/// Lines tagged with [tag], each kept under its heading. Headings with no
/// matching lines are dropped.
List<String> filterLinesByTag(String content, String tag) {
  final wanted = tag.toLowerCase();
  final result = <String>[];
  String? pendingHeading;

  for (final line in content.split('\n')) {
    if (isHeading(line)) {
      pendingHeading = line;
    } else if (_lineTags(line).contains(wanted)) {
      if (pendingHeading != null) {
        if (result.isNotEmpty) result.add('');
        result.add(pendingHeading);
        pendingHeading = null;
      }
      result.add(line);
    }
  }
  return result;
}

/// Splits [line] into plain text and tag parts, for styling.
List<({String text, bool isTag})> splitTags(String line) {
  final parts = <({String text, bool isTag})>[];
  var last = 0;
  for (final m in _tagPattern.allMatches(line)) {
    if (m.start > last) {
      parts.add((text: line.substring(last, m.start), isTag: false));
    }
    parts.add((text: m.group(0)!, isTag: true));
    last = m.end;
  }
  if (last < line.length) {
    parts.add((text: line.substring(last), isTag: false));
  }
  return parts;
}

Set<String> _lineTags(String line) {
  if (isHeading(line)) return const {};
  return {
    for (final m in _tagPattern.allMatches(line)) m.group(1)!.toLowerCase(),
  };
}
