class DrivingClass {
  final int id;
  final int instructorId;
  final int studentId;
  final DateTime date;
  final String time;
  final int duration;
  final String status; // scheduled, completed, canceled
  final String? notes;
  final double? rating;
  final String? feedback;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relaciones
  final Map<String, dynamic>? instructor;
  final User? student;

  DrivingClass({
    required this.id,
    required this.instructorId,
    required this.studentId,
    required this.date,
    required this.time,
    required this.duration,
    required this.status,
    this.notes,
    this.rating,
    this.feedback,
    required this.createdAt,
    required this.updatedAt,
    this.instructor,
    this.student,
  });

  factory DrivingClass.fromJson(Map<String, dynamic> json) {
    return DrivingClass(
      id: json['id'] as int,
      instructorId: json['instructorId'] as int,
      studentId: json['studentId'] as int,
      date: DateTime.parse(json['date'] as String),
      time: json['time'] as String,
      duration: json['duration'] as int,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      feedback: json['feedback'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      instructor: json['instructor'] as Map<String, dynamic>?,
      student: json['student'] != null
          ? User.fromJson(json['student'] as Map<String, dynamic>)
          : null,
    );
  }
}

class User {
  final int id;
  final String? name;
  final String? surname;
  final String? email;
  final String? role;

  User({
    required this.id,
    this.name,
    this.surname,
    this.email,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String?,
      surname: json['surname'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String?,
    );
  }
}

