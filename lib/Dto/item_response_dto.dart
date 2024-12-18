class ItemResponseDto {
  final String itemName;
  final int itemPrice;
  final String itemId;
  int quantity;
  final String type;

  ItemResponseDto({
    required this.itemName,
    required this.itemPrice,
    required this.itemId,
    required this.quantity,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      'itemPrice': itemPrice,
      'itemId': itemId,
      'quantity': quantity,
      'type': type,
    };
  }

  factory ItemResponseDto.fromJson(Map<String, dynamic> json) {
    return ItemResponseDto(
      itemName: json['itemName'] as String,
      itemPrice: json['itemPrice'] as int,
      itemId: json['itemId'] as String,
      quantity: json['quantity'] as int,
      type: json['type'] as String,
    );
  }
}
