# Vinyl Room — Ứng Dụng Nghe Nhạc Trực Tuyến

**Vinyl Room** là dự án ứng dụng nghe nhạc trực tuyến đa nền tảng phong cách hoài cổ kết hợp hiện đại, được xây dựng trong khuôn khổ môn học **PRM393 (Mobile Programming)**.

---

## 1. Mô Tả Ứng Dụng
Ứng dụng hướng đến trải nghiệm nghe nhạc ấm cúng, thư thái với giao diện mô phỏng máy phát đĩa than Vinyl cổ điển. Hệ thống cho phép người dùng thưởng thức âm nhạc chất lượng cao, khám phá các album và bảng xếp hạng thịnh hành, đồng thời tự tạo và chia sẻ các danh sách phát (playlist) cá nhân tới cộng đồng.

---

## 2. Chức Năng Dự Kiến

### 🎧 Phân hệ Người Dùng
- **Xác thực:** Đăng ký và Đăng nhập tài khoản người dùng an toàn.
- **Khám phá âm nhạc:** Trang chủ với các bản nhạc nghe gần đây, bài hát nổi bật và danh mục playlist.
- **Trình phát nhạc cao cấp:** Trình phát nhạc toàn màn hình với hoạt họa đĩa than quay mô phỏng máy hát đĩa, thanh Mini Player ghim đáy màn hình tiện lợi, tua nhạc, điều chỉnh âm lượng.
- **Bảng xếp hạng (Ranking):** Vinh danh các bản nhạc có lượt nghe cao nhất.
- **Tìm kiếm thông minh:** Tìm kiếm bài hát theo tên và nghệ sĩ, lưu lại lịch sử tìm kiếm gần đây.
- **Quản lý Playlist:** Tạo playlist cá nhân, thêm/bớt bài hát, chuyển đổi chế độ Riêng tư (Private) / Công khai (Public), lưu playlist yêu thích từ người dùng khác.
- **Cá nhân hóa:** Chuyển đổi giao diện Sáng / Tối (Light & Dark Mode) phong cách Vinyl sang trọng.

### 🛡️ Phân hệ Quản Trị Viên (Admin Portal)
- Dashboard theo dõi số liệu thống kê hệ thống (bài hát, người dùng, nghệ sĩ, lượt nghe).
- Quản lý kho bài hát (CRUD), nghệ sĩ, thể loại và album.
- Quản lý trạng thái tài khoản người dùng.

---

## 3. Công Nghệ Sử Dụng

- **Frontend:** **Flutter SDK** (Dart) — đa nền tảng Android, iOS, Web & Desktop.
- **Backend:** **Node.js** kết hợp **Express.js** xây dựng hệ thống RESTful API.
- **Cơ Sở Dữ Liệu:** **Microsoft SQL Server (MSSQL)** quan hệ chuẩn hóa cao (không sử dụng SQLite theo đúng yêu cầu đề tài).

---

## 4. Thiết Kế Cơ Sở Dữ Liệu

Toàn bộ sơ đồ ERD chi tiết và danh sách cấu trúc các bảng được tài liệu hóa tại:
👉 [**Tài liệu Sơ đồ ERD & Danh sách bảng**](./docs/ERD.md)
👉 [**Kịch bản Schema CSDL ban đầu**](./vinyl-room.sql)

### Danh Sách Bảng Chính
1. `users`: Thông tin tài khoản người dùng và trạng thái kích hoạt.
2. `artists`: Thông tin ca sĩ / nghệ sĩ.
3. `albums`: Danh mục album âm nhạc.
4. `genres`: Phân loại thể loại nhạc.
5. `music`: Kho bài hát và liên kết file âm thanh, ảnh bìa.
6. `playlist` & `playlist_music`: Danh sách phát tuyển chọn từ hệ thống.
7. `user_playlist` & `user_playlist_music`: Danh sách phát cá nhân của người dùng.
8. `user_liked_songs`: Bài hát yêu thích.
9. `user_liked_playlists` & `playlist_favourites`: Playlist công khai được người dùng lưu lại.
10. `history`: Nhật ký nghe nhạc và từ khóa tìm kiếm.

---

## 5. Cấu Trúc Mã Nguồn Frontend (`ui/lib`)

```
ui/lib/
├── config/        # Cấu hình API và biến môi trường
├── models/        # Data models
├── presenters/    # Presenter xử lý nghiệp vụ theo mô hình MVP
├── providers/     # State management toàn cục (Provider)
├── screens/       # Các màn hình giao diện ứng dụng
├── services/      # Tầng giao tiếp HTTP API
├── utils/         # Tiện ích chung
├── widgets/       # Các thành phần UI tái sử dụng
└── main.dart      # Điểm khởi chạy ứng dụng
```
