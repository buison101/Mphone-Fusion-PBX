# Triển khai quản trị Customer và Extension Assignment

Trạng thái: đã triển khai pilot ngày 2026-08-22.

Phạm vi: Bước 4 của `PHASE_2_NEXT_STEPS_PLAN.md`, thực hiện trước Bước 3.

## 1. Kết quả

- Module operator FusionPBX tại
  `/app/customer_identities/customer_identities.php`.
- Danh sách Customer, Membership, Extension ownership, Assignment và exception.
- Operator có thể xác nhận Extension thuộc Customer, gán Extension cho Identity,
  cập nhật độc lập `can_use`/`can_manage` và gỡ Assignment bằng soft removal.
- Reconciliation chỉ ghi/resolve exception; không tự xóa hoặc tự sửa Assignment.
- Mọi thay đổi được ghi vào `mphone_customer_admin_events`, không chứa password,
  access/refresh token, FCM token hoặc SIP credential.
- Permission `customer_identity_view` và `customer_identity_edit` mặc định chỉ
  cấp cho `superadmin`. Operator khác phải được cấp rõ ràng qua FusionPBX.

## 2. Ranh giới Customer trong shared Domain

Bảng `mphone_customer_extensions` là nguồn ownership chuẩn:

```text
Customer -> Customer Extension ownership -> Identity Assignment
```

Việc Customer cùng dùng một Fusion Domain hoặc Tenant không chứng minh họ sở hữu
cùng Extension. API từ chối gán hoặc claim Extension đã thuộc Customer khác.
Một Extension có thể được gán cho nhiều Identity bên trong cùng Customer; việc
chuyển ownership giữa Customer không diễn ra tự động.

Migration đã tạo ownership cho ba Extension không mơ hồ. Dữ liệu pilot hiện có
một Extension đang được Assignment cho hai Customer khác nhau; hệ thống giữ
nguyên dữ liệu, không tự chọn chủ sở hữu, và ghi exception
`multiple_customer_owners` để operator quyết định.

## 3. API quản trị

Edge function `mphone-customer-admin` chỉ nhận request server-to-server có service
credential riêng. Trình duyệt không nhận credential này. PHP module kiểm tra
Fusion session, permission và CSRF trước khi gọi API qua localhost.

Các action:

- `list`
- `claim_extension`
- `save_assignment`
- `remove_assignment`
- `reconcile`

Service credential nằm ngoài repository:

- `/etc/mphone/customer-admin-secret`: PHP, quyền đọc root/www-data.
- `/etc/mphone/customer-admin.env`: Edge Functions environment.

## 4. Reconciliation

Job kiểm tra Assignment active đối với:

- Membership không còn active.
- Customer Tenant không còn active.
- Thiếu Customer Extension ownership.
- Extension bị xóa.
- Extension bị disable.
- Extension đổi Domain.

Exception hợp lệ ở lần chạy sau được đánh dấu resolved. Dữ liệu không hợp lệ chỉ
được báo cáo, không bị tự động sửa hoặc xóa.

## 5. Kiểm thử

- Admin endpoint không có service credential trả HTTP 401.
- PHP bridge chạy bằng user `www-data` trả HTTP 200 và đọc được bốn Customer.
- Danh sách Customer chi tiết trả Membership, Assignment và Extension đúng
  ownership.
- Save Assignment idempotent trả HTTP 200.
- Customer khác gán Extension đã có owner trả HTTP 403
  `extension_outside_customer`.
- Customer khác claim Extension đã có owner trả HTTP 409
  `owned_by_another_customer`.
- Reconciliation kiểm tra năm Assignment và phát hiện hai Assignment thiếu
  ownership do một Extension đang mơ hồ giữa hai Customer.
- Module self-test, PHP lint và schema migration lặp lại đều đạt.

## 6. Cài đặt FusionPBX

Module, permission và menu đã được cài vào database. Phiên superadmin đang mở từ
trước khi cài permission cần đăng xuất rồi đăng nhập lại để session nạp quyền mới.

## 7. Giới hạn pilot

- UI chỉ dành cho operator; chưa mở self-service cho Customer owner/admin.
- Chưa tạo Identity/Membership mới từ UI. Bước này tập trung vào ownership và
  Assignment của các Identity đã migration.
- Một ownership mơ hồ hiện cần operator chọn Customer bằng chức năng “Gán máy
  nhánh cho khách hàng”, sau đó chạy reconciliation và xử lý Assignment còn lại.
- Giao diện chưa được kiểm tra trực quan bằng browser trong môi trường agent.

## 8. Rollback

- Có thể gỡ menu/permission hoặc tắt Edge Function mà không xóa dữ liệu Identity.
- Assignment được gỡ bằng trạng thái `removed`, không hard delete.
- Bảng ownership và audit là bổ sung; rollback UI không ảnh hưởng SIP, Fusion
  Extension hoặc các session đã tồn tại.
