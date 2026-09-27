-- ============================================================
-- DATABASE SCRIPT: vinyl_room (Vinyl Room Music Streaming)
-- Giai đoạn 1: Thiết Kế Sơ Đồ CSDL & Khởi Tạo Bảng (ERD Schema)
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
