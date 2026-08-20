# Mantis — Design System trích đầy đủ

Nguồn: `mantis-free-react-admin-template` **v2.2.0** (MIT © CodedThemes) · đối chiếu với demo Pro tại `mantisdashboard.com`
Ngày trích: 19/08/2026

---

## 0. Kết luận ngắn

**Design system lấy được 100%, không thiếu một giá trị nào** — vì nó nằm nguyên trong source bản Free, và Free là **MIT**.

Điểm mấu chốt: Mantis **không tự nghĩ ra bảng màu**. Nó lấy thẳng `presetPalettes` và `presetDarkPalettes` của **`@ant-design/colors`** rồi ánh xạ chỉ số ramp sang tên MUI. Nghĩa là bảng màu của bản Pro không phải bí mật gì — nó là bảng màu công khai của Ant Design.

Tôi đã kiểm chứng: sinh lại scheme dark từ `presetDarkPalettes` cho ra `#1668dc`, `#d89614`, `#a61d24`, `#49aa19` — **trùng khít** với màu đo được trên demo Pro (`rgb(22,104,220)`, `rgb(216,150,20)`, `rgb(166,29,36)`, `rgb(73,170,25)`).

---

## 1. Kiến trúc theme

```
vite/src/themes/
├── index.jsx            # createTheme: breakpoints, mixins, typography, colorSchemes, cssVariables
├── palette.js           # buildPalette(presetColor) → { light }        ← Pro thêm { dark }
├── theme/index.js       # Default(colors): ánh xạ ramp Ant → tên MUI
├── typography.js        # thang chữ
├── custom-shadows.jsx   # z1, focus ring, button shadow
└── overrides/           # 24 file override component
```

Luồng: `presetPalettes` (Ant) → `Default()` gán `lighter/light/main/dark/darker` → `extendPaletteWithChannels()` thêm kênh rgb cho `alpha()` → `createTheme({ colorSchemes, cssVariables })`.

`cssVariables` bật với `cssVarPrefix: ''` và `colorSchemeSelector: 'data-color-scheme'` — nên toàn bộ token phát ra thành CSS custom property thật, dùng được cả ngoài React.

---

## 2. Ánh xạ ramp → token

| Token MUI | Ramp Ant | Chỉ số |
|---|---|---|
| `primary` | `blue` | lighter=0 · light=3 · **main=5** · dark=6 · darker=8 |
| `error` | `red` | lighter=0 · light=2 · **main=4** · dark=7 · darker=9 |
| `warning` | `gold` | lighter=0 · light=3 · **main=5** · dark=7 · darker=9 |
| `info` | `cyan` | lighter=0 · light=3 · **main=5** · dark=7 · darker=9 |
| `success` | `green` | lighter=0 · light=3 · **main=5** · dark=7 · darker=9 |
| `secondary` | thang grey riêng | lighter=100 · light=300 · **main=500** · dark=700 · darker=900 |

> Chú ý `error.main` lấy index **4**, khác với 4 màu còn lại lấy index 5. Đây không phải lỗi — Ant `red[5] = #f5222d` quá gắt cho nền sáng, nên Mantis lùi một bậc xuống `#ff4d4f`.

### Giá trị đã resolve

**Light**

| | lighter | light | main | dark | darker |
|---|---|---|---|---|---|
| primary | `#e6f4ff` | `#69b1ff` | **`#1677ff`** | `#0958d9` | `#002c8c` |
| error | `#fff1f0` | `#ffa39e` | **`#ff4d4f`** | `#a8071a` | `#5c0011` |
| warning | `#fffbe6` | `#ffd666` | **`#faad14`** | `#ad6800` | `#613400` |
| info | `#e6fffb` | `#5cdbd3` | **`#13c2c2`** | `#006d75` | `#002329` |
| success | `#f6ffed` | `#95de64` | **`#52c41a`** | `#237804` | `#092b00` |

**Dark** (bản Free thiếu — đã dựng lại, khớp demo Pro)

| | lighter | light | main | dark | darker |
|---|---|---|---|---|---|
| primary | `#111a2c` | `#15417e` | **`#1668dc`** | `#3c89e8` | `#8dc5f8` |
| error | `#2a1215` | `#58181c` | **`#a61d24`** | `#f37370` | `#fac8c3` |
| warning | `#2b2111` | `#7c5914` | **`#d89614`** | `#f3cc62` | `#faedb5` |
| info | `#112123` | `#146262` | **`#13a8a8`** | `#58d1c9` | `#b2f1e8` |
| success | `#162312` | `#306317` | **`#49aa19`** | `#8fd460` | `#d5f2bb` |

### Thang grey (light)

`0:#ffffff · 50:#fafafa · 100:#f5f5f5 · 200:#f0f0f0 · 300:#d9d9d9 · 400:#bfbfbf · 500:#8c8c8c · 600:#595959 · 700:#262626 · 800:#141414 · 900:#000000`
Hằng số phụ: `A50:#fafafb` (nền trang) · `A800:#e6ebf1`

Gán ngữ nghĩa: `text.primary = grey[700]` · `text.secondary = grey[500]` · `text.disabled = grey[400]` · `divider = grey[200]` · `background.paper = grey[0]` · `background.default = grey.A50`

---

## 3. Typography

Font mặc định **`'Public Sans'`** (đóng gói qua `@fontsource/public-sans`). Repo cho đổi sang Inter / Poppins / Roboto qua `config.fontFamily`. `htmlFontSize: 16`.

| Biến thể | Cỡ | Line-height | Weight |
|---|---|---|---|
| h1 | 2.375rem (38px) | 1.21 | 600 |
| h2 | 1.875rem (30px) | 1.27 | 600 |
| h3 | 1.5rem (24px) | 1.33 | 600 |
| h4 | 1.25rem (20px) | 1.40 | 600 |
| h5 | 1rem (16px) | 1.50 | 600 |
| h6 | 0.875rem (14px) | 1.57 | 400 |
| body1 / subtitle1 | 0.875rem | 1.57 | 400 / 600 |
| body2 / subtitle2 / caption | 0.75rem (12px) | 1.66 | 400 / 500 / 400 |

Weight: light 300 · regular 400 · medium 500 · **bold 600** (không phải 700).
`button.textTransform: 'capitalize'` — nút không viết hoa toàn bộ.

---

## 4. Shadow, layout, breakpoint

```
z1            0px 1px 4px  rgb(0 0 0 / 8%)     ← bóng card duy nhất
button        0 2px #0000000b
text          0 -1px 0 rgb(0 0 0 / 12%)
focus ring    0 0 0 2px  <màu>/20%             ← sinh cho cả 7 màu
button shadow 0 14px 12px <màu>/20%            ← variant "shadow"
```

Chỉ có **một** cấp bóng cho card. Mantis tạo phân tầng bằng border + màu nền, không bằng độ nổi.

```
DRAWER_WIDTH        260px
MINI_DRAWER_WIDTH    60px
toolbar minHeight    60px  (padding 8px trên/dưới)
```

**Breakpoint khác mặc định MUI** — dễ vấp nếu không để ý:

| | xs | sm | md | lg | xl |
|---|---|---|---|---|---|
| Mantis | 0 | **768** | **1024** | **1266** | 1440 |
| MUI mặc định | 0 | 600 | 900 | 1200 | 1536 |

---

## 5. Quy ước override component

24 file trong `overrides/`, gộp bằng `lodash.merge`. Ba hàm tiện ích là xương sống:

- `getColors(theme, color)` → trả nhánh palette theo tên màu
- `getShadow(theme, key)` → trả `customShadows[key]`
- `withAlpha(color, a)` → dùng kênh rgb đã extend

Mẫu lặp đi lặp lại: sinh style cho **mọi tổ hợp** `color × variant` bằng vòng lặp thay vì viết tay. Ví dụ `Button.js` phủ 6 màu × 5 variant (thêm hai variant riêng của Mantis: **`dashed`** và **`shadow`**).

Input: `padding 10.5px 14px 10.5px 12px`, size small `7.5px 8px 7.5px 12px`, viền `grey[300]`, focus đổi viền sang `light` + focus ring.

---

## 6. Free so với Pro

Đã duyệt menu demo Pro. **Design system hai bên giống hệt nhau** — Pro không thêm token nào, chỉ dùng cùng bộ token cho nhiều trang hơn.

| | Free v2.2.0 | Pro |
|---|---|---|
| Dashboard | Default | Default, Analytics, Invoice |
| Widget | — | Statistics, Data, Chart |
| App | — | Chat, Calendar, Kanban, Customer, Profile, E-commerce, Invoice |
| Form | — | Validation, Wizard, Layout, Plugins |
| Bảng | — | React Table, MUI Table |
| Khác | Sample Page | Charts, Map, Pricing, Contact Us, Maintenance, Menu Levels |
| Auth | Login, Register | + Forgot/Reset/Check-mail/Code, và 3 phương thức (JWT, Firebase, Auth0) |
| Dark mode | **không** | có |
| Layout | 1 (mini drawer) | nhiều biến thể + RTL + preset màu |
| Component overview | Color, Shadows, Typography | toàn bộ MUI |

Ba thứ Pro có mà Free thiếu ở tầng **hệ thống** (chứ không phải tầng trang): **dark mode**, **RTL**, **preset màu thay được**. Cả ba đều dựng lại được — dark mode thì tôi đã làm sẵn (xem `palette.js` kèm theo).

---

## 7. Trả lời câu hỏi

**Lấy design system?** Xong, đầy đủ. Xem `mantis-tokens.css` (CSS custom property, cả light lẫn dark) và `mantis-tokens.json`.

**Dựng lại bản Pro?** Cần tách làm hai phần:

*Phần hệ thống* — dark mode, RTL, preset màu: **dựng lại được chính xác**, vì tất cả đều là hàm thuần trên bảng màu Ant. Dark mode đã có bản vá kèm theo, verify khớp demo.

*Phần nội dung* — ~200 trang, app Chat/Kanban/Calendar/E-commerce: **không phải "dựng lại", mà là viết mới**. Chúng không chứa design system nào cả; chúng chỉ là ứng dụng viết bằng design system đó. Nhìn ảnh demo mà code lại Kanban là làm lại từ đầu, không phải trích xuất.

Nói thẳng: nếu mục tiêu là **có design system** thì bản Free đã đủ và giấy phép MIT cho bạn toàn quyền, kể cả thương mại hoá. Nếu mục tiêu là **có 200 trang dựng sẵn** thì mua Pro rẻ hơn nhiều so với công tự viết.

---

## 8. Giấy phép

Bản Free là **MIT** — dùng, sửa, phân phối, bán lại đều được, chỉ cần giữ notice bản quyền. Đây là khác biệt lớn so với theme Appwork ở dự án Softphone.Pro: chỗ đó bạn không có quyền gì, chỗ này bạn có gần như mọi quyền.

Cần cẩn thận đúng một điểm: giấy phép MIT áp cho **bản Free**. Nội dung riêng của bản Pro (trang, layout, asset) không nằm trong đó — sao chép từ ảnh chụp demo Pro là chuyện khác.
