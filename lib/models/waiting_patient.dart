import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle léger représentant un patient présent physiquement dans la salle
/// d'attente. Volontairement séparé du modèle [Patient] car il ne contient
/// aucune donnée médicale (accessible à la réception comme au médecin).
class WaitingPatient {
  final String id;
  final String name;
  final String phone;
  final String condition; // État médical / motif de la visite
  final DateTime arrivalTime;
  final String addedBy; // 'receptionist' | 'doctor'

  WaitingPatient({
    required this.id,
    required this.name,
    required this.phone,
    this.condition = '',
    required this.arrivalTime,
    this.addedBy = 'receptionist',
  });

  factory WaitingPatient.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return WaitingPatient(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      condition: data['condition'] ?? '',
      arrivalTime:
          (data['arrivalTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      addedBy: data['addedBy'] ?? 'receptionist',
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'phone': phone,
    'condition': condition,
    'arrivalTime': Timestamp.fromDate(arrivalTime),
    'addedBy': addedBy,
  };
}
