import '../models/item_response.dart';
import '../models/non_barcode_item_response.dart';

class CartItem {
  final int itemId;
  final String itemCode;
  final String itemName;
  final int itemPrice;
  final String? eventStatus;
  final String itemCategory;
  int quantity;

  CartItem({
    required this.itemId,
    required this.itemCode,
    required this.itemName,
    required this.itemPrice,
    this.eventStatus,
    required this.itemCategory,
    this.quantity = 1,
  });

  factory CartItem.fromNonBarcodeResponse(NonBarcodeItemResponse response) {
    return CartItem(
      itemId: response.itemId,
      itemCode: response.itemCode,
      itemName: response.itemName,
      itemPrice: response.itemPrice,
      eventStatus: response.eventStatus,
      itemCategory: response.itemCategory,
    );
  }

  factory CartItem.fromItemResponse(ItemResponse response) {
    return CartItem(
      itemId: response.itemId,
      itemCode: response.itemCode,
      itemName: response.itemName,
      itemPrice: response.itemPrice,
      eventStatus: response.eventStatus,
      itemCategory: response.itemCategory,
    );
  }

  factory CartItem.fromNonBarcodeItem(NonBarcodeItemResponse item) {
    return CartItem(
      itemId: item.itemId,
      itemCode: item.itemCode,
      itemName: item.itemName,
      itemPrice: item.itemPrice,
      itemCategory: item.itemCategory,
    );
  }

  int get totalPrice => itemPrice * quantity;

  CartItem copyWith({
    int? itemId,
    String? itemCode,
    String? itemName,
    int? itemPrice,
    String? eventStatus,
    String? itemCategory,
    int? quantity,
  }) {
    return CartItem(
      itemId: itemId ?? this.itemId,
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      itemPrice: itemPrice ?? this.itemPrice,
      eventStatus: eventStatus ?? this.eventStatus,
      itemCategory: itemCategory ?? this.itemCategory,
      quantity: quantity ?? this.quantity,
    );
  }
}
