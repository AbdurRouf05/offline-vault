import 'package:flutter_test/flutter_test.dart';
import 'package:offline_vault/features/notes/note_tags.dart';

const _note = '''## Sudah ditonton
1.Inuyasha⭐ #action #fantasy
5.konosuba ⭐ #isekai #comedy
7.tate no yuusha ⭐ #isekai #Action

## Top 5
1.konosuba

## Mau ditonton
2.one piece #action
9.karakai jouzu no Takagi-san√ #romance #comedy
email me@mail.com and C# are not tags''';

void main() {
  test('extractTags finds unique lowercased tags, ignores headings', () {
    expect(extractTags(_note), [
      'action',
      'comedy',
      'fantasy',
      'isekai',
      'romance',
    ]);
  });

  test('countTags counts lines per tag', () {
    final counts = countTags(_note);
    expect(counts['action'], 3);
    expect(counts['isekai'], 2);
    expect(counts['romance'], 1);
  });

  test('filterLinesByTag keeps matching lines under their headings', () {
    expect(filterLinesByTag(_note, 'comedy'), [
      '## Sudah ditonton',
      '5.konosuba ⭐ #isekai #comedy',
      '',
      '## Mau ditonton',
      '9.karakai jouzu no Takagi-san√ #romance #comedy',
    ]);
  });

  test('filterLinesByTag is case-insensitive and drops empty sections', () {
    final lines = filterLinesByTag(_note, 'ISEKAI');
    expect(lines, [
      '## Sudah ditonton',
      '5.konosuba ⭐ #isekai #comedy',
      '7.tate no yuusha ⭐ #isekai #Action',
    ]);
  });

  test('headings', () {
    expect(isHeading('## Top 5'), isTrue);
    expect(isHeading('#isekai'), isFalse);
    expect(headingText('## Top 5'), 'Top 5');
  });

  test('splitTags separates tags from text', () {
    expect(splitTags('5.konosuba ⭐ #isekai #comedy'), [
      (text: '5.konosuba ⭐ ', isTag: false),
      (text: '#isekai', isTag: true),
      (text: ' ', isTag: false),
      (text: '#comedy', isTag: true),
    ]);
  });
}
