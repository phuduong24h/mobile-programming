import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:nhom3_ungdungonthitotnghiep/constants/host.dart';

DateTime? parseCustomDateTime(String dateTimeStr) {
  try {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.parse(dateTimeStr);
  } catch (e) {
    print('Parse date error: $e');
    return null;
  }
}

class ExamDetailPage extends StatefulWidget {
  final int examId;
  final int studentId;
  final String token;
  final String examTime; // định dạng dd/MM/yyyy HH:mm
  final int examResultId;

  const ExamDetailPage({
    super.key,
    required this.examResultId,
    required this.examId,
    required this.studentId,
    required this.token,
    required this.examTime,
  });

  @override
  _ExamDetailPageState createState() => _ExamDetailPageState();
}

class _ExamDetailPageState extends State<ExamDetailPage> {
  bool isLoading = false;
  String? error;

  Map<int, int> studentAnswers = {};
  Map<int, int> correctAnswers = {};
  Map<int, bool> answerCorrectness = {};

  Map<String, dynamic>? exam;
  List<dynamic> questions = [];
  int? score;

  @override
  void initState() {
    super.initState();
    fetchExamDetailWithHistory();
  }

  Future<void> fetchExamDetailWithHistory() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      // 1. Lấy thông tin đề thi
      final examResponse = await http.get(
        Uri.parse(
          'http://${HostString.hoststring}:5001/api/student/exams/${widget.examId}',
        ),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (examResponse.statusCode != 200) {
        throw Exception("Lỗi tải thông tin đề thi: ${examResponse.statusCode}");
      }

      final examData = json.decode(examResponse.body);
      final examInfo = examData['exam'];
      final questionList = examData['questions'] as List<dynamic>;

      // 2. Lấy lịch sử làm bài
      final historyResponse = await http.get(
        Uri.parse(
          'http://${HostString.hoststring}:5001/api/student/exam-history/${widget.studentId}/${widget.examId}',
        ),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (historyResponse.statusCode != 200) {
        throw Exception("Lỗi tải lịch sử thi: ${historyResponse.statusCode}");
      }

      final historyData = json.decode(historyResponse.body);
      final List<dynamic> historyList = historyData['history'] ?? [];

      // 3. Parse examTime (dd/MM/yyyy HH:mm) và chuyển sang UTC chuẩn
      DateTime? examDateTimeLocal = parseCustomDateTime(widget.examTime);
      if (examDateTimeLocal == null) {
        throw Exception("Định dạng examTime không hợp lệ");
      }
      DateTime examDateTimeUtc = DateTime.utc(
        examDateTimeLocal.year,
        examDateTimeLocal.month,
        examDateTimeLocal.day,
        examDateTimeLocal.hour,
        examDateTimeLocal.minute,
      );

      Map<int, int> studentAnsMap = {};
      Map<int, int> correctAnsMap = {};
      Map<int, bool> correctnessMap = {};
      int? foundScore;

      // Lấy đáp án đúng từ câu hỏi
      for (var q in questionList) {
        final questionId = q['question']['MaCH'] as int;
        final choices = q['choices'] as List<dynamic>;
        for (var choice in choices) {
          if (choice['LaDAD'] == true) {
            correctAnsMap[questionId] = choice['MaLC'] as int;
            break;
          }
        }
      }

      for (var history in historyList) {
        String submittedAtStr = history['submittedAt'];

        // Parse submittedAt và chuyển sang UTC
        DateTime submittedAtUtc = DateTime.parse(submittedAtStr).toUtc();

        // Chuẩn hóa bỏ giây, mili giây (chỉ lấy đến phút)
        submittedAtUtc = DateTime.utc(
          submittedAtUtc.year,
          submittedAtUtc.month,
          submittedAtUtc.day,
          submittedAtUtc.hour,
          submittedAtUtc.minute,
        );

        if (submittedAtUtc.millisecondsSinceEpoch ==
            examDateTimeUtc.millisecondsSinceEpoch) {
          foundScore = history['score'] as int?;
          final answerDetails =
              history['answerDetails'] as List<dynamic>? ?? [];
          for (var ans in answerDetails) {
            int qId = ans['questionId'] as int;
            studentAnsMap[qId] = ans['selectedChoiceId'] as int;
            correctAnsMap[qId] = ans['correctChoiceId'] as int;
            correctnessMap[qId] = ans['isCorrect'] as bool;
          }
          break;
        }
      }

      setState(() {
        exam = examInfo;
        questions = questionList;
        studentAnswers = studentAnsMap;
        correctAnswers = correctAnsMap;
        answerCorrectness = correctnessMap;
        score = foundScore;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = "Lỗi khi tải dữ liệu: $e";
        isLoading = false;
      });
    }
  }

  Widget buildChoice(int questionId, dynamic choice) {
    int maLC = choice['MaLC'] as int;
    bool isCorrectAnswer = correctAnswers[questionId] == maLC;
    bool isSelected = studentAnswers[questionId] == maLC;
    bool? isCorrect = answerCorrectness[questionId];

    Color? bgColor;
    Icon? icon;
    Color borderColor = Colors.grey.shade400;
    double borderWidth = 1.0;

    if (isSelected) {
      borderColor = Colors.blue;
      borderWidth = 2.0;
      if (isCorrect == true) {
        bgColor = Colors.green[200];
        icon = Icon(Icons.check_circle, color: Colors.green);
      } else {
        bgColor = Colors.red[100];
        icon = Icon(Icons.close, color: Colors.red);
      }
    } else if (isCorrectAnswer) {
      bgColor = Colors.green[50];
      icon = Icon(Icons.check_circle_outline, color: Colors.green);
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.transparent,
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (icon != null) ...[icon, SizedBox(width: 8)],
          Expanded(
            child: Text(
              choice['NoiDungLC'] ?? '',
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exam != null
                  ? exam!['TieuDe'] ?? 'Chi tiết đề thi'
                  : 'Chi tiết đề thi',
              style: TextStyle(fontSize: 18),
            ),
            if (score != null)
              Text(
                'Điểm: $score',
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
            SizedBox(height: 4),
            Text(
              'Thời gian nộp bài: ${widget.examTime}',
              style: TextStyle(fontSize: 12, color: Colors.black),
            ),
          ],
        ),
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : error != null
              ? Center(child: Text(error!))
              : ListView.builder(
                padding: EdgeInsets.all(12),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final q = questions[index];
                  final question = q['question'];
                  final choices = q['choices'] as List<dynamic>;

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Câu ${index + 1}: ${question['NoiDungCH'] ?? ''}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          ...choices.map(
                            (choice) =>
                                buildChoice(question['MaCH'] as int, choice),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
