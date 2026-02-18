import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/product_model.dart';
import '../models/stock_movement_model.dart';
import '../models/category_model.dart';
import '../models/profile_model.dart';

class IsarDb {
  static late Isar instance;

  static Future<void> initialize() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      instance = await Isar.open(
        [ProductSchema, StockMovementSchema, CategorySchema, ProfileSchema],
        directory: dir.path,
        inspector: true, // DevTools'da Isar sekmesi açılması için
      );
    } else {
      instance = Isar.getInstance()!;
    }
  }
}
