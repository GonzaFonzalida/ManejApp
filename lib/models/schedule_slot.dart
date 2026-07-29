class ScheduleSlot {
  final dynamic id; // Puede ser String o int
  final int instructorId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final bool isAvailable;
  final int? studentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relaciones
  final Map<String, dynamic>? instructor;
  final User? student;

  ScheduleSlot({
    required this.id,
    required this.instructorId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    this.studentId,
    required this.createdAt,
    required this.updatedAt,
    this.instructor,
    this.student,
  });

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) {
    final startDateTime = DateTime.parse(json['startTime'].toString());
    final endDateTime = DateTime.parse(json['endTime'].toString());

    return ScheduleSlot(
      id: json['id'], // Mantener el tipo original (String o int)
      instructorId: int.tryParse(json['instructorId'].toString()) ?? 0,
      date: startDateTime.toLocal(),
      startTime:
          '${startDateTime.toLocal().hour.toString().padLeft(2, '0')}:${startDateTime.toLocal().minute.toString().padLeft(2, '0')}:00',
      endTime:
          '${endDateTime.toLocal().hour.toString().padLeft(2, '0')}:${endDateTime.toLocal().minute.toString().padLeft(2, '0')}:00',
      isAvailable: json['isBooked'] != true,
      studentId: json['studentId'] != null
          ? int.tryParse(json['studentId'].toString())
          : null,
      createdAt: DateTime.parse(json['createdAt'].toString()),
      updatedAt: DateTime.parse(json['updatedAt'].toString()),
      instructor: json['instructor'] is Map<String, dynamic>
          ? json['instructor'] as Map<String, dynamic>
          : null,
      student:
          json['student'] != null && json['student'] is Map<String, dynamic>
              ? User.fromJson(json['student'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'instructorId': instructorId,
      'date': date.toIso8601String().split('T')[0],
      'startTime': startTime,
      'endTime': endTime,
      'isAvailable': isAvailable,
      'studentId': studentId,
    };
  }
}

class User {
  final int id;
  final String? name;
  final String? surname;
  final String? email;

  User({
    required this.id,
    this.name,
    this.surname,
    this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString(),
      surname: json['surname']?.toString(),
      email: json['email']?.toString(),
    );
  }
}
