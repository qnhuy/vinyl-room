import 'dart:convert';
import '../utils/http.dart';

/// Kết quả tạo liên kết thanh toán PayOS
class PaymentLinkResult {
  final int orderCode;
  final int amount;
  final String description;
  final String checkoutUrl;
  final String qrCode;
  final String accountName;
  final String accountNumber;
  final String bin;
  final bool isPayOSConfigured;

  PaymentLinkResult({
    required this.orderCode,
    required this.amount,
    required this.description,
    required this.checkoutUrl,
    required this.qrCode,
    required this.accountName,
    required this.accountNumber,
    required this.bin,
    required this.isPayOSConfigured,
  });

  factory PaymentLinkResult.fromMap(Map<String, dynamic> map) {
    return PaymentLinkResult(
      orderCode: (map['orderCode'] is int)
          ? map['orderCode'] as int
          : int.tryParse('${map['orderCode']}') ?? 0,
      amount: (map['amount'] is int)
          ? map['amount'] as int
          : int.tryParse('${map['amount']}') ?? 19000,
      description: map['description']?.toString() ?? '',
      checkoutUrl: map['checkoutUrl']?.toString() ?? '',
      qrCode: map['qrCode']?.toString() ?? '',
      accountName: map['accountName']?.toString() ?? 'NGUYEN QUANG HUY',
      accountNumber: map['accountNumber']?.toString() ?? '10142611112216716',
      bin: map['bin']?.toString() ?? '970452',
      isPayOSConfigured: map['isPayOSConfigured'] == true,
    );
  }
}

/// Trạng thái đơn hàng thanh toán
class OrderStatusResult {
  final int orderCode;
  final String status;
  final bool isPaid;
  final bool isPremium;
  final DateTime? premiumExpiresAt;

  OrderStatusResult({
    required this.orderCode,
    required this.status,
    required this.isPaid,
    required this.isPremium,
    this.premiumExpiresAt,
  });

  factory OrderStatusResult.fromMap(Map<String, dynamic> map) {
    DateTime? exp;
    if (map['premiumExpiresAt'] != null && map['premiumExpiresAt'].toString().isNotEmpty) {
      exp = DateTime.tryParse(map['premiumExpiresAt'].toString());
    }
    return OrderStatusResult(
      orderCode: (map['orderCode'] is int)
          ? map['orderCode'] as int
          : int.tryParse('${map['orderCode']}') ?? 0,
      status: map['status']?.toString() ?? 'PENDING',
      isPaid: map['isPaid'] == true,
      isPremium: map['isPremium'] == true,
      premiumExpiresAt: exp,
    );
  }
}

/// Service giao tiếp với các API thanh toán PayOS
class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  /// Tạo link / mã QR VietQR thanh toán gói Premium 19.000đ (30 ngày)
  Future<PaymentLinkResult> createPaymentLink() async {
    final res = await Http.post('/payment/create-payment-link');
    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);
      throw Exception(data['message'] ?? 'Không thể tạo mã thanh toán');
    }
    final body = jsonDecode(res.body);
    return PaymentLinkResult.fromMap(Map<String, dynamic>.from(body['data']));
  }

  /// Kiểm tra trạng thái đơn hàng (xác nhận chuyển khoản thành công)
  Future<OrderStatusResult> checkStatus(int orderCode) async {
    final res = await Http.get('/payment/check-status/$orderCode');
    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);
      throw Exception(data['message'] ?? 'Lỗi kiểm tra trạng thái đơn hàng');
    }
    final body = jsonDecode(res.body);
    return OrderStatusResult.fromMap(Map<String, dynamic>.from(body));
  }

  /// Kích hoạt thử nghiệm 30 ngày (Dành cho việc Demo / Chấm thi)
  Future<Map<String, dynamic>> testActivate() async {
    final res = await Http.post('/payment/test-activate');
    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);
      throw Exception(data['message'] ?? 'Lỗi kích hoạt thử nghiệm');
    }
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  /// Hủy gói Premium chuyển về Free (để test luồng khóa tính năng)
  Future<void> testCancel() async {
    final res = await Http.post('/payment/test-cancel');
    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);
      throw Exception(data['message'] ?? 'Lỗi hủy gói thử nghiệm');
    }
  }
}
