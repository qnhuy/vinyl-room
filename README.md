# Vinyl Room — Ứng Dụng Nghe Nhạc Trực Tuyến

**Vinyl Room** là ứng dụng phát và quản lý âm nhạc đa nền tảng được xây dựng phục vụ môn học **PRM393 (Mobile Programming)**. Dự án kết hợp giữa **Flutter** (giao diện người dùng & quản trị), **Node.js / Express** (RESTful API backend), **Microsoft SQL Server** (cơ sở dữ liệu quan hệ), tích hợp **Google Gemini AI** (gợi ý bài hát theo cảm xúc) và cổng thanh toán **PayOS (VietQR)** cho gói thành viên cao cấp.

---

## 🚀 Hướng Dẫn Cài Đặt & Khởi Chạy Nhanh (Quick Start)

### 📋 Yêu Cầu Môi Trường
* **Node.js** (phiên bản 18+ trở lên).
* **Flutter SDK** (phiên bản 3.20+ hoặc 3.47+).
* **Microsoft SQL Server** (2019/2022 hoặc Express Edition) kèm **SQL Server Management Studio (SSMS)**.

### 🔑 Tài Khoản Mẫu Để Kiểm Thử (Seed Accounts)
| Vai trò | Tên đăng nhập (Username) | Mật khẩu (Password) | Phân hạng gói | Quyền hạn & Mục đích kiểm thử |
|---|---|---|---|---|
| **Quản trị viên (Admin)** | `admin` | `admin123456` | 👑 **Vinyl Premium** | Toàn quyền Dashboard KPI, Quản lý bài hát (CRUD), Quản lý người dùng |
| **Người dùng mẫu 1** | `nguyenvanA` | `123456` | 👑 **Vinyl Premium** *(còn 25 ngày)* | Mở khóa AI Smart Flow, tạo playlist không giới hạn, badge Vàng |
| **Người dùng mẫu 2** | `tranthib` | `123456` | 🆓 **Miễn Phí (Free)** | Dùng để test luồng khóa AI Smart Flow & hộp thoại nâng cấp khi tạo quá 3 playlist |
| **Tài khoản bị khóa mẫu** | `hoangvane` | `123456` | 🔒 Bị khóa | Bị khóa (`isActive = 0`), hiển thị thông báo lỗi khi cố đăng nhập |

### 🛠️ Bước 1: Khởi Tạo Cơ Sở Dữ Liệu
1. Mở **SQL Server Management Studio (SSMS)** và kết nối tới SQL Server của bạn.
2. Mở file [`vinyl-room.sql`](./vinyl-room.sql).
3. Bấm **Execute (F5)** để tự động xóa sạch phiên bản cũ (nếu có), tạo mới database `PRM392_PE` và nạp toàn bộ cấu trúc bảng cùng dữ liệu mẫu (Seed Data).

### ⚙️ Bước 2: Cài Đặt & Khởi Động Backend API
1. Điều hướng vào thư mục backend:
   ```powershell
   cd api
   ```
2. Tạo file `.env` (tham khảo `.env.example`):
   ```ini
   PORT=3000
   DB_HOST=localhost
   DB_PORT=1433
   DB_NAME=PRM392_PE
   DB_USER=sa
   DB_PASSWORD=YourPassword123
   GEMINI_API_KEY=your_gemini_api_key_here

   # Cổng thanh toán PayOS (Nếu để trống, hệ thống tự kích hoạt chế độ VietQR Sandbox & Demo)
   PAYOS_CLIENT_ID=your_client_id_here
   PAYOS_API_KEY=your_api_key_here
   PAYOS_CHECKSUM_KEY=your_checksum_key_here
   ```
3. Cài đặt các gói phụ thuộc và khởi động server:
   ```powershell
   npm install
   npm start
   # Hoặc chạy chế độ dev tự reload:
   npm run dev
   ```
   Server sẽ lắng nghe tại `http://localhost:3000`.

### 📱 Bước 3: Cài Đặt & Khởi Chạy Ứng Dụng Flutter
1. Điều hướng vào thư mục giao diện:
   ```powershell
   cd ui
   ```
2. Cài đặt các thư viện Flutter:
   ```powershell
   flutter pub get
   ```
3. Cấu hình file `ui/.env` theo môi trường thử nghiệm:
   * **Windows / macOS Desktop hoặc Web:**
     ```ini
     BASE_API_URL=http://localhost:3000
     ```
   * **Máy ảo Android Emulator:**
     ```ini
     BASE_API_URL=http://10.0.2.2:3000
     ```
   * **Thiết bị thật (điện thoại cắm cáp / Wi-Fi):**
     ```ini
     BASE_API_URL=http://<IP_LAN_CỦA_MÁY_TÍNH>:3000
     ```
4. Khởi chạy ứng dụng:
   ```powershell
   flutter run
   ```

---

## 📑 Mục Lục Chi Tiết
- [1. Phân Chia Tính Năng: Miễn Phí vs Trả Tiền (PayOS)](#1-phân-chia-tính-năng-miễn-phí-vs-trả-tiền-payos)
- [2. Tính Năng Nổi Bật](#2-tính-năng-nổi-bật)
- [3. Kiến Trúc Mã Nguồn Frontend (ui/lib)](#3-kiến-trúc-mã-nguồn-frontend-uilib)
- [4. Kiến Trúc Backend (api)](#4-kiến-trúc-backend-api)
- [5. Cơ Sở Dữ Liệu Chi Tiết](#5-cơ-sở-dữ-liệu-chi-tiết)
- [6. Kiểm Thử & Đảm Bảo Chất Lượng](#6-kiểm-thử--đảm-bảo-chất-lượng)

---

## 1. Phân Chia Tính Năng: Miễn Phí vs Trả Tiền (PayOS)

Dự án áp dụng mô hình phân hạng tinh gọn với **chất lượng âm thanh như nhau cho 100% người dùng** và mức phí chỉ **19.000đ / 30 ngày**:

| Quyền Lợi | 🆓 Miễn Phí (Free) | 👑 Vinyl Premium (19.000đ / 30 ngày) |
|---|:---:|:---:|
| **Kho nhạc & Chất lượng âm thanh** | **Chất lượng đầy đủ 100%** | **Chất lượng đầy đủ 100%** *(như nhau)* |
| **Tìm kiếm & Bảng xếp hạng** | ✅ Đầy đủ | ✅ Đầy đủ |
| **Nghe Playlist công khai & Yêu thích** | ✅ Đầy đủ | ✅ Đầy đủ |
| **Tạo Playlist cá nhân** | Tối đa **3 Playlist** | **Không giới hạn** số lượng playlist |
| **✨ AI Smart Flow (Gemini AI)** | 🔒 Khóa *(mời nâng cấp)* | ⚡ **Mở khóa không giới hạn** (Nối nhạc theo mood) |
| **Huy hiệu hồ sơ (Profile Badge)** | Người dùng tiêu chuẩn | 👑 **Huy hiệu Vinyl Premium Vàng** |
| **Cổng thanh toán tích hợp** | — | **PayOS VietQR** (Quét mã chuyển khoản tức thì) |
| **Nút Demo chấm bài nhanh** | — | Bấm 1 chạm kích hoạt 30 ngày ngay trên Dialog |

---

## 2. Tính Năng Nổi Bật

### 🎧 Phân hệ Người Dùng (Client App)
* **Khám phá âm nhạc:** Trang chủ hiển thị danh sách bài hát nghe gần đây, các bản hit thịnh hành và danh sách playlist cá nhân.
* **Trình phát nhạc cao cấp (Audio Player):** Phát nhạc nền, thanh Mini Player thu nhỏ ở mọi màn hình, chế độ toàn màn hình (Now Playing) với đĩa than xoay mượt mà, điều chỉnh âm lượng, tua nhạc thời gian thực, lặp bài, xáo trộn bài.
* **✨ AI Smart Flow (Gemini AI Music Continuation):**
  * Phân tích giai điệu, tiết tấu (tempo), thể loại và tâm trạng (mood) của bài hát đang phát bằng mô hình **Google Gemini 3.8 Flash**.
  * Khi người dùng nghe hết một bài hát lẻ, hết playlist/album hoặc nghe ngẫu nhiên, AI tự động tuyển chọn bài hát kế tiếp phù hợp nhất trong kho nhạc để dòng cảm xúc không bị ngắt quãng.
  * Tùy chọn bật/tắt chế độ Smart Flow bằng nút toggle gắn huy hiệu lấp lánh ngay trên màn hình Now Playing.
  * Tích hợp kiểm tra quyền gói Premium: Mở hộp thoại thanh toán VietQR nếu là tài khoản Free.
* **Bảng xếp hạng (Ranking):** Top bài hát được nghe nhiều nhất với huy hiệu Top 1 (Vàng), Top 2 (Bạc), Top 3 (Đồng).
* **Tìm kiếm thông minh:** Tìm kiếm bài hát theo tên bài hát, nghệ sĩ; lưu trữ và xóa lịch sử tìm kiếm gần đây.
* **Playlist & Cộng đồng:** Tạo playlist cá nhân, thêm/xóa bài hát trong playlist, bật/tắt chia sẻ Công khai (Public) hoặc Riêng tư (Private), lưu và yêu thích playlist công khai của người khác.

### 🛡️ Phân hệ Quản Trị Viên (Admin Portal)
* **Phân quyền vai trò (Role-Based Access Control - RBAC):** Kiểm soát bảo mật nghiêm ngặt giữa người dùng thường (`user`) và Quản trị viên (`admin`), tự động khóa truy cập route nếu không đủ thẩm quyền (`403 Forbidden`).
* **Dashboard Thống kê & KPI:** Thẻ số liệu thời gian thực (Tổng bài hát, Tổng người dùng, Tổng nghệ sĩ, Tổng lượt nghe), Top 5 bài hát hot nhất, các từ khóa tìm kiếm phổ biến.
* **Quản lý Kho Bài hát (Songs CRUD):** Xem danh sách có tìm kiếm, Thêm mới bài hát (chọn Nghệ sĩ, Thể loại, nhập URL âm thanh/ảnh bìa), Chỉnh sửa metadata, Xóa bài hát (tự động dọn dẹp các ràng buộc liên kết an toàn).
* **Quản lý Người dùng (Users Management):** Xem toàn bộ danh sách tài khoản, Khóa / Mở khóa tài khoản (`isActive = 0/1`), Thăng cấp Admin hoặc Hạ quyền tài khoản trực tiếp.

---

## 3. Kiến Trúc Mã Nguồn Frontend (`ui/lib`)

Frontend được chuẩn hóa theo mô hình kiến trúc phân lớp sạch sẽ, gồm đúng 9 thư mục/thành phần chuyên biệt:

```
ui/lib/
├── config/                  # Quản lý cấu hình toàn ứng dụng
│   └── config.dart          # AppConfig: nạp an toàn .env, quản lý Base URL
├── models/                  # Định nghĩa các Data Model từ Backend trả về
│   ├── playlist.dart        # Model Playlist cá nhân và công khai
│   ├── search_history.dart  # Model Lịch sử tìm kiếm
│   ├── song.dart            # Model Bài hát (Song)
│   └── user.dart            # Model Người dùng kèm thuộc tính role, isPremium, premiumExpiresAt
├── presenters/              # MVP Presenters điều phối logic và cập nhật View
│   ├── admin_dashboard_presenter.dart
│   ├── admin_song_presenter.dart
│   ├── admin_user_presenter.dart
│   ├── home_presenter.dart
│   ├── playlist_detail_presenter.dart
│   ├── profile_presenter.dart
│   ├── ranking_presenter.dart
│   └── search_presenter.dart
├── providers/               # Quản lý State toàn cục bằng Provider (ChangeNotifier)
│   ├── auth_provider.dart   # Quản lý phiên đăng nhập, tài khoản, Theme Mode, trạng thái Premium
│   ├── music_provider.dart  # Bắn tín hiệu làm mới dữ liệu realtime
│   └── player_provider.dart # Trình phát nhạc AudioPlayer, AI Smart Flow, hàng đợi
├── screens/                 # Các màn hình tương ứng với URL (URL Routing)
│   ├── admin/               # Các màn hình quản trị Admin
│   │   ├── admin_dashboard_screen.dart
│   │   ├── admin_song_form_screen.dart
│   │   ├── admin_songs_screen.dart
│   │   └── admin_users_screen.dart
│   ├── app_routes.dart      # Đăng ký & kiểm soát bảo vệ toàn bộ URL Routes (RBAC)
│   ├── home_screen.dart
│   ├── login_screen.dart
│   ├── main_shell_screen.dart
│   ├── now_playing_screen.dart # Trình phát đĩa than & nút kích hoạt AI Smart Flow
│   ├── playlist_detail_screen.dart
│   ├── premium_payment_screen.dart # Màn hình riêng biệt thanh toán VietQR (PayOS) & tải ảnh QR
│   ├── profile_screen.dart     # Thông tin cá nhân & Banner Nâng cấp Vinyl Premium
│   ├── public_playlists_screen.dart
│   ├── ranking_screen.dart
│   ├── register_screen.dart
│   └── search_screen.dart
├── services/                # Tầng giao tiếp mạng gọi API Backend & Session
│   ├── admin_service.dart   # Gọi các API quản trị /admin/*
│   ├── api_config.dart      # Alias tương thích ngược về config/
│   ├── auth_service.dart    # API Đăng nhập, Đăng ký, Lấy profile
│   ├── music_service.dart   # API Bài hát, Xếp hạng, Playlist, Yêu thích, AI Smart Next
│   ├── payment_service.dart # API Thanh toán PayOS VietQR & kiểm tra đơn hàng
│   └── session.dart         # Lưu trữ phiên làm việc cục bộ (SharedPreferences)
├── utils/                   # Các tiện ích dùng chung
│   └── http.dart            # Http wrapper: timeout 15s, đính kèm x-user-id
├── widgets/                 # Các widget giao diện tái sử dụng nhiều lần
│   ├── cover_placeholder.dart # Ảnh bìa mặc định khi lỗi
│   ├── mini_player.dart       # Thanh phát nhạc thu nhỏ ở đáy màn hình
│   ├── playlist_card.dart     # Thẻ hiển thị playlist
│   ├── section_header.dart    # Tiêu đề phân mục nội dung
│   ├── song_card.dart         # Thẻ bài hát dạng cuộn ngang
│   ├── song_tile.dart         # Dòng bài hát danh sách chuẩn
│   └── widgets.dart           # File re-export tập trung
└── main.dart                # Điểm khởi đầu (Root) của Frontend, thiết lập Theme & Routes
```

---

## 4. Kiến Trúc Backend (`api`)

Backend viết bằng **Express.js (Node.js)** kết nối trực tiếp đến **Microsoft SQL Server**:

* **`api/server.js`**: File khởi chạy server, cấu hình CORS, static file `/musics`, và gắn các router.
* **`api/services/aiService.js`**: Service tích hợp SDK `@google/genai` mô hình **Gemini 3.8 Flash**.
* **`api/middlewares/adminAuth.js`**: Middleware bảo vệ route Admin (`role === 'admin'`).
* **Các nhóm Route API chính:**
  * **Xác thực (`/auth`):**
    * `POST /auth/register`: Đăng ký tài khoản mới.
    * `POST /auth/login`: Đăng nhập, trả về `is_premium` và `premium_expires_at`.
    * `GET /auth/profile`: Lấy thông tin cá nhân và gói Premium mới nhất.
  * **Thanh toán PayOS (`/payment`):**
    * `POST /payment/create-payment-link`: Tạo link thanh toán / mã VietQR gói 19.000đ.
    * `POST /payment/webhook`: Nhận thông báo tự động từ PayOS khi thanh toán thành công, cộng 30 ngày Premium.
    * `GET /payment/check-status/:orderCode`: Kiểm tra trạng thái đơn hàng.
    * `POST /payment/test-activate`: Kích hoạt ngay 30 ngày Premium phục vụ chấm thi / demo.
    * `POST /payment/test-cancel`: Chuyển về gói Miễn Phí để test luồng khóa tính năng.
  * **Âm nhạc & AI (`/music`):**
    * `GET /music`: Danh sách toàn bộ bài hát.
    * `GET /music/ranking`: Bảng xếp hạng bài hát nghe nhiều nhất.
    * `GET /music/:musicId/smart-next`: Gọi AI Gemini phân tích bài hát (Kiểm tra quyền Vinyl Premium).
  * **Playlist (`/playlists` & `/users`):**
    * `POST /users/:userId/playlists`: Tạo playlist mới (Tài khoản Free tối đa 3 playlist, Premium không giới hạn).
    * `GET /playlists/public`: Danh sách playlist công khai.
    * `PUT /playlists/:id/share`: Bật/tắt chia sẻ công khai.
  * **Quản trị viên (`/admin`):**
    * `GET /admin/stats`: KPI Dashboard.
    * `GET/POST/PUT/DELETE /admin/songs`: CRUD kho bài hát.
    * `GET /admin/users`: Quản lý người dùng và phân quyền.

---

## 5. Cơ Sở Dữ Liệu Chi Tiết

Toàn bộ cấu trúc cơ sở dữ liệu được định nghĩa trong file duy nhất: [`vinyl-room.sql`](./vinyl-room.sql).

### Sơ đồ Bảng
* **`users`**: `user_id`, `username`, `password`, `email`, `avatar_url`, `role` (`user` / `admin`), `isActive`, `is_premium`, `premium_expires_at`.
* **`orders`**: Quản lý giao dịch thanh toán PayOS VietQR (`order_id`, `order_code`, `user_id`, `amount`, `status`, `paid_at`).
* **`artists`**: Thông tin ca sĩ / nghệ sĩ.
* **`albums`**: Thông tin album phát hành.
* **`genres`**: Danh mục thể loại âm nhạc.
* **`music`**: Kho bài hát, file audio, ảnh bìa, lượt nghe (`listen_count`).
* **`playlist` & `playlist_music`**: Playlist hệ thống do Admin tuyển chọn.
* **`user_playlist` & `user_playlist_music`**: Playlist do người dùng tự tạo.
* **`user_liked_songs`**: Danh sách bài hát người dùng yêu thích.
* **`user_liked_playlists` & `playlist_favourites`**: Playlist công khai được người dùng lưu lại.
* **`history`**: Lịch sử tìm kiếm và lịch sử nghe nhạc.

---

## 6. Kiểm Thử & Đảm Bảo Chất Lượng

Dự án tuân thủ nghiêm ngặt chuẩn lint và code quality của Flutter:

```powershell
cd ui

# Phân tích tĩnh toàn bộ mã nguồn (Đạt tiêu chuẩn 0 error, 0 warning)
flutter analyze

# Chạy kiểm thử tự động (Unit / Smoke test)
flutter test
```
