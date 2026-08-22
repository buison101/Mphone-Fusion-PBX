# Phase 2 — Mphone runtime session revocation

Trạng thái: đã hoàn thiện phần triển khai Bước 5 trong môi trường
thử nghiệm; chờ build APK và nghiệm thu trên thiết bị.

Ngày triển khai: 2026-08-22.

## 1. Vấn đề

Portal đã revoke đúng Auth v2 session và ghi audit, nhưng Mphone chỉ làm mới
token khi token sắp hết hạn. SIP REGISTER hoạt động độc lập với Auth
session nên thiết bị vẫn có thể nhận cuộc gọi sau khi bị đăng xuất từ
Portal.

## 2. Xử lý đã triển khai

- Bổ sung kiểm tra Auth v2 `GET /session` cho Managed Account.
- Kiểm tra ngay khi Main Activity vào foreground.
- Trong khi app ở foreground, kiểm tra lại mỗi 60 giây.
- Kiểm tra ngay khi Linphone Core báo mạng có thể truy cập lại.
- Khi server trả `401`, xóa Auth session cục bộ, gỡ các SIP account có
  origin `MANAGED_ACCOUNT`, chuyển người dùng về Assistant và khôi phục các
  Multi-SIP đã bị tạm ngắt trước đó.
- Lỗi mạng hoặc lỗi server tạm thời không làm mất session hay cấu hình
  SIP của người dùng.

## 3. Phạm vi bảo toàn

- Không xóa SIP account do người dùng nhập thủ công.
- Không xóa Mphone Extension login độc lập.
- Chỉ bật REGISTER lại cho những identity đã thực sự bị tạm ngắt
  khi chuyển sang Managed Account.
- Push registration thuộc một Extension session độc lập trên cùng
  installation không bị revoke nhầm.

## 4. SLA hiện tại

- App đang foreground: phát hiện revoke tối đa khoảng 60 giây.
- App quay lại foreground: kiểm tra ngay.
- Thiết bị offline: giữ nguyên trạng thái cục bộ và kiểm tra ngay khi
  mạng khôi phục.
- App bị hệ điều hành dừng hoàn toàn: xử lý khi app được mở lại;
  background push-command chưa nằm trong bước 5A.

## 5. Kiểm thử cần thực hiện trên thiết bị

1. Đăng nhập Managed Account, sau đó revoke thiết bị từ Portal.
2. Xác nhận app về Assistant trong SLA và managed SIP ngừng REGISTER.
3. Xác nhận Multi-SIP cũ còn cấu hình và REGISTER lại.
4. Lặp lại khi app background/foreground và khi mạng bị ngắt/rồi khôi phục.
5. Xác nhận Extension login và third-party SIP không bị xóa nhầm.

## 6. Phần còn lại của Bước 5

Không còn hạng mục triển khai trong phạm vi Bước 5. Các phần đã bổ sung:

- Reconcile Identity, Customer, Membership và Extension Assignment khi app
  foreground, sau refresh token và khi mạng khôi phục.
- Provision managed Extension mới chỉ khi server trả snapshot hợp lệ và
  `can_use=true`.
- Khi assignment mất `can_use`, giữ cấu hình managed SIP nhưng tắt REGISTER,
  loại khỏi danh sách tài khoản và không đăng ký lại push.
- Tự khôi phục transition dở dang khi app crash trong lúc vào/thoát
  Managed Account.
- Hiển thị email, Customer và Membership role trong màn hình tài khoản.
- Identity, Customer, Membership, Tenant, Fusion user hoặc session bị khóa
  làm runtime context trả `401` và thoát Managed Account an toàn.

## 7. Quy tắc offline và SLA

- Không có snapshot server hợp lệ thì không provision Extension mới.
- Lỗi mạng/5xx không xóa session, SIP account hay Multi-SIP; snapshot cục bộ
  gần nhất tiếp tục được dùng.
- App foreground phát hiện session/assignment revoke trong tối đa 60 giây.
- App background hoặc bị dừng sẽ reconcile ngay lần foreground/khởi động
  tiếp theo. Background command qua FCM không thuộc SLA hiện tại.

## 8. Bảo vệ credential

Auth v2 chỉ trả SIP credential của assignment còn `can_use=true`. Portal PHP
whitelist các trường hiển thị trước khi trả về trình duyệt, do đó không
chuyển tiếp SIP password, access token, refresh token hoặc installation ID.
