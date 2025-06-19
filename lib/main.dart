import 'package:flutter/material.dart';

import 'package:nhom3_ungdungonthitotnghiep/pages/HomePage_Student.dart';
import 'package:nhom3_ungdungonthitotnghiep/pages/Login_Page.dart';
import 'package:nhom3_ungdungonthitotnghiep/pages/Register_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/', // mặc định vào LoginPage
      routes: {
        '/': (context) => LoginPage(),
        '/home': (context) => HomePage_Student(),
        '/register':
            (context) => RegisterPage(), // thêm route cho trang đăng ký
      },
    );
  }
}
