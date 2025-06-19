import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nhom3_ungdungonthitotnghiep/pages/ExamDetailPage.dart';
import 'package:nhom3_ungdungonthitotnghiep/constants/host.dart';

class ExamHistory extends StatefulWidget {
  final int studentId;
  final String token;

  const ExamHistory({super.key, required this.studentId, required this.token});

  @override
  _ExamHistoryState createState() => _ExamHistoryState();
}

class _ExamHistoryState extends State<ExamHistory> {
  bool isLoading = false;
  String? error;
  List<dynamic> results = [];

  @override
  void initState() {
    super.initState();
    fetchExamResults();
  }

  Future<Map<int, dynamic>> fetchExamDetailsForResults(
    List<dynamic> results,
  ) async {
    Map<int, dynamic> examDetailsMap = {};
    for (var result in results) {
      int examId = result['MaDT'];
      if (!examDetailsMap.containsKey(examId)) {
        final examResponse = await http.get(
          Uri.parse(
            'http://${HostString.hoststring}:5001/api/student/exams/$examId',
          ),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );
        if (examResponse.statusCode == 200) {
          final examData = json.decode(examResponse.body);
          examDetailsMap[examId] = examData['exam'];
        } else {
          examDetailsMap[examId] = null;
        }
      }
    }
    return examDetailsMap;
  }

  Future<void> fetchExamResults() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final response = await http.get(
        Uri.parse(
          'http://${HostString.hoststring}:5001/api/student/exam-results/${widget.studentId}',
        ),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final resultsData = data['results'] ?? [];

        final examDetails = await fetchExamDetailsForResults(resultsData);

        final combinedResults =
            resultsData.map((result) {
              final examId = result['MaDT'];
              final examDetail = examDetails[examId];
              return {
                ...result,
                'TenDT':
                    examDetail != null
                        ? examDetail['TenDT'] ?? 'Không tên đề thi'
                        : 'Không tên đề thi',
              };
            }).toList();

        setState(() {
          results = combinedResults;
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Lỗi tải lịch sử đề thi.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Lỗi kết nối server.';
        isLoading = false;
      });
    }
  }

  void openExamDetail(int examResultId, int examId, String examTime) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ExamDetailPage(
              examResultId: examResultId,
              examId: examId,
              studentId: widget.studentId,
              token: widget.token,
              examTime: examTime,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lịch sử đề thi')),

      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : error != null
              ? Center(child: Text(error!))
              : results.isEmpty
              ? Center(child: Text('Chưa có đề thi nào.'))
              : ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final result = results[index];
                  final examId = result['MaDT'];
                  final examTitle = result['TenDT'] ?? 'Không tên đề thi';

                  // Format điểm số
                  String score = '-';
                  if (result['Diem'] != null) {
                    final double? diem = double.tryParse(
                      result['Diem'].toString(),
                    );
                    if (diem != null) {
                      score = diem.toStringAsFixed(2);
                    } else {
                      score = result['Diem'].toString();
                    }
                  }

                  // Format ngày thi (ThoiGianNop)
                  final examDateRaw = result['ThoiGianNop'];
                  String examDate = '-';
                  if (examDateRaw != null) {
                    try {
                      DateTime dt = DateTime.parse(examDateRaw);
                      examDate =
                          "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                    } catch (e) {
                      examDate = examDateRaw.toString();
                    }
                  }

                  return ListTile(
                    title: Text(examTitle),
                    subtitle: Text('Điểm: $score - Ngày thi: $examDate'),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      final int? examResultId = result['MaKQ'];
                      if (examResultId != null && examId != null) {
                        openExamDetail(examResultId, examId, examDate);
                      }
                    },
                  );
                },
              ),
    );
  }
}
