// 명세서: POST /orders — 결제 실행 전 반드시 주문 생성 필요
// 요청 구조:
// {
//   "orderInfos": [{
//     "itemId": 1,
//     "itemName": "아메리카노",
//     "itemPrice": 3000,
//     "quantity": 2
//   }],
//   "totalAmount": 6000,
//   "kioskId": "KIOSK_001"
// }
class OrderRequest {
  final List<OrderItem> orderInfos;
  final int totalAmount;
  final String kioskId;

  OrderRequest({
    required this.orderInfos,
    required this.totalAmount,
    required this.kioskId,
  });

  Map<String, dynamic> toJson() {
    return {
      'order_infos': orderInfos.map((e) => e.toJson()).toList(),
      'total_amount': totalAmount,
      'kiosk_id': int.tryParse(kioskId) ?? kioskId,
    };
  }
}

class OrderItem {
  final int itemId;
  final String itemName;
  final int itemPrice;
  final int quantity;

  OrderItem({
    required this.itemId,
    required this.itemName,
    required this.itemPrice,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'item_name': itemName,
        'item_price': itemPrice,
        'quantity': quantity,
      };
}
