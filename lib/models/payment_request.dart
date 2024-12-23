import '../models/cart_item.dart';

class PaymentRequest {
  final String type;
  final UserInfo userInfo;
  final PaymentInfo payment;

  PaymentRequest({
    required this.type,
    required this.userInfo,
    required this.payment,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'userInfo': userInfo.toJson(),
        'payment': payment.toJson(),
      };
}

class UserInfo {
  final String id;

  UserInfo({required this.id});

  Map<String, dynamic> toJson() => {'id': id};
}

class PaymentInfo {
  final List<PaymentItem> items;
  final int totalAmount;

  PaymentInfo({
    required this.items,
    required this.totalAmount,
  });

  Map<String, dynamic> toJson() => {
        'items': items.map((item) => item.toJson()).toList(),
        'totalAmount': totalAmount,
      };
}

class PaymentItem {
  final int itemId;
  final String itemName;
  final int itemPrice;
  final int quantity;
  final int totalPrice;

  PaymentItem({
    required this.itemId,
    required this.itemName,
    required this.itemPrice,
    required this.quantity,
    required this.totalPrice,
  });

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'itemName': itemName,
        'itemPrice': itemPrice,
        'quantity': quantity,
        'totalPrice': totalPrice,
      };

  factory PaymentItem.fromCartItem(CartItem item) {
    return PaymentItem(
      itemId: item.itemId,
      itemName: item.itemName,
      itemPrice: item.itemPrice,
      quantity: item.quantity,
      totalPrice: item.totalPrice,
    );
  }
}
