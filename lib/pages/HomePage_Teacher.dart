import 'package:flutter/material.dart';
import 'package:nhom3_ungdungonthitotnghiep/pages/HomeClassList.dart';
import 'package:nhom3_ungdungonthitotnghiep/pages/HomeTeacherAddQuiz.dart';
import 'package:nhom3_ungdungonthitotnghiep/pages/CreatExams.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'Login_Page.dart'; // Thêm import trang đăng nhập
import 'package:nhom3_ungdungonthitotnghiep/constants/host.dart';
class HomePage_Teacher extends StatefulWidget {
  const HomePage_Teacher({super.key});

  @override
  _HomePageTeacherState createState() => _HomePageTeacherState();
}

class _HomePageTeacherState extends State<HomePage_Teacher> {
  List<Map<String, dynamic>> exams = [];
  List<Map<String, dynamic>> filteredExams = [];
  bool isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String teacherName = '';
  String teacherEmail = ''; // Add email field

  @override
  void initState() {
    super.initState();
    fetchExams();
    _loadUserData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      teacherName = prefs.getString('user_name') ?? 'Giáo viên';
      teacherEmail = prefs.getString('user_email') ?? ''; // Load email
    });
  }

  Future<void> fetchExams() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final teacherId = prefs.getInt('student_id');

      if (token == null || teacherId == null) {
        throw Exception('Không tìm thấy thông tin đăng nhập');
      }

      final response = await http.get(
        Uri.parse('http://${HostString.hoststring}:5001/api/teacher/teacher-exams'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          exams = List<Map<String, dynamic>>.from(data['exams']);
          filteredExams = exams;
          isLoading = false;
        });
      } else {
        throw Exception('Lỗi khi tải danh sách đề thi');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> searchExams(String query) async {
    setState(() {
      isLoading = true;
    });

    try {
      if (query.isEmpty) {
        setState(() {
          filteredExams = exams;
          isLoading = false;
        });
        return;
      }

      // Xử lý query
      final searchTerm = query.trim().toLowerCase();      setState(() {
        filteredExams = exams.where((exam) {
          // Chuyển đổi mã đề thi thành string để so sánh và đảm bảo so sánh chính xác
          final examId = exam['MaDT']?.toString() ?? '';
          // Chuyển tiêu đề về chữ thường để so sánh
          final title = (exam['TieuDe'] ?? exam['TenDT'])?.toString().toLowerCase() ?? '';
          
          // So sánh mã đề thi chính xác (không phân biệt chữ hoa/thường)
          if (examId.toLowerCase() == searchTerm) {
            return true;
          }
          
          // Nếu searchTerm là số, thì chỉ tìm theo mã đề
          if (int.tryParse(searchTerm) != null) {
            return examId == searchTerm;
          }
          
          // Nếu không phải là số, tìm theo tiêu đề
          return title.contains(searchTerm);
        }).toList();
        isLoading = false;
      });

      // Xử lý IME
      if (mounted) {
        FocusScope.of(context).unfocus();
      }

      // Hiển thị thông báo nếu không tìm thấy kết quả
      if (filteredExams.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tìm thấy đề thi phù hợp'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tìm kiếm: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _unfocus() {
    _searchFocus.unfocus();
  }

  void _showPasswordPopup(Map<String, dynamic> exam) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 40, color: Colors.purple),
                const SizedBox(height: 10),
                const Text(
                  'Mật khẩu đề thi',
                  style: TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  exam['TenDT'] ?? 'Không có tiêu đề',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
            content: Text(
              'Mật khẩu: ${exam['MatKhau'] ?? 'Chưa có mật khẩu'}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Đóng',
                  style: TextStyle(color: Colors.purple),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  Widget _buildExamCard(Map<String, dynamic> exam) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.assignment, color: Colors.purple),
        ),        title: Text(
          exam['TieuDe'] ?? exam['TenDT'] ?? 'Chưa có tiêu đề',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mã đề thi: ${exam['MaDT'] ?? 'N/A'}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Giáo viên: $teacherName',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.lock_outline, color: Colors.purple),
              onPressed: () => _showPasswordPopup(exam),
            ),
            IconButton(
              icon: const Icon(Icons.edit_note, color: Colors.purple),
              onPressed: () {
                final examId = exam['MaDT']?.toString() ?? '0';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeacherQuizScreen(examId: examId),
                  ),
                );
              },
            ),
          ],
        ),
        onTap: () {
          final examId = exam['MaDT']?.toString() ?? '0';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreenClassList(examId: examId),
            ),
          );
        },
      ),
    );
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Xóa tất cả dữ liệu đã lưu

      if (mounted) {
        // Chuyển về trang đăng nhập và xóa tất cả các trang trong stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false, // Xóa tất cả các trang khỏi stack
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Có lỗi xảy ra khi đăng xuất'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _logout();
              },
              child: const Text(
                'Đăng xuất',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Colors.purple[400],
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundImage: AssetImage('assets/images/avatar.jpg'),
            ),
            accountName: Text(
              teacherName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              teacherEmail,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Đăng xuất',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Đóng drawer
                    _showLogoutDialog(); // Hiển thị dialog xác nhận
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Phiên bản 1.0.0',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _unfocus,
      child: Scaffold(
        drawer: _buildDrawer(),
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.purple),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 10),
              Text(
                'Xin chào GV. $teacherName',
                style: const TextStyle(color: Colors.black),
              ),
            ],
          ),
          actions: [
            GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: const Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: CircleAvatar(
                  backgroundImage: AssetImage('assets/images/logo.jpg'),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: 'Tìm theo mã đề hoặc tiêu đề...',
                  prefixIcon: const Icon(Icons.search, color: Colors.purple),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.purple),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.purple, width: 2),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            searchExams('');
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  searchExams(value);
                  // Giữ focus khi đang nhập
                  _searchFocus.requestFocus();
                },
                textInputAction: TextInputAction.search,
              ),
            ),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredExams.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Không tìm thấy đề thi',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      )
                    : Expanded(
                        child: ListView.builder(
                          itemCount: filteredExams.length,
                          itemBuilder: (context, index) {
                            return _buildExamCard(filteredExams[index]);
                          },
                        ),
                      ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreatExams(),
              ),
            ).then((_) => fetchExams()); // Refresh sau khi quay lại
          },
          backgroundColor: Colors.purple,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}