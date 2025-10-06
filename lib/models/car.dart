class Car {
  final int id;
  final String brand;
  final String model;
  final int year;
  final String licensePlate;
  final String transmission; // MANUAL or AUTOMATIC
  final int? instructorId;
  final String? color;
  final bool isActive;

  Car({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.licensePlate,
    required this.transmission,
    this.instructorId,
    this.color,
    this.isActive = true,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'] as int,
      brand: json['brand'] as String,
      model: json['model'] as String,
      year: json['year'] as int,
      licensePlate: json['licensePlate'] as String,
      transmission: json['transmission'] as String,
      instructorId: json['instructorId'] as int?,
      color: json['color'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brand': brand,
      'model': model,
      'year': year,
      'licensePlate': licensePlate,
      'transmission': transmission,
      'instructorId': instructorId,
      'color': color,
      'isActive': isActive,
    };
  }
}