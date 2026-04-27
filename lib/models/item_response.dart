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
      itemId: json['item_id'] as int,
      // 명세서 변경: 'itemCode' → 'barcode'
      itemCode: json['barcode'] as String? ?? '',
      // 명세서 변경: 'itemName' → 'name'
      itemName: json['name'] as String,
      // 명세서 변경: 'itemPrice' → 'price'
      itemPrice: json['price'] as int,
      // 명세서에서 eventStatus 제거됨
      eventStatus: null,
      // 명세서 변경: 'itemCategory' → 'category'
      // /items/{barcode} 응답에는 category 없으므로 빈 문자열로 기본값 처리
      itemCategory: json['category'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'item_code': itemCode,
      'item_name': itemName,
      'item_price': itemPrice,
      'item_category': itemCategory,
      'event_status': eventStatus,
    };
  }
}
