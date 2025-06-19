import 'package:intl/intl.dart';

DateTime? parseCustomDateTime(String dateTimeStr) {
  try {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.parse(dateTimeStr);
  } catch (e) {
    print('Parse date error: $e');
    return null;
  }
}
