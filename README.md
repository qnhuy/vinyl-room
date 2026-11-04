# Vinyl Room — Ứng Dụng Nghe Nhạc Trực Tuyến

**Vinyl Room** là ứng dụng phát và quản lý âm nhạc đa nền tảng kết hợp **Flutter** (Frontend), **Node.js / Express** (Backend RESTful API) và **Microsoft SQL Server** (Cơ sở dữ liệu quan hệ).

---

## 📑 Mục Lục
- [1. Tính Năng Đã Hoàn Thiện](#1-tính-năng-đã-hoàn-thiện)
- [2. Kiến Trúc Phân Lớp Frontend (ui/lib)](#2-kiến-trúc-phân-lớp-frontend-uilib)
- [3. Hướng Dẫn Cài Đặt & Khởi Chạy](#3-hướng-dẫn-cài-đặt--khởi-chạy)
- [4. Tài Khoản Kiểm Thử](#4-tài-khoản-kiểm-thử)
- [5. State Management & Lưu Trữ Cục Bộ](#5-state-management--lưu-trữ-cục-bộ)
- [6. Danh Sách RESTful API Backend](#6-danh-sách-restful-api-backend)

---

## 1. Tính Năng Đã Hoàn Thiện

* **Xác thực người dùng:** Đăng ký, đăng nhập tài khoản, kiểm tra dữ liệu đầu vào (validation), lưu trữ phiên làm việc lâu dài.
* **Trình phát nhạc Audio Player:**
  * Phát trực tuyến qua mạng nền tảng đa luồng.
  * Thanh Mini Player thu nhỏ gắn liền ở đáy ứng dụng giúp điều khiển nhạc thuận tiện trên mọi màn hình.
  * Màn hình toàn diện Now Playing với đĩa than xoay hoạt họa mô phỏng máy phát đĩa Vinyl.
  * Thanh tua thời gian thực, điều chỉnh âm lượng, nút lặp bài hát.
* **Khám phá & Bảng xếp hạng:** Danh sách bài hát thịnh hành, Top lượt nghe Ranking vinh danh Top 1/2/3 với huy hiệu màu sắc riêng biệt.
* **Tìm kiếm & Lịch sử:** Tìm kiếm bài hát theo tên hoặc ca sĩ, lưu và xóa lịch sử tìm kiếm gần đây.
* **Playlist Cá nhân & Cộng đồng:** Tạo playlist, thêm/bớt bài hát, bật/tắt chia sẻ Công khai (Public) hoặc Riêng tư (Private), lưu playlist của người dùng khác.
* **Giao diện:** Hỗ trợ linh hoạt Dark Mode và Light Mode.

---

## 2. Kiến Trúc Phân Lớp Frontend (`ui/lib`)

Ứng dụng Flutter được tổ chức theo cấu trúc phân lớp sạch sẽ và rõ ràng:

```
ui/lib/
├── config/        # Quản lý cấu hình toàn ứng dụng & biến môi trường
├── models/        # Các mô hình dữ liệu (Song, User, Playlist, SearchHistory)
├── presenters/    # Tầng Presenter xử lý nghiệp vụ theo mô hình MVP
├── providers/     # Quản lý State toàn cục bằng Provider (PlayerProvider, AuthProvider, MusicProvider)
├── screens/       # Các màn hình người dùng (Login, Register, Home, Ranking, Search, NowPlaying, Playlist...)
├── services/      # Tầng giao tiếp HTTP API và SharedPreferences Session
├── utils/         # Tiện ích Http wrapper (timeout 15s, tự động đính kèm x-user-id)
├── widgets/       # Các widget dùng chung (MiniPlayer, SongTile, SongCard, PlaylistCard...)
└── main.dart      # Điểm khởi đầu ứng dụng
```

---

## 3. Hướng Dẫn Cài Đặt & Khởi Chạy

### Bước 1: Khởi Tạo Cơ Sở Dữ Liệu
1. Mở file [`vinyl-room.sql`](./vinyl-room.sql) trong SQL Server Management Studio (SSMS).
2. Nhấn **Execute (F5)** để tạo database `vinyl_room` và nạp toàn bộ bảng cùng dữ liệu mẫu.

### Bước 2: Khởi Động Backend API
1. Mở terminal và điều hướng vào thư mục backend:
   ```powershell
   cd api
   npm install
   npm start
   ```
   Backend sẽ lắng nghe tại `http://localhost:3000`.

### Bước 3: Khởi Động Ứng Dụng Flutter
1. Điều hướng vào thư mục `ui`:
   ```powershell
   cd ui
   flutter pub get
   ```
2. Cấu hình biến môi trường trong file `ui/.env`:
   - Chạy trên máy ảo Android Emulator: `BASE_API_URL=http://10.0.2.2:3000`
   - Chạy trên máy tính (Desktop/Web): `BASE_API_URL=http://localhost:3000`
   - Chạy trên điện thoại thật (cùng Wi-Fi): `BASE_API_URL=http://<IP_LAN_MAY_TINH>:3000`
3. Chạy ứng dụng:
   ```powershell
   flutter run
   ```

---

## 4. Tài Khoản Kiểm Thử

| Tên đăng nhập (Username) | Mật khẩu (Password) | Trạng thái |
|---|---|---|
| `nguyenvanA` | `123456` | Hoạt động bình thường |
| `tranthib` | `123456` | Hoạt động bình thường |
| `hoangvane` | `123456` | Đã bị khóa (`isActive = 0`, báo lỗi khi đăng nhập) |

---

## 5. State Management & Lưu Trữ Cục Bộ

* **State Management (Provider):**
  * `PlayerProvider`: Quản lý luồng phát nhạc, trạng thái đang phát/tạm dừng, hàng đợi bài hát, thời lượng bài hát và âm lượng.
  * `AuthProvider`: Quản lý trạng thái phiên đăng nhập của người dùng và chế độ Theme (Dark / Light Mode).
  * `MusicProvider`: Bắn tín hiệu lắng nghe làm mới danh sách bài hát realtime.
* **Lưu Trữ Cục Bộ (SharedPreferences):**
  * Lưu trữ định danh người dùng đăng nhập (`user_id`, `username`, `email`, `avatar_url`) giúp duy trì phiên làm việc không bị gián đoạn khi mở lại app.
  * Lưu trữ lịch sử các từ khóa tìm kiếm gần đây.

---

## 6. Danh Sách RESTful API Backend

* **`/auth`**: Đăng ký (`POST /register`), Đăng nhập (`POST /login`).
* **`/music`**: Lấy kho bài hát (`GET /`), Xếp hạng (`GET /ranking`), Yêu thích (`GET /favorites`), Vừa nghe (`GET /recent`), Tìm kiếm (`GET /search`), Tăng lượt nghe (`POST /:id/listen`).
* **`/playlists` & `/users`**: Lấy danh sách phát công khai (`GET /playlists/public`), Bài hát trong playlist (`GET /playlists/:id/songs`), Bật/tắt chia sẻ (`PUT /playlists/:id/share`), Yêu thích bài hát/playlist (`POST/DELETE`).
