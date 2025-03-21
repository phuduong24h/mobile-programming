import 'package:flutter/material.dart';

class TeacherQuizScreen extends StatefulWidget {
  const TeacherQuizScreen({super.key});

  @override
  _TeacherQuizScreenState createState() => _TeacherQuizScreenState();
}

class _TeacherQuizScreenState extends State<TeacherQuizScreen> {
  int currentPage = 1;
  final int totalPages = 50;
  final List<Map<String, dynamic>> pagesData = List.generate(
    50,
    (_) => {
      'question': TextEditingController(),
      'answers': List.generate(4, (_) => TextEditingController()),
    },
  );

  void nextPage() {
    setState(() {
      if (currentPage < totalPages) currentPage++;
    });
  }

  void prevPage() {
    setState(() {
      if (currentPage > 1) currentPage--;
    });
  }

  @override
  void dispose() {
    for (var pageData in pagesData) {
      pageData['question'].dispose();
      for (var controller in pageData['answers']) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPageData = pagesData[currentPage - 1];
    final questionController = currentPageData['question'] as TextEditingController;
    final answerControllers = currentPageData['answers'] as List<TextEditingController>;

    return Scaffold(
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildPaginationBar(),
            const SizedBox(height: 16),
            _buildQuestionField(questionController),
            const SizedBox(height: 16),
            ...List.generate(
              4,
              (index) => _buildAnswerField(
                String.fromCharCode(65 + index),
                answerControllers[index],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () {
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 40,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  "Hoàn Thành",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
    AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        "Xin chào giáo viên",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      backgroundColor: const Color(0xFFF8E8F8),
      toolbarHeight: 60,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ClipOval(
            child: Image.asset(
              "assets/images/avatar.jpg",
              width: 36,
              height: 36,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ClipOval(
          child: Image.asset(
            "assets/images/logo.jpg",
            width: 36,
            height: 36,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.error,
                color: Colors.red,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationBar() {
    List<Widget> pageButtons = [];

    if (currentPage > 3) {
      pageButtons.add(_buildPageButton(1));
      pageButtons.add(const Text("..."));
    }

    for (int i = currentPage - 1; i <= currentPage + 1; i++) {
      if (i > 0 && i <= totalPages) {
        pageButtons.add(_buildPageButton(i));
      }
    }

    if (currentPage < totalPages - 2) {
      pageButtons.add(const Text("..."));
      pageButtons.add(_buildPageButton(totalPages));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: currentPage > 1 ? prevPage : null,
        ),
        ...pageButtons,
        IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: currentPage < totalPages ? nextPage : null,
        ),
      ],
    );
  }

  Widget _buildPageButton(int pageNumber) {
    bool isSelected = pageNumber == currentPage;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () {
          setState(() {
            currentPage = pageNumber;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "$pageNumber",
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildQuestionField(TextEditingController controller) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF0E8F8),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Câu hỏi $currentPage:", 
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Hãy nhập câu hỏi ở đây",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    ),
  );
}


  Widget _buildAnswerField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.red.shade900,
            radius: 14,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: "Đáp án $label",
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
