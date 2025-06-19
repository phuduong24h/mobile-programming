import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:nhom3_ungdungonthitotnghiep/constants/host.dart';
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _tenController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _tenFocus = FocusNode();

  String? _emailError;
  String? _passwordError;
  String? _tenError;

  @override
  void initState() {
    super.initState();

    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus) {
        _validateEmail();
      }
    });

    _passwordFocus.addListener(() {
      if (!_passwordFocus.hasFocus) {
        _validatePassword();
      }
    });

    _tenFocus.addListener(() {
      if (!_tenFocus.hasFocus) {
        _validateTen();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _tenController.dispose();

    _emailFocus.dispose();
    _passwordFocus.dispose();
    _tenFocus.dispose();

    super.dispose();
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    return emailRegex.hasMatch(email);
  }

  bool isValidPassword(String password) {
    final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z]).{6,}$');
    return passwordRegex.hasMatch(password);
  }

  bool isValidUsername(String ten) {
    // Chỉ kiểm tra không được để trống, cho phép tiếng Việt có dấu
    return ten.trim().isNotEmpty;
  }

  void _validateEmail() {
    final email = _emailController.text.trim();
    setState(() {
      if (email.isEmpty) {
        _emailError = 'Email không được để trống';
      } else if (!isValidEmail(email)) {
        _emailError = 'Email không hợp lệ';
      } else {
        _emailError = null;
      }
    });
  }

  void _validatePassword() {
    final password = _passwordController.text;
    setState(() {
      if (password.isEmpty) {
        _passwordError = 'Mật khẩu không được để trống';
      } else if (!isValidPassword(password)) {
        _passwordError = 'Phải có ít nhất 6 ký tự, gồm chữ hoa và chữ thường';
      } else {
        _passwordError = null;
      }
    });
  }

  void _validateTen() {
    final ten = _tenController.text.trim();
    setState(() {
      if (!isValidUsername(ten)) {
        _tenError = 'Tên tài khoản không được để trống';
      } else {
        _tenError = null;
      }
    });
  }

  Future<Map<String, dynamic>> registerUser(
      String email, String password, String ten, String vaiTro) async {
    final url = Uri.parse('http://${HostString.hoststring}:5001/api/auth/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'ten': ten,
          'vaiTro': vaiTro,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        return {'success': true, 'message': null};
      } else {
        try {
          final data = jsonDecode(response.body);
          final msg = data['message'] ??
              data['error'] ??
              data['errors']?.toString() ??
              'Đăng ký thất bại';
          return {'success': false, 'message': msg};
        } catch (e) {
          print('Lỗi parse JSON: $e');
          return {
            'success': false,
            'message': 'Đăng ký thất bại: Không đọc được lỗi từ server',
          };
        }
      }
    } catch (e) {
      print('Lỗi mạng hoặc server: $e');
      return {'success': false, 'message': 'Lỗi mạng hoặc server: $e'};
    }
  }

  void _onRegisterPressed() async {
    _validateEmail();
    _validatePassword();
    _validateTen();

    if (_emailError != null || _passwordError != null || _tenError != null) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final ten = _tenController.text.trim();

    // Vai trò mặc định gửi 'null' (chuỗi) lên backend
    const vaiTro = 'Student';

    final result = await registerUser(email, password, ten, vaiTro);

    if (result['success']) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Thông báo'),
          content: const Text('Đăng ký thành công!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/');
              },
              child: const Text('OK'),
            )
          ],
        ),
      );
    } else {
      final errorMsg = result['message'] ?? 'Đăng ký thất bại, vui lòng thử lại';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 5,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 32.0),
              Text(
                'Đăng ký tài khoản',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8.0),
              Text(
                'Vui lòng điền các thông tin bên dưới',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32.0),
              // Tên tài khoản
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _tenController,
                  focusNode: _tenFocus,
                  decoration: InputDecoration(
                    hintText: 'Tên tài khoản',
                    errorText: _tenError,
                    prefixIcon: Icon(Icons.person, color: Colors.purple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              // Email
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    errorText: _emailError,
                    prefixIcon: Icon(Icons.email, color: Colors.purple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              // Mật khẩu
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Mật khẩu',
                    errorText: _passwordError,
                    prefixIcon: Icon(Icons.lock, color: Colors.purple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 32.0),
              // Nút đăng ký
              ElevatedButton(
                onPressed: _onRegisterPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 1,
                ),
                child: const Text(
                  'Đăng ký',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              // Nút quay lại đăng nhập
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Đã có tài khoản?"),
                  TextButton(
                  onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/');
                  },
                  child: Text(
                      'Đăng nhập ngay',
                      style: TextStyle(
                       color: Colors.deepPurple,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                  ),
                ),
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
