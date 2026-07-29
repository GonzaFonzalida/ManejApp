class Instructor {
  final int id;
  final String? licenseNumber;
  final int experienceYears;
  final double? hourlyRate;
  final String? image;
  final double? rating;
  final String? description;
  final User? user;

  final List<dynamic>? cars;
  final String? bio;

  /// Cuenta aprobada por la plataforma (documentación revisada).
  final bool? isValid;

  /// Dirección legible del instructor (si el backend la envía).
  final String? addressText;

  Instructor({
    required this.id,
    this.licenseNumber,
    required this.experienceYears,
    this.hourlyRate,
    this.user,
    this.image,
    this.rating,
    this.description,
    this.cars,
    this.bio,
    this.isValid,
    this.addressText,
  });

  double get effectiveHourlyRate => hourlyRate ?? user?.hourlyRate ?? 45000.0;

  factory Instructor.fromJson(Map<String, dynamic> json) {
    return Instructor(
      id: json['id'] as int,
      licenseNumber: json['licenseNumber'] as String?,
      experienceYears: json['experienceYears'] as int,
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      rating: (json['rating'] as num?)?.toDouble(),
      image: json['image'] as String?,
      description: json['description'] as String?,
      bio: json['bio'] as String?,
      cars: json['cars'] as List<dynamic>?,
      isValid: json['isValid'] as bool?,
      addressText:
          json['addressText'] as String? ?? json['address_text'] as String?,
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
  final String? location;
  final String? profileImage;
  final String? profileImageUrl;

  User({
    required this.id,
    this.name,
    this.surname,
    this.email,
    this.role,
    this.hourlyRate,
    this.location,
    this.profileImage,
    this.profileImageUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String?,
      surname: json['surname'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String?,
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
      location: json['location'] as String?,
      profileImage: json['profileImage'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }
}
