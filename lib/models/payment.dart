class Payment {
  final int id;
  final int drivingClassId;
  final double amount;
  final String method; // mercadopago, cash, transfer
  final String status; // pending, paid, failed
  final String? transactionId;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relación
  final Map<String, dynamic>? drivingClass;

  Payment({
    required this.id,
    required this.drivingClassId,
    required this.amount,
    required this.method,
    required this.status,
    this.transactionId,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.drivingClass,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    final methodRaw = json['method'] ?? json['paymentMethod'];
    return Payment(
      id: json['id'] as int,
      drivingClassId: json['drivingClassId'] as int,
      amount: (json['amount'] as num).toDouble(),
      method: methodRaw as String,
      status: json['status'] as String,
      transactionId: json['transactionId'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      drivingClass: json['drivingClass'] as Map<String, dynamic>?,
    );
  }
}
