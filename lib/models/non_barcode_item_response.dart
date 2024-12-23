class NonBarcodeItemResponse {
  final int itemId;
  final String itemCode;
  final String itemName;
  final int itemPrice;
  final String? eventStatus;
  final String itemCategory;

  NonBarcodeItemResponse({
    required this.itemId,
    required this.itemCode,
    required this.itemName,
    required this.itemPrice,
    this.eventStatus,
    required this.itemCategory,
  });

  factory NonBarcodeItemResponse.fromJson(Map<String, dynamic> json) {
    return NonBarcodeItemResponse(
      itemId: json['itemId'] as int,
      itemCode: json['itemCode'] as String? ?? '',
      itemName: json['itemName'] as String,
      itemPrice: json['itemPrice'] as int,
      eventStatus: json['eventStatus'] as String?,
      itemCategory: json['itemCategory'] as String,
    );
  }
}
