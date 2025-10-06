class Instructor {
  final int id;
  final String licenseNumber;
  final int experienceYears;
  final String? image;
  final double? rating;
  // ✅ The user object is now optional to prevent TypeErrors
  final User? user;

  Instructor({
    required this.id,
    required this.licenseNumber,
    required this.experienceYears,
    this.user,
    this.image,
    this.rating,
  });

  factory Instructor.fromJson(Map<String, dynamic> json) {
    return Instructor(
      id: json['id'] as int,
      licenseNumber: json['licenseNumber'] as String,
      experienceYears: json['experienceYears'] as int,
      // ✅ Correctly handles a null or missing 'user' key
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      rating: (json['rating'] as num?)?.toDouble(),
      image: json['image'] as String?,
    );
  }
}

class User {
  final int id;
  final String? name;
  final String? surname;
  final String? email;
  final String? role;
  final double? hourlyRate;

  User({
    required this.id,
    this.name,
    this.surname,
    this.email,
    this.role,
    this.hourlyRate,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String?,
      surname: json['surname'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String?,
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
    );
  }
}