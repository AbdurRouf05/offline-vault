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
}
