import 'package:flutter/material.dart';
import '../models/user.dart';
import '../config/mongodb_connection.dart';
import 'add_user_screen.dart';
import 'edit_user_screen.dart';
import 'dart:convert';
import 'dart:typed_data';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<AppUser> _users = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async{
    setState(() {
      _loading = true;
      _error = null;
    });
    try{
      final users = await MongoService.fetchUsers();
      setState(() {
        _users = users;
        _loading = false;
      });
    }catch(e){
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _deleteUser(AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa người dùng "${user.username}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if(confirmed != true) return;

    try{
      await MongoService.deleteUser(user.username);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa người dùng')),
      );
      _loadUsers();
    }catch(e){
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xóa: $e')),
      );
    }
  }

  Uint8List? _decodeImage(String imageData) {
    try {
      if (imageData.startsWith('data:image')) {
        final base64Str = imageData.split(',')[1];
        return base64Decode(base64Str);
      } else if (!imageData.startsWith('http')) {
        return base64Decode(imageData);
      }
    } catch (e) {
      setState(() {
        e.toString();
      });
    }
    return null;
  }
  Widget _buildUserImage(String imageData) {
    final imageBytes = _decodeImage(imageData);
    if (imageBytes != null) {
      return Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.person, size: 40, color: Colors.grey);
        },
      );
    } else if (imageData.startsWith('http')) {
      return Image.network(
        imageData,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.person, size: 40, color: Colors.grey);
        },
      );
    } else {
      return const Icon(Icons.person, size: 40, color: Colors.grey);
    }
  }
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách nguòiư dùng'),
        backgroundColor: Colors.lightBlue,
        actions: [
          IconButton(onPressed: _loadUsers, icon: const Icon(Icons.refresh), tooltip: 'Làm mới',),
        ],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _error != null
        ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Lỗi: $_error'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ): _users.isEmpty ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.lightBlueAccent,),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                // Chuyển sang màn hình thêm người dùng mới
                final added = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddUserScreen(),
                  ),
                );
                if (added == true) {
                  _loadUsers(); // Nếu thêm thành công → tải lại
                }
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Thêm người dùng đầu tiên'),
            ),
          ],
        ),
      )
      // Nếu có danh sách người dùng → hiển thị danh sách
      :RefreshIndicator(
        onRefresh: _loadUsers,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _users.length,
          itemBuilder: (context, index){
            final user = _users[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              child: InkWell(
                onTap: () async {
                  // Nhấn vào card để chỉnh sửa người dùng
                  final updated =
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          EditUserScreen(user: user),
                    ),
                  );
                  if (updated == true) {
                    _loadUsers(); // Sau khi sửa → reload lại
                  }
                },
                child: Padding(padding: const  EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: _buildUserImage(user.image),
                    ),
                    const SizedBox(width: 16),
                    // Thông tin người dùng
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.username,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.email,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  user.email,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14
                                  ),
                                  overflow:
                                  TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.lock,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                '•' * user.password.length,
                                style: const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit,
                              color: Colors.blue),
                          tooltip: 'Chỉnh sửa',
                          onPressed: () async {
                            final updated =
                            await Navigator.of(context)
                                .push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    EditUserScreen(user: user),
                              ),
                            );
                            if (updated == true) {
                              _loadUsers();
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          tooltip: 'Xóa',
                          onPressed: () => _deleteUser(user),
                        ),
                      ],
                    )
                  ],
                ),
                ),
              ),
            );
          },
        ) ,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AddUserScreen(),
            ),
          );
          if (added == true) {
            _loadUsers(); // Tải lại nếu có thêm mới
          }
        },
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.person_add),
        label: const Text('Thêm người dùng'),
      ),
    );
  }
}