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
      itemId: json['item_id'] as int,
      itemCode: json['item_code'] as String,
      itemName: json['item_name'] as String,
      itemPrice: json['item_price'] as int,
      eventStatus: json['event_status'] as String?,
    );
  }
}
