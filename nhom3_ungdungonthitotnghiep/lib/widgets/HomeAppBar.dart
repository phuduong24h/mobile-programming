import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      // padding: EdgeInsets.all(25),
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo.jpg',
            width: 50,
            height: 50,
          ),
          SizedBox(width: 15),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Nhập lớp",
                  hintStyle: TextStyle(color: Colors.grey),
                  suffixIcon: GestureDetector(
                    onTap: () {
                    },
                    child: Icon(Icons.search, color: Colors.grey),
                  ),
                  border: InputBorder.none,
                ),
              ),
            )
          ),
          SizedBox(width: 15),
          IconButton(
            icon: Icon(Icons.menu, color: Colors.black),
            onPressed: () {},
          ),
          SizedBox(width: 10),
          CircleAvatar(
            radius: 15,
            backgroundColor: Colors.grey[200],
            child: Image.asset(
              'assets/images/avatar.jpg',
              width: 30,
              height: 30,
            ),
          ),
        ],
      )
    );
  }
}