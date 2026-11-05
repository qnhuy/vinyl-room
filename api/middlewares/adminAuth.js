const { getPool } = require("../configs/db");

/**
 * Middleware xác thực quyền quản trị viên (Admin).
 * Kiểm tra x-user-id gửi lên từ header/query và đối chiếu vai trò trong database.
 */
async function verifyAdmin(req, res, next) {
  try {
    const rawUserId =
      req.headers["x-user-id"] ||
      req.headers["user-id"] ||
      req.query?.userId ||
      req.body?.userId;

    const userId = Number(rawUserId);
    if (!userId || isNaN(userId)) {
      return res.status(401).json({
        error: "Yêu cầu đăng nhập với tài khoản Quản trị viên!",
      });
    }

    const pool = await getPool();
    const result = await pool
      .request()
      .input("userId", userId)
      .query(`
        SELECT user_id, username, email, role, isActive
        FROM users
        WHERE user_id = @userId
      `);

    if (!result.recordset.length) {
      return res.status(401).json({ error: "Tài khoản không tồn tại!" });
    }

    const user = result.recordset[0];

    if (user.isActive !== 1) {
      return res.status(403).json({ error: "Tài khoản của bạn đã bị vô hiệu hóa!" });
    }

    if (String(user.role).toLowerCase() !== "admin") {
      return res.status(403).json({
        error: "Truy cập bị từ chối. Bạn không có quyền Quản trị viên!",
      });
    }

    req.adminUser = user;
    next();
  } catch (err) {
    console.error("[AdminAuth Error]:", err);
    res.status(500).json({ error: "Lỗi hệ thống khi xác thực quyền quản trị viên!" });
  }
}

module.exports = {
  verifyAdmin,
};
