import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle d'un médicament au sein de l'ordonnance
class Medication {
  final String name;
  final String instructions;
  // Quantité remise par le pharmacien, notée par la doctoresse (usage interne,
  // n'apparaît pas sur l'ordonnance imprimée).
  final String quantity;

  Medication({
    required this.name,
    required this.instructions,
    this.quantity = '',
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'instructions': instructions,
    'quantity': quantity,
  };

  factory Medication.fromMap(Map<String, dynamic> map) => Medication(
    name: map['name'] ?? '',
    instructions: map['instructions'] ?? '',
    quantity: map['quantity'] ?? '',
  );
}

/// Modèle complet d'une visite/patient, représentant un document Firestore
class Patient {
  final String? id;
  final String name; // Nom complet (prénom + nom), utilisé partout dans l'app
  final String nom; // Nom de famille seul, utilisé sur l'ordonnance imprimée
  final String
  prenom; // Prénom seul, utilisé sur l'ordonnance imprimée
  final String phone;
  final String age; // Âge du patient, affiché sur l'ordonnance
  final String
  wilaya; // Wilaya du patient (information administrative, non affichée sur l'ordonnance)
  final String condition; // État médical / observations cliniques
  final DateTime visitDate;
  final DateTime? nextAppointment;
  final List<Medication> medications;
  final double price;
  final String billingStatus; // 'settled' | 'pending' | 'partial'
  final DateTime createdAt;

  Patient({
    this.id,
    required this.name,
    this.nom = '',
    this.prenom = '',
    required this.phone,
    this.age = '',
    this.wilaya = '',
    required this.condition,
    required this.visitDate,
    this.nextAppointment,
    required this.medications,
    required this.price,
    this.billingStatus = 'pending',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'name': name,
    'nom': nom,
    'prenom': prenom,
    'phone': phone,
    'age': age,
    'wilaya': wilaya,
    'condition': condition,
    'visitDate': Timestamp.fromDate(visitDate),
    'nextAppointment': nextAppointment != null
        ? Timestamp.fromDate(nextAppointment!)
        : null,
    'medications': medications.map((m) => m.toMap()).toList(),
    'price': price,
    'billingStatus': billingStatus,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory Patient.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Patient(
      id: doc.id,
      name: data['name'] ?? '',
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      phone: data['phone'] ?? '',
      age: data['age'] ?? '',
      wilaya: data['wilaya'] ?? '',
      condition: data['condition'] ?? '',
      visitDate: (data['visitDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      nextAppointment: (data['nextAppointment'] as Timestamp?)?.toDate(),
      medications: (data['medications'] as List<dynamic>? ?? [])
          .map((m) => Medication.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
      price: (data['price'] ?? 0).toDouble(),
      billingStatus: data['billingStatus'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
