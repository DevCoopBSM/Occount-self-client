import '../models/cart_item.dart';

// 명세서 변경:
// - CHARGE 타입 제거 (PAYMENT, MIXED만 유지)
// - userInfo 필드 제거 (토큰 기반 인증으로 서버가 사용자 식별)
// - charge 필드 제거 (포인트 충전 기능 분리됨)
enum PaymentType {
  PAYMENT, // 포인트 단독 결제
  MIXED;   // 포인트 + 카드 혼합 결제

  @override
  String toString() => name;
}

class PaymentRequest {
  final PaymentType type;
  final PaymentInfo payment;

  PaymentRequest({
    required this.type,
    required this.payment,
  });

  Map<String, dynamic> toJson() {
    // 명세서 요청 구조: type + payment만 포함 (userInfo, charge 제거)
    return {
      'type': type.toString(),
      'payment': payment.toJson(),
    };
  }
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
        'total_amount': totalAmount,
      };
}

class PaymentItem {
  // 명세서 변경: itemId가 String 타입 (다른 API의 Long/int와 다름)
  final String itemId;
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
        // 명세서: itemId는 반드시 String으로 직렬화
        'item_id': itemId,
        'item_name': itemName,
        'item_price': itemPrice,
        'quantity': quantity,
        'total_price': totalPrice,
      };

  factory PaymentItem.fromCartItem(CartItem item) {
    return PaymentItem(
      // 명세서: itemId를 String으로 변환 (CartItem.itemId는 int)
      itemId: item.itemId.toString(),
      itemName: item.itemName,
      itemPrice: item.itemPrice,
      quantity: item.quantity,
      totalPrice: item.totalPrice,
    );
  }
}
