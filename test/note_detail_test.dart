import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_vault/features/notes/note_detail_screen.dart';
import 'package:offline_vault/features/notes/note_form_screen.dart';
import 'package:offline_vault/features/notes/note_item.dart';

void main() {
  final note = NoteItem(
    id: 'n1',
    title: 'List anime',
    content: '1.Inuyasha⭐\n2.highschool dxd\n3.boku no Hero academia ⭐',
    category: 'Pribadi',
    createdAt: DateTime(2026, 10, 30),
    updatedAt: DateTime(2026, 10, 30),
  );

  Future<void> openDetail(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: NoteDetailScreen(note: note)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the note read-only', (tester) async {
    await openDetail(tester);

    expect(find.text('List anime'), findsOneWidget);
    expect(find.textContaining('2.highschool dxd'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('edit button opens the form with the note', (tester) async {
    await openDetail(tester);
    await tester.tap(find.byTooltip('Ubah'));
    await tester.pumpAndSettle();

    expect(find.byType(NoteFormScreen), findsOneWidget);
    expect(find.text('List anime'), findsWidgets);
  });

  testWidgets('tag chips filter lines and keep headings', (tester) async {
    final tagged = NoteItem(
      id: 'n2',
      title: 'Anime',
      content:
          '## Sudah ditonton\n1.Inuyasha⭐ #action\n2.konosuba #comedy\n'
          '\n## Mau ditonton\n9.takagi-san #comedy',
      category: 'Anime',
      createdAt: DateTime(2026, 10, 30),
      updatedAt: DateTime(2026, 10, 30),
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: NoteDetailScreen(note: tagged)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('#comedy (2)'), findsOneWidget);
    expect(find.textContaining('Inuyasha'), findsOneWidget);

    await tester.tap(find.text('#comedy (2)'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Inuyasha'), findsNothing);
    expect(find.textContaining('konosuba'), findsOneWidget);
    expect(find.textContaining('Mau ditonton'), findsOneWidget);
    expect(find.textContaining('## '), findsNothing);

    await tester.tap(find.text('Semua'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Inuyasha'), findsOneWidget);
  });
}
