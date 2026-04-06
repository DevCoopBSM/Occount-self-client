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
      // 명세서 변경: 'itemCode' → 'barcode' (without-barcode 응답에서는 항상 null)
      itemCode: json['barcode'] as String? ?? '',
      // 명세서 변경: 'itemName' → 'name'
      itemName: json['name'] as String,
      // 명세서 변경: 'itemPrice' → 'price'
      itemPrice: json['price'] as int,
      // 명세서에서 eventStatus 제거됨
      eventStatus: null,
      // 명세서: /items/without-barcode 응답에 category 없음 → 빈 문자열 기본값
      // /items (전체 목록) 응답에는 category 있음 — CategoryService에서 이 모델 재사용 시 채워짐
      itemCategory: json['category'] as String? ?? '',
    );
  }
}
