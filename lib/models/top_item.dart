class TopItem {
  final String itemId;
  final String itemCode;
  final String itemName;
  final int itemPrice;
  final String? eventStatus;
  final String itemCategory;
  final int totalSales;
  final int salesCount;

  TopItem({
    required this.itemId,
    required this.itemCode,
    required this.itemName,
    required this.itemPrice,
    this.eventStatus,
    required this.itemCategory,
    required this.totalSales,
    required this.salesCount,
  });

  factory TopItem.fromJson(Map<String, dynamic> json) {
    return TopItem(
      itemId: json['item_id'].toString(),
      itemCode: json['item_code'],
      itemName: json['item_name'],
      itemPrice: json['item_price'],
      eventStatus: json['event_status'],
      itemCategory: json['item_category'],
      totalSales: json['total_sales'],
      salesCount: json['sales_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'item_code': itemCode,
      'item_name': itemName,
      'item_price': itemPrice,
      'event_status': eventStatus,
      'item_category': itemCategory,
      'total_sales': totalSales,
      'sales_count': salesCount,
    };
  }
}
