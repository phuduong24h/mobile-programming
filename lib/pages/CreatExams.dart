import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nhom3_ungdungonthitotnghiep/constants/host.dart';

class CreatExams extends StatefulWidget {
  @override
  _CreatExamsState createState() => _CreatExamsState();
}

class _CreatExamsState extends State<CreatExams> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _passwordController = TextEditingController();
  final _examIdController = TextEditingController();
  bool _isLoading = false;
  String? teacherName;
  int? teacherId;

  @override
  void initState() {
    super.initState();
    _loadTeacherInfo();
  }

  Future<void> _loadTeacherInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      teacherName = prefs.getString('user_name');
      teacherId = prefs.getInt('student_id');
    });
    
    if (teacherId == null || teacherName == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng đăng nhập lại để tạo đề thi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _passwordController.dispose();
    _examIdController.dispose();
    super.dispose();
  }

  Future<void> _createExam() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (teacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy thông tin giáo viên, vui lòng đăng nhập lại'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phiên đăng nhập hết hạn, vui lòng đăng nhập lại'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Tạo đề thi mới
      final response = await http.post(
        Uri.parse('http://${HostString.hoststring}:5001/api/teacher/create-exam'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'MaDT': int.parse(_examIdController.text),
          'title': _titleController.text,
          'password': _passwordController.text,
        }),
      );      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tạo đề thi thành công'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Trả về true để refresh danh sách
        }
      } else if (response.statusCode == 400) {
        // Xử lý khi mã đề thi đã tồn tại
        final error = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error['message'] ?? 'Mã đề thi đã tồn tại'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        final error = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error['message'] ?? 'Lỗi khi tạo đề thi'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi kết nối tới server'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tạo đề thi mới',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.purple),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (teacherName != null) 
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Giáo viên: $teacherName',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ),
              TextFormField(
                controller: _examIdController,
                decoration: InputDecoration(
                  labelText: 'Mã đề thi',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.numbers, color: Color.fromARGB(255, 230, 195, 236)),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mã đề thi';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Mã đề thi phải là số';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Tiêu đề đề thi',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.title, color: Color.fromARGB(255, 230, 195, 236)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tiêu đề đề thi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu đề thi',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.purple),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu đề thi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _createExam,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 39, 10, 119),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Tạo đề thi',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}