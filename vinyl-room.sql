-- ============================================================
-- DATABASE SCRIPT: vinyl_room (Vinyl Room Music Streaming)
-- Giai đoạn 2: CSDL Kèm Toàn Bộ Dữ Liệu Mẫu (Seed Data)
-- ============================================================

USE master;
GO

IF DB_ID('vinyl_room') IS NOT NULL
BEGIN
    ALTER DATABASE vinyl_room SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE vinyl_room;
END
GO

CREATE DATABASE vinyl_room;
GO

USE vinyl_room;
GO

-- ==========================================
-- 1. QUẢN LÝ NGƯỜI DÙNG
-- ==========================================
CREATE TABLE users (
  user_id INT IDENTITY(1,1) PRIMARY KEY,
  username NVARCHAR(255) NOT NULL UNIQUE,
  password NVARCHAR(255) NOT NULL,
  email NVARCHAR(255),
  avatar_url NVARCHAR(MAX),
  isActive INT NOT NULL DEFAULT 1 -- 1: Hoạt động, 0: Bị khóa
);

-- ==========================================
-- 2. DỮ LIỆU ÂM NHẠC
-- ==========================================
CREATE TABLE artists (
  artist_id INT IDENTITY(1,1) PRIMARY KEY,
  artist_name NVARCHAR(255) NOT NULL,
  avatar_url NVARCHAR(MAX),
  bio NVARCHAR(MAX)
);

CREATE TABLE albums (
  album_id INT IDENTITY(1,1) PRIMARY KEY,
  album_name NVARCHAR(255) NOT NULL,
  artist_id INT NOT NULL,
  cover_image_url NVARCHAR(MAX),
  release_date DATE,
  CONSTRAINT FK_Albums_Artists FOREIGN KEY (artist_id)
    REFERENCES artists(artist_id) ON DELETE CASCADE
);

CREATE TABLE genres (
  genre_id INT IDENTITY(1,1) PRIMARY KEY,
  genre_name NVARCHAR(100) NOT NULL,
  description NVARCHAR(MAX)
);

CREATE TABLE music (
  music_id INT IDENTITY(1,1) PRIMARY KEY,
  music_name NVARCHAR(255) NOT NULL,
  music_length NVARCHAR(50),
  audio_url NVARCHAR(MAX) NOT NULL,
  cover_image_url NVARCHAR(MAX),
  artist_id INT,
  album_id INT,
  genre_id INT,
  ranking INT DEFAULT 0,
  listen_count INT DEFAULT 0,
  CONSTRAINT FK_Music_Artists FOREIGN KEY (artist_id)
    REFERENCES artists(artist_id) ON DELETE SET NULL,
  CONSTRAINT FK_Music_Albums FOREIGN KEY (album_id)
    REFERENCES albums(album_id) ON DELETE SET NULL,
  CONSTRAINT FK_Music_Genres FOREIGN KEY (genre_id)
    REFERENCES genres(genre_id) ON DELETE SET NULL
);

-- ==========================================
-- 3. PLAYLIST & YÊU THÍCH
-- ==========================================
CREATE TABLE playlist (
  playlist_id INT IDENTITY(1,1) PRIMARY KEY,
  playlist_name NVARCHAR(255) NOT NULL,
  playlist_song_list_count INT DEFAULT 0,
  favourite INT DEFAULT 0,
  favourite_count INT DEFAULT 0,
  description NVARCHAR(MAX),
  cover_image_url NVARCHAR(MAX)
);

CREATE TABLE playlist_music (
  playlist_id INT NOT NULL,
  music_id INT NOT NULL,
  CONSTRAINT PK_PlaylistMusic PRIMARY KEY (playlist_id, music_id),
  CONSTRAINT FK_PlaylistMusic_Playlist FOREIGN KEY (playlist_id)
    REFERENCES playlist(playlist_id) ON DELETE CASCADE,
  CONSTRAINT FK_PlaylistMusic_Music FOREIGN KEY (music_id)
    REFERENCES music(music_id) ON DELETE CASCADE
);

CREATE TABLE user_playlist (
  user_playlist_id INT IDENTITY(1,1) PRIMARY KEY,
  user_id INT NOT NULL,
  playlist_name NVARCHAR(255) NOT NULL,
  playlist_song_list_count INT DEFAULT 0,
  favourite INT NOT NULL DEFAULT 0,
  favourite_count INT DEFAULT 0,
  description NVARCHAR(MAX),
  is_shared INT NOT NULL DEFAULT 0, -- 1: public, 0: private
  CONSTRAINT FK_UserPlaylist_Users FOREIGN KEY (user_id)
    REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE user_playlist_music (
  user_playlist_id INT NOT NULL,
  music_id INT NOT NULL,
  CONSTRAINT PK_UserPlaylistMusic PRIMARY KEY (user_playlist_id, music_id),
  CONSTRAINT FK_UPM_UserPlaylist FOREIGN KEY (user_playlist_id)
    REFERENCES user_playlist(user_playlist_id) ON DELETE CASCADE,
  CONSTRAINT FK_UPM_Music FOREIGN KEY (music_id)
    REFERENCES music(music_id) ON DELETE CASCADE
);

CREATE TABLE user_liked_songs (
  user_id INT NOT NULL,
  music_id INT NOT NULL,
  CONSTRAINT PK_UserLikedSongs PRIMARY KEY (user_id, music_id),
  CONSTRAINT FK_ULS_Users FOREIGN KEY (user_id)
    REFERENCES users(user_id) ON DELETE CASCADE,
  CONSTRAINT FK_ULS_Music FOREIGN KEY (music_id)
    REFERENCES music(music_id) ON DELETE CASCADE
);

CREATE TABLE user_liked_playlists (
  user_id INT NOT NULL,
  user_playlist_id INT NOT NULL,
  CONSTRAINT PK_UserLikedPlaylists PRIMARY KEY (user_id, user_playlist_id),
  CONSTRAINT FK_ULP_Users FOREIGN KEY (user_id)
    REFERENCES users(user_id) ON DELETE NO ACTION,
  CONSTRAINT FK_ULP_UserPlaylist FOREIGN KEY (user_playlist_id)
    REFERENCES user_playlist(user_playlist_id) ON DELETE CASCADE
);

-- ==========================================
-- 4. LỊCH SỬ
-- ==========================================
CREATE TABLE history (
  history_id INT IDENTITY(1,1) PRIMARY KEY,
  user_id INT NOT NULL,
  search_query NVARCHAR(255),
  music_id INT,
  type NVARCHAR(50) NOT NULL, -- 'listen' | 'search'
  created_at DATETIME2 DEFAULT GETDATE(),
  CONSTRAINT FK_History_Users FOREIGN KEY (user_id)
    REFERENCES users(user_id) ON DELETE CASCADE,
  CONSTRAINT FK_History_Music FOREIGN KEY (music_id)
    REFERENCES music(music_id) ON DELETE SET NULL
);
GO

-- ==========================================
-- 5. SEED DATA KHỞI TẠO
-- ==========================================

-- Seed 10 Người dùng mẫu
INSERT INTO users (username, password, email, avatar_url, isActive) VALUES
(N'nguyenvanA', N'123456', N'a.nv@email.com', N'https://example.com/avatars/a.jpg', 1),
(N'tranthib', N'123456', N'b.tt@email.com', N'https://example.com/avatars/b.jpg', 1),
(N'levanc', N'123456', N'c.lv@email.com', N'https://example.com/avatars/c.jpg', 1),
(N'phamthid', N'123456', N'd.pt@email.com', N'https://example.com/avatars/d.jpg', 1),
(N'hoangvane', N'123456', N'e.hv@email.com', N'https://example.com/avatars/e.jpg', 0),
(N'vuthip', N'123456', N'f.vt@email.com', N'https://example.com/avatars/f.jpg', 1),
(N'dangvang', N'123456', N'g.dv@email.com', N'https://example.com/avatars/g.jpg', 1),
(N'buihinh', N'123456', N'h.bh@email.com', N'https://example.com/avatars/h.jpg', 1),
(N'ngothii', N'123456', N'i.nt@email.com', N'https://example.com/avatars/i.jpg', 0),
(N'duongvank', N'123456', N'k.dv@email.com', N'https://example.com/avatars/k.jpg', 1);

INSERT INTO artists (artist_name, avatar_url, bio) VALUES
(N'Sơn Tùng M-TP', N'https://example.com/artists/sontung.jpg', N'Ca sĩ nhạc Pop/R&B hàng đầu Việt Nam.'),
(N'Mỹ Tâm', N'https://example.com/artists/mytam.jpg', N'Họa mi tóc nâu - Biểu tượng nhạc nhẹ Việt Nam.'),
(N'Đen Vâu', N'https://example.com/artists/den.jpg', N'Rapper mộc mạc với ca từ sâu sắc.'),
(N'Vũ', N'https://example.com/artists/vu.jpg', N'Hoàng tử Indie Việt với các bản ballad trầm ấm.'),
(N'Hà Anh Tuấn', N'https://example.com/artists/haanhtuan.jpg', N'Ca sĩ acoustic truyền cảm hứng.'),
(N'Hoàng Thùy Linh', N'https://example.com/artists/hoangthuylinh.jpg', N'Âm nhạc dân gian đương đại độc đáo.'),
(N'Bích Phương', N'https://example.com/artists/bichphuong.jpg', N'Nữ ca sĩ Pop/Ballad đa dạng phong cách.'),
(N'Soobin Hoàng Sơn', N'https://example.com/artists/soobin.jpg', N'Ca sĩ theo đuổi R&B hiện đại.'),
(N'AMEE', N'https://example.com/artists/amee.jpg', N'Nữ ca sĩ trẻ với phong cách ngọt ngào.'),
(N'Trúc Nhân', N'https://example.com/artists/trucnhan.jpg', N'Ca sĩ phong cách châm biếm, cá tính.');

INSERT INTO genres (genre_name, description) VALUES
(N'V-Pop', N'Nhạc Pop Việt Nam hiện đại'),
(N'Ballad', N'Giai điệu nhẹ nhàng, sâu lắng'),
(N'Rap / Hip-hop', N'Nhạc Rap đời thường, gieo vần cá tính'),
(N'Indie', N'Âm nhạc độc lập, mộc mạc và chân thành'),
(N'R&B', N'Giai điệu mượt mà, cảm xúc');

INSERT INTO playlist (playlist_name, playlist_song_list_count, favourite, favourite_count, description, cover_image_url) VALUES
(N'Top Hits Việt Nam', 0, 0, 1200, N'Tuyển tập các bản hit đình đám nhất.', N'https://example.com/playlists/tophits.jpg'),
(N'Giai Điệu Thư Giãn', 0, 0, 850, N'Nhẹ nhàng thư thái sau ngày dài.', N'https://example.com/playlists/chill.jpg'),
(N'Acoustic Chiều Mưa', 0, 0, 640, N'Mộc mạc bên tách cà phê.', N'https://example.com/playlists/acoustic.jpg'),
(N'Trữ Tình Quê Hương', 0, 0, 300, N'Giai điệu quê hương đong đầy.', N'https://example.com/playlists/bolero.jpg'),
(N'Top Album Cũ Mà Hay', 0, 0, 150, N'Những hoài niệm xưa cũ.', N'https://example.com/playlists/classic.jpg');

INSERT INTO albums (album_name, artist_id, cover_image_url, release_date) VALUES
(N'm-tp MTP', 1, N'https://example.com/albums/mtpmtp.jpg', '2017-04-01'),
(N'Tâm 9', 2, N'https://example.com/albums/tam9.jpg', '2017-12-03'),
(N'Một Triệu Like', 3, N'https://example.com/albums/mottrieulike.jpg', '2020-01-19'),
(N'Một Giấc Mơ', 4, N'https://example.com/albums/motgiacmo.jpg', '2020-10-10'),
(N'Truyện Ngắn', 5, N'https://example.com/albums/truyenngan.jpg', '2019-09-01'),
(N'Hoàng', 6, N'https://example.com/albums/hoang.jpg', '2019-10-20'),
(N'Dramatic', 7, N'https://example.com/albums/dramatic.jpg', '2018-11-18'),
(N'The Playah', 8, N'https://example.com/albums/theplayah.jpg', '2020-11-15'),
(N'dreAMEE', 9, N'https://example.com/albums/dreamee.jpg', '2020-06-28'),
(N'Thật Bất Ngờ', 10, N'https://example.com/albums/thatbatngo.jpg', '2015-12-10');

INSERT INTO user_playlist (user_id, playlist_name, playlist_song_list_count, favourite, favourite_count, description, is_shared) VALUES
(1, N'Nhạc Buổi Sáng', 2, 0, 0, N'Nhạc khởi đầu ngày mới', 1),
(1, N'Gym & Chạy Bộ', 0, 0, 0, N'Năng lượng tập luyện', 0),
(2, N'Ballad Tâm Trạng', 2, 0, 0, N'Những đêm mưa', 1),
(3, N'Indie Việt Hay Nhất', 1, 0, 0, N'Tuyển chọn Indie', 1),
(4, N'Nhạc Làm Việc', 0, 0, 0, N'Tập trung cao độ', 0),
(5, N'Nhạc Quê Hương', 0, 0, 0, N'Giai điệu ngọt ngào', 0),
(6, N'Chill Cuối Tuần', 1, 0, 0, N'Thư giãn thứ 7', 1),
(7, N'Acoustic Chọn Lọc', 0, 0, 0, N'Mộc mạc guitar', 1),
(8, N'H yêu âm nhạc', 0, 0, 0, N'Chưa phân loại', 0),
(10, N'K Track', 1, 0, 0, N'Thư viện cá nhân', 1);

INSERT INTO music (music_name, music_length, audio_url, cover_image_url, artist_id, album_id, genre_id, ranking, listen_count) VALUES
(N'Lạc Trôi', '03:55', N'http://10.0.2.2:3000/musics/LacTroi.mp3', N'https://example.com/cover/lactroi.jpg', 1, 1, 1, 1, 150000),
(N'Đâu Chỉ Riêng Em', '04:12', N'http://10.0.2.2:3000/musics/DauChiRiengEm.mp3', N'https://example.com/cover/dauchiriengem.jpg', 2, 2, 2, 2, 120000),
(N'Trốn Tìm', '04:05', N'http://10.0.2.2:3000/musics/TronTim.mp3', N'https://example.com/cover/trontim.jpg', 3, 3, 3, 3, 98000),
(N'Bước Qua Nhau', '04:17', N'http://10.0.2.2:3000/musics/BuocQuaNhau.mp3', N'https://example.com/cover/buocquanhau.jpg', 4, 4, 4, 4, 110000),
(N'Tháng Tư Là Lời Nói Dối Của Em', '05:02', N'http://10.0.2.2:3000/musics/ThangTu.mp3', N'https://example.com/cover/thangtu.jpg', 5, 5, 2, 5, 135000),
(N'Để Mị Nói Cho Mà Nghe', '03:20', N'http://10.0.2.2:3000/musics/DeMiNoi.mp3', N'https://example.com/cover/deminoi.jpg', 6, 6, 1, 6, 142000),
(N'Bùa Yêu', '04:01', N'http://10.0.2.2:3000/musics/BuaYeu.mp3', N'https://example.com/cover/buayeu.jpg', 7, 7, 1, 7, 105000),
(N'Phía Sau Một Cô Gái', '04:25', N'http://10.0.2.2:3000/musics/PhiaSauMotCoGai.mp3', N'https://example.com/cover/phiasau.jpg', 8, 8, 2, 8, 118000),
(N'Sao Anh Chưa Về Nhà', '03:36', N'http://10.0.2.2:3000/musics/SaoAnhChuaVeNha.mp3', N'https://example.com/cover/saoanhchuavenha.jpg', 9, 9, 1, 9, 67000),
(N'Sáng Mắt Chưa', '03:40', N'http://10.0.2.2:3000/musics/SangMatChua.mp3', N'https://example.com/cover/sangmatchua.jpg', 10, 10, 5, 10, 89000);

-- Bảng trung gian
INSERT INTO playlist_music (playlist_id, music_id) VALUES
(1, 1), (1, 4), (1, 5),
(2, 1), (2, 6),
(3, 4), (3, 5),
(4, 2),
(5, 5), (5, 6);

INSERT INTO user_playlist_music (user_playlist_id, music_id) VALUES
(1, 1), (1, 3),
(3, 2), (3, 8),
(4, 4),
(7, 6),
(10, 5);

INSERT INTO user_liked_songs (user_id, music_id) VALUES
(1, 1), (1, 2), (1, 4),
(2, 2), (2, 3),
(3, 4),
(4, 5), (4, 6),
(5, 1),
(6, 7), (6, 8),
(7, 3),
(8, 9), (8, 10),
(9, 2),
(10, 5);

INSERT INTO history (user_id, search_query, music_id, type) VALUES
(1, N'Lạc Trôi', NULL, 'search'),
(1, NULL, 1, 'listen'),
(2, N'Đâu Chỉ Riêng Em', NULL, 'search'),
(2, NULL, 2, 'listen'),
(3, N'Đen Vâu', NULL, 'search'),
(4, NULL, 4, 'listen'),
(5, NULL, 5, 'listen'),
(6, NULL, 6, 'listen'),
(7, N'Hà Anh Tuấn', 7, 'search');

INSERT INTO user_liked_playlists (user_id, user_playlist_id) VALUES
(2, 1),
(3, 1),
(1, 3),
(1, 4),
(6, 1),
(7, 3),
(10, 7),
(2, 10);

UPDATE up
SET favourite_count = (
  SELECT COUNT(*)
  FROM user_liked_playlists ulp
  WHERE ulp.user_playlist_id = up.user_playlist_id
)
FROM user_playlist up;
GO
