# Kế hoạch Mphone Account Center

Trạng thái: đề xuất để lập kế hoạch triển khai  
Tài liệu chính tiếng Anh: `MPHONE_ACCOUNT_CENTER_PLAN.md`

## 1. Mục tiêu

Xây dựng khu vực tài khoản dùng chung cho hệ sinh thái Mphone dựa trên hai chủ
thể độc lập:

- **Identity** là con người đăng nhập và thực hiện hành động.
- **Customer** là cá nhân hoặc tổ chức sử dụng, sở hữu và thanh toán dịch vụ.

Customer Platform hiện tại sẽ là nguồn chính cho định danh, ngữ cảnh xác thực,
session, Membership và phân quyền Customer của Portal, ứng dụng Mphone và các
dịch vụ khách hàng trong tương lai.

Không dùng FusionPBX User, Google Account hoặc Odoo Contact làm định danh người
dùng trung tâm.

## 2. Mô hình dữ liệu

```text
Google / Password / Provider tương lai
                    |
                    | xác thực
                    v
                 Identity
                    +-- Hồ sơ cá nhân
                    +-- Provider đăng nhập
                    +-- Device Session
                    |
                    +-- Membership
                            |
                            v
                         Customer
                            +-- Thành viên và vai trò
                            +-- Extension và dịch vụ
                            +-- Gói cước và thanh toán
                            +-- Hồ sơ Customer
```

Một Identity có thể thuộc nhiều Customer. Một Customer có thể có nhiều Identity
với role `owner`, `customer_admin`, `billing_admin` hoặc `member`.

Customer không thuộc cố định về một cá nhân. Owner được biểu diễn bằng
Membership có role `owner` và được thay đổi qua một quy trình riêng có audit.

## 3. Nguồn Identity và xác thực

Customer Platform là nguồn Identity chính. Google là provider xác thực, không
phải cơ sở dữ liệu người dùng.

```text
mphone_identities
    identity_uuid
    primary_email
    status
         +-- mphone_identity_providers
                +-- password
                +-- google
                +-- provider tương lai
```

Mọi phương thức đăng nhập phải quy về cùng một `identity_uuid`. Không liên kết
provider chỉ vì email trùng nhau; việc liên kết cần session hợp lệ kèm recent
authentication hoặc quy trình khôi phục có kiểm soát.

FusionPBX User được giữ làm principal tương thích trong giai đoạn chuyển đổi,
không phải nguồn Identity của toàn hệ sinh thái.

## 4. Cấu trúc Account Center

Giai đoạn đầu mở rộng Portal hiện tại thay vì tạo frontend độc lập.

```text
/p/account                 Hồ sơ Identity cá nhân
/p/customers               Chọn Customer đang hoạt động
/p/customer/profile        Hồ sơ Customer hiện tại
/p/customer/members        Thành viên và phân quyền
/p/customer/services       Extension và dịch vụ
/p/customer/billing        Gói cước, hóa đơn và thanh toán
/p/customer/security       Audit và phiên đặc quyền
```

### 4.1 Tài khoản cá nhân — `/p/account`

Chủ thể là Identity đang đăng nhập. Trang gồm họ tên, avatar, điện thoại cá
nhân, email đã xác minh, password, provider liên kết, ngôn ngữ, múi giờ, device
session và danh sách Customer Membership.

Hồ sơ ứng dụng cá nhân được lưu trong bảng Customer Platform một-một mới:

```text
mphone_identity_profiles
    identity_uuid
    full_name
    phone_number
    avatar_object_key
    locale
    timezone
    created_at
    updated_at
    version
```

Email và provider vẫn nằm trong `mphone_identities` và
`mphone_identity_providers`. File avatar nằm trong object storage; database chỉ
lưu object key và metadata.

### 4.2 Chọn Customer — `/p/customers`

Hiển thị mọi Membership đang hoạt động của Identity và cho phép chọn Customer
workspace hiện tại.

```text
Nguyễn Văn A
  +-- Công ty ABC -- owner
  +-- Công ty XYZ -- member
  +-- Tài khoản cá nhân -- owner
```

Server phải kiểm tra Membership và phát hành lại session/token context. React
không được tự tạo quyền bằng cách thay `customer_uuid` cục bộ.

### 4.3 Hồ sơ Customer — `/p/customer/profile`

Chủ thể là active Customer. Owner và, tùy chính sách cuối cùng, customer admin
được sửa tên hiển thị, người liên hệ, điện thoại, email và địa chỉ liên hệ.

Portal không cập nhật trực tiếp mã, trạng thái, loại Customer, mã số thuế, tên
pháp lý, địa chỉ xuất hóa đơn, PBX tenant, gói cước, giá hoặc trạng thái dịch vụ.
Thay đổi pháp lý/hóa đơn tạo yêu cầu xác minh cho Odoo hoặc operator.

### 4.4 Thành viên — `/p/customer/members`

Chức năng gồm xem và mời thành viên, gán role, tạm ngưng/xóa Membership, gán
Extension thuộc Customer và quản lý `can_use`/`can_manage`.

Không được xóa hoặc hạ quyền owner cuối cùng. Chuyển owner phải dùng nghiệp vụ
riêng thay vì cập nhật role chung. Server khóa mọi Membership và Extension đích
theo active Customer.

### 4.5 Dịch vụ — `/p/customer/services`

Customer xem Extension, Identity Assignment, quyền hiệu lực và dịch vụ liên
quan. Chỉ các thao tác self-service hẹp, được cấp quyền rõ ràng, mới được ghi.

Quản trị FusionPBX nằm ngoài Account Center. Customer không quản lý Domain,
dialplan, SIP profile dùng chung, cấu hình hệ thống hoặc chuyển Extension giữa
các Customer.

### 4.6 Billing — `/p/customer/billing`

Customer xem gói cước, chu kỳ, hóa đơn, công nợ, số dư và lịch sử thanh toán;
thực hiện thanh toán khi được hỗ trợ.

Odoo là nguồn chính cho hồ sơ pháp lý, hợp đồng, gói thương mại, hóa đơn và công
nợ. Customer Platform có thể giữ read projection ổn định cho Portal và Mphone.

### 4.7 Security — `/p/customer/security`

Hiển thị theo role lịch sử thay đổi Membership, role, hồ sơ Customer, owner,
hành động đặc quyền, session bị ảnh hưởng và cảnh báo bảo mật.

Mỗi sự kiện lưu cả actor và workspace:

```text
actor_identity_uuid
customer_uuid
membership_uuid
action
target_type
target_id
occurred_at
```

## 5. Customer context và token contract

Session/access token dùng chung cần có tối thiểu:

```text
identity_uuid
active_customer_uuid
membership_uuid
membership_role
tenant_uuid
session_uuid
authorization_version
expires_at
```

`identity_uuid` xác định người thực hiện; `active_customer_uuid` xác định
workspace; `membership_uuid` chứng minh quan hệ truy cập; `tenant_uuid` khóa tài
nguyên thoại; `session_uuid` cho phép thu hồi phiên; `authorization_version` vô
hiệu hóa quyền cũ sau khi role/capability thay đổi.

Mỗi endpoint tự kiểm tra Identity, Customer, Membership, tenant, trạng thái và
capability. Việc ẩn/hiện trên trình duyệt không phải phân quyền.

## 6. Ranh giới sở hữu dữ liệu

| Hệ thống | Trách nhiệm chính |
|---|---|
| Customer Platform | Identity, hồ sơ cá nhân, Membership, Customer context, session, authorization |
| Google | Provider xác thực bên ngoài |
| Odoo | CRM, hồ sơ pháp lý, hợp đồng, gói thương mại, hóa đơn, công nợ |
| FusionPBX | Domain, Extension, SIP, thiết bị thoại, dữ liệu cuộc gọi |
| Portal và Mphone | Trải nghiệm người dùng sử dụng các API trên |

Mỗi trường dữ liệu chỉ có một hệ thống sở hữu chính. Không đồng bộ hai chiều tự
do.

## 7. Đồng bộ Odoo

Customer liên kết Odoo sử dụng tích hợp bất đồng bộ:

```text
Portal -> Customer Platform -> outbox có idempotency -> Odoo
                                                  -> Customer Platform projection
```

Yêu cầu:

- Không gọi Odoo trong mỗi lần tải trang.
- Hỗ trợ `pending`, `synced`, `failed`, `verification_required`.
- Có idempotency và retry.
- Không báo thành công khi chưa xác định trạng thái đồng bộ.
- Audit không lưu credential/token.
- Odoo gián đoạn không làm mất khả năng đăng nhập và chức năng không liên quan.

Trường do Customer Platform sở hữu có thể cập nhật ngay. Trường do Odoo sở hữu
phải qua luồng tích hợp hoặc xác minh.

## 8. Chuyển owner

Customer đang hoạt động phải còn ít nhất một owner active.

Luồng đề xuất:

1. Owner hiện tại chọn một member active.
2. Người nhận xác nhận yêu cầu.
3. Yêu cầu recent authentication khi phù hợp.
4. Một transaction nâng người nhận, hạ owner cũ theo lựa chọn, kiểm tra invariant,
   tăng authorization version, vô hiệu hóa session đặc quyền bị ảnh hưởng và ghi
   audit.
5. Superadmin dùng quy trình khôi phục có kiểm soát nếu owner mất truy cập.

Không dùng thao tác cập nhật Membership chung để thay thế luồng này.

## 9. Ma trận phân quyền đề xuất

| Capability | Owner | Customer admin | Billing admin | Member |
|---|---:|---:|---:|---:|
| Sửa tên hiển thị/liên hệ | Có | Đề xuất | Không | Không |
| Yêu cầu thay đổi pháp lý | Có | Đề xuất | Đề xuất | Không |
| Quản lý thành viên | Có | Giới hạn | Không | Không |
| Chuyển owner | Luồng riêng | Không | Không | Không |
| Xem billing | Có | Theo capability | Có | Không |
| Quản lý gán Extension | Có | Theo capability | Chỉ xem | Chỉ của mình |
| Quản lý tenant/cấu hình PBX | Không | Không | Không | Không |

Role cung cấp mặc định, nhưng capability phía server quyết định từng hành động.

## 10. Các giai đoạn triển khai

### Giai đoạn 1 — Hồ sơ Identity

- Thêm migration và `mphone_identity_profiles`.
- Thêm API đọc/cập nhật hồ sơ phạm vi hẹp.
- Nâng cấp `/p/account` với form song ngữ và validation.
- Giữ luồng đổi email đã xác minh và password hiện tại.
- Thêm CSRF, chuẩn hóa, optimistic concurrency, rate limit phù hợp và audit.

### Giai đoạn 2 — Customer context

- Thêm API liệt kê Membership được phép.
- Triển khai `/p/customers` và Customer switcher.
- Phát hành lại context phía server khi chọn Customer.
- Thêm và thực thi `authorization_version`.
- Kiểm tra lại context khi refresh và thao tác đặc quyền.

### Giai đoạn 3 — Hồ sơ Customer

- Xác định nơi lưu hồ sơ liên hệ và field ownership.
- Triển khai `/p/customer/profile`.
- Thực thi capability của owner/customer admin.
- Tách thay đổi tức thời khỏi thay đổi pháp lý cần xác minh.
- Hoàn thiện outbox, trạng thái và retry Odoo.

### Giai đoạn 4 — Membership và ownership

- Hoàn thiện `/p/customer/members`.
- Chuẩn hóa role-to-capability.
- Hoàn thiện mời, tạm ngưng, xóa và gán Extension.
- Thêm luồng chuyển owner riêng.
- Vô hiệu hóa session khi authorization thay đổi.

### Giai đoạn 5 — Services, billing và security

- Triển khai `/p/customer/services`.
- Hoàn thiện `/p/customer/billing`.
- Triển khai `/p/customer/security`.
- Thêm audit history, cảnh báo và lịch sử hành động đặc quyền cho Customer.

## 11. Nguyên tắc bất biến

- Identity là actor; Customer là workspace.
- Customer Platform là nguồn Identity chính.
- Google là provider xác thực, không phải chủ sở hữu user.
- Không dùng `customer_uuid` thay cho actor Identity.
- Không dùng FusionPBX `user_uuid` làm định danh toàn hệ sinh thái.
- Quản trị FusionPBX và cấu hình dùng chung nằm ngoài Portal.
- Server luôn khóa phạm vi theo Identity, Customer, Membership, tenant và tài
  nguyên sở hữu.
- Email, password, owner và hồ sơ pháp lý dùng luồng bảo mật riêng.
- Mỗi trường chỉ có một hệ thống sở hữu chính.
- Mọi thao tác đặc quyền có audit và vô hiệu hóa quyền cũ khi cần.

## 12. Các quyết định cần chốt trước thiết kế kỹ thuật

1. `customer_admin` có được sửa hồ sơ liên hệ hay chỉ owner?
2. Một Customer có được có nhiều owner đồng thời không?
3. Chuyển owner cần người nhận xác nhận, superadmin duyệt hay cả hai đối với một
   số loại Customer?
4. Những trường Customer nào luôn do Odoo sở hữu?
5. Có tự động tạo Customer cá nhân khi đăng ký Identity không?
6. Membership nhiều Customer và Customer switching có bắt buộc trong bản đầu?
7. Account Center tiếp tục dùng `/p/` hay sau này chuyển sang host riêng như
   `account.mphone.vn`?
8. Những hành động nào cần capability riêng thay vì suy ra từ role?

Cần chốt các quyết định này trước khi hoàn thiện API contract, database migration
và ước lượng triển khai.

## 13. Thuật ngữ và tên gọi trên giao diện

Các thuật ngữ Identity, Customer, Membership và Customer context phù hợp trong
kiến trúc, API, database và công cụ operator. Không nên hiển thị trực tiếp các
thuật ngữ này xuyên suốt giao diện tiếng Việt dành cho khách hàng.

Giao diện phải giúp người dùng phân biệt hai câu hỏi:

- **Ai đang đăng nhập?** — `Tài khoản của tôi`.
- **Ai đang sử dụng và thanh toán dịch vụ?** — `Hồ sơ dịch vụ`.

`Hồ sơ dịch vụ` là tên tiếng Việt được chọn cho Customer trên giao diện. Tên này
tự nhiên hơn `Không gian`, dùng được cho cả cá nhân và doanh nghiệp, đồng thời ít
bị nhầm với thông tin đăng nhập hơn `Tài khoản dịch vụ`.

### 13.1 Bộ thuật ngữ tiếng Việt

| Khái niệm kỹ thuật | Tên trên giao diện | Ghi chú |
|---|---|---|
| Account Center | Trung tâm tài khoản | Tên sản phẩm/khu vực |
| Identity account | Tài khoản của tôi | Người đang đăng nhập |
| Personal Identity profile | Thông tin cá nhân | Tên, avatar, điện thoại, ngôn ngữ |
| Customer | Hồ sơ dịch vụ | Tên bao quát hướng khách hàng |
| Customer list | Hồ sơ dịch vụ | Nhãn menu/danh sách |
| Active Customer | Hồ sơ đang sử dụng | Ngữ cảnh dịch vụ hiện tại |
| Customer switcher | Chuyển hồ sơ | Nhãn hành động ngắn |
| Individual Customer | Hồ sơ cá nhân | Chủ thể sử dụng dịch vụ là cá nhân |
| Organization Customer | Hồ sơ doanh nghiệp | Công ty hoặc tổ chức |
| Membership | Quyền tham gia | Chỉ dùng khi cần giải thích quan hệ |
| Owner | Chủ sở hữu | Vai trò sở hữu Customer |
| Customer administrator | Quản trị viên | Quản trị trong phạm vi Customer |
| Billing administrator | Quản trị thanh toán | Vai trò billing |
| Member | Thành viên | Thành viên thông thường |
| Ownership transfer | Chuyển quyền sở hữu | Nghiệp vụ đặc quyền riêng |

Từ `Khách hàng` vẫn phù hợp trong giao diện FusionPBX/operator, công cụ hỗ trợ,
báo cáo và tài liệu nội bộ. Không đổi tên Customer UUID hoặc các định danh kỹ
thuật trong code và API contract.

### 13.2 Tên menu được chốt

| Route | Tên tiếng Việt |
|---|---|
| `/p/account` | Tài khoản của tôi |
| `/p/customers` | Hồ sơ dịch vụ |
| `/p/customer/profile` | Thông tin hồ sơ |
| `/p/customer/members` | Thành viên |
| `/p/customer/services` | Dịch vụ & máy nhánh |
| `/p/customer/billing` | Thanh toán |
| `/p/customer/security` | Bảo mật & hoạt động |

Khu vực cá nhân và khu vực hồ sơ dịch vụ cần được phân biệt rõ về bố cục:

```text
Tài khoản của tôi
  +-- Thông tin cá nhân
  +-- Đăng nhập & bảo mật
  +-- Thiết bị của tôi

Hồ sơ dịch vụ
  +-- Thông tin hồ sơ
  +-- Thành viên
  +-- Dịch vụ & máy nhánh
  +-- Thanh toán
  +-- Bảo mật & hoạt động
```

### 13.3 Bộ chọn hồ sơ dịch vụ

Ưu tiên cách diễn đạt trực tiếp thay cho thuật ngữ context:

```text
Bạn đang sử dụng dịch vụ cho:

Công ty ABC
Doanh nghiệp · Chủ sở hữu
```

Danh sách chuyển hồ sơ có thể hiển thị:

```text
Chuyển hồ sơ

Nguyễn Văn A
Cá nhân · Chủ sở hữu

Công ty ABC
Doanh nghiệp · Chủ sở hữu

Công ty XYZ
Doanh nghiệp · Thành viên
```

Các hành động được dùng gồm `Chuyển hồ sơ`, `Quản lý hồ sơ`, `Tạo hồ sơ doanh
nghiệp` và `Rời khỏi hồ sơ`. Tránh dùng `Chọn Customer`, `Customer context` hoặc
`Chuyển tài khoản` trong giao diện khách hàng.

### 13.4 Quy tắc đặt tên

- Chỉ dùng `Tài khoản của tôi` cho thông tin thuộc Identity.
- Dùng `Hồ sơ dịch vụ` cho danh sách hoặc khái niệm Customer tổng quát.
- Khi đã biết loại hồ sơ, hiển thị `Cá nhân` hoặc `Doanh nghiệp` làm loại.
- Luôn hiển thị tên hồ sơ đang hoạt động trên các trang thuộc Customer.
- Trong xác nhận đổi role, billing hoặc owner, phải nêu tên hồ sơ bị tác động.
- Giữ nguyên tên backend `identity_uuid`, `customer_uuid`, `membership_uuid` và
  API contract.
- Mọi nhãn mới phải được thêm vào cả catalogue tiếng Việt và tiếng Anh; không
  hardcode trong React.
