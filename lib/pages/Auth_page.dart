import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nhom3_ungdungonthitotnghiep/pages/HomePage_Student.dart';
import 'dart:convert';
import 'HomePage_Teacher.dart'; // Teacher
import 'package:nhom3_ungdungonthitotnghiep/constants/host.dart';
class UserSelectionScreen extends StatefulWidget {
  final String token; // Token hiện tại từ lần đăng nhập
  final String? currentRole; // Role hiện tại (có thể null)
  final int? studentId; // ID của học sinh (có thể null)

  const UserSelectionScreen({super.key, required this.token, this.currentRole,this.studentId});

  @override
  State<UserSelectionScreen> createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  bool _loading = false;

  Future<void> _changeRoleAndNavigate(String selectedRole) async {
    setState(() {
      _loading = true;
    });

    final url = Uri.parse('http://${HostString.hoststring}:5001/api/auth/change-role');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({'newRole': selectedRole}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newRole = data['role'];
        final newToken = data['token'];

        // TODO: Lưu token mới và role mới vào storage hoặc state management
        // Ví dụ:
        // await saveToken(newToken);
        // await saveRole(newRole);

        // Điều hướng theo role
        if (newRole == 'Student') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) =>  HomePage_Student()),
          );
        } else if (newRole == 'Teacher') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) =>  HomePage_Teacher()),
          );
        } else {
          // Nếu có role khác thì xử lý tùy ý
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Vai trò không hợp lệ')),
          );
        }
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Lỗi server';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi mạng hoặc không kết nối được')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Widget _buildRoleCard({
    required String title,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _loading ? null : onTap,
      child: Container(
        width: 140,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
          border: Border.all(color: Colors.deepPurple, width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipOval(
              child: Image.asset(
                imagePath,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 30),
              const Text(
                'Bạn là ai?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Vui lòng chọn vai trò của bạn để tiếp tục',
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              if (_loading)
                const CircularProgressIndicator()
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildRoleCard(
                      title: 'Student',
                      imagePath: 'assets/images/teacher.png',
                      onTap: () => _changeRoleAndNavigate('Student'),
                    ),
                    const SizedBox(width: 20),
                    _buildRoleCard(
                      title: 'Teacher',
                      imagePath: 'assets/images/teacher.png',
                      onTap: () => _changeRoleAndNavigate('Teacher'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}