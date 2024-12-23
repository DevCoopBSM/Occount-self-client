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
      itemId: json['itemId'].toString(),
      itemCode: json['itemCode'],
      itemName: json['itemName'],
      itemPrice: json['itemPrice'],
      eventStatus: json['eventStatus'],
      itemCategory: json['itemCategory'],
      totalSales: json['totalSales'],
      salesCount: json['salesCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemCode': itemCode,
      'itemName': itemName,
      'itemPrice': itemPrice,
      'eventStatus': eventStatus,
      'itemCategory': itemCategory,
      'totalSales': totalSales,
      'salesCount': salesCount,
    };
  }
}
