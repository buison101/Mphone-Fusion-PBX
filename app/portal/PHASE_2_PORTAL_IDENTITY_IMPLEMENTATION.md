# Triển khai Portal dùng chung Customer Identity

Trạng thái: đã triển khai trên môi trường thử nghiệm.

Ngày hoàn thành: 2026-08-22.

Phạm vi: Bước 1 của `PHASE_2_NEXT_STEPS_PLAN.md`.

## 1. Kết quả

- `login.mphone.vn/p/` có màn hình đăng nhập email/password dùng Auth v2 và
  Customer Identity giống Mphone.
- Sau khi Auth v2 xác thực, server tạo FusionPBX PHP session tương thích với các
  Portal service hiện hữu. Trình duyệt chỉ nhận session cookie; access token và
  refresh token nằm trong PHP session phía server, không lưu ở `localStorage`.
- Portal trả Identity, Customer, Membership và danh sách Extension được gán cho
  SPA sau khi xác thực.
- Portal customer session không kế thừa quyền đọc toàn Domain. Mọi truy vấn CDR,
  cuộc gọi, ghi âm, báo cáo, contact và metadata dùng danh sách Extension đã gán.
- Trang quản trị FusionPBX và luồng xác thực quản trị hiện tại không bị thay đổi.
- Logout thu hồi Auth v2 session, xóa cầu nối local và vô hiệu hóa WebSocket token
  của Portal session.

## 2. Luồng session

```text
Browser tại login.mphone.vn
        |
        | Email/password + login CSRF
        v
Portal identity endpoint (PHP)
        |
        | Auth v2 qua localhost
        v
Identity + Customer + Membership + Assignment
        |
        | kiểm tra mapping Fusion user/domain
        v
PHP session HttpOnly/Secure + Portal extension scope
```

Auth v2 session được kiểm tra lại tối đa mỗi 60 giây. Access token gần hết hạn
được refresh bằng refresh-token rotation. Nếu refresh, validation hoặc tải
assignment thất bại, Portal fail closed và xóa session cục bộ. Vì vậy revoke
session hoặc thay đổi assignment có độ trễ hiệu lực tối đa 60 giây trong pilot.

## 3. Thành phần đã thay đổi

- `resources/identity_session.php`: Auth v2 client, refresh/validation, cleanup,
  đồng bộ Extension và khóa quyền Domain cho Customer Identity.
- `service/identity.php`: login/logout endpoint, CSRF, tạo Fusion session bridge.
- `service/session.php`: trả Identity context, Portal CSRF, scoped WebSocket token
  và trạng thái `401` cho màn hình đăng nhập.
- Các Portal service và scope helper: bắt buộc validation và dùng Extension
  Assignment thay cho quyền toàn Domain đối với Customer Identity.
- Portal SPA: form email/password, trạng thái lỗi, logout Customer Identity và
  hiển thị session mới.
- Nginx `login.mphone.vn`: cho phép Portal service PHP, static theme và proxy
  `/websockets/` trên HTTPS.

## 4. Kiểm thử đã thực hiện

- Đăng nhập email trên `login.mphone.vn`: đạt.
- Tải Portal session: đúng Identity, Customer, Membership và hai Extension của
  tài khoản pilot.
- Dashboard qua customer session: HTTP 200.
- Quyền toàn Domain bị loại khỏi customer session.
- Logout: đạt; session cũ trả HTTP 401.
- Session chưa đăng nhập trả login CSRF 64 ký tự.
- Login thiếu hoặc sai CSRF trả HTTP 403.
- PHP lint các file thay đổi: đạt.
- Portal ESLint/Prettier và Vite production build: đạt.
- Portal self-test Phase 0, Phase 1, Phase 2, Phase 4.1.1 và Phase 4.2: đạt.
- `nginx -t` và reload Nginx: đạt.

WebSocket token tiếp tục do cơ chế Portal hiện hữu phát hành sau khi session và
Extension scope đã được kiểm tra. Việc bắt tay WebSocket thực tế cần được kiểm
tra lại trong phiên browser pilot tiếp theo để xác nhận cả subscribe và event
delivery trên hostname mới.

## 5. Giới hạn của pilot

- Tenant login hiện được gửi là `shared`; bước resolve tenant theo hostname cho
  VIP sẽ thực hiện khi đưa VIP domain vào pilot.
- Chưa có Google OAuth, email verification/recovery, quản lý thiết bị hay
  logout-all UI; đây là các bước tiếp theo trong kế hoạch.
- Endpoint nội bộ mặc định là `http://127.0.0.1:8000`; có thể đổi bằng biến môi
  trường `MPHONE_PORTAL_AUTH_URL`.
- Chưa mở public Internet. TLS/DNS hiện thuộc môi trường LAN thử nghiệm.

## 6. Rollback

Rollback ứng dụng bằng cách bỏ route Portal service khỏi virtual host
`login.mphone.vn` và khôi phục Portal SPA/session service trước Bước 1. Không cần
xóa Identity, Customer, Membership, Assignment, Fusion user, Extension hay cấu
hình SIP. Các session Auth v2 đang tồn tại có thể được revoke độc lập.

## 7. Bước tiếp theo

Triển khai **Bước 2 — Quản lý tài khoản và thiết bị**: hiển thị hồ sơ Identity,
Customer/Membership, Extension permission và danh sách Device Session; sau đó
thêm revoke một thiết bị và logout-all với recent authentication và audit.
