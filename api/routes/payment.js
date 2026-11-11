const express = require('express');
const router = express.Router();
const sql = require('mssql');
const { getPool } = require('../configs/db');
const { PayOS } = require('@payos/node');

// Khởi tạo SDK PayOS nếu có cấu hình trong file .env
let payos = null;
const clientId = process.env.PAYOS_CLIENT_ID;
const apiKey = process.env.PAYOS_API_KEY;
const checksumKey = process.env.PAYOS_CHECKSUM_KEY;

if (clientId && apiKey && checksumKey && clientId.trim() !== '') {
  try {
    payos = new PayOS(clientId.trim(), apiKey.trim(), checksumKey.trim());
    console.log('✅ PayOS SDK initialized');
  } catch (err) {
    console.warn('⚠️ PayOS init warning:', err.message);
  }
}

// 1. Tạo Link / Mã QR thanh toán VietQR gói 19.000đ (30 ngày)
router.post('/create-payment-link', async (req, res) => {
  try {
    const userId = req.headers['x-user-id'] || req.body.userId;
    if (!userId) {
      return res.status(401).json({ success: false, message: 'Vui lòng đăng nhập để nâng cấp gói' });
    }

    // Giá cố định gói Vinyl Premium: 19.000đ / 30 ngày
    const amount = 19000;
    // PayOS yêu cầu orderCode là số nguyên (tối đa 9007199254740991)
    const orderCode = Number(String(Date.now()).slice(-6) + Math.floor(Math.random() * 900 + 100));
    const description = `VinylRoom ${orderCode}`; // Tối đa 25 ký tự, không dấu

    let checkoutUrl = '';
    let qrCode = '';
    let paymentLinkId = null;
    let payosData = null;

    if (payos) {
      try {
        const domain = process.env.APP_DOMAIN || 'http://localhost:3000';
        const paymentLinkData = {
          orderCode,
          amount,
          description: `VinylRoom ${orderCode}`.slice(0, 25),
          returnUrl: `${domain}/payment/success`,
          cancelUrl: `${domain}/payment/cancel`
        };

        const payosRes = await payos.paymentRequests.create(paymentLinkData);
        payosData = payosRes;
        checkoutUrl = payosRes.checkoutUrl || '';
        qrCode = payosRes.qrCode || '';
        paymentLinkId = payosRes.paymentLinkId || payosRes.id || null;
      } catch (payosErr) {
        console.warn('PayOS API error, using VietQR fallback:', payosErr.message);
      }
    }

    // Fallback nếu chưa kết nối được PayOS API
    if (!qrCode) {
      qrCode = `00020101021238610010A00000072701310006970422011709012345670208QRIBFTTA53037045405${amount}5802VN62${String(orderCode).length + 4}08${orderCode}6304`;
      checkoutUrl = `https://pay.payos.vn`;
    }

    const pool = await getPool();

    // Lưu đơn hàng vào bảng orders với trạng thái PENDING
    await pool.request()
      .input('orderCode', sql.BigInt, orderCode)
      .input('userId', sql.Int, userId)
      .input('amount', sql.Int, amount)
      .input('desc', sql.NVarChar, description)
      .input('paymentLinkId', sql.NVarChar, paymentLinkId)
      .query(`
        INSERT INTO orders (order_code, user_id, amount, description, status, payment_link_id, created_at)
        VALUES (@orderCode, @userId, @amount, @desc, 'PENDING', @paymentLinkId, GETDATE())
      `);

    res.json({
      success: true,
      data: {
        orderCode,
        amount,
        description,
        checkoutUrl,
        qrCode,
        accountName: payosData?.accountName || 'NGUYEN QUANG HUY',
        accountNumber: payosData?.accountNumber || '10142611119770087',
        bin: payosData?.bin || '970452',
        isPayOSConfigured: !!payos
      }
    });
  } catch (error) {
    console.error('Error creating payment link:', error);
    res.status(500).json({ success: false, message: 'Lỗi tạo liên kết thanh toán' });
  }
});

// 2. Webhook PayOS tự động gọi về khi người dùng quét mã thanh toán thành công
router.post('/webhook', async (req, res) => {
  try {
    let webhookData = req.body;

    // Xác thực chữ ký dữ liệu nếu PayOS được cấu hình
    if (payos && req.body.data) {
      try {
        webhookData = await payos.webhooks.verify(req.body);
      } catch (verifyErr) {
        console.error('PayOS Webhook verification failed:', verifyErr.message);
        return res.status(400).json({ success: false, message: 'Chữ ký webhook không hợp lệ' });
      }
    }

    const data = webhookData.data || webhookData;
    const orderCode = data.orderCode;

    // Nếu không có orderCode (request ping kiểm tra webhook từ PayOS Dashboard)
    if (!orderCode) {
      return res.status(200).json({ success: true, message: 'Webhook test ping nhận thành công' });
    }

    const pool = await getPool();

    // Cập nhật trạng thái đơn hàng thành PAID
    const orderResult = await pool.request()
      .input('orderCode', sql.BigInt, orderCode)
      .query('SELECT user_id, status FROM orders WHERE order_code = @orderCode');

    if (orderResult.recordset.length === 0) {
      // Trả về 200 để PayOS Dashboard xác nhận webhook thành công
      console.log(`[PayOS Webhook] Nhận orderCode test ping hoặc chưa lưu trong DB: ${orderCode}`);
      return res.status(200).json({ success: true, message: 'Đã nhận webhook' });
    }

    const order = orderResult.recordset[0];
    if (order.status !== 'PAID') {
      await pool.request()
        .input('orderCode', sql.BigInt, orderCode)
        .query(`
          UPDATE orders 
          SET status = 'PAID', paid_at = GETDATE() 
          WHERE order_code = @orderCode
        `);

      // Gia hạn hoặc cấp mới 30 ngày Premium cho người dùng (tự động cộng dồn nếu đang còn hạn)
      await pool.request()
        .input('userId', sql.Int, order.user_id)
        .query(`
          UPDATE users
          SET is_premium = 1,
              premium_expires_at = DATEADD(day, 30, CASE WHEN premium_expires_at > GETDATE() THEN premium_expires_at ELSE GETDATE() END)
          WHERE user_id = @userId
        `);

      console.log(`🎉 User ${order.user_id} upgraded to Vinyl Premium (30 days) via PayOS order ${orderCode}`);
    }

    res.json({ success: true, message: 'Xử lý webhook thành công' });
  } catch (error) {
    console.error('PayOS Webhook error:', error);
    res.status(500).json({ success: false, message: 'Lỗi xử lý webhook' });
  }
});

// 3. Kiểm tra trạng thái đơn hàng (Polling từ Flutter hoặc đồng bộ với PayOS)
router.get('/check-status/:orderCode', async (req, res) => {
  try {
    const orderCode = req.params.orderCode;
    const pool = await getPool();

    const orderRes = await pool.request()
      .input('orderCode', sql.BigInt, orderCode)
      .query(`
        SELECT o.order_id, o.order_code, o.user_id, o.amount, o.status, o.paid_at,
               u.is_premium, u.premium_expires_at
        FROM orders o
        JOIN users u ON o.user_id = u.user_id
        WHERE o.order_code = @orderCode
      `);

    if (orderRes.recordset.length === 0) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy đơn hàng' });
    }

    let order = orderRes.recordset[0];

    // Nếu đơn hàng đang PENDING và PayOS khả dụng, đồng bộ trực tiếp với PayOS
    if (order.status === 'PENDING' && payos) {
      try {
        const paymentInfo = await payos.paymentRequests.get(orderCode);
        if (paymentInfo && paymentInfo.status === 'PAID') {
          await pool.request()
            .input('orderCode', sql.BigInt, orderCode)
            .query(`UPDATE orders SET status = 'PAID', paid_at = GETDATE() WHERE order_code = @orderCode`);

          await pool.request()
            .input('userId', sql.Int, order.user_id)
            .query(`
              UPDATE users
              SET is_premium = 1,
                  premium_expires_at = DATEADD(day, 30, CASE WHEN premium_expires_at > GETDATE() THEN premium_expires_at ELSE GETDATE() END)
              WHERE user_id = @userId
            `);

          order.status = 'PAID';
          order.is_premium = 1;
        }
      } catch (checkErr) {
        // Bỏ qua lỗi kết nối PayOS khi kiểm tra
      }
    }

    const isActivePremium = order.is_premium === 1 && (!order.premium_expires_at || new Date(order.premium_expires_at) > new Date());

    res.json({
      success: true,
      orderCode: order.order_code,
      status: order.status,
      isPaid: order.status === 'PAID',
      isPremium: isActivePremium,
      premiumExpiresAt: order.premium_expires_at
    });
  } catch (error) {
    console.error('Error checking order status:', error);
    res.status(500).json({ success: false, message: 'Lỗi kiểm tra đơn hàng' });
  }
});

// 4. Kích hoạt thử nghiệm (Dành riêng cho Demo / Chấm thi không cần chuyển khoản thật)
router.post('/test-activate', async (req, res) => {
  try {
    const userId = req.headers['x-user-id'] || req.body.userId;
    if (!userId) {
      return res.status(401).json({ success: false, message: 'Vui lòng đăng nhập' });
    }

    const orderCode = Number(String(Date.now()).slice(-6) + Math.floor(Math.random() * 900 + 100));
    const pool = await getPool();

    // Thêm bản ghi order PAID
    await pool.request()
      .input('orderCode', sql.BigInt, orderCode)
      .input('userId', sql.Int, userId)
      .input('desc', sql.NVarChar, 'Demo Test Kích Hoạt 19k')
      .query(`
        INSERT INTO orders (order_code, user_id, amount, description, status, created_at, paid_at)
        VALUES (@orderCode, @userId, 19000, @desc, 'PAID', GETDATE(), GETDATE())
      `);

    // Gia hạn 30 ngày Premium
    const updateRes = await pool.request()
      .input('userId', sql.Int, userId)
      .query(`
        UPDATE users
        SET is_premium = 1,
            premium_expires_at = DATEADD(day, 30, CASE WHEN premium_expires_at > GETDATE() THEN premium_expires_at ELSE GETDATE() END)
        OUTPUT inserted.is_premium, inserted.premium_expires_at
        WHERE user_id = @userId
      `);

    const updatedUser = updateRes.recordset[0];

    res.json({
      success: true,
      message: '🎉 Kích hoạt 30 ngày gói Vinyl Premium thành công!',
      isPremium: true,
      premiumExpiresAt: updatedUser.premium_expires_at
    });
  } catch (error) {
    console.error('Error activating test premium:', error);
    res.status(500).json({ success: false, message: 'Lỗi kích hoạt thử nghiệm' });
  }
});

// 5. Hủy gói Premium về Free (Dành cho việc test lại luồng khóa tính năng)
router.post('/test-cancel', async (req, res) => {
  try {
    const userId = req.headers['x-user-id'] || req.body.userId;
    if (!userId) {
      return res.status(401).json({ success: false, message: 'Vui lòng đăng nhập' });
    }

    const pool = await getPool();
    await pool.request()
      .input('userId', sql.Int, userId)
      .query(`
        UPDATE users
        SET is_premium = 0,
            premium_expires_at = NULL
        WHERE user_id = @userId
      `);

    res.json({
      success: true,
      message: 'Đã chuyển tài khoản về gói Miễn Phí (Free)',
      isPremium: false
    });
  } catch (error) {
    console.error('Error canceling premium:', error);
    res.status(500).json({ success: false, message: 'Lỗi hủy gói' });
  }
});

module.exports = router;
