import '../models/cart_item.dart';

enum PaymentType {
  PAYMENT,
  CHARGE,
  MIXED;

  @override
  String toString() => name;
}

class PaymentRequest {
  final PaymentType type;
  final UserInfo userInfo;
  final PaymentInfo? payment;
  final ChargeInfo? charge;

  PaymentRequest({
    required this.type,
    required this.userInfo,
    this.payment,
    this.charge,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'type': type.toString(),
      'userInfo': userInfo.toJson(),
    };

    if (payment != null) {
      json['payment'] = payment!.toJson();
    }

    if (charge != null) {
      json['charge'] = charge!.toJson();
    }

    return json;
  }

  PaymentRequest copyWith({
    PaymentType? type,
    UserInfo? userInfo,
    PaymentInfo? payment,
    ChargeInfo? charge,
  }) {
    return PaymentRequest(
      type: type ?? this.type,
      userInfo: userInfo ?? this.userInfo,
      payment: payment ?? this.payment,
      charge: charge ?? this.charge,
    );
  }
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

class ChargeInfo {
  final int amount;
  final String method;

  ChargeInfo({
    required this.amount,
    this.method = 'CARD',
  });

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'method': method,
      };
}
