# Vinyl Room — Ứng Dụng Nghe Nhạc Trực Tuyến

**Vinyl Room** là ứng dụng nghe nhạc trực tuyến đa nền tảng kết hợp **Flutter** (Frontend), **Node.js / Express** (Backend RESTful API) và **Microsoft SQL Server** (Cơ sở dữ liệu quan hệ).

---

## 📑 Mục Lục
- [1. Mô Tả Ứng Dụng](#1-mô-tả-ứng-dụng)
- [2. Cấu Trúc Dự Án](#2-cấu-trúc-dự-án)
- [3. Hướng Dẫn Cài Đặt & Khởi Chạy Backend API](#3-hướng-dẫn-cài-đặt--khởi-chạy-backend-api)
- [4. Danh Sách RESTful API](#4-danh-sách-restful-api)
- [5. Cơ Sở Dữ Liệu & Dữ Liệu Mẫu](#5-cơ-sở-dữ-liệu--dữ-liệu-mẫu)

---

## 1. Mô Tả Ứng Dụng
Ứng dụng nghe nhạc với giao diện đĩa than cổ điển, hỗ trợ phát nhạc trực tuyến, quản lý danh sách phát cá nhân và công khai, bảng xếp hạng nghe nhiều nhất và tìm kiếm bài hát theo sở thích.

---

## 2. Cấu Trúc Dự Án
```
vinyl-room/
├── api/             # Mã nguồn Backend Node.js / Express API
│   ├── configs/     # Cấu hình kết nối SQL Server
│   ├── musics/      # Static files nhạc mẫu
│   ├── routes/      # Các routers (auth, music, playlists, users)
│   └── server.js    # Entry point của server Express
├── docs/            # Tài liệu thiết kế ERD
├── ui/              # Mã nguồn Frontend Flutter
└── vinyl-room.sql   # Kịch bản khởi tạo CSDL & dữ liệu mẫu
```

---

## 3. Hướng Dẫn Cài Đặt & Khởi Chạy Backend API

### Yêu Cầu
* Node.js phiên bản 18 trở lên.
* Microsoft SQL Server (2019/2022 hoặc Express Edition) kèm SSMS.

### Bước 1: Khởi Tạo Cơ Sở Dữ Liệu
1. Mở SQL Server Management Studio (SSMS).
2. Mở file [`vinyl-room.sql`](./vinyl-room.sql) và nhấn **Execute (F5)** để tạo cơ sở dữ liệu `vinyl_room` cùng toàn bộ dữ liệu mẫu ban đầu.

### Bước 2: Cài Đặt & Khởi Chạy Backend
1. Điều hướng vào thư mục backend:
   ```powershell
   cd api
   ```
2. Tạo file cấu hình `.env` dựa trên `.env.example`:
   ```ini
   PORT=3000
   DB_HOST=localhost
   DB_PORT=1433
   DB_NAME=vinyl_room
   DB_USER=sa
   DB_PASSWORD=YourPassword123
   ```
3. Cài đặt các gói phụ thuộc và khởi động server:
   ```powershell
   npm install
   npm start
   # Hoặc chế độ dev tự nạp lại khi sửa code:
   npm run dev
   ```
Server sẽ chạy tại `http://localhost:3000`.

---

## 4. Danh Sách RESTful API

Hệ thống đã triển khai đầy đủ các endpoint RESTful và có thể kiểm thử trực tiếp qua Postman hoặc Swagger:

### 🔐 Xác Thực (`/auth`)
| Phương thức | Đường dẫn | Chức năng | Tham số / Body |
|---|---|---|---|
| `POST` | `/auth/register` | Đăng ký tài khoản người dùng mới | `{ username, password, email }` |
| `POST` | `/auth/login` | Đăng nhập tài khoản | `{ username, password }` |

### 🎵 Âm Nhạc (`/music`)
| Phương thức | Đường dẫn | Chức năng | Ghi chú |
|---|---|---|---|
| `GET` | `/music` | Lấy toàn bộ danh sách bài hát | Trả về metadata và URL stream |
| `GET` | `/music/ranking` | Bảng xếp hạng các bài hát nghe nhiều nhất | Sắp xếp theo `listen_count DESC` |
| `GET` | `/music/favorites` | Lấy danh sách bài hát yêu thích | Header: `x-user-id` |
| `GET` | `/music/recent` | Danh sách bài hát vừa nghe gần đây | Header: `x-user-id` |
| `GET` | `/music/search?q=...` | Tìm kiếm bài hát theo tên hoặc ca sĩ | Query string: `q` |
| `POST` | `/music/:id/listen` | Ghi nhận lượt nghe bài hát | Tăng `listen_count` và lưu lịch sử |

### 📂 Danh Sách Phát (`/playlists` & `/users`)
| Phương thức | Đường dẫn | Chức năng | Ghi chú |
|---|---|---|---|
| `GET` | `/playlists/public` | Lấy tất cả playlist công khai của cộng đồng | `is_shared = 1` |
| `GET` | `/playlists/:id/songs` | Lấy danh sách bài hát trong một playlist | Theo `playlist_id` |
| `PUT` | `/playlists/:id/share` | Bật/Tắt chế độ công khai playlist | `{ is_shared: 0 / 1 }` |
| `POST/DELETE`| `/users/:userId/liked/:musicId` | Thêm / Xóa bài hát yêu thích | Lưu vào `user_liked_songs` |

---

## 5. Cơ Sở Dữ Liệu & Dữ Liệu Mẫu

Cơ sở dữ liệu được định nghĩa trong file [`vinyl-room.sql`](./vinyl-room.sql), đi kèm dữ liệu mẫu gồm 10 tài khoản người dùng, hàng loạt nghệ sĩ hàng đầu Việt Nam (Sơn Tùng M-TP, Mỹ Tâm, Đen Vâu, Vũ, Bích Phương...), các album phát hành và các bài hát mẫu có sẵn file audio mp3.
