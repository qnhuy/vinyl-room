import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../services/payment_service.dart';

/// Màn hình riêng biệt hiển thị thông tin gói và mã QR thanh toán VietQR (PayOS).
class PremiumPaymentScreen extends StatefulWidget {
  const PremiumPaymentScreen({super.key});

  @override
  State<PremiumPaymentScreen> createState() => _PremiumPaymentScreenState();
}

class _PremiumPaymentScreenState extends State<PremiumPaymentScreen> {
  bool _isLoading = true;
  bool _isChecking = false;
  bool _isSavingImage = false;
  PaymentLinkResult? _paymentLink;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initPaymentLink();
  }

  /// Khởi tạo và lấy link/mã QR thanh toán VietQR từ Backend PayOS
  Future<void> _initPaymentLink() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await PaymentService.instance.createPaymentLink();
      if (!mounted) return;
      setState(() {
        _paymentLink = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  /// Lưu ảnh mã QR về bộ nhớ máy (Download / Documents)
  Future<void> _saveQrImageToDevice() async {
    if (_paymentLink == null || _paymentLink!.qrCode.isEmpty) return;

    setState(() => _isSavingImage = true);
    try {
      final qrUrl = _paymentLink!.qrCode;
      final response = await http.get(Uri.parse(qrUrl));
      if (response.statusCode != 200) {
        throw Exception('Không thể tải dữ liệu ảnh mã QR');
      }

      final bytes = response.bodyBytes;
      String? saveDirPath;

      if (Platform.isAndroid) {
        // Thư mục Download ngoài trên Android
        final publicDownloadDir = Directory('/storage/emulated/0/Download');
        if (await publicDownloadDir.exists()) {
          saveDirPath = publicDownloadDir.path;
        } else {
          final extDir = await getExternalStorageDirectory();
          saveDirPath = extDir?.path;
        }
      } else if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null) {
          final winDownload = Directory('$userProfile\\Downloads');
          if (await winDownload.exists()) {
            saveDirPath = winDownload.path;
          }
        }
        if (saveDirPath == null) {
          final docDir = await getDownloadsDirectory();
          saveDirPath = docDir?.path;
        }
      } else if (Platform.isIOS || Platform.isMacOS) {
        final dir = await getApplicationDocumentsDirectory();
        saveDirPath = dir.path;
      }

      if (saveDirPath == null) {
        final dir = await getApplicationDocumentsDirectory();
        saveDirPath = dir.path;
      }

      final fileName = 'VinylRoom_PayOS_QR_${_paymentLink!.orderCode}.png';
      final file = File('$saveDirPath${Platform.pathSeparator}$fileName');
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Đã lưu ảnh mã QR thành công:\n$fileName'),
          backgroundColor: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Sao chép đường dẫn',
            textColor: Colors.amber,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: file.path));
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi lưu ảnh: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSavingImage = false);
    }
  }

  /// Mở liên kết thanh toán PayOS trên trình duyệt web
  Future<void> _openCheckoutUrl() async {
    if (_paymentLink == null || _paymentLink!.checkoutUrl.isEmpty) return;
    try {
      final uri = Uri.parse(_paymentLink!.checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching url: $e');
    }
  }

  /// Kiểm tra trạng thái đơn hàng (xác nhận chuyển khoản thành công)
  Future<void> _checkPaymentStatus() async {
    if (_paymentLink == null) return;

    setState(() => _isChecking = true);
    try {
      final status = await PaymentService.instance.checkStatus(_paymentLink!.orderCode);
      if (!mounted) return;

      if (status.isPaid) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        await auth.updatePremiumStatus(true, status.premiumExpiresAt);

        if (!mounted) return;
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chưa ghi nhận chuyển khoản. Vui lòng quét mã VietQR và kiểm tra lại sau giây lát!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  /// Kích hoạt thử nghiệm 30 ngày (Dành cho việc Demo / Chấm thi tức thì)
  Future<void> _handleTestActivate() async {
    setState(() => _isChecking = true);
    try {
      final res = await PaymentService.instance.testActivate();
      if (!mounted) return;

      final auth = Provider.of<AuthProvider>(context, listen: false);
      DateTime? exp;
      if (res['premiumExpiresAt'] != null) {
        exp = DateTime.tryParse(res['premiumExpiresAt'].toString());
      }
      await auth.updatePremiumStatus(true, exp);

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  /// Hủy gói Premium về Free (để test luồng khóa tính năng)
  Future<void> _handleTestCancel() async {
    setState(() => _isChecking = true);
    try {
      await PaymentService.instance.testCancel();
      if (!mounted) return;

      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.updatePremiumStatus(false, null);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã chuyển tài khoản về gói Miễn Phí (Free)'),
          backgroundColor: Colors.grey,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Color(0xFFD4AF37), size: 32),
            SizedBox(width: 10),
            Text('Nâng cấp thành công!'),
          ],
        ),
        content: const Text(
          'Chúc mừng bạn đã trở thành thành viên Vinyl Premium (30 ngày)!\n\nToàn bộ tính năng AI Smart Flow và Tạo playlist không giới hạn đã được mở khóa.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(ctx); // đóng dialog
              Navigator.pop(context, true); // quay lại màn hình trước
            },
            child: const Text('Bắt đầu trải nghiệm', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthProvider>(context);
    final isPrem = auth.isPremium;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh Toán Vinyl Premium'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFD4AF37)),
                  SizedBox(height: 16),
                  Text('Đang tạo mã thanh toán VietQR (PayOS)...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 550),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Package Info
                      _buildPackageHeader(theme, auth, isPrem),
                      const SizedBox(height: 16),

                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red, fontSize: 13),
                                ),
                              ),
                              IconButton(
                                onPressed: _initPaymentLink,
                                icon: const Icon(Icons.refresh, color: Colors.red),
                                tooltip: 'Thử lại',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // QR Code Card Section
                      if (_paymentLink != null) ...[
                        _buildQrCodeCard(theme),
                        const SizedBox(height: 16),

                        // Action Buttons: Lưu ảnh & Mở PayOS
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isSavingImage ? null : _saveQrImageToDevice,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(color: Color(0xFFD4AF37)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                icon: _isSavingImage
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.download, color: Color(0xFFD4AF37)),
                                label: const Text(
                                  'Lưu ảnh QR',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _openCheckoutUrl,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('Mở PayOS', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Primary Action: Kiểm tra thanh toán
                        SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _isChecking ? null : _checkPaymentStatus,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF37),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 2,
                            ),
                            icon: _isChecking
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                : const Icon(Icons.check_circle_outline, size: 22),
                            label: const Text(
                              'Tôi đã chuyển khoản (Kiểm tra)',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Fast Demo Testing Button
                        SizedBox(
                          height: 44,
                          child: TextButton.icon(
                            onPressed: _isChecking ? null : _handleTestActivate,
                            icon: const Icon(Icons.flash_on, color: Colors.amber, size: 20),
                            label: const Text(
                              '⚡ Kích hoạt dùng thử ngay (Demo chấm bài)',
                              style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ),

                        if (isPrem) ...[
                          Center(
                            child: TextButton(
                              onPressed: _isChecking ? null : _handleTestCancel,
                              child: Text(
                                'Chuyển về gói Miễn Phí (để test luồng khóa)',
                                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildPackageHeader(ThemeData theme, AuthProvider auth, bool isPrem) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFD4AF37), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFDF00), Color(0xFFD4AF37)],
                    ),
                  ),
                  child: const Icon(Icons.workspace_premium, color: Colors.black, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VINYL PREMIUM (30 NGÀY)',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1.2,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPrem
                            ? 'Bạn đang có gói Premium (Còn ${auth.remainingPremiumDays} ngày)'
                            : 'Chỉ 19.000đ — Tận hưởng trọn vẹn âm nhạc',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isPrem ? Colors.green : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniPerk(Icons.auto_awesome, 'AI Smart Flow'),
                _buildMiniPerk(Icons.queue_music, 'Vô hạn Playlist'),
                _buildMiniPerk(Icons.military_tech, 'Huy hiệu Vàng'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPerk(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFFD4AF37)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildQrCodeCard(ThemeData theme) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Quét mã VietQR chuyển khoản (Napas247 / PayOS)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Hỗ trợ toàn bộ app ngân hàng & ví điện tử tại Việt Nam',
              style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 16),

            // Large QR Code Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  _paymentLink!.qrCode,
                  height: 240,
                  width: 240,
                  fit: BoxFit.contain,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return const SizedBox(
                      height: 240,
                      width: 240,
                      child: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    alignment: Alignment.center,
                    child: const Text('Không thể tải ảnh mã QR'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Transfer details table
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark ? const Color(0xFF1E1E26) : const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _buildTransferRow('Số tiền:', '19.000 VNĐ', isHighlight: true),
                  const Divider(height: 16),
                  _buildTransferRow(
                    'Nội dung CK:',
                    _paymentLink!.description,
                    canCopy: true,
                  ),
                  const Divider(height: 16),
                  _buildTransferRow('Mã đơn hàng:', '#${_paymentLink!.orderCode}'),
                  const Divider(height: 16),
                  _buildTransferRow('Cổng thanh toán:', 'PayOS VietQR Napas247'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferRow(String label, String value, {bool isHighlight = false, bool canCopy = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isHighlight ? const Color(0xFFD4AF37) : null,
              ),
            ),
            if (canCopy) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã sao chép "$value" vào khay nhớ tạm'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: const Icon(Icons.copy, size: 16, color: Color(0xFFD4AF37)),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
