import 'package:flutter/material.dart';
import 'package:nhom3_ungdungonthitotnghiep/widgets/HomeAppBar.dart';
import 'package:nhom3_ungdungonthitotnghiep/widgets/HomePassWordScreen.dart';

class HomePage extends StatelessWidget {
  void _showNotificationDialog(BuildContext context, String className, String teacherName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Thông Báo"),
          content: Text("Đây là lớp $className của  $teacherName."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); 
                _navigateToClassDetail(context, className, teacherName); 
              },
              child: const Text("Ok"),
            ),
          ],
        );
      },
    );
  }
  void _navigateToClassDetail(BuildContext context, String className, String teacherName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomePassWordScreen(
          className: className,
          teacherName: teacherName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          HomeAppBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(15),
              children: [
                GestureDetector(
                  onTap: () {
                    _showNotificationDialog(context, "Lớp Ôn Hóa", "Cô Nguyễn Thị Hoa");
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.pink[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Lớp Ôn Hóa",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "Giáo viên: Cô Nguyễn Thị Hoa",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward, color: Colors.blue, size: 20),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _showNotificationDialog(context, "Lớp Ôn Văn", "Cô Nguyễn Thị Hồng");
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.pink[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Lớp Ôn Văn",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "Giáo viên: Cô Nguyễn Thị Hồng",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward, color: Colors.blue, size: 20),
                      ],
                    ),
                  ),
                ),
                                GestureDetector(
                  onTap: () {
                    _showNotificationDialog(context, "Lớp Ôn Tiếng Anh", "Thầy Nguyên Văn Hùng");
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.pink[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Lớp Ôn Tiếng Anh",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "Giáo viên: Thầy Nguyên Văn Hùng",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward, color: Colors.blue, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
