OVERVIEW
Library of 13 data models under lib/models used across auth, cart, orders, and payments. Plus 2 DTOs under lib/Dto/ (uppercase — intentional).

WHERE TO LOOK
auth_response.dart — Auth API response wrapper (token + UserInfo); toJson only
cart_item.dart — Central cart model; converts from ItemResponse/NonBarcodeItemResponse; totalPrice getter, copyWith; no toJson
category.dart — Product category model; fromJson only
item_response.dart — Barcode item lookup response; fromJson/toJson; used by CartItem
login_result.dart — Login result data holder; no serialization
non_barcode_item_response.dart — Non-barcode item data; fromJson; used by CartItem
order_request.dart — Order creation request; contains OrderItem; toJson
order_status_response.dart — Order status: OrderStatus constants + OrderStatusResponse (isTerminal, fromSseEvent, fromJson/toJson)
payment_request.dart — Payment execution request; PaymentType enum + PaymentInfo + PaymentItem; PaymentItem.fromCartItem; toJson
payment_response.dart — Payment execution response; fromJson/toJson
top_item_response.dart — Top/popular item response DTO; fromJson
top_item.dart — Top item domain model; fromJson/toJson
user_info.dart — User profile; fromJson/toJson; empty() factory

DTOs (lib/Dto/)
event_item_response_dto.dart — Event item DTO; fromJson
non_barcode_item.dart — Non-barcode item payload; fromJson

KEY RELATIONSHIPS
- CartItem ← converts from ItemResponse and NonBarcodeItemResponse
- PaymentRequest.PaymentItem ← built from CartItem via fromCartItem
- OrderRequest.OrderItem ← extracted from cart items
- AuthResponse ← wraps UserInfo

SERIALIZATION
- All models: manual fromJson/toJson (no codegen). freezed/json_serializable in pubspec but commented out.
- When API contracts change, update both models and corresponding services.

NOTES
- Error payloads from server follow `{ "message": "ERROR_CODE" }` structure.
- Guest mode uses X-Kiosk-Id header instead of Bearer tokens.
- CartItem is the central model consumed by AuthProvider (cart state) and PaymentProvider (payment flow).
- Dto/ holds network-layer payloads; models/ holds domain models with business helpers.
