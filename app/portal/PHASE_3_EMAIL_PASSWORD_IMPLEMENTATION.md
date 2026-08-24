# Triển khai vòng đời email/password

Trạng thái: backend và Portal đã triển khai ngày 2026-08-24. Ngày 2026-08-25 đã
bổ sung luồng yêu cầu đặt lại mật khẩu trong mã nguồn Android; còn chờ build APK
và nghiệm thu bằng một email pilot thật.

Phạm vi: Bước 3 của `PHASE_2_NEXT_STEPS_PLAN.md`.

## 1. Hạ tầng công khai

- `login.mphone.vn` dùng chứng thư Let's Encrypt công khai thay cho Mphone LAN
  Test CA.
- Nginx phục vụ chứng thư từ
  `/etc/letsencrypt/live/login.mphone.vn/fullchain.pem` và `privkey.pem`.
- HTTP chuyển hướng sang HTTPS; Portal và callback reset/verify chạy qua cổng
  443 công khai.
- `certbot renew --dry-run --no-random-sleep-on-renew` đã đạt. Certbot đã cài
  scheduled renewal.
- Resend domain `auth.mphone.vn` được API xác nhận trạng thái `verified`.
- Resend API key và sender/base URL nằm ngoài repository tại
  `/etc/mphone/email.env`, mode `0600`, owner `root:root`.

## 2. Backend

Migration:

- `/opt/supabase/supabase-project/volumes/db/init/mphone_identity_phase3.sql`

Edge Function:

- `/opt/supabase/supabase-project/volumes/functions/mphone-identity-email/index.ts`

Các endpoint:

```text
POST /functions/v1/mphone-identity-email/request-recovery
POST /functions/v1/mphone-identity-email/confirm-recovery
POST /functions/v1/mphone-identity-email/request-verification
POST /functions/v1/mphone-identity-email/confirm-verification
POST /functions/v1/mphone-identity-email/change-password
POST /functions/v1/mphone-identity-email/request-email-change
POST /functions/v1/mphone-identity-email/confirm-email-change
```

Đã triển khai:

- Token ngẫu nhiên chỉ lưu SHA-256 hash, không lưu token thô.
- Token reset/change-email hết hạn sau 30 phút; verify hết hạn sau 24 giờ.
- Challenge mới revoke challenge cũ cùng loại; consume dùng transaction và row
  lock nên chỉ một request đồng thời thành công.
- Recovery request luôn trả cùng response cho email tồn tại và không tồn tại.
- Recovery/verify giới hạn ba request trong 15 phút theo IP + email fingerprint.
- Recent authentication sai cho đổi password/email giới hạn năm lần trong 10
  phút.
- Password mới dài 12–128 ký tự và hash bcrypt cost 12.
- Reset password revoke mọi Device Session và push registration của Identity.
- Đổi password giữ session hiện tại, revoke session/push của thiết bị khác.
- Đổi email chỉ cập nhật primary email sau khi email mới xác nhận token; session
  và push bị revoke sau khi hoàn tất.
- Identity `disabled` không thể verify hoặc reset.
- Đổi application password không thay đổi SIP password.
- Resend request có idempotency key theo challenge để retry không gửi trùng.
- Delivery audit chỉ lưu provider message ID, trạng thái và error code; không lưu
  recipient, body, password hoặc token.

Gửi email hiện thực hiện đồng bộ trong Edge request cho pilot. Outbox bất đồng bộ
và webhook bounce/complaint là hardening tiếp theo trước khi tăng lưu lượng lớn.

## 3. Portal

- PHP bridge: `service/identity_lifecycle.php`.
- Trang đăng nhập có luồng Quên mật khẩu với phản hồi chống dò email.
- Callback `/p/reset-password` nhận token và đặt mật khẩu mới.
- Callback `/p/verify-email` xác minh email mới hoặc Identity pending.
- Trang `/p/account` có đổi mật khẩu và đổi email, yêu cầu mật khẩu hiện tại.
- Tất cả chuỗi hiển thị có cả tiếng Việt và tiếng Anh.
- Browser không nhận Resend API key, access token hoặc refresh token.
- Callback token không được lưu vào localStorage; URL được làm sạch sau khi
  confirm thành công.

## 4. Kiểm thử

- Nginx syntax và reload: đạt.
- HTTPS public trả chứng thư Let's Encrypt: đạt.
- Certbot simulated renewal: đạt.
- Resend Domains API xác nhận `auth.mphone.vn` verified.
- Gửi tới test address chính thức
  `delivered+mphone-phase3@resend.dev`: HTTP 200 và có provider message ID.
- Public PHP lifecycle với email không tồn tại: HTTP 202, body đồng nhất.
- Verify token lần đầu 200, replay 400.
- Reset token lần đầu 200, replay 400.
- Identity disabled reset trả 400.
- Rate limit recovery ghi event `rate_limited` sau ngưỡng.
- PHP lint, locale JSON, ESLint và Vite production build: đạt.
- Fixture Identity/challenge và audit test tạm đã được xóa.
- Android XML và wiring API đã được kiểm tra tĩnh. Chưa thể chạy
  `./gradlew assembleDebug` trên VM vì VM không có Java/Android SDK;
  `local.properties` của project đang trỏ SDK Windows
  `D:\Programs\AndroidStudio\Sdk`.

Không gửi recovery tới email khách hàng thật trong kiểm thử tự động. Cần chọn một
Identity pilot và thực hiện kiểm thử hộp thư thực tế trước khi mở rộng.

## 5. Android

- Android source đã mount bằng SSHFS tại `/mnt/linphone`.
- `RecoverAccountFragment` gọi trực tiếp endpoint công khai
  `mphone-identity-email/request-recovery`, kiểm tra email và hiển thị trạng thái
  gửi.
- Màn hình khôi phục cũ bằng trình duyệt/số điện thoại đã được thay bằng biểu mẫu
  email native có chuỗi tiếng Việt và tiếng Anh.
- Nút Quên mật khẩu chỉ hiện ở chế độ tài khoản Mphone (`USER`), không hiện ở
  chế độ máy nhánh vì application password độc lập với SIP password.
- Chưa tạo được APK trên VM. Cần build từ Android Studio/Gradle trên máy Windows
  đang có SDK, hoặc cài JDK và Android SDK tương ứng vào VM.

## 6. Giới hạn và bước tiếp theo

- Chưa có Resend webhook cho delivered, bounced, complained và suppressed.
- Chưa có worker outbox/retry bất đồng bộ; lỗi provider hiện được audit và trả
  `delivery_failed` cho thao tác đã xác thực, còn public recovery vẫn giữ response
  chống enumeration.
- Resend Free giới hạn 100 email/ngày và 3.000 email/tháng; cần cảnh báo quota
  trước khi mở rộng pilot.

## 7. Rollback

- Có thể ẩn UI lifecycle bằng cách rollback bundle Portal và PHP bridge mà không
  xóa Identity hoặc SIP configuration.
- Có thể dừng route Edge Function hoặc gỡ `/etc/mphone/email.env` để ngừng gửi.
- Hai bảng Phase 3 là additive; không drop trong lúc còn challenge hợp lệ.
- Rollback UI/backend không hoàn tác password/email đã được người dùng xác nhận.
- Chứng thư Let's Encrypt không phụ thuộc Bước 3 và nên được giữ nguyên ngay cả
  khi rollback email lifecycle.
