import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_vault/features/categories/categories_provider.dart';
import 'package:offline_vault/features/categories/category_list.dart';
import 'package:offline_vault/features/categories/category_widgets.dart';

class _FakeCategories extends CategoriesNotifier {
  _FakeCategories() : super(CategoryScope.notes);

  @override
  Future<List<String>> build() async => ['Umum', 'Pribadi'];

  @override
  Future<void> add(String name) async {
    state = AsyncData(addCategory(await future, name));
  }
}

void main() {
  Future<ValueNotifier<String>> pumpDropdown(WidgetTester tester) async {
    final selected = ValueNotifier('Umum');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [noteCategoriesProvider.overrideWith(_FakeCategories.new)],
        child: MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<String>(
              valueListenable: selected,
              builder: (context, value, _) => CategoryDropdown(
                scope: CategoryScope.notes,
                value: value,
                onChanged: (v) => selected.value = v,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return selected;
  }

  Future<void> chooseNewCategory(WidgetTester tester) async {
    await tester.tap(find.text('Umum'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+ Kategori baru').last);
    await tester.pumpAndSettle();
  }

  testWidgets('creates and selects a new category', (tester) async {
    final selected = await pumpDropdown(tester);
    await chooseNewCategory(tester);

    await tester.enterText(find.byType(TextField), 'Anime');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(selected.value, 'Anime');
    expect(find.text('Anime'), findsOneWidget);
  });

  testWidgets('cancel restores the previous category', (tester) async {
    final selected = await pumpDropdown(tester);
    await chooseNewCategory(tester);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(selected.value, 'Umum');
    expect(find.text('Umum'), findsOneWidget);
    expect(find.text('+ Kategori baru'), findsNothing);
  });

  testWidgets('duplicate name shows an error and keeps the dialog open', (
    tester,
  ) async {
    await pumpDropdown(tester);
    await chooseNewCategory(tester);

    await tester.enterText(find.byType(TextField), 'pribadi');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Kategori "pribadi" sudah ada.'), findsOneWidget);
  });
}
