# Triển khai quản lý tài khoản và thiết bị

Trạng thái: đã triển khai trên môi trường thử nghiệm.

Ngày hoàn thành: 2026-08-22.

Phạm vi: Bước 2 của `PHASE_2_NEXT_STEPS_PLAN.md`.

## 1. Kết quả

- Portal có trang `/p/account` hiển thị email chính, Customer, Membership role,
  Extension Assignment cùng `can_use`/`can_manage` và các session đang hoạt động.
- Mỗi session mới có metadata đã lọc: loại client, tên thiết bị, platform và
  phiên bản ứng dụng. Không trả installation ID/hash, refresh/access token, FCM
  token hoặc SIP password cho trình duyệt.
- Portal dùng installation cookie ổn định, `HttpOnly`, `Secure`, `SameSite=Lax`;
  JavaScript không đọc được định danh này.
- Revoke một thiết bị chỉ tác động session thuộc đúng Identity và tắt push của
  installation tương ứng. Revoke session Portal hiện tại xóa ngay PHP session và
  WebSocket token.
- “Đăng xuất khỏi tất cả các thiết bị khác” yêu cầu nhập lại mật
  khẩu, revoke các session khác của Identity và tắt push của các
  installation tương ứng; Portal session hiện tại được giữ nguyên.
- Dòng “Thiết bị này” không hiển thị nút đăng xuất riêng.
- Xác nhận logout-all sai từ 5 lần trong 10 phút bị rate-limit.
- Login, logout, revoke, logout-all và các lần xác nhận thất bại được ghi audit
  mà không ghi credential/token.
- Mphone gửi metadata Android trong request đăng nhập Auth v2.

## 2. Kiến trúc

```text
Portal SPA /p/account
        |
        | PHP session + Portal CSRF
        v
Portal account.php
        |
        | bearer token chỉ ở phía server
        v
Auth v2: me / extensions / devices / revoke-device / logout-all
        |
        v
Device session + refresh rotation + push registration + auth audit
```

Trang web không gọi Auth v2 trực tiếp và không sở hữu bearer/refresh token.
`session_id` được dùng làm opaque target cho revoke; Auth v2 luôn ràng buộc target
vào cùng `actor_type` và `actor_uuid` của principal.

## 3. Recent authentication

Trong pilot password hiện tại được gửi qua Portal PHP tới Auth v2 chỉ cho thao
tác logout-all. Auth v2 so khớp bcrypt với Customer Identity đang xác thực, không
tạo session/token mới và không ghi password vào audit. Thao tác thành công sẽ
đăng xuất cả chính thiết bị đang thực hiện.

Khi Google OAuth được triển khai, contract này cần mở rộng thành re-auth challenge
theo provider; không dùng việc trùng email làm bằng chứng recent authentication.

## 4. Kiểm thử đã thực hiện

- Auth v2 tạo hai session, `/devices` chỉ trả session của cùng Identity.
- Revoke session thứ hai trả HTTP 200; refresh token của session đó trả HTTP 401.
- Logout-all với mật khẩu sai trả HTTP 401.
- Logout-all đúng trả HTTP 200; access token cũ sau đó trả HTTP 401.
- Năm lần nhập sai recent-auth trả HTTP 401; lần thứ sáu trong cửa sổ 10 phút
  trả HTTP 429.
- Identity A revoke session của Identity B trả HTTP 404; session B vẫn hoạt động
  và không xuất hiện trong danh sách thiết bị của A.
- Audit có event `device_revoke`, `logout_all/rejected` và
  `logout_all/accepted`.
- Portal login, session và account service trả HTTP 200.
- Portal account nhận diện session web hiện tại; CSRF sai trả HTTP 403.
- Logout-all qua Portal xóa session ngay; account service sau đó trả HTTP 401.
- PHP lint, JSON validation, Portal ESLint và Vite production build: đạt.

Mật khẩu/hash kiểm thử được khôi phục và các session/dữ liệu kiểm thử tạm đã được
xóa sau kiểm thử.

## 5. Giới hạn pilot

- Session cũ tạo trước Bước 2 không có metadata nên hiển thị “Thiết bị không xác
  định” cho đến khi đăng nhập lại.
- Lịch sử revoked session được giữ trong database để audit nhưng Portal chỉ hiện
  tổng số, không hiện credential hay định danh installation.
- Chưa có đổi Customer context khi Identity có nhiều Membership.
- Chưa có Google re-authentication; logout-all hiện chỉ áp dụng cho Identity có
  password provider.
- Android source đã sẵn sàng nhưng môi trường Debian hiện không có Java nên chưa
  tạo được APK debug tại đây.

## 6. Rollback

- Bỏ route/menu `/p/account` và Portal `account.php` để tắt self-service UI.
- Metadata trong `mphone_device_sessions.metadata` là bổ sung, không yêu cầu đổi
  schema và có thể được bỏ qua bởi phiên bản cũ.
- Không xóa Customer, Identity, Membership, Assignment hoặc cấu hình SIP khi
  rollback.

## 7. Bước tiếp theo

Sau khi người dùng kiểm thử trang Tài khoản trên browser và APK có metadata thiết
bị, có thể chuyển sang Bước 3: email verification, recovery và password lifecycle.
