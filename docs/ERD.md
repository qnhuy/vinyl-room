# Sơ Đồ Thực Thể Quan Hệ (ERD) & Cấu Trúc Cơ Sở Dữ Liệu

Dự án **Vinyl Room** sử dụng hệ quản trị cơ sở dữ liệu **Microsoft SQL Server (MSSQL)** quan hệ chuẩn hóa cao, hỗ trợ phân quyền người dùng, danh mục âm nhạc, playlist đa cấp độ và lịch sử nghe nhạc.

---

## 1. Sơ Đồ ERD (Entity Relationship Diagram)

```mermaid
erDiagram
    USERS ||--o{ USER_PLAYLIST : "tạo"
    USERS ||--o{ USER_LIKED_SONGS : "yêu thích bài hát"
    USERS ||--o{ USER_LIKED_PLAYLISTS : "lưu playlist"
    USERS ||--o{ PLAYLIST_FAVOURITES : "favourite"
    USERS ||--o{ HISTORY : "ghi nhận"

    ARTISTS ||--o{ ALBUMS : "phát hành"
    ARTISTS ||--o{ MUSIC : "trình bày"
    ALBUMS ||--o{ MUSIC : "thuộc album"
    GENRES ||--o{ MUSIC : "phân loại"

    MUSIC ||--o{ PLAYLIST_MUSIC : "nằm trong"
    PLAYLIST ||--o{ PLAYLIST_MUSIC : "chứa"

    MUSIC ||--o{ USER_PLAYLIST_MUSIC : "nằm trong"
    USER_PLAYLIST ||--o{ USER_PLAYLIST_MUSIC : "chứa"

    MUSIC ||--o{ USER_LIKED_SONGS : "được thích"
    USER_PLAYLIST ||--o{ USER_LIKED_PLAYLISTS : "được lưu"
    USER_PLAYLIST ||--o{ PLAYLIST_FAVOURITES : "được lưu"
    MUSIC ||--o{ HISTORY : "lịch sử nghe"

    USERS {
        int user_id PK
        nvarchar username
        nvarchar password
        nvarchar email
        nvarchar avatar_url
        nvarchar role "user | admin"
        int isActive "1: active, 0: locked"
    }

    ARTISTS {
        int artist_id PK
        nvarchar artist_name
        nvarchar avatar_url
        nvarchar bio
    }

    ALBUMS {
        int album_id PK
        nvarchar album_name
        int artist_id FK
        nvarchar cover_image_url
        date release_date
    }

    GENRES {
        int genre_id PK
        nvarchar genre_name
        nvarchar description
    }

    MUSIC {
        int music_id PK
        nvarchar music_name
        nvarchar music_length
        nvarchar audio_url
        nvarchar cover_image_url
        int artist_id FK
        int album_id FK
        int genre_id FK
        int ranking
        int listen_count
    }

    PLAYLIST {
        int playlist_id PK
        nvarchar playlist_name
        int playlist_song_list_count
        int favourite
        int favourite_count
        nvarchar description
        nvarchar cover_image_url
    }

    PLAYLIST_MUSIC {
        int playlist_id PK,FK
        int music_id PK,FK
    }

    USER_PLAYLIST {
        int user_playlist_id PK
        int user_id FK
        nvarchar playlist_name
        int playlist_song_list_count
        int favourite
        int favourite_count
        nvarchar description
        int is_shared "1: public, 0: private"
    }

    USER_PLAYLIST_MUSIC {
        int user_playlist_id PK,FK
        int music_id PK,FK
    }

    USER_LIKED_SONGS {
        int user_id PK,FK
        int music_id PK,FK
    }

    USER_LIKED_PLAYLISTS {
        int user_id PK,FK
        int user_playlist_id PK,FK
    }

    PLAYLIST_FAVOURITES {
        int id PK
        int user_id FK
        int playlist_id FK
        datetime2 created_at
    }

    HISTORY {
        int history_id PK
        int user_id FK
        nvarchar search_query
        int music_id FK
        nvarchar type "listen | search"
    }
```

---

## 2. Danh Sách Các Bảng & Mô Tả

| Tên Bảng | Vai Trò & Mô Tả |
|---|---|
| **`users`** | Quản lý tài khoản, mật khẩu, email, avatar, trạng thái kích hoạt (`isActive`), và vai trò phân quyền (`role`: `user` hoặc `admin`). |
| **`artists`** | Danh mục nghệ sĩ / ca sĩ thể hiện. |
| **`albums`** | Danh mục album âm nhạc do nghệ sĩ phát hành. |
| **`genres`** | Danh mục thể loại âm nhạc (Pop, Ballad, Rock, Rap, Jazz, ...). |
| **`music`** | Kho bài hát chính: tên bài, thời lượng, file audio, ảnh bìa, lượt nghe (`listen_count`), thứ hạng. |
| **`playlist`** | Danh sách playlist công cộng / hệ thống tạo sẵn do Admin tuyển chọn. |
| **`playlist_music`** | Bảng trung gian liên kết bài hát vào playlist của hệ thống. |
| **`user_playlist`** | Playlist do người dùng tự tạo, có cờ `is_shared` để bật/tắt chia sẻ cộng đồng (Public/Private). |
| **`user_playlist_music`** | Bảng trung gian liên kết bài hát vào playlist của người dùng. |
| **`user_liked_songs`** | Danh sách các bài hát mà người dùng bấm yêu thích (Liked Songs). |
| **`user_liked_playlists`** | Danh sách playlist của người khác mà người dùng lưu về thư viện cá nhân. |
| **`playlist_favourites`** | Bảng ghi nhận lượt yêu thích playlist phục vụ API backend. |
| **`history`** | Ghi nhận nhật ký nghe nhạc và các từ khóa tìm kiếm gần đây của người dùng. |
