class ItemResponse {
  final int itemId;
  final String itemCode;
  final String itemName;
  final int itemPrice;
  final String? eventStatus;
  final String itemCategory;

  ItemResponse({
    required this.itemId,
    required this.itemCode,
    required this.itemName,
    required this.itemPrice,
    this.eventStatus,
    required this.itemCategory,
  });

  factory ItemResponse.fromJson(Map<String, dynamic> json) {
    return ItemResponse(
      itemId: json['itemId'] as int,
      itemCode: json['itemCode'] as String? ?? '',
      itemName: json['itemName'] as String,
      itemPrice: json['itemPrice'] as int,
      eventStatus: json['eventStatus'] as String?,
      itemCategory: json['itemCategory'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemCode': itemCode,
      'itemName': itemName,
      'itemPrice': itemPrice,
      'itemCategory': itemCategory,
      'eventStatus': eventStatus,
    };
  }
}
