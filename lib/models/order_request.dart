// 명세서: POST /orders — 결제 실행 전 반드시 주문 생성 필요
// 요청 구조: { "orderInfos": [{ "itemId": 1, "orderQuantity": 2 }] }
class OrderRequest {
  final List<OrderItem> orderInfos;

  OrderRequest({required this.orderInfos});

  Map<String, dynamic> toJson() => {
        'orderInfos': orderInfos.map((e) => e.toJson()).toList(),
      };
}

class OrderItem {
  // 명세서: itemId는 Long (int) — PaymentItem의 String과 다름
  final int itemId;
  final int orderQuantity;

  OrderItem({required this.itemId, required this.orderQuantity});

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'orderQuantity': orderQuantity,
      };
}
