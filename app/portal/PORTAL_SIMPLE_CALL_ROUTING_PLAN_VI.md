# Kế hoạch định tuyến cuộc gọi đơn giản trên Portal

## 1. Mục tiêu

Cung cấp cho Owner Customer quy trình tự cấu hình các mô hình tổng đài thông thường mà không phải nhìn thấy các khái niệm kỹ thuật của FusionPBX như dialplan, destination, ring group hoặc IVR.

Tính năng gồm:

- Chọn thành viên Nhóm nhận mặc định cho từng số gọi vào được cấp quyền.
- Chọn một số gọi ra mặc định được cấp quyền cho từng máy nhánh.
- Tự động đổ chuông đồng thời các thành viên trong cùng Nhóm nhận mặc định.
- Cấu hình lời chào riêng cho từng số điện thoại được cấp.
- Tùy chọn phím điều hướng đơn giản một tầng từ `0-9`.
- Giữ các kịch bản nâng cao dưới quyền quản lý của nhân viên Mphone.

Tài liệu này chỉ là kế hoạch. Tài liệu không bao gồm hoặc cho phép thay đổi triển khai.

## 2. Nguyên tắc sản phẩm

1. Màn hình Số điện thoại là nguồn duy nhất có thể sửa cho nhóm nhận mặc định, lời chào, phím điều hướng và fallback của DID.
2. Màn hình Máy nhánh chỉ hiển thị các số gọi vào dưới dạng tóm tắt chỉ đọc và chỉ quản lý Caller ID gọi ra mặc định được cấp quyền của máy nhánh.
3. Mỗi số gọi vào chỉ có một chế độ định tuyến đang hoạt động tại một thời điểm.
4. Số gọi ra độc lập với định tuyến gọi vào, lời chào và phím điều hướng.
5. Khách hàng chỉ được chọn các tài nguyên đã được cấp quyền cho Customer.
6. Chỉ membership role `owner` của Customer được thay đổi cấu hình này trên Portal.
7. Portal tuyệt đối không ghi đè kịch bản nâng cao hoặc cấu hình do nhân viên quản lý thủ công.
8. Portal lưu ý định nghiệp vụ; một dịch vụ phía server chuyển đổi ý định đó thành tài nguyên FusionPBX.
9. Chế độ quản lý định tuyến thuộc về từng DID gọi vào, không thuộc về máy nhánh hoặc toàn bộ Customer.
10. Mỗi DID chỉ có đúng một bên quản lý và một tuyến đang hoạt động tại một thời điểm.
11. Owner Customer không bao giờ được tự chuyển DID nâng cao về chế độ đơn giản; chỉ nhân viên Mphone có quyền mới được trả lại quyền quản lý.

## 3. Trải nghiệm MVP

### 3.1 Màn hình Máy nhánh

Ví dụ:

```text
101 — Nguyễn Văn An

Nhận cuộc gọi từ:
02873001234
02873005678
(chỉ xem)

Số gọi ra mặc định:
[02873001234 v]
```

Quy tắc:

- Một máy nhánh có thể nhận cuộc gọi từ nhiều số gọi vào được cấp quyền, nhưng membership này chỉ được sửa tại màn hình Số điện thoại.
- Danh sách số gọi vào được suy ra từ các nhóm nhận mặc định và chỉ đọc tại màn hình này.
- Mỗi máy nhánh có một số gọi ra mặc định.
- Nhiều máy nhánh có thể dùng chung một số gọi ra.
- Số gọi ra chỉ được chọn từ danh sách do server cung cấp; không cho nhập tự do.
- Các role không phải Owner không được thay đổi các trường này.

### 3.2 Màn hình Số điện thoại

Ví dụ:

```text
02873001234

Nhóm nhận mặc định:
[101 Nguyễn Văn An] [102 Trần Văn Bình] [+ Thêm]

Lời chào:                 [Bật]
Tệp lời chào:             [Chọn hoặc tải lên]

Cho phép bấm phím:        [Bật]

0 -> [Lễ tân v]
1 -> [Nhóm Kinh doanh v]
2 -> [Nhóm Kỹ thuật v]

Fallback khi không bấm hoặc bấm sai:
Nhóm nhận mặc định: 101, 102

Tóm tắt luồng gọi:
Lời chào -> chờ bấm phím
             |- 0 -> Lễ tân
             |- 1 -> Nhóm Kinh doanh
             |- 2 -> Nhóm Kỹ thuật
             `- không bấm/sai -> 101, 102
```

Nhóm nhận mặc định là nguồn duy nhất có thể sửa cho membership gọi vào. Nhiều máy nhánh trong nhóm này đổ chuông đồng thời. Đây cũng là fallback cho luồng lời chào và phím điều hướng.

Trong chế độ đơn giản, fallback được cố định là Nhóm nhận mặc định; khách không cấu hình một đích fallback tùy ý khác. Giao diện phải trình bày rõ hành vi này để kết quả định tuyến có thể dự đoán được.

Tóm tắt luồng gọi do server sinh từ cấu hình dự kiến. Nó hiển thị luồng đổ chuông trực tiếp, chỉ lời chào hoặc có phím trước khi nhấn **Lưu và áp dụng**, mà không làm lộ tên tài nguyên FusionPBX.

Khi DID không ở `portal_simple`, mọi điều khiển lời chào, recording và phím điều hướng chuyển thành chỉ đọc, đồng thời màn hình hiển thị thông báo quản lý tương ứng. Trình duyệt không được cung cấp nút để khách tự trả DID nâng cao về chế độ đơn giản.

Tên tính năng hiển thị cho khách hàng nên là **Lời chào & phím điều hướng**, không dùng thuật ngữ IVR.

## 4. Cách xử lý cuộc gọi

### 4.1 Đổ chuông trực tiếp

```text
DID -> Nhóm nhận mặc định, tất cả thành viên đổ chuông đồng thời
```

### 4.2 Có lời chào, không có phím điều hướng

```text
DID -> phát lời chào -> Nhóm nhận mặc định
```

### 4.3 Có lời chào và phím điều hướng

```text
DID -> phát lời chào và nhận phím
      |- phím hợp lệ -> máy nhánh hoặc nhóm đã cấu hình
      |- không bấm   -> Nhóm nhận mặc định
      `- phím sai    -> phát lại một lần -> Nhóm nhận mặc định
```

Khi bật phím điều hướng, các thành viên của Nhóm nhận mặc định không đổ chuông ngay. Nhóm này vẫn là fallback cho trường hợp không bấm và lần bấm sai cuối cùng.

Cấu hình số gọi ra không bị ảnh hưởng bởi các chế độ trên.

## 5. Giới hạn phím điều hướng đơn giản

Để tính năng không trở thành công cụ tạo dialplan tổng quát:

- Chỉ hỗ trợ một tầng phím.
- Chỉ hỗ trợ các phím `0-9`.
- Mỗi phím có tối đa một đích.
- Đích phải là máy nhánh hoặc nhóm máy nhánh được cấp quyền, thuộc Customer hiện tại.
- Không cho một phím trỏ sang menu phím hoặc IVR khác.
- Không hỗ trợ đích là số điện thoại ngoài trong chế độ đơn giản.
- Không bao gồm giờ làm việc, ngày nghỉ, queue, điều kiện hoặc IVR nhiều tầng.
- Phím sai chỉ phát lại tối đa một lần rồi chuyển về đích không bấm.
- Không bấm và lần bấm sai cuối cùng sẽ chuyển tới Nhóm nhận mặc định hiện tại.
- Không cho bật phím điều hướng nếu thiếu lời chào hợp lệ hoặc đường dự phòng hợp lệ.

Mọi yêu cầu vượt qua giới hạn trên được coi là kịch bản nâng cao do Mphone quản lý.

## 6. Phân quyền và cô lập tenant

### 6.1 Chỉ Owner được ghi

Mọi endpoint ghi phải yêu cầu chính xác membership role:

```text
portal_identity.membership.role = owner
```

`customer_admin`, `billing_admin`, user được gán máy nhánh và FusionPBX `admin` không tương đương với Owner Customer đối với tính năng này.

Việc ẩn nút trên React chỉ phục vụ trải nghiệm. Mọi endpoint ghi phải kiểm tra quyền lại ở phía server.

### 6.2 Kiểm tra bắt buộc phía server

Mọi truy vấn đọc và ghi phải dùng phạm vi từ session và xác minh:

- Portal identity hợp lệ và có workspace Customer đang hoạt động.
- Role chính xác là Owner đối với thao tác ghi.
- `domain_uuid` từ session.
- `customer_uuid` từ session.
- DID thuộc quyền sở hữu hoặc quyền sử dụng của Customer hiện tại.
- Máy nhánh thuộc quyền quản lý của Customer hiện tại.
- Quyền sử dụng số làm Caller ID gọi ra.
- Quyền sở hữu recording và nhóm đích.
- Từ chối UUID của Customer khác, kể cả khi cùng Domain.

Không tin `domain_uuid` hoặc `customer_uuid` do trình duyệt gửi lên làm phạm vi có thẩm quyền.

## 7. Khảo sát trước khi triển khai

Trước khi chốt schema hoặc endpoint, phải xác định nguồn dữ liệu có thẩm quyền cho:

1. Các DID được cấp cho Customer.
2. Các máy nhánh do Customer quản lý, không chỉ máy nhánh gán cho user đăng nhập.
3. Các số được phép dùng làm Caller ID gọi ra.
4. Các nhóm máy nhánh được phép xuất hiện trong danh sách đích của phím.
5. Các tuyến nâng cao hoặc cấu hình thủ công đang tồn tại.

Không được giả định mọi tài nguyên cùng `domain_uuid` đều thuộc một Customer.

Giai đoạn khảo sát phải tạo được các phép tra cứu nội bộ đáng tin cậy:

```text
Customer -> DID gọi vào được cấp quyền
Customer -> máy nhánh được quản lý
Customer -> Caller ID gọi ra được cấp quyền
Customer -> nhóm đích được cấp quyền
```

## 8. Mô hình dữ liệu cấu hình

Portal nên lưu trạng thái mong muốn ở cấp nghiệp vụ, thay vì chỉ cố gắng suy ngược cấu hình từ dialplan đã sinh.

Thiết kế cần lưu:

- Thành viên Nhóm nhận mặc định theo từng DID.
- Caller ID gọi ra mặc định của máy nhánh.
- Chế độ định tuyến của từng DID.
- Cấu hình lời chào và tham chiếu recording của từng DID.
- Ánh xạ phím với đích của từng DID.
- UUID các tài nguyên FusionPBX do hệ thống sinh.
- Chế độ và quyền sở hữu cấu hình.
- Revision quản lý, trạng thái chuyển tiếp và tham chiếu duy nhất tới tuyến đang hoạt động.
- Fingerprint được áp dụng gần nhất và fingerprint quan sát gần nhất để phát hiện xung đột.
- Snapshot có thể khôi phục của cấu hình đơn giản hoạt động gần nhất.
- Phiên bản, trạng thái và lịch sử thay đổi.

Mọi bản ghi thuộc tenant phải có:

- `domain_uuid`
- `customer_uuid`
- UUID của đối tượng
- User và thời gian tạo/cập nhật
- Trạng thái kích hoạt hoặc vòng đời
- Phiên bản cấu hình khi phù hợp

Tên bảng và trường cụ thể chỉ được chốt sau khi khảo sát mô hình cấp quyền Customer hiện có.

## 9. Chuyển đổi sang FusionPBX

### 9.1 Thành viên nhận cuộc gọi

- Đọc danh sách thành viên Nhóm nhận mặc định của DID.
- Tạo hoặc cập nhật Ring Group đổ chuông đồng thời cho từng DID do Portal quản lý.
- Nên giữ Ring Group kể cả khi chỉ có một thành viên để việc thay đổi thành viên không làm thay đổi loại đích.
- Cho Destination của DID trỏ tới điểm định tuyến do hệ thống quản lý.

### 9.2 Lời chào

- Chỉ dùng recording hợp lệ thuộc cùng Customer và Domain.
- Phát lời chào trước Ring Group do hệ thống quản lý.
- Khi tắt lời chào, khôi phục tuyến trực tiếp tới Ring Group.

### 9.3 Phím điều hướng

- Tạo hoặc cập nhật IVR FusionPBX một tầng do hệ thống quản lý.
- Chỉ ánh xạ phím tới máy nhánh hoặc nhóm được cấp quyền.
- Timeout/không bấm và lần bấm sai cuối cùng chuyển về Ring Group được sinh từ Nhóm nhận mặc định hiện tại.
- Cho Destination của DID trỏ tới IVR do hệ thống quản lý.
- Khi tắt phím, khôi phục chế độ chỉ lời chào hoặc đổ chuông trực tiếp.

### 9.4 Caller ID gọi ra

- Chỉ cập nhật Caller ID gọi ra của máy nhánh bằng giá trị được cấp quyền.
- Không tin Caller ID do SIP client hoặc dữ liệu tùy ý từ trình duyệt gửi lên.

## 10. Quản lý tệp lời chào

Portal nên cung cấp quy trình recording phạm vi hẹp, chỉ dành cho Owner, đồng thời tận dụng chức năng recording của FusionPBX khi phù hợp.

Yêu cầu:

- Chỉ chấp nhận định dạng âm thanh được phê duyệt.
- Giới hạn dung lượng và thời lượng.
- Kiểm tra loại media thực tế, không chỉ dựa vào phần mở rộng.
- Chuẩn hóa âm thanh sang định dạng tương thích với FreeSWITCH.
- Tạo tên file ở phía server và chống chèn đường dẫn.
- Giới hạn recording theo Domain và Customer.
- Cho phép nghe thử trước khi áp dụng.
- Không cho xóa recording đang được tham chiếu.
- Ghi audit khi tải lên, thay thế hoặc xóa.

Phiên bản đầu có thể chỉ hỗ trợ tải lên và nghe thử. Tính năng thu âm trực tiếp trên trình duyệt triển khai sau.

## 11. Chế độ đơn giản và nâng cao

Chế độ quản lý được gán theo từng DID, không gán cho máy nhánh hoặc toàn bộ Customer. Vì vậy một máy nhánh có thể nhận cuộc gọi từ một DID đơn giản và đồng thời tham gia một DID nâng cao khác mà không tạo quyền sở hữu chung.

Mỗi DID cần có trạng thái quản lý rõ ràng:

- `portal_simple`: dịch vụ Portal được phép quản lý luồng gọi.
- `transitioning_to_advanced`: mọi thao tác ghi từ Portal bị khóa trong khi Mphone chuẩn bị và xuất bản một tuyến nâng cao riêng.
- `mphone_advanced`: nhân viên Mphone sở hữu luồng gọi; Portal chỉ đọc.
- `unmanaged`: cấu hình hiện có không thuộc quyền chỉnh sửa của Portal.

Quy tắc quyền sở hữu:

- Trong `portal_simple`, synchronizer độc quyền quản lý điểm định tuyến Destination, Ring Group, luồng lời chào, IVR và các dialplan được sinh cho DID đó.
- Trong `mphone_advanced`, Mphone độc quyền quản lý luồng gọi đang hoạt động; synchronizer không được tạo, sửa chữa, trỏ lại hoặc đối soát bất kỳ tài nguyên định tuyến nào của DID.
- Quyền dùng Caller ID gọi ra vẫn độc lập với chế độ quản lý DID gọi vào.
- Owner Customer không được chọn chế độ, tự lấy lại DID nâng cao hoặc áp dụng form đơn giản cũ sau khi Mphone tiếp quản.
- Chỉ nhân viên Mphone có permission takeover hoặc release phạm vi hẹp mới được đổi quyền quản lý.

Với DID nâng cao, hiển thị thông báo ngắn:

```text
Số này đang sử dụng kịch bản nâng cao. Vui lòng liên hệ Mphone để thay đổi.
```

Portal không được suy đoán quyền sở hữu dựa trên tên và không được ghi đè Destination, Ring Group, IVR hoặc dialplan hiện có không thuộc quyền quản lý.

### 11.1 Quy trình Mphone tiếp quản

Khi Customer yêu cầu định tuyến nâng cao, Mphone phải tiếp quản theo quy trình có kiểm soát, không sửa trực tiếp các tài nguyên Portal đã sinh:

1. Kiểm tra lại DID, Customer, Domain, mode, revision và fingerprint của tài nguyên đã sinh.
2. Chuyển nguyên tử DID từ `portal_simple` sang `transitioning_to_advanced`, tăng management revision và từ chối mọi thao tác ghi Portal tiếp theo đối với DID đó.
3. Giữ lại desired state đơn giản, các assignment, UUID tài nguyên và tuyến đang hoạt động dưới dạng snapshot có thể khôi phục. Assignment đơn giản chuyển sang suspended, không bị xóa.
4. Tạo mới hoặc clone một graph tài nguyên nâng cao riêng với UUID mới. Sau đó Mphone có thể thêm giờ làm việc, ngày nghỉ, queue, số ngoài hoặc IVR nhiều tầng mà không sửa graph đơn giản được giữ lại.
5. Kiểm tra toàn bộ graph nâng cao và XML trước khi xuất bản.
6. Ở bước xuất bản cuối cùng, chuyển tham chiếu tuyến hoạt động duy nhất của DID từ phiên bản đơn giản sang phiên bản nâng cao.
7. Đặt mode thành `mphone_advanced` và ghi người thao tác, trạng thái trước/sau, revision cùng các tham chiếu tài nguyên vào audit.
8. Nếu chuẩn bị hoặc xuất bản thất bại, giữ hoặc khôi phục tuyến đơn giản đang hoạt động và trả trạng thái quản lý về `portal_simple`.

Ẩn hoặc khóa nút trên React không phải là khóa bảo mật. Mọi mutation Portal phải đọc lại mode và management revision phía server ngay trước khi lưu. Request cũ phải nhận `409 route_management_changed`, không được thay đổi desired state hoặc tài nguyên FusionPBX.

### 11.2 Trả DID về quản lý đơn giản

Customer không được thực hiện chuyển đổi này. Nhân viên Mphone có quyền có thể chủ động release DID nâng cao bằng cách khôi phục snapshot simple tốt gần nhất hoặc tạo và kiểm tra một phiên bản simple mới. Hệ thống không được cố suy ngược cấu hình đơn giản từ một dialplan nâng cao tùy ý.

Quy trình release phải chuẩn bị và kiểm tra graph simple, chuyển tham chiếu tuyến hoạt động duy nhất, rồi mới đặt mode thành `portal_simple`. Thao tác phải có bước xác nhận và audit.

## 12. Quy trình áp dụng và an toàn khi lỗi

Thay đổi được giữ tạm trên giao diện và chỉ áp dụng khi Owner nhấn **Lưu và áp dụng**.

Quy trình phía server:

1. Kiểm tra quyền Owner và phạm vi tenant.
2. Đọc lại mode và revision quản lý của DID; trả HTTP `409` nếu không còn đúng revision `portal_simple` được mong đợi.
3. Kiểm tra mọi tài nguyên tham chiếu, quyền sử dụng và fingerprint tài nguyên đã sinh.
4. Validate toàn bộ cấu hình mới.
5. Tạo phiên bản cấu hình/change set mới.
6. Tạo hoặc cập nhật một phiên bản tuyến chưa hoạt động và kiểm tra tham chiếu cùng XML của nó.
7. Chỉ xuất bản bằng cách đổi tham chiếu tuyến hoạt động duy nhất sau khi phiên bản mới đã hoàn chỉnh.
8. Làm mới XML/cache cần thiết và xác minh tuyến đã xuất bản.
9. Đánh dấu phiên bản hoạt động và ghi audit.
10. Nếu lỗi, giữ hoặc khôi phục tham chiếu tới tuyến hoạt động tốt gần nhất.

Các trạng thái trên giao diện:

- Không có thay đổi
- Có thay đổi chưa lưu
- Đang áp dụng
- Đã áp dụng
- Áp dụng thất bại

Luồng cuộc gọi đang hoạt động phải được giữ nguyên nếu lần áp dụng mới thất bại.

## 13. Cấu trúc service Portal

Sử dụng các endpoint phạm vi hẹp dưới `app/portal/service/`; không tạo endpoint ghi cấu hình tổng quát.

Các trách nhiệm dự kiến:

```text
GET  cấu hình số và tài nguyên được cấp quyền
GET  tóm tắt số gọi vào và danh sách số gọi ra được cấp quyền của máy nhánh
POST cấu hình Nhóm nhận mặc định của số điện thoại
POST cấu hình Caller ID gọi ra của máy nhánh
POST cấu hình lời chào của số điện thoại
POST cấu hình phím điều hướng
POST tải lên lời chào
```

Mỗi endpoint ghi phải tự kiểm tra Owner, Customer, Domain, quyền sở hữu, quyền sử dụng và payload.

Mọi response dùng cho form có thể sửa phải chứa mode và revision quản lý hiện tại của từng DID. Mọi mutation phải gửi revision làm cơ sở; server đọc và kiểm tra lại cả hai giá trị, đồng thời trả HTTP `409` cho request cũ hoặc DID không còn ở simple.

Tên file endpoint cụ thể sẽ được chọn khi triển khai để phù hợp quy ước hiện có của Portal.

## 14. Các giai đoạn triển khai

### Giai đoạn 0 — Khảo sát và chốt đặc tả

Tài liệu triển khai: [`PHASE_0_SIMPLE_CALL_ROUTING_DISCOVERY.md`](PHASE_0_SIMPLE_CALL_ROUTING_DISCOVERY.md). Giai đoạn 0 hoàn thành ngày 2026-08-31 mà không thay đổi dữ liệu Customer hoặc luồng thoại đang chạy.

- Xác nhận nguồn có thẩm quyền của DID, máy nhánh, Caller ID và nhóm.
- Kiểm kê Destination, Ring Group, recording, IVR và tuyến nâng cao hiện có.
- Định nghĩa cách nhận diện tài nguyên được quản lý và quy tắc xung đột.
- Định nghĩa state machine theo DID, management revision, fingerprint, active-route pointer và cách xử lý request cũ.
- Thiết kế schema trạng thái mong muốn và chiến lược audit.
- Xác định cách backup và rollback an toàn cho các bảng bị tác động.
- Chuẩn bị dữ liệu kiểm thử cho ít nhất hai Customer trong cùng Domain nếu mô hình hỗ trợ.
- Hoàn thành đặc tả có thể triển khai và kế hoạch migration. Không bắt đầu thao tác ghi định tuyến của Customer khi nguồn quyền sở hữu, phân loại tài nguyên hiện hữu hoặc hành vi vòng đời vẫn chưa được giải quyết.

### Giai đoạn 1 — Nền tảng DID và xuất bản tuyến

Tài liệu triển khai: [`PHASE_1_SIMPLE_CALL_ROUTING_IMPLEMENTATION.md`](PHASE_1_SIMPLE_CALL_ROUTING_IMPLEMENTATION.md). Giai đoạn 1 được triển khai local ngày 2026-08-31 và vẫn khóa hoàn toàn thao tác ghi định tuyến của Customer.

- Thêm kho DID, lịch sử assignment và entitlement gọi vào/Caller ID gọi ra gắn với revision của assignment.
- Thêm bản ghi quản lý định tuyến theo DID, management revision, trạng thái chuyển đổi, phiên bản cấu hình và tham chiếu tuyến hoạt động duy nhất.
- Thêm dịch vụ vòng đời DID dùng khóa theo DID, revision, idempotency và audit.
- Thêm các primitive dùng chung để chuẩn bị, kiểm tra, xuất bản, xác minh và rollback cho cả tuyến Simple và Advanced.
- Thêm fingerprint tài nguyên, phát hiện xung đột, lịch sử cấu hình và audit trước khi xuất bản tuyến được quản lý đầu tiên.
- Thêm công cụ import và đối soát an toàn; không tiếp quản DID hay tuyến hiện hữu chỉ vì trùng số.
- Thêm migration, backup, rollback và kiểm thử tự động cho tính duy nhất của assignment, revision cũ, locking, idempotency và lỗi xuất bản.
- Chưa mở thao tác ghi định tuyến cho Customer trong giai đoạn này.

### Giai đoạn 2 — Vòng đời DID dành cho nhân viên Mphone

Tài liệu triển khai: [`PHASE_2_SIMPLE_CALL_ROUTING_IMPLEMENTATION.md`](PHASE_2_SIMPLE_CALL_ROUTING_IMPLEMENTATION.md). Giai đoạn 2 được triển khai local ngày 2026-08-31; kho DID vẫn trống cho đến khi nhân viên chủ động thêm số.

- Thêm kho DID, chi tiết assignment, lịch sử assignment và thao tác theo trạng thái trong Portal Superadmin.
- Thêm workflow reserve, assign, suspend, resume, release, quarantine, transfer và chuyển Domain qua dịch vụ vòng đời DID dùng chung.
- Khi assign, tạo và xuất bản một tuyến ban đầu tối thiểu nhưng hợp lệ; chỉ kích hoạt và hiển thị assignment sau khi xác minh xuất bản thành công.
- Thu hồi hoặc khôi phục entitlement Caller ID gọi ra khi suspend, release hoặc transfer yêu cầu.
- Thêm đối soát trạng thái provider và chẩn đoán có hướng xử lý, nhưng không coi dữ liệu provider là quyền Customer.
- Kiểm tra retry và recovery cho pending assignment, lỗi xuất bản, suspend, transfer, release và quarantine.
- Giới hạn mọi thao tác vòng đời DID bằng permission hẹp dành cho nhân viên Mphone.
- Chưa mở thao tác ghi định tuyến cho Customer trong giai đoạn này.

### Giai đoạn 3 — Định tuyến Simple cơ bản

Tài liệu triển khai: [`PHASE_3_SIMPLE_CALL_ROUTING_IMPLEMENTATION.md`](PHASE_3_SIMPLE_CALL_ROUTING_IMPLEMENTATION.md). Giai đoạn 3 được triển khai local ngày 2026-08-31 và mở thao tác ghi Simple routing chỉ dành cho Owner qua cơ chế xuất bản có phiên bản.

- Thêm API đọc và ghi chỉ dành cho Owner.
- Thêm tóm tắt số gọi vào chỉ đọc và Caller ID gọi ra có thể sửa tại màn hình Máy nhánh.
- Thêm Nhóm nhận mặc định có thể sửa tại màn hình Số điện thoại.
- Lưu thành viên Nhóm nhận mặc định theo DID làm nguồn duy nhất cho gán số gọi vào.
- Tự động tạo/cập nhật Ring Group đổ chuông đồng thời.
- Áp dụng Caller ID gọi ra được cấp quyền.
- Dùng cơ chế xuất bản có phiên bản và rollback của Giai đoạn 1 cho mọi thao tác **Lưu và áp dụng**.
- Thêm kiểm tra mode/revision phía server và phát hiện xung đột trước khi bật thao tác ghi Portal đầu tiên.
- Chưa bao gồm lời chào hoặc phím điều hướng.

### Giai đoạn 4 — Lời chào và phím điều hướng

Tài liệu triển khai: [`PHASE_4_SIMPLE_CALL_ROUTING_IMPLEMENTATION.md`](PHASE_4_SIMPLE_CALL_ROUTING_IMPLEMENTATION.md). Giai đoạn 4A và 4B được triển khai local ngày 2026-08-31 với cổng kiểm tra riêng cho recording và keypad.

#### Giai đoạn 4A — Lời chào

- Thêm tải lên, chọn, nghe thử và kiểm tra recording.
- Thêm bật/tắt lời chào theo DID.
- Triển khai luồng lời chào tới Ring Group mặc định.
- Kiểm thử media bị thiếu, không hợp lệ, bị thay thế hoặc đang được sử dụng.

#### Giai đoạn 4B — Phím điều hướng

- Thêm bật/tắt phím theo DID.
- Thêm ánh xạ phím `0-9`.
- Hỗ trợ đích là máy nhánh hoặc nhóm được cấp quyền.
- Triển khai timeout/không bấm về các thành viên DID hiện tại.
- Triển khai xử lý phím sai.
- Khôi phục chế độ đơn giản trước đó khi tắt phím.
- Thêm Tóm tắt luồng gọi do server sinh cho các tuyến trực tiếp, chỉ lời chào và có phím.

Giai đoạn 4A và 4B có thể phát hành cùng một đợt, nhưng phải có cổng kiểm thử riêng vì xử lý media và định tuyến phím có các dạng lỗi khác nhau.

### Giai đoạn 5 — Tiếp quản nâng cao và hoàn thiện vận hành

- Thêm workflow chỉ dành cho Mphone để tiếp quản trực tiếp tuyến đang hoạt động từ `portal_simple` sang `mphone_advanced`; Customer bị khóa ghi ngay và kỹ thuật viên cấu hình live trong FusionPBX.
- Không cung cấp lịch sử phiên bản hoặc rollback cho Customer. Customer chỉ thấy mode hiện tại và lỗi ngắn gọn có thể xử lý.
- Khi trả về Basic, kỹ thuật viên chọn ít nhất một máy nhánh Customer làm nhóm nhận ban đầu. Hệ thống tạo, kiểm tra và chuyển sang một tuyến Basic mới trước khi đặt mode về `portal_simple`.
- Chỉ tự động xóa Destination của DID, Dialplan entry point đã xác minh là dành riêng cho DID và tài nguyên Basic cũ có UUID ownership chính xác.
- IVR, Queue, Time Condition, Recording và Ring Group thủ công không bị tự động xóa. Hệ thống chỉ liệt kê action tham chiếu trực tiếp để kỹ thuật viên kiểm tra và tự dọn.
- Nếu không xác định được duy nhất Destination hoặc Dialplan entry point đang dùng chung, workflow tự động dừng trước khi thay đổi route.
- Hoàn thiện audit backend, trạng thái chuyển đổi, lỗi có hướng xử lý và tài liệu vận hành Mphone.

## 15. Ma trận kiểm thử bắt buộc

### Chức năng định tuyến

- Một DID có một thành viên trong Nhóm nhận mặc định.
- Một DID có nhiều thành viên trong Nhóm nhận mặc định.
- Một máy nhánh hiển thị chỉ đọc dưới nhiều DID gọi vào.
- Nhiều máy nhánh dùng chung Caller ID gọi ra.
- Bật lời chào nhưng không bật phím.
- Bật phím và người gọi bấm phím hợp lệ.
- Người gọi không bấm phím.
- Người gọi bấm phím chưa được gán.
- Tóm tắt luồng gọi khớp với tuyến hiệu lực được sinh trong mọi chế độ simple.
- Máy nhánh hoặc nhóm đích bị vô hiệu hóa hoặc xóa.
- DID không còn máy nhánh nào nhận.
- Tắt phím và khôi phục đổ chuông trực tiếp.
- Tắt lời chào và khôi phục đổ chuông trực tiếp.

### Phân quyền và cô lập dữ liệu

- Owner đọc và thay đổi được cấu hình được cấp quyền.
- Mọi role không phải Owner bị endpoint ghi từ chối.
- Customer A không thể gửi DID, máy nhánh, nhóm hoặc recording UUID của Customer B.
- Việc đổi workspace làm mất hiệu lực các giả định của form cũ.
- Customer hoặc Domain do trình duyệt gửi lên không thể mở rộng phạm vi.
- Form Portal cũ được mở trước lúc takeover phải bị từ chối bằng HTTP `409` và không thay đổi dữ liệu.
- Owner Customer không thể chuyển DID nâng cao về quản lý đơn giản.
- Chỉ thao tác của nhân viên Mphone có quyền mới được takeover hoặc release DID.

### Độ tin cậy

- Đồng bộ FusionPBX thất bại không làm hỏng tuyến cuộc gọi hiện tại.
- Áp dụng lại cấu hình không đổi phải có tính idempotent.
- Phát hiện và đối soát tài nguyên sinh dở dang.
- Không bao giờ ghi đè DID ở chế độ nâng cao.
- Graph tài nguyên simple và advanced dùng UUID riêng và không bao giờ bị hai bên cùng sửa.
- Chuẩn bị advanced thất bại vẫn giữ tuyến simple hoạt động và cho phép cấu hình.
- Xuất bản advanced thất bại phải giữ hoặc khôi phục tuyến simple hoạt động gần nhất.
- Assignment simple bị suspended và snapshot vẫn có thể khôi phục sau takeover.
- Audit xác định được người thao tác và cấu hình trước/sau.

## 16. Tiêu chí hoàn thành MVP

MVP được coi là hoàn thành khi:

- Chỉ Owner Customer có thể thay đổi tính năng qua Portal.
- Owner chỉ thấy tài nguyên được cấp cho Customer đang hoạt động.
- Không thể nhập số gọi vào/gọi ra ngoài danh mục được cấp quyền.
- Các máy nhánh trong cùng Nhóm nhận mặc định đổ chuông đồng thời.
- Membership DID gọi vào chỉ được sửa tại màn hình Số điện thoại và chỉ đọc tại màn hình Máy nhánh.
- Lời chào hoạt động được cả khi có và không có phím điều hướng.
- Chế độ phím không làm nhóm mặc định đổ chuông ngay.
- Không bấm và lần bấm sai cuối cùng chuyển tới Nhóm nhận mặc định hiện tại.
- Màn hình Số điện thoại hiển thị tóm tắt do server sinh của tuyến sắp được áp dụng.
- Tắt phím sẽ khôi phục tuyến đơn giản trước đó.
- Số gọi ra độc lập với chế độ định tuyến gọi vào.
- Tuyến nâng cao và không được quản lý được bảo vệ khỏi thao tác ghi của Portal.
- Chế độ quản lý được thực thi theo từng DID ở phía server cho mọi mutation.
- Takeover khóa thao tác ghi Portal trước khi Mphone chuẩn bị tuyến advanced.
- Owner Customer không thể release DID nâng cao về simple.
- Tuyến simple và advanced là các phiên bản riêng và chỉ một tham chiếu tuyến hoạt động được xuất bản.
- Mọi thay đổi đều có audit.
- Tuyến hoạt động trước đó vẫn chạy nếu áp dụng cấu hình mới thất bại.

## 17. Thứ tự triển khai khuyến nghị

Hoàn thành các giai đoạn theo thứ tự phụ thuộc:

```text
Khảo sát và chốt đặc tả
    -> Nền tảng DID và xuất bản tuyến
    -> Vòng đời DID dành cho nhân viên Mphone
    -> Định tuyến Simple cơ bản
    -> Lời chào và phím điều hướng
    -> Tiếp quản nâng cao và hoàn thiện vận hành
```

Giai đoạn 1 là điều kiện tiên quyết cho mọi tuyến được quản lý, bao gồm tuyến ban đầu được tạo khi gán DID. Giai đoạn 2 phải chứng minh việc gán, xuất bản, suspend, transfer, release và recovery của DID là an toàn trước khi Giai đoạn 3 mở thao tác ghi định tuyến đầu tiên cho Customer.

Xác minh entitlement DID, quyền Caller ID gọi ra và việc tự đồng bộ Ring Group trong Giai đoạn 3 trước khi thêm media hoặc phím điều hướng. Giai đoạn 4A và 4B có thể phát triển trong cùng đợt, nhưng phải kiểm thử độc lập.

Chỉ workflow Advanced dành cho nhân viên được lùi tới Giai đoạn 5. State quản lý, revision, phiên bản tuyến, active-route pointer, audit, phát hiện xung đột và rollback phải có từ Giai đoạn 1, không được trì hoãn. Thứ tự này loại bỏ phụ thuộc vòng giữa gán DID và xuất bản tuyến ban đầu, đồng thời giữ cho từng đợt triển khai có thể kiểm thử độc lập.
