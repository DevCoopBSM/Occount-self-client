class Category {
  final int itemId;
  final String itemCode;
  final String itemName;
  final int itemPrice;
  final String? eventStatus;

  Category({
    required this.itemId,
    required this.itemCode,
    required this.itemName,
    required this.itemPrice,
    this.eventStatus,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      itemId: json['itemId'] as int,
      itemCode: json['itemCode'] as String,
      itemName: json['itemName'] as String,
      itemPrice: json['itemPrice'] as int,
      eventStatus: json['eventStatus'] as String?,
    );
  }
}
