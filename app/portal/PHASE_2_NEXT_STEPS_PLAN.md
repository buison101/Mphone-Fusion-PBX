# Kế hoạch hoàn thiện Phase 2 sau Identity Pilot

Trạng thái: Bước 1, Bước 2 và Bước 4 đã triển khai trên môi trường thử nghiệm;
Bước 5 đã hoàn thiện phần triển khai; Bước 3 và Bước 6 chưa triển khai.

Ngày lập: 2026-08-22.

Tài liệu liên quan:

- `CUSTOMER_IDENTITY_PHASE_1_2_PLAN.md`
- `PHASE_1_IDENTITY_IMPLEMENTATION.md`
- `PHASE_2_IDENTITY_IMPLEMENTATION.md`

## 1. Mục tiêu

Hoàn thiện Customer Identity Platform sau khi Mphone đã đăng nhập thành công bằng
email, để `login.mphone.vn` trở thành cổng đăng nhập chung cho Mphone, Portal và
các dịch vụ tương lai như quản lý gói, thanh toán và tự động hóa.

Kế hoạch này không thay đổi ba chế độ tài khoản của Mphone và không xóa cấu hình
Multi-SIP. Managed Account tiếp tục tạm ngắt, ẩn và khôi phục Multi-SIP theo cơ
chế đã triển khai trong Phase 1.

## 2. Nguyên tắc triển khai

- Identity, Customer, Membership, PBX Tenant và Extension Assignment tiếp tục là
  các đối tượng độc lập.
- `customer_uuid` là khóa nghiệp vụ cho thanh toán tương lai; không dùng
  `domain_uuid` hoặc Fusion `user_uuid` thay thế.
- Mọi quyền truy cập dữ liệu khách hàng phải được kiểm tra trên server.
- Shared Domain không bao giờ được coi là ranh giới Customer.
- Email/password của ứng dụng độc lập với SIP password.
- Mọi thay đổi phải tương thích ngược và có đường rollback cho pilot.
- Môi trường LAN có thể dùng endpoint HTTP nội bộ cho debug; bản release và mọi
  callback OAuth phải dùng HTTPS công khai hợp lệ.

## 3. Thứ tự triển khai

### Bước 1 — Portal dùng chung Customer Identity

**Trạng thái: hoàn thành triển khai pilot ngày 2026-08-22.** Chi tiết kỹ thuật,
kiểm thử và rollback nằm tại `PHASE_2_PORTAL_IDENTITY_IMPLEMENTATION.md`.

#### Phạm vi

- Tạo màn hình đăng nhập khách hàng tại `login.mphone.vn`.
- Dùng cùng Auth v2 và Customer Identity với Mphone.
- Sau đăng nhập, tạo web session bằng cookie có `HttpOnly`, `Secure` và
  `SameSite` phù hợp.
- Portal lấy Identity, Customer, Membership và Extension Assignment từ session
  đã xác thực.
- Tạo cầu nối có kiểm soát cho các Portal PHP service hiện đang phụ thuộc vào
  FusionPBX PHP session.
- Giữ trang quản trị FusionPBX và phiên đăng nhập quản trị tách biệt.

#### Yêu cầu bảo mật

- Không lưu access token hoặc refresh token dài hạn trong `localStorage`.
- Không nhận `customer_uuid`, `domain_uuid` hoặc `extension_uuid` từ trình duyệt
  làm bằng chứng sở hữu.
- Có CSRF protection cho các thao tác ghi.
- Cookie web session có thời hạn, revoke theo thiết bị và logout-all.
- Websocket token chỉ được cấp sau khi kiểm tra Customer và Extension scope.
- Portal Customer A không được đọc dữ liệu Customer B trong cùng shared Domain.

#### Tiêu chí nghiệm thu

- Người dùng đăng nhập bằng email tại `login.mphone.vn` và vào được Portal.
- Portal hiển thị đúng Customer, vai trò và các Extension được gán.
- Phiên hết hạn, logout và revoke thiết bị được thực thi trên server.
- Kiểm thử chéo Customer trả `403` hoặc `404` không tiết lộ dữ liệu.
- Đăng nhập quản trị FusionPBX hiện tại không bị ảnh hưởng.

### Bước 2 — Quản lý tài khoản và thiết bị

**Trạng thái: hoàn thành triển khai pilot ngày 2026-08-22.** Chi tiết kỹ thuật,
kiểm thử và giới hạn nằm tại `PHASE_2_ACCOUNT_DEVICES_IMPLEMENTATION.md`.

#### Phạm vi

- Hiển thị email chính, Customer hiện tại và vai trò Membership.
- Hiển thị danh sách Extension có `can_use` và `can_manage`.
- Hiển thị các Device Session: loại thiết bị, thời điểm tạo, hoạt động gần nhất,
  hạn session và trạng thái revoke.
- Cho phép thu hồi một thiết bị.
- Cho phép đăng xuất tất cả thiết bị, với xác nhận và recent authentication.
- Không hiển thị installation ID thô, refresh token, FCM token hoặc SIP password.

#### Tiêu chí nghiệm thu

- Người dùng chỉ thấy session thuộc Identity của mình.
- Revoke thiết bị làm access/refresh session không còn sử dụng được.
- Push registration của đúng installation bị vô hiệu hóa.
- Audit ghi hành động nhưng không ghi credential hoặc token.

### Bước 3 — Hoàn thiện vòng đời email/password

#### Phạm vi

- Xác minh email khi tạo Identity hoặc đổi email.
- Quên mật khẩu và đặt lại mật khẩu bằng token dùng một lần, thời hạn ngắn.
- Đổi mật khẩu yêu cầu mật khẩu hiện tại hoặc recent authentication.
- Đổi email yêu cầu xác minh địa chỉ mới trước khi thay primary email.
- Thay đổi mật khẩu ứng dụng không thay đổi SIP password.
- Bổ sung giới hạn tần suất cho verify, resend và recovery.

#### Hạ tầng cần có

- Nhà cung cấp SMTP hoặc email API.
- Domain gửi email và SPF/DKIM/DMARC phù hợp.
- Template email tiếng Việt và tiếng Anh.
- URL HTTPS công khai cho verify/recovery callback.

#### Tiêu chí nghiệm thu

- Token verify/reset chỉ dùng được một lần và hết hạn đúng.
- Phản hồi recovery không tiết lộ email có tồn tại hay không.
- Identity bị disabled không thể verify, reset hoặc tạo session mới.
- Mật khẩu và token không xuất hiện trong log/audit.

### Bước 4 — Quản trị Customer và Extension Assignment

**Trạng thái: hoàn thành triển khai pilot ngày 2026-08-22.** Bước này được thực
hiện trước Bước 3 theo quyết định triển khai. Chi tiết nằm tại
`PHASE_2_CUSTOMER_ASSIGNMENT_IMPLEMENTATION.md`.

#### Phạm vi

- Cho phép operator/admin được cấp quyền gán hoặc bỏ Extension khỏi Identity.
- Tách rõ `can_use` và `can_manage`.
- Hỗ trợ một Extension được dùng bởi nhiều Identity khi nghiệp vụ cho phép.
- Tạo reconciliation job so sánh Customer Platform với FusionPBX.
- Báo cáo Extension bị xóa, đổi Domain, disabled hoặc không còn liên kết hợp lệ.
- Không tự sửa dữ liệu mơ hồ; đưa vào exception report.

#### Tiêu chí nghiệm thu

- Customer admin chỉ quản lý bản ghi trong Customer của họ.
- Gỡ `can_use` chặn provisioning, push và thao tác Extension ngay trên server.
- Shared-Domain Customer A không thể gán Extension thuộc Customer B.
- Migration/reconciliation chạy lặp lại không tạo bản ghi trùng.

### Bước 5 — Hoàn thiện Mphone runtime

**Trạng thái: đã hoàn thiện triển khai Bước 5 ngày 2026-08-22.**
Chi tiết nằm tại
`PHASE_2_MPHONE_RUNTIME_REVOCATION_IMPLEMENTATION.md`.

#### Phạm vi

- Đồng bộ Identity/Customer/Membership và assignment khi mở ứng dụng.
- Đồng bộ lại sau refresh token và khi app quay lại foreground.
- Tạm ngắt và loại khỏi giao diện managed Extension đã mất `can_use`.
- Không xóa SIP account do người dùng nhập thủ công.
- Xử lý an toàn khi Identity, Customer, Membership, Tenant hoặc session bị khóa.
- Hoàn thiện state chuyển tiếp khi app crash trong lúc vào/thoát Managed Account.
- Hiển thị email và Customer hiện tại trong phần tài khoản.

#### Quy tắc offline

- Không provisioning Extension mới khi không xác thực được session.
- Có thời gian grace rõ ràng cho Extension đang hoạt động nếu sản phẩm yêu cầu.
- Assignment bị revoke phải có thời gian hiệu lực tối đa được định nghĩa và đo
  kiểm được.
- Khi đăng xuất Managed Account, chỉ khôi phục những Multi-SIP trước đó thực sự
  đang enabled.

#### Tiêu chí nghiệm thu

- Một account có một và nhiều Extension đều đồng bộ đúng.
- Gỡ assignment trên server làm Extension tương ứng ngừng REGISTER theo SLA.
- Mất mạng, hết hạn token, crash và khởi động lại không làm mất Multi-SIP.
- Extension login và third-party SIP vẫn hoạt động đúng ngoài Managed Account.

### Bước 6 — Google OAuth và liên kết provider

Chỉ bắt đầu sau khi các bước 1–5 ổn định và có HTTPS công khai.

#### Phạm vi

- Cấu hình Google OAuth Client ID/secret và redirect URI chính thức.
- Liên kết bằng Google provider subject ổn định.
- Không tự liên kết chỉ vì Google email trùng primary email.
- Người dùng đang xác thực phải thực hiện explicit provider-linking flow.
- Không cho gỡ provider cuối cùng nếu chưa có phương thức đăng nhập thay thế.
- Provider unlink, đổi email và chuyển owner yêu cầu recent authentication.

#### Tiêu chí nghiệm thu

- Google login tạo hoặc truy xuất đúng Identity theo provider subject.
- Trùng email không dẫn đến chiếm tài khoản.
- Password và Google có thể cùng liên kết với một Identity.
- Logout/revoke áp dụng thống nhất cho session tạo từ mọi provider.

## 4. Công việc chuẩn bị cho Billing

Chưa triển khai thanh toán trong kế hoạch này, nhưng cần giữ các ranh giới sau:

- Subscription, plan, invoice và payment customer sẽ tham chiếu
  `customer_uuid`.
- Entitlement được kiểm tra cùng application permission và resource scope.
- Customer status và billing status là hai trạng thái riêng.
- Khóa thanh toán không được tự động xóa Identity, Extension hoặc lịch sử.
- VIP và shared Customer dùng chung Customer/Billing Platform dù PBX Tenant khác
  nhau.

## 5. Kiểm thử bắt buộc

- Đăng nhập email/password trên Mphone và Portal.
- Identity có một và nhiều Customer Membership.
- Customer A/B nằm chung Fusion Domain.
- Extension được gán cho một và nhiều Identity.
- `can_use=false` nhưng `can_manage=true`, và trường hợp ngược lại.
- Identity, Customer, Membership, Tenant, Fusion user và Extension bị disabled.
- Access token hết hạn, refresh rotation, replay, revoke và logout-all.
- Portal session cookie, CSRF, websocket token và session fixation.
- Email verify/reset hết hạn, dùng lại và rate limit.
- Google account trùng email nhưng chưa được liên kết.
- Mphone mất mạng, crash, khởi động lại và assignment bị thu hồi.
- Không có password, JWT, refresh token, SIP password hoặc FCM token trong log.

## 6. Rollout đề xuất

1. Triển khai Portal Identity cho một Customer test trong shared Domain.
2. Bật trang thiết bị và revoke session cho Customer test.
3. Kết nối SMTP và thử verify/reset với địa chỉ nội bộ.
4. Bật quản lý assignment cho operator, chưa mở self-service rộng rãi.
5. Phát hành debug APK có assignment reconciliation.
6. Kiểm thử Customer A/B isolation và một VIP Domain.
7. Cấu hình HTTPS công khai và Google OAuth cho allowlist.
8. Mở rộng pilot theo nhóm Customer.
9. Chỉ bắt đầu Billing sau khi Identity, Membership và entitlement ổn định.

Mỗi bước phải có feature flag hoặc đường rollback; không xóa session, local SIP
configuration hoặc dữ liệu FusionPBX trong quá trình rollback.

## 7. Thứ tự ưu tiên ngay tiếp theo

Ưu tiên số một là **Bước 1 — Portal dùng chung Customer Identity**. Công việc nên
bắt đầu bằng thiết kế contract web session và cầu nối Portal PHP/websocket, sau
đó mới xây màn hình đăng nhập. Đây là điểm phụ thuộc lớn nhất trước quản lý thiết
bị, email recovery, Google OAuth và Billing.
