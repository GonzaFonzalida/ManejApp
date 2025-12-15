class Instructor {
  final int id;
  final String licenseNumber;
  final int experienceYears;
  final String? image;
  final double? rating;
  final String? description;
  // ✅ The user object is now optional to prevent TypeErrors
  final User? user;

  Instructor({
    required this.id,
    required this.licenseNumber,
    required this.experienceYears,
    this.user,
    this.image,
    this.rating,
    this.description,
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
      description: json['description'] as String?,
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