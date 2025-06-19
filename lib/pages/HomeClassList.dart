import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'HomePage_Teacher.dart';
import 'package:nhom3_ungdungonthitotnghiep/constants/host.dart';
class HomeScreenClassList extends StatefulWidget {
  final String examId;
  const HomeScreenClassList({super.key, required this.examId});

  @override
  _HomeScreenClassListState createState() => _HomeScreenClassListState();
}

class _HomeScreenClassListState extends State<HomeScreenClassList> {  List<Map<String, dynamic>> results = [];
  bool isLoading = false;
  String teacherName = '';
  String errorMessage = '';
  String examTitle = ''; // Thêm biến để lưu tiêu đề đề thi

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadExamInfo(); // Load thông tin đề thi trước
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      teacherName = prefs.getString('user_name') ?? 'Giáo viên';
    });
  }

  Future<void> _loadExamInfo() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        throw Exception('Token not found');
      }

      // Fetch thông tin đề thi
      final response = await http.get(
        Uri.parse('http://${HostString.hoststring}:5001/api/teacher/exams/${widget.examId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['exam'] != null) {
          setState(() {
            examTitle = data['exam']['TieuDe'] ?? 'Không có tiêu đề';
          });
        }
      }
      
      // Sau khi lấy thông tin đề thi, fetch kết quả thi
      await fetchExamResults();
    } catch (e) {
      print('Error loading exam info: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Lỗi khi tải thông tin đề thi';
      });
    }
  }
  Future<void> fetchExamResults() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null || token.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'Token không hợp lệ';
        });
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, '/');
        });
        return;
      }

      // Lấy kết quả thi theo mã đề thi
      final response = await http.get(
        Uri.parse('http://${HostString.hoststring}:5001/api/teacher/exam-results/${widget.examId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        if (jsonResponse['results'] != null) {
          final List<dynamic> examResults = jsonResponse['results'];
          
          setState(() {
            results = examResults.map((item) {
              return {
                'Ten': item['Ten'] ?? 'Không có tên', // Tên từ bảng Users
                'Diem': item['Diem']?.toString() ?? 'Chưa có điểm',
                'MaHS': item['MaHS']?.toString() ?? '',
                'ThoiGianNop': item['ThoiGianNop'] ?? '',
              };
            }).toList();
            isLoading = false;
          });
          
          print('Đã parse được ${results.length} kết quả');
          print('Results: $results');
        } else {
          setState(() {
            results = [];
            isLoading = false;
            errorMessage = 'Không có kết quả thi';
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          isLoading = false;
          errorMessage = 'Phiên đăng nhập hết hạn';
        });
        await prefs.remove('auth_token');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        throw Exception('Lỗi server: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Lỗi kết nối: ${e.toString()}';
        results = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    // Hiển thị hộp thoại xác nhận
    bool confirmLogout = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirmLogout) {
      // Xóa token và chuyển về màn hình đăng nhập
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_name');
        if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.purple,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 35,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  teacherName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                const Text(
                  'Giáo viên',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.arrow_back, color: Colors.purple),
            title: const Text('Quay lại trang chủ'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomePage_Teacher(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.purple),
            title: const Text('Thông tin cá nhân'),
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Đăng xuất'),
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      appBar: AppBar(
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
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          const CircleAvatar(
            backgroundImage: AssetImage('assets/images/logo.jpg'),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchExamResults,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [              const Center(
                child: Text(
                  'Danh Sách Kết Quả Thi',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [                  SizedBox(
                    width: 220, // Chiều rộng cố định cho ô đề thi
                    child: Card(
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Center(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Đề thi: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                    color: Colors.purple[700],
                                  ),
                                ),
                                TextSpan(
                                  text: examTitle,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),                  SizedBox(
                    height: 50, // Đồng bộ chiều cao với ô đề thi
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Container(
                        width: 80, // Rộng vừa phải để không lấn sang ô đề thi
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.group, size: 22, color: Colors.purple),
                            const SizedBox(width: 6),
                            Text(
                              '${results.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : results.isEmpty
                        ? const Center(
                            child: Text(
                              'Không có kết quả thi',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            itemCount: results.length,
                            itemBuilder: (context, index) {
                              final result = results[index];
                              return buildResultItem(
                                context,
                                result['Ten'],
                                result['Diem'],
                              );
                            },
                          ),
              ),
            ],
          ),        ),
      ),
      
    );
  }

  Widget buildResultItem(BuildContext context, String name, String score) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundImage: AssetImage('assets/images/avatar.jpg'),
        ),
        title: Text(name),
        subtitle: Text('Điểm: $score'),        // Không cần trailing vì đã xóa nút xóa
      ),
    );
  }
}
