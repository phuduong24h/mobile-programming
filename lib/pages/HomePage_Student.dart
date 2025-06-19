import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nhom3_ungdungonthitotnghiep/constants/host.dart';
import 'package:nhom3_ungdungonthitotnghiep/pages/ExamHistory.dart';
import 'package:nhom3_ungdungonthitotnghiep/widgets/StudentAppBar.dart';
import 'package:shared_preferences/shared_preferences.dart'; // thêm import này
import 'package:nhom3_ungdungonthitotnghiep/pages/HomeClassList.dart';
import 'package:nhom3_ungdungonthitotnghiep/pages/HomeQuizPage.dart';
import 'package:nhom3_ungdungonthitotnghiep/constants/host.dart';

class HomePage_Student extends StatefulWidget {
  const HomePage_Student({super.key});

  @override
  _HomePage_StudentState createState() => _HomePage_StudentState();
}

class _HomePage_StudentState extends State<HomePage_Student> {
  String? token;
  int? studentId;
  String? userEmail;
  String? userName;

  final TextEditingController _examCodeController = TextEditingController();
  List<Map<String, String>> fetchedClasses = []; // Danh sách lớp lấy về
  bool isLoading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('user_name');
    final savedEmail = prefs.getString('user_email');
    print('SharedPreferences - userName: $savedName'); // Log saved name
    print('SharedPreferences - userEmail: $savedEmail'); // Log saved email

    setState(() {
      token = prefs.getString('auth_token');
      studentId = prefs.getInt('student_id');
      userEmail = savedEmail ?? '';
      userName = savedName ?? 'Học sinh';
    });
  }

  Future<void> fetchClasses(String examId) async {
    setState(() {
      isLoading = true;
      error = null;
      fetchedClasses = [];
    });

    try {
      final response = await http.get(
        Uri.parse(
          'http://${HostString.hoststring}:5001/api/student/exams/$examId',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List exams;
        if (data['exams'] != null) {
          exams = data['exams'];
        } else if (data['exam'] != null) {
          exams = [data['exam']];
        } else {
          exams = [];
        }

        List<Map<String, String>> classes =
            exams.map<Map<String, String>>((exam) {
              return {
                'className': exam['TenDT'] ?? 'Chưa có tên lớp',
                'teacherName': exam['TenGV'] ?? 'Giáo viên chưa có API',
                'password': exam['MatKhau'] ?? '',
                'examId': exam['MaDT'].toString(),
              };
            }).toList();

        setState(() {
          fetchedClasses = classes;
          isLoading = false;
        });
      } else {
        setState(() {
          error = "Không tìm thấy đề thi với mã này.";
          fetchedClasses = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Lỗi khi kết nối đến server.";
        fetchedClasses = [];
        isLoading = false;
      });
    }
  }

  void _showNotificationDialog(
    BuildContext context,
    String className,
    String teacherName,
    String password,
    String examId,
  ) {
    final TextEditingController passwordController = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Thông Báo"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Đây là lớp $className của $teacherName."),
                  SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Nhập mật khẩu đề thi",
                      errorText: error,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Hủy"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (passwordController.text == password) {
                      Navigator.of(context).pop(); // Đóng dialog

                      int examIdInt = int.parse(examId);
                      int studentIdInt =
                          studentId ?? 0; // hoặc xử lý null phù hợp

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => QuizScreen(
                                examId: examIdInt,
                                studentId: studentIdInt,
                                token: token!,
                              ),
                        ),
                      );
                    } else {
                      setState(() {
                        error = "Mật khẩu không đúng!";
                      });
                    }
                  },
                  child: Text("Vào thi"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _classItem(String className, String teacherName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.class_, color: Colors.blue[700]),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  className,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Giáo viên: $teacherName",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.blue[700], size: 16),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _examCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StudentAppBar(),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.purple),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage('assets/images/avatar.jpg'),
                          fit: BoxFit.cover,
                        ),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Text(
                          'Tên: ',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        Expanded(
                          child: Text(
                            userName ?? 'Học sinh',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              // fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Email: ',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        Expanded(
                          child: Text(
                            userEmail ?? '',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              // fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('Lịch sử thi'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                final studentId = prefs.getInt('student_id') ?? 0;
                final token = prefs.getString('auth_token') ?? '';

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            ExamHistory(studentId: studentId, token: token),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Đăng xuất'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.of(context).pushReplacementNamed('/');
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Container(
            height:
                MediaQuery.of(context).size.height -
                AppBar().preferredSize.height -
                MediaQuery.of(context).padding.top,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue[50]!, Colors.white],
              ),
            ),
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _examCodeController,
                          decoration: InputDecoration(
                            hintText: "Nhập mã đề thi",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          onSubmitted: (_) {
                            if (_examCodeController.text.isNotEmpty) {
                              fetchClasses(_examCodeController.text.trim());
                            }
                          },
                        ),
                      ),
                      Material(
                        color: Colors.purple,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(15),
                          bottomRight: Radius.circular(15),
                        ),
                        child: InkWell(
                          onTap: () {
                            if (_examCodeController.text.isNotEmpty) {
                              fetchClasses(_examCodeController.text.trim());
                            }
                          },
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(15),
                            bottomRight: Radius.circular(15),
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                            child: Icon(
                              Icons.search,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                    ),
                  ),
                if (error != null)
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            error!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    child:
                        fetchedClasses.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 80,
                                    color: Colors.grey[300],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    "Không có lớp nào.\nVui lòng nhập mã đề để tìm.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              padding: EdgeInsets.only(top: 10, bottom: 20),
                              itemCount: fetchedClasses.length,
                              itemBuilder: (context, index) {
                                final classItem = fetchedClasses[index];
                                return GestureDetector(
                                  onTap: () {
                                    _showNotificationDialog(
                                      context,
                                      classItem['className']!,
                                      classItem['teacherName']!,
                                      classItem['password']!,
                                      classItem['examId']!,
                                    );
                                  },
                                  child: _classItem(
                                    classItem['className']!,
                                    classItem['teacherName']!,
                                  ),
                                );
                              },
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
