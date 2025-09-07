import 'package:hive_flutter/hive_flutter.dart';

class HiveBoxes {
  static const history = 'history_box';
  static const favorites = 'favorites_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(history);
    await Hive.openBox<Map>(favorites);
  }
}
