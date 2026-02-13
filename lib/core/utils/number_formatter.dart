import 'package:intl/intl.dart';

class NumberFormatter {
  NumberFormatter._();

  /// 1240 -> "1,240"
  static String formatCount(int number) {
    return NumberFormat('#,###').format(number);
  }

  /// 15400 -> "15.4k", 1500000 -> "1.5M"
  static String formatCompact(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}
