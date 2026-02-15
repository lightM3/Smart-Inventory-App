class CategoryCount {
  final String category;
  final int totalQuantity;
  final int productCount;

  CategoryCount({
    required this.category,
    required this.totalQuantity,
    required this.productCount,
  });
}

class DailyMovement {
  final DateTime date;
  final int totalIn;
  final int totalOut;

  DailyMovement({
    required this.date,
    required this.totalIn,
    required this.totalOut,
  });
}

class TopProduct {
  final int productId;
  final String productTitle;
  final String? productBarcode;
  final String? productImagePath;
  final int movementCount;

  TopProduct({
    required this.productId,
    required this.productTitle,
    this.productBarcode,
    this.productImagePath,
    required this.movementCount,
  });
}
