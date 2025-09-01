class Instructor {
  final int id;
  final String name;
  final double rating;
  final int experienceYears;
  final int hourlyRate;
  final String image;

  Instructor({
    required this.id,
    required this.name,
    required this.rating,
    required this.experienceYears,
    required this.hourlyRate,
    required this.image,
  });

  factory Instructor.fromJson(Map<String, dynamic> json) {
    print('Instructor json: $json');
    return Instructor(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      rating: double.tryParse(json['rating']?.toString() ?? '0.0') ?? 0.0,
      experienceYears: int.tryParse(json['experienceYears']?.toString() ?? '0') ?? 0,
      hourlyRate: int.tryParse(json['hourlyRate']?.toString() ?? '0') ?? 0,
      image: json['image'] ?? 'assets/car1.png',
    );
  }
}