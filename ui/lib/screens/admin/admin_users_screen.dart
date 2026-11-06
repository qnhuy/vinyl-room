import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../presenters/admin_user_presenter.dart';
import '../../services/session.dart';

/// Màn hình Quản trị Người dùng (Khóa/Mở khóa tài khoản, phân quyền Role).
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen>
    implements AdminUserView {
  late final AdminUserPresenter _presenter;
  List<User> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _presenter = AdminUserPresenter(this);
    _presenter.loadUsers();
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
  void showUsers(List<User> users) {
    if (mounted) {
      setState(() {
        _users = users;
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
  void showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _changeRoleDialog(User user) async {
    final nextRole = user.isAdmin ? 'user' : 'admin';
    final actionName = user.isAdmin ? 'hạ quyền xuống User' : 'thăng cấp lên Admin';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thay đổi vai trò người dùng'),
        content: Text(
          'Bạn có chắc chắn muốn $actionName cho tài khoản "${user.username}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (ok == true && user.userId != null) {
      await _presenter.updateRole(user.userId!, nextRole);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Người dùng'),
        actions: [
          IconButton(
            onPressed: () => _presenter.loadUsers(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _users.isEmpty
                  ? const Center(child: Text('Chưa có tài khoản nào'))
                  : RefreshIndicator(
                      onRefresh: () => _presenter.loadUsers(),
                      child: ListView.separated(
                        itemCount: _users.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final u = _users[i];
                          final isMe = u.userId == Session.userId;
                          final isLocked = u.isActive == 0;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: u.isAdmin
                                  ? const Color(0xFFE8A35A)
                                  : Colors.grey[700],
                              child: Icon(
                                u.isAdmin
                                    ? Icons.security
                                    : Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  u.username,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 8),
                                  const Chip(
                                    label: Text('Tôi',
                                        style: TextStyle(fontSize: 10)),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u.email ?? 'Chưa có email'),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isLocked
                                            ? Colors.redAccent.withValues(alpha: 0.2)
                                            : Colors.greenAccent.withValues(alpha: 0.2),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isLocked
                                            ? 'ĐÃ KHÓA'
                                            : 'HOẠT ĐỘNG',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isLocked
                                              ? Colors.redAccent
                                              : Colors.greenAccent,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent.withValues(alpha: 0.2),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        u.role.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: isMe
                                ? const Text(
                                    'Admin hiện tại',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white54),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          u.isAdmin
                                              ? Icons.arrow_downward
                                              : Icons.arrow_upward,
                                          color: Colors.amberAccent,
                                        ),
                                        tooltip: u.isAdmin
                                            ? 'Hạ quyền xuống User'
                                            : 'Thăng cấp lên Admin',
                                        onPressed: () => _changeRoleDialog(u),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          isLocked
                                              ? Icons.lock_open
                                              : Icons.lock,
                                          color: isLocked
                                              ? Colors.greenAccent
                                              : Colors.redAccent,
                                        ),
                                        tooltip: isLocked
                                            ? 'Mở khóa tài khoản'
                                            : 'Khóa tài khoản',
                                        onPressed: () =>
                                            _presenter.toggleStatus(
                                                u.userId!, !isLocked),
                                      ),
                                    ],
                                  ),
                          );
                        },
                      ),
                    ),
    );
  }
}
