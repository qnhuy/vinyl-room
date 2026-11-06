import 'package:flutter/material.dart';
import '../../presenters/admin_dashboard_presenter.dart';
import '../app_routes.dart';

/// Màn hình Bảng điều khiển Quản trị viên (Admin Dashboard).
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    implements AdminDashboardView {
  late final AdminDashboardPresenter _presenter;
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _presenter = AdminDashboardPresenter(this);
    _presenter.loadDashboard();
  }

  @override
  void showLoading() {
    if (mounted) setState(() => _loading = true);
  }

  @override
  void hideLoading() {
    if (mounted) setState(() => _loading = false);
  }

  @override
  void showStats(Map<String, dynamic> stats) {
    if (mounted) {
      setState(() {
        _stats = stats;
        _error = null;
      });
    }
  }

  @override
  void showError(String message) {
    if (mounted) {
      setState(() => _error = message);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final counts = (_stats?['counts'] as Map<String, dynamic>?) ?? {};
    final topSongs = (_stats?['topSongs'] as List<dynamic>?) ?? [];
    final topSearches = (_stats?['topSearches'] as List<dynamic>?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trung tâm Quản trị Admin'),
        actions: [
          IconButton(
            onPressed: () => _presenter.loadDashboard(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới thống kê',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: () => _presenter.loadDashboard(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // 1. Lưới thẻ KPI Tổng quan
                      Row(
                        children: [
                          Expanded(
                            child: _buildKpiCard(
                              title: 'Bài hát',
                              value: '${counts['total_songs'] ?? 0}',
                              icon: Icons.music_note,
                              color: Colors.blueAccent,
                              onTap: () => Navigator.pushNamed(
                                  context, AppRoutes.adminSongs),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildKpiCard(
                              title: 'Người dùng',
                              value: '${counts['total_users'] ?? 0}',
                              icon: Icons.people,
                              color: Colors.greenAccent,
                              onTap: () => Navigator.pushNamed(
                                  context, AppRoutes.adminUsers),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildKpiCard(
                              title: 'Nghệ sĩ',
                              value: '${counts['total_artists'] ?? 0}',
                              icon: Icons.person_pin,
                              color: Colors.purpleAccent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildKpiCard(
                              title: 'Tổng lượt nghe',
                              value: '${counts['total_plays'] ?? 0}',
                              icon: Icons.headphones,
                              color: const Color(0xFFE8A35A),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 2. Lối tắt quản trị nhanh
                      const Text(
                        'Quản lý danh mục',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.blueAccent,
                                child: Icon(Icons.library_music,
                                    color: Colors.white),
                              ),
                              title: const Text('Quản lý Kho Bài hát'),
                              subtitle: const Text(
                                  'Thêm mới, sửa metadata, xóa bài hát khỏi hệ thống'),
                              trailing:
                                  const Icon(Icons.chevron_right),
                              onTap: () => Navigator.pushNamed(
                                  context, AppRoutes.adminSongs),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.greenAccent,
                                child: Icon(Icons.manage_accounts,
                                    color: Colors.black),
                              ),
                              title: const Text('Quản lý Người dùng'),
                              subtitle: const Text(
                                  'Khóa/Mở khóa tài khoản, phân quyền quản trị viên'),
                              trailing:
                                  const Icon(Icons.chevron_right),
                              onTap: () => Navigator.pushNamed(
                                  context, AppRoutes.adminUsers),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 3. Top bài hát được nghe nhiều nhất
                      const Text(
                        'Top 5 bài hát hot nhất',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (topSongs.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Chưa có dữ liệu bài hát'),
                          ),
                        )
                      else
                        Card(
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: topSongs.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final item = topSongs[i] as Map<String, dynamic>;
                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text('${i + 1}'),
                                ),
                                title: Text(
                                  '${item['music_name'] ?? ''}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                    'Nghệ sĩ: ${item['artist_name'] ?? 'Chưa rõ'}'),
                                trailing: Text(
                                  '${item['listen_count'] ?? 0} lượt nghe',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 24),

                      // 4. Top từ khóa tìm kiếm
                      if (topSearches.isNotEmpty) ...[
                        const Text(
                          'Từ khóa tìm kiếm phổ biến',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: topSearches.map((s) {
                            final map = s as Map<String, dynamic>;
                            return Chip(
                              avatar: const Icon(Icons.search, size: 16),
                              label: Text(
                                  '${map['search_query']} (${map['count']})'),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Icon(icon, color: color, size: 24),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
