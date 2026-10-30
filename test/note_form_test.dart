import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_vault/features/notes/note_form_screen.dart';

void main() {
  Future<void> openForm(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(builder: (_) => const NoteFormScreen()),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> pressBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  group('NoteFormScreen leave guard', () {
    testWidgets('leaves without asking when nothing changed', (tester) async {
      await openForm(tester);
      await pressBack(tester);

      expect(find.byType(NoteFormScreen), findsNothing);
      expect(find.text('Simpan perubahan?'), findsNothing);
    });

    testWidgets('asks before leaving with unsaved text', (tester) async {
      await openForm(tester);
      await tester.enterText(find.byType(TextFormField).first, 'List anime');
      await pressBack(tester);

      expect(find.text('Simpan perubahan?'), findsOneWidget);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(find.byType(NoteFormScreen), findsOneWidget);
      expect(find.text('List anime'), findsOneWidget);
    });

    testWidgets('discard closes the form', (tester) async {
      await openForm(tester);
      await tester.enterText(find.byType(TextFormField).first, 'List anime');
      await pressBack(tester);
      await tester.tap(find.text('Buang'));
      await tester.pumpAndSettle();

      expect(find.byType(NoteFormScreen), findsNothing);
    });

    testWidgets('save button still closes the form', (tester) async {
      await openForm(tester);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, 'List anime');
      await tester.enterText(fields.last, '1. Inuyasha');
      await tester.tap(find.byTooltip('Simpan'));
      await tester.pumpAndSettle();

      expect(find.byType(NoteFormScreen), findsNothing);
    });
  });
}
