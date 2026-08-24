# Triển khai Google OAuth và liên kết provider

Trạng thái: backend, Portal và Android đã triển khai ngày 2026-08-25; chờ nghiệm
thu bằng Google test user thật.

## Phạm vi đã triển khai

- Google login chỉ tra cứu bằng `provider_subject` (`sub`) đã liên kết; không tự
  liên kết theo email trùng.
- Backend xác minh chữ ký Google, audience allowlist, issuer, expiry,
  `email_verified` và subject.
- Hash của mỗi Google ID token chỉ được dùng một lần để chặn replay; token thô
  không được lưu database hoặc audit.
- Portal dùng Authorization Code + PKCE + state. Client secret và ID token chỉ
  tồn tại phía server, không chuyển tới JavaScript hoặc localStorage.
- Người dùng liên kết/gỡ Google tại trang Tài khoản. Cả hai thao tác yêu cầu mật
  khẩu hiện tại; không cho gỡ provider cuối cùng.
- Android dùng Credential Manager và Web Client ID do server công bố, sau đó gửi
  ID token qua HTTPS tới Auth v2 để xác minh.
- Session, refresh, revoke, assignment và Managed Account dùng chung contract với
  đăng nhập password.

## Cấu hình

- Secret/config: `/etc/mphone/google-oauth.env`, `root:root`, mode `0600`.
- Edge Functions nhận config qua Docker `env_file`.
- PHP-FPM nhận ba biến allowlist qua systemd `EnvironmentFile` và pool config;
  worker web không có quyền đọc trực tiếp file secret.
- Redirect URI Portal:
  `https://login.mphone.vn/app/portal/service/google_oauth.php?action=callback`.
- Android package pilot: `org.linphone`.

## Nghiệm thu còn lại

1. Password Identity liên kết Google trong Portal bằng test user.
2. Đăng xuất rồi đăng nhập Portal bằng Google.
3. Cài APK debug và đăng nhập Managed Account bằng cùng Google account.
4. Google account có email trùng nhưng chưa liên kết phải bị từ chối.
5. Gỡ Google sai mật khẩu phải bị từ chối; đúng mật khẩu phải thành công và
   password login vẫn hoạt động.
6. Revoke session Google từ Portal phải làm Android thoát Managed Account theo
   SLA hiện tại.

## Rollback

- Gỡ ba biến Google khỏi Edge/PHP-FPM hoặc đổi giá trị thành rỗng để tắt tính
  năng; password login không bị ảnh hưởng.
- Rollback Portal bundle và APK để ẩn UI.
- Không xóa provider mapping khi rollback UI. Chỉ gỡ mapping bằng flow unlink đã
  xác thực hoặc thao tác quản trị được phê duyệt.
- Bảng token-use có thể giữ lại; dữ liệu chỉ là hash và tự hết giá trị sau expiry.
