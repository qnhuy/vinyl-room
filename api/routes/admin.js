const express = require("express");
const { getPool } = require("../configs/db");
const { verifyAdmin } = require("../middlewares/adminAuth");

const router = express.Router();

// Áp dụng middleware kiểm tra quyền Admin cho toàn bộ route /admin
router.use(verifyAdmin);

/**
 * 1. KIỂM TRA QUYỀN ADMIN (Ping)
 */
router.get("/check", (req, res) => {
  res.json({ ok: true, admin: req.adminUser });
});

/**
 * 2. THỐNG KÊ TỔNG QUAN DASHBOARD
 */
router.get("/stats", async (req, res) => {
  try {
    const pool = await getPool();

    // Thống kê số lượng tổng
    const countsResult = await pool.request().query(`
      SELECT 
        (SELECT COUNT(*) FROM music) AS total_songs,
        (SELECT COUNT(*) FROM users) AS total_users,
        (SELECT COUNT(*) FROM artists) AS total_artists,
        (SELECT COUNT(*) FROM albums) AS total_albums,
        (SELECT ISNULL(SUM(listen_count), 0) FROM music) AS total_plays;
    `);

    // Top 5 bài hát nghe nhiều nhất
    const topSongsResult = await pool.request().query(`
      SELECT TOP 5 m.music_id, m.music_name, m.listen_count, a.artist_name, m.cover_image_url
      FROM music m
      LEFT JOIN artists a ON a.artist_id = m.artist_id
      ORDER BY m.listen_count DESC;
    `);

    // Top 5 từ khóa tìm kiếm hot
    let topSearches = [];
    try {
      const searchResult = await pool.request().query(`
        SELECT TOP 5 search_query, COUNT(*) AS count
        FROM history
        WHERE type = 'search' AND search_query IS NOT NULL AND search_query != ''
        GROUP BY search_query
        ORDER BY count DESC;
      `);
      topSearches = searchResult.recordset;
    } catch (_) {}

    res.json({
      counts: countsResult.recordset[0] || {},
      topSongs: topSongsResult.recordset || [],
      topSearches,
    });
  } catch (err) {
    console.error("[Admin Stats Error]:", err);
    res.status(500).json({ error: String(err.message || err) });
  }
});

/**
 * 3. QUẢN LÝ BÀI HÁT (SONGS CRUD)
 */
router.get("/songs", async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query(`
      SELECT 
        m.music_id, m.music_name, m.music_length, m.audio_url, m.cover_image_url,
        m.artist_id, a.artist_name,
        m.album_id, al.album_name,
        m.genre_id, g.genre_name,
        m.listen_count, m.ranking
      FROM music m
      LEFT JOIN artists a ON a.artist_id = m.artist_id
      LEFT JOIN albums al ON al.album_id = m.album_id
      LEFT JOIN genres g ON g.genre_id = m.genre_id
      ORDER BY m.music_id DESC;
    `);
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: String(err.message || err) });
  }
});

router.post("/songs", async (req, res) => {
  try {
    const {
      music_name,
      music_length,
      audio_url,
      cover_image_url,
      artist_id,
      album_id,
      genre_id,
    } = req.body || {};

    if (!music_name || !audio_url) {
      return res.status(400).json({ error: "Tên bài hát và đường dẫn âm thanh không được để trống!" });
    }

    const pool = await getPool();
    const result = await pool
      .request()
      .input("music_name", music_name)
      .input("music_length", music_length || "03:00")
      .input("audio_url", audio_url)
      .input("cover_image_url", cover_image_url || null)
      .input("artist_id", artist_id ? Number(artist_id) : null)
      .input("album_id", album_id ? Number(album_id) : null)
      .input("genre_id", genre_id ? Number(genre_id) : null)
      .query(`
        INSERT INTO music (music_name, music_length, audio_url, cover_image_url, artist_id, album_id, genre_id, listen_count)
        OUTPUT INSERTED.music_id, INSERTED.music_name, INSERTED.music_length, INSERTED.audio_url, INSERTED.cover_image_url
        VALUES (@music_name, @music_length, @audio_url, @cover_image_url, @artist_id, @album_id, @genre_id, 0);
      `);

    res.json(result.recordset[0]);
  } catch (err) {
    res.status(500).json({ error: String(err.message || err) });
  }
});

router.put("/songs/:id", async (req, res) => {
  try {
    const musicId = Number(req.params.id);
    const {
      music_name,
      music_length,
      audio_url,
      cover_image_url,
      artist_id,
      album_id,
      genre_id,
    } = req.body || {};

    const pool = await getPool();
    await pool
      .request()
      .input("musicId", musicId)
      .input("music_name", music_name)
      .input("music_length", music_length || "03:00")
      .input("audio_url", audio_url)
      .input("cover_image_url", cover_image_url || null)
      .input("artist_id", artist_id ? Number(artist_id) : null)
      .input("album_id", album_id ? Number(album_id) : null)
      .input("genre_id", genre_id ? Number(genre_id) : null)
      .query(`
        UPDATE music
        SET 
          music_name = @music_name,
          music_length = @music_length,
          audio_url = @audio_url,
          cover_image_url = @cover_image_url,
          artist_id = @artist_id,
          album_id = @album_id,
          genre_id = @genre_id
        WHERE music_id = @musicId;
      `);

    res.json({ ok: true, message: "Đã cập nhật bài hát thành công!" });
  } catch (err) {
    res.status(500).json({ error: String(err.message || err) });
  }
});

router.delete("/songs/:id", async (req, res) => {
  try {
    const musicId = Number(req.params.id);
    const pool = await getPool();

    // Dọn dẹp các ràng buộc trước khi xóa bài hát
    await pool
      .request()
      .input("musicId", musicId)
      .query(`
        DELETE FROM user_liked_songs WHERE music_id = @musicId;
        DELETE FROM playlist_music WHERE music_id = @musicId;
        DELETE FROM user_playlist_music WHERE music_id = @musicId;
        DELETE FROM music WHERE music_id = @musicId;
      `);

    res.json({ ok: true, message: "Đã xóa bài hát thành công!" });
  } catch (err) {
    res.status(500).json({ error: String(err.message || err) });
  }
});

/**
 * 4. QUẢN LÝ NGƯỜI DÙNG (USERS)
 */
router.get("/users", async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query(`
      SELECT user_id, username, email, avatar_url, role, isActive
      FROM users
      ORDER BY user_id DESC;
    `);
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: String(err.message || err) });
  }
});

router.put("/users/:id/status", async (req, res) => {
  try {
    const targetUserId = Number(req.params.id);
    const isActive = Number(req.body?.isActive) === 1 ? 1 : 0;

    // Không cho phép tự khóa tài khoản của chính mình
    if (targetUserId === req.adminUser.user_id && isActive === 0) {
      return res.status(400).json({ error: "Bạn không thể tự khóa tài khoản của chính mình!" });
    }

    const pool = await getPool();
    await pool
      .request()
      .input("userId", targetUserId)
      .input("isActive", isActive)
      .query("UPDATE users SET isActive = @isActive WHERE user_id = @userId;");

    res.json({ ok: true, isActive });
  } catch (err) {
    res.status(500).json({ error: String(err.message || err) });
  }
});

router.put("/users/:id/role", async (req, res) => {
  try {
    const targetUserId = Number(req.params.id);
    const newRole = String(req.body?.role || "user").toLowerCase();

    if (newRole !== "admin" && newRole !== "user") {
      return res.status(400).json({ error: "Vai trò không hợp lệ (chỉ nhận 'admin' hoặc 'user')!" });
    }

    // Không cho phép tự hạ quyền của chính mình
    if (targetUserId === req.adminUser.user_id && newRole !== "admin") {
      return res.status(400).json({ error: "Bạn không thể tự hạ quyền quản trị của chính mình!" });
    }

    const pool = await getPool();
    await pool
      .request()
      .input("userId", targetUserId)
      .input("role", newRole)
      .query("UPDATE users SET role = @role WHERE user_id = @userId;");

    res.json({ ok: true, role: newRole });
  } catch (err) {
    res.status(500).json({ error: String(err.message || err) });
  }
});

/**
 * 5. DANH MỤC PHỤ TRỢ: NGHỆ SĨ & THỂ LOẠI (Cho dropdown form)
 */
router.get("/artists", async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query("SELECT artist_id, artist_name, avatar_url FROM artists ORDER BY artist_name ASC");
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: String(err.message || err) });
  }
});

router.get("/genres", async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query("SELECT genre_id, genre_name FROM genres ORDER BY genre_name ASC");
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: String(err.message || err) });
  }
});

module.exports = router;
