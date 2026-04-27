OVERVIEW
A focused widget suite for 18 payment widgets that compose cart, barcode entry, dialogs, and finalization steps in the self-service kiosk payments UI.

WHERE TO LOOK
- payment_header.dart — User name + Aripay balance header; consumes AuthProvider; includes a hidden admin long-press (5s).
- payment_item_header.dart — Static column headers for cart: 상품 이름, 이벤트, 수량, 상품 가격.
- payment_item_list.dart — ListView of cart items rendered via PaymentItemCard.
- payment_item_card.dart — Cart line item with +/- quantity controls, EVENT badge, and price.
- payment_item_tile.dart — Lightweight cart row variant.
- product_selection_panel.dart — Composite: BarcodeInput plus PaymentItemHeader.
- barcode_input.dart — Barcode text field; calls PaymentProvider.addItemByBarcode; can open NonBarcodeDialog/AllItemsDialog.
- non_barcode_dialog.dart — Dialog for barcode-less items; adds via PaymentProvider.addNonBarcodeItem; shows an overlay toast.
- all_items_dialog.dart — Dialog for all items with category filtering; adds via PaymentProvider.addAllItem; shows an overlay toast.
- product_list.dart — Grid of category items via CategoryProvider; tapping adds to cart via AuthProvider.addToCart.
- product_type_selector.dart — Category dropdown powered by CategoryProvider.
- payment_summary.dart — Total/points/card breakdown computed by PaymentProvider.calculatePayment.
- payment_action_buttons.dart — Global actions: 전체 삭제, 홈으로, 결제.
- charge_dialog.dart — Aripay charge flow invoked through PaymentProvider.chargeAmount.
- payment_processing_dialog.dart — Processing modal with progress and cancel option.
- payment_result_dialog.dart — Result dialog showing success/failure and auto-return timer.
- payments_popup.dart — Shared popup helper functions used by the payment dialogs.
- pay_item.dart — Reusable item row widget used by multiple lists.

PROVIDER DEPENDENCIES
- AuthProvider: payment_header, payment_item_list, payment_item_card, product_list
- PaymentProvider: barcode_input, non_barcode_dialog, all_items_dialog, payment_summary, payment_action_buttons, charge_dialog, payment_processing_dialog, payment_result_dialog
- CategoryProvider: product_list, product_type_selector

PAYMENT FLOW (widget order)
1. BarcodeInput / NonBarcodeDialog / AllItemsDialog → add items to cart
2. PaymentItemList + PaymentItemCard → review cart
3. PaymentSummary → see totals (points vs card)
4. ChargeDialog → optional Aripay charge
5. PaymentActionButtons(결제) → trigger PaymentProvider.processPayment
6. PaymentProcessingDialog → show progress (cancel via PaymentProvider.cancelPayment)
7. PaymentResultDialog → success/failure result, auto-navigate home

NOTES
- Admin access is hidden behind 5-second long-press on PaymentHeader.
- Guest mode: points visibility and some calculations gated via AuthProvider.isGuestMode.
- Mix of Consumer<T> and Provider.of<T> to optimize rebuild scope.
- Overlay toasts in non_barcode_dialog and all_items_dialog give immediate add-item feedback.
