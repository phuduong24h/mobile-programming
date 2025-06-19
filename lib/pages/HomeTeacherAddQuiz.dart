import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nhom3_ungdungonthitotnghiep/constants/host.dart';

class TeacherQuizScreen extends StatefulWidget {
  final String examId;
  
  const TeacherQuizScreen({super.key, required this.examId});

  @override
  _TeacherQuizScreenState createState() => _TeacherQuizScreenState();
}

class _TeacherQuizScreenState extends State<TeacherQuizScreen> {
  int currentPage = 1;
  final int totalPages = 50;
  bool isLoading = false;
  String? error;
  String teacherName = '';

  final Map<int, Map<String, dynamic>> savedQuestions = {};

  final TextEditingController questionController = TextEditingController();
  final List<TextEditingController> answerControllers =
      List.generate(4, (_) => TextEditingController());
  int correctAnswerIndex = 0;

  // Add FocusNode instances
  late final FocusNode questionFocusNode;
  final List<FocusNode> answerFocusNodes = List.generate(4, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    _loadTeacherName();
    questionFocusNode = FocusNode();
  }

  Future<void> _loadTeacherName() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name') ?? '';
    setState(() {
      teacherName = userName;
    });
  }

  void nextPage() {
    if (currentPage < totalPages) {
      saveCurrentPageData();
      setState(() {
        currentPage++;
      });
      loadPageData();
    }
  }

  void prevPage() {
    if (currentPage > 1) {
      saveCurrentPageData();
      setState(() {
        currentPage--;
      });
      loadPageData();
    }
  }

  void saveCurrentPageData() {
    savedQuestions[currentPage] = {
      'question': questionController.text,
      'answers': answerControllers.map((c) => c.text).toList(),
      'correctAnswerIndex': correctAnswerIndex,
    };
  }

  void loadPageData() {
    final pageData = savedQuestions[currentPage];
    if (pageData != null) {
      questionController.text = pageData['question'] as String;
      final answers = pageData['answers'] as List;
      for (var i = 0; i < answers.length; i++) {
        answerControllers[i].text = answers[i] as String;
      }
      setState(() {
        correctAnswerIndex = pageData['correctAnswerIndex'] as int;
      });
    } else {
      questionController.clear();
      for (var controller in answerControllers) {
        controller.clear();
      }
      setState(() {
        correctAnswerIndex = 0;
      });
    }
  }  Future<void> _saveQuestion() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Không tìm thấy token');
      }

      // Lưu câu hỏi hiện tại vào savedQuestions
      saveCurrentPageData();

      // Tạo danh sách câu hỏi và đáp án từ savedQuestions
      final questionsToSave = savedQuestions.entries.where((entry) {
        final questionData = entry.value;
        final answers = questionData['answers'] as List<dynamic>;
        return questionData['question'].toString().isNotEmpty &&
            answers.every((answer) => answer.toString().isNotEmpty);
      }).toList();

      if (questionsToSave.isEmpty) {
        throw Exception('Không có câu hỏi nào để lưu');
      }

      // Gửi tất cả câu hỏi lên server
      for (var questionEntry in questionsToSave) {
        final questionData = questionEntry.value;
        final answers = questionData['answers'] as List<dynamic>;
        
        final response = await http.post(
          Uri.parse('http://${HostString.hoststring}:5001/api/teacher/add-question-to-class'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'classCode': int.parse(widget.examId),
            'content': questionData['question'].toString(),
            'choices': List.generate(4, (index) => {
              'content': answers[index].toString(),
              'isCorrect': index == questionData['correctAnswerIndex'],
            }),
          }),
        );

        if (response.statusCode != 201) {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? 'Lỗi khi thêm câu hỏi');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu tất cả câu hỏi thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    questionFocusNode.dispose();
    for (var node in answerFocusNodes) {
      node.dispose();
    }
    questionController.dispose();
    for (var controller in answerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.purple),
          onPressed: () {
            saveCurrentPageData();
            Navigator.pop(context);
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 10),
            Text(
              'Xin chào GV. $teacherName',
              style: const TextStyle(color: Colors.black),
            ),
          ],
        ),
        actions: const [
          CircleAvatar(
            backgroundImage: AssetImage('assets/images/avatar.jpg'),
          ),
          SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          Material(
            elevation: 2,
            child: Container(
              height: 45,
              color: Colors.white,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Nút back
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: currentPage > 1 ? () {
                            saveCurrentPageData();
                            setState(() {
                              currentPage--;
                            });
                            loadPageData();
                          } : null,
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Phần số trang giữa
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Trang đầu
                                if (currentPage > 3)
                                  _buildPageButton(1),

                                // Dấu ... đầu
                                if (currentPage > 4)
                                  _buildEllipsis(),

                                // Các trang xung quanh trang hiện tại
                                ..._buildPageRange(),

                                // Dấu ... cuối
                                if (currentPage < totalPages - 3)
                                  _buildEllipsis(),

                                // Trang cuối
                                if (currentPage < totalPages - 2)
                                  _buildPageButton(totalPages),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Nút next
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: currentPage < totalPages ? () {
                            saveCurrentPageData();
                            setState(() {
                              currentPage++;
                            });
                            loadPageData();
                          } : null,
                          child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.purple[50]!, Colors.white],
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Câu hỏi ${currentPage}/${totalPages}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: questionController,
                              focusNode: questionFocusNode,
                              maxLines: 3,
                              textInputAction: TextInputAction.next,
                              onEditingComplete: () {
                                answerFocusNodes[0].requestFocus();
                              },
                              decoration: const InputDecoration(
                                labelText: 'Nội dung câu hỏi',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.all(16),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Các đáp án:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...List.generate(4, (index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Radio<int>(
                                      value: index,
                                      groupValue: correctAnswerIndex,
                                      onChanged: (value) {
                                        setState(() {
                                          correctAnswerIndex = value!;
                                        });
                                      },
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: answerControllers[index],
                                        focusNode: answerFocusNodes[index],
                                        textInputAction: index < 3 ? TextInputAction.next : TextInputAction.done,
                                        onEditingComplete: () {
                                          if (index < 3) {
                                            answerFocusNodes[index + 1].requestFocus();
                                          } else {
                                            answerFocusNodes[index].unfocus();
                                          }
                                        },
                                        decoration: InputDecoration(
                                          labelText: 'Đáp án ${String.fromCharCode(65 + index)}',
                                          border: const OutlineInputBorder(),
                                          contentPadding: const EdgeInsets.all(16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _saveQuestion,
                      icon: const Icon(Icons.save),
                      label: const Text('Lưu câu hỏi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    if (isLoading)
                      const Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton(int pageNumber) {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: currentPage == pageNumber ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          padding: EdgeInsets.zero,
          side: BorderSide(
            color: currentPage == pageNumber ? Colors.black : Colors.purple,
          ),
        ),
        onPressed: () {
          saveCurrentPageData();
          setState(() {
            currentPage = pageNumber;
          });
          loadPageData();
        },
        child: Text(
          '$pageNumber',
          style: TextStyle(
            color: currentPage == pageNumber ? Colors.white : Colors.purple,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEllipsis() {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: const Text(
        '...',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.purple,
        ),
      ),
    );
  }

  List<Widget> _buildPageRange() {
    List<Widget> widgets = [];
    int start = (currentPage - 2).clamp(1, totalPages);
    int end = (currentPage + 2).clamp(1, totalPages);

    for (int i = start; i <= end; i++) {
      widgets.add(_buildPageButton(i));
    }
    return widgets;
  }
}