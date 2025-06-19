import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class QuizScreen extends StatefulWidget {
  final int examId;
  final int studentId;
  final String token;

  const QuizScreen({
    super.key,
    required this.examId,
    required this.studentId,
    required this.token,
  });

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Map<String, dynamic>> questions = [];
  Map<int, int> selectedAnswers = {};
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    // fetchExam();
    fetchExamWithTimeout();
  }
  Future<void> fetchExamWithTimeout() async {
  // Bắt đầu tải đề thi
  fetchExam();

  // Sau 60s, nếu vẫn đang loading thì thông báo lỗi
  Future.delayed(const Duration(seconds: 60), () {
    if (mounted && isLoading) {
      setState(() {
        isLoading = false;
        error = "Tải đề thi mất quá nhiều thời gian. Vui lòng thử lại sau.";
      });
    }
  });
}

  Future<void> fetchExam() async {
    setState(() {
      isLoading = true;
      error = null;
      questions = [];
    });

    final url = Uri.parse("http://192.168.1.6:5001/api/student/exams/${widget.examId}");

    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer ${widget.token}',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['questions'] != null) {
          List questionList = data['questions'];

          // Kiểm tra dữ liệu câu hỏi có đúng format
          List<Map<String, dynamic>> loadedQuestions = questionList.map<Map<String, dynamic>>((item) {
            // item thường có cấu trúc: { question: {...}, choices: [...] }
            return {
              'question': item['question'],
              'choices': item['choices'],
            };
          }).toList();

          setState(() {
            questions = loadedQuestions;
            isLoading = false;
          });
        } else {
          setState(() {
            error = "Không có câu hỏi cho đề thi này.";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          error = "Lỗi tải đề thi (code ${response.statusCode}).";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Lỗi kết nối: $e";
        isLoading = false;
      });
    }
  }

  Future<void> submitExam() async {
    final url = Uri.parse("http://192.168.1.6:5001/api/student/answers/${widget.studentId}");
    // sửa thành /student/answers/:id_student giống backend bạn cho

    final answers = selectedAnswers.entries
        .map((entry) => {
              "examId": widget.examId,
              "questionId": entry.key,
              "choiceId": entry.value,
            })
        .toList();

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({"answers": answers}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        double score = data['score']?.toDouble() ?? 0.0;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Kết quả"),
            content: Text("Điểm của bạn: ${score.toStringAsFixed(2)}/10"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // thoát màn hình Quiz nếu muốn
                },
                child: const Text("Đóng"),
              ),
            ],
          ),
        );
      } else {
        final err = response.body;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gửi bài thất bại: $err")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi gửi bài: $e")),
      );
    }
  }

  Widget buildQuestion(int index, Map<String, dynamic> item) {
    final q = item["question"];
    final List<dynamic> choices = item["choices"];

    // Đảm bảo questionId lấy đúng, backend trả về MaCH trong question object
    final questionId = q["MaCH"] as int;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Câu ${index + 1}: ${q["NoiDungCH"]}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...choices.map((c) {
              final choiceId = c["MaLC"] as int;
              final content = c["NoiDungLC"] as String;
              final isSelected = selectedAnswers[questionId] == choiceId;
              return RadioListTile<int>(
                title: Text(content),
                value: choiceId,
                groupValue: selectedAnswers[questionId],
                onChanged: (value) {
                  setState(() {
                    selectedAnswers[questionId] = value!;
                  });
                },
                activeColor: Colors.purple,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Làm bài thi"),
        backgroundColor: Colors.purple.shade300,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    return buildQuestion(index, questions[index]);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (selectedAnswers.length < questions.length) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Bạn chưa chọn hết câu trả lời!")),
            );
            return;
          }

          final confirm = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Xác nhận"),
              content: const Text("Bạn có chắc chắn muốn nộp bài không?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Không"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Có"),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await submitExam();
          }
        },
        label: const Text("Nộp bài"),
        icon: const Icon(Icons.send),
        backgroundColor: Colors.purple,
      ),
    );
  }
}