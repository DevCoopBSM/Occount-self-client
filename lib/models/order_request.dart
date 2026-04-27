// 명세서: POST /orders — 결제 실행 전 반드시 주문 생성 필요
// 요청 구조:
// {
//   "items": [{
//     "item_id": 1,
//     "quantity": 2
//   }]
// }
class OrderRequest {
  final List<OrderItem> items;

  OrderRequest({
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class OrderItem {
  final int itemId;
  final int quantity;

  OrderItem({
    required this.itemId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'quantity': quantity,
      };
}
