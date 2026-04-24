OVERVIEW
Library of 13 data models under lib/models used across auth, cart, orders, and payments.

WHERE TO LOOK
auth_response.dart — Auth API response model
cart_item.dart — Cart item with quantity, price, category
category.dart — Product category model
item_response.dart — Barcode item lookup response
login_result.dart — Login result model
non_barcode_item_response.dart — Non-barcode item data
order_request.dart — Order creation request body
order_status_response.dart — SSE order status response
payment_request.dart — Payment execution request body
payment_response.dart — Payment execution response
top_item_response.dart — Top/popular item response
top_item.dart — Top item domain model
user_info.dart — User profile data

NOTES
- Models are pure data carriers with API mappings used by Auth, Cart, and Payment flows.
- Error payloads from server follow { "message": "ERROR_CODE" } structure.
- Payment type determination follows: points >= total -> PAYMENT; otherwise MIXED (logic lives in related services).
- Guest mode in API uses header X-Kiosk-Id instead of Bearer tokens for auth.
- cart_item.dart is the central cart model consumed by AuthProvider and PaymentProvider.

- Serialization in these models is implemented manually (no codegen) to keep the app lean.
- Changes in API payloads should be reflected here and in corresponding services.
- When API contracts change, update both models and the corresponding service mapping.
