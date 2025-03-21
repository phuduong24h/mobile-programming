import 'package:flutter/material.dart';
import 'package:nhom3_ungdungonthitotnghiep/pages/HomePage.dart';
import 'package:nhom3_ungdungonthitotnghiep/pages/login_DoAn.dart';
import 'package:nhom3_ungdungonthitotnghiep/pages/HomePage_Teacher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: {
        '/': (context) => HomePage_Teacher(),
      },
    );
  }
}
