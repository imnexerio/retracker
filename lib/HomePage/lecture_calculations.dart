int calculateMonthlyLectures(List<Map<String, dynamic>> records, Map<String, Set<String>> selectedTrackingTypesMap) {
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  Set<String> selectedLectureTypes = selectedTrackingTypesMap['lecture'] ?? {};

  return records.where((record) {
    if (record['details']['date_learnt'] == null) return false;
    final dateLearnt = DateTime.parse(record['details']['date_learnt']);
    return (dateLearnt.isAfter(startOfMonth) || dateLearnt.isAtSameMomentAs(startOfMonth)) &&
        selectedLectureTypes.contains(record['details']['lecture_type']);
  }).length;
}

int calculateWeeklyLectures(List<Map<String, dynamic>> records, Map<String, Set<String>> selectedTrackingTypesMap) {
  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final startOfDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
  Set<String> selectedLectureTypes = selectedTrackingTypesMap['lecture'] ?? {};

  return records.where((record) {
    if (record['details']['date_learnt'] == null) return false;
    final dateLearnt = DateTime.parse(record['details']['date_learnt']);
    return (dateLearnt.isAfter(startOfDay) || dateLearnt.isAtSameMomentAs(startOfDay)) &&
        selectedLectureTypes.contains(record['details']['lecture_type']);
  }).length;
}

int calculateDailyLectures(List<Map<String, dynamic>> records, Map<String, Set<String>> selectedTrackingTypesMap) {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  Set<String> selectedLectureTypes = selectedTrackingTypesMap['lecture'] ?? {};

  return records.where((record) {
    if (record['details']['date_learnt'] == null) return false;
    final dateLearnt = DateTime.parse(record['details']['date_learnt']);
    return (dateLearnt.isAfter(startOfDay) || dateLearnt.isAtSameMomentAs(startOfDay)) &&
        selectedLectureTypes.contains(record['details']['lecture_type']);
  }).length;
}