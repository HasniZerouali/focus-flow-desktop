import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/app_database.dart';
import '../storage/models.dart';
import 'database_provider.dart';

class CategoriesNotifier extends StateNotifier<AsyncValue<List<CategoryModel>>> {
  final AppDatabase _db;

  CategoriesNotifier(this._db) : super(const AsyncValue.loading()) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      state = const AsyncValue.loading();
      final cats = await _db.getAllCategories();
      state = AsyncValue.data(cats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCategory(CategoryModel category) async {
    try {
      await _db.insertCategory(category);
      await loadCategories();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final categoriesProvider = StateNotifierProvider<CategoriesNotifier, AsyncValue<List<CategoryModel>>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return CategoriesNotifier(db);
});
