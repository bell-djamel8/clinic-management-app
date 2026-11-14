import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient.dart';
import '../models/waiting_patient.dart';

class FirestoreService {
  final CollectionReference<Map<String, dynamic>> _patients = FirebaseFirestore
      .instance
      .collection('patients');

  final CollectionReference<Map<String, dynamic>> _waitingRoom =
      FirebaseFirestore.instance.collection('waiting_room');

  /// Flux en direct de tous les patients, les plus récents en premier
  Stream<List<Patient>> streamPatients() {
    return _patients
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Patient.fromDoc(d)).toList());
  }

  Future<void> addPatient(Patient patient) async {
    await _patients.add(patient.toMap());
  }

  /// Récupère une fois la liste complète des patients (utilisé par l'écran
  /// Statistiques pour calculer les agrégats sur la période choisie).
  Future<List<Patient>> fetchAllPatientsOnce() async {
    final snap = await _patients.get();
    return snap.docs.map((d) => Patient.fromDoc(d)).toList();
  }

  Future<void> updateBillingStatus(String patientId, String status) async {
    await _patients.doc(patientId).update({'billingStatus': status});
  }

  /// Annule le rendez-vous d'un patient (par exemple lorsqu'il change de
  /// date, ou ne peut plus venir). Le patient reste dans l'archive, mais
  /// disparaît de la liste des rendez-vous et libère la place ce jour-là.
  Future<void> cancelAppointment(String patientId) async {
    await _patients.doc(patientId).update({'nextAppointment': null});
  }

  /// Flux de tous les patients (utilisé pour construire la liste des
  /// rendez-vous à venir, triée côté écran du plus proche au plus lointain)
  Stream<List<Patient>> streamAllPatientsForAppointments() {
    return _patients.snapshots().map(
      (snap) => snap.docs.map((d) => Patient.fromDoc(d)).toList(),
    );
  }

  /// Recherche un patient existant par numéro de téléphone (utilisé lors
  /// de la prise de rendez-vous pour éviter les doublons)
  Future<Patient?> findPatientByPhone(String phone) async {
    if (phone.trim().isEmpty) return null;
    final query = await _patients
        .where('phone', isEqualTo: phone.trim())
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return Patient.fromDoc(query.docs.first);
  }

  /// Recherche un patient existant avec le même numéro de téléphone ET le
  /// même nom (comparaison insensible à la casse). Utilisé lors de la
  /// prise de rendez-vous : seule une correspondance exacte nom+téléphone
  /// est considérée comme "le même patient qui change de date" — sinon
  /// (même téléphone, nom différent, ex : un enfant réservé avec le
  /// téléphone d'un parent) un nouveau dossier séparé est créé.
  Future<Patient?> findPatientByPhoneAndName(String phone, String name) async {
    if (phone.trim().isEmpty) return null;
    final query = await _patients.where('phone', isEqualTo: phone.trim()).get();
    final normalizedName = name.trim().toLowerCase();
    for (final doc in query.docs) {
      final patient = Patient.fromDoc(doc);
      if (patient.name.trim().toLowerCase() == normalizedName) {
        return patient;
      }
    }
    return null;
  }

  /// Nombre maximal de rendez-vous que le médecin accepte par jour.
  static const int maxAppointmentsPerDay = 8;

  /// Compte le nombre de rendez-vous déjà pris pour une date donnée
  /// (utilisé pour savoir si le jour est complet, et pour l'affichage du
  /// nombre de réservations lors de la recherche par date).
  /// [excludePatientId] permet d'exclure le patient en cours de
  /// modification (cas d'un patient qui change juste l'heure/le jour de
  /// son propre rendez-vous, sans compter deux fois sa place).
  Future<int> countAppointmentsForDate(
    DateTime date, {
    String? excludePatientId,
  }) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final query = await _patients
        .where(
          'nextAppointment',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        )
        .where('nextAppointment', isLessThan: Timestamp.fromDate(end))
        .get();
    var docs = query.docs;
    if (excludePatientId != null) {
      docs = docs.where((d) => d.id != excludePatientId).toList();
    }
    return docs.length;
  }

  /// Prend un rendez-vous depuis la réception.
  /// - Si un patient avec le même nom ET le même numéro de téléphone
  ///   existe déjà, met à jour uniquement son prochain rendez-vous (cas
  ///   d'un patient qui change juste la date de son propre rendez-vous).
  /// - Sinon, crée un nouveau dossier patient séparé avec ce rendez-vous
  ///   (ex : un enfant réservé avec le téléphone d'un parent déjà connu),
  ///   qui apparaîtra automatiquement dans l'archive et la facturation.
  /// Lève une exception si le jour choisi est déjà complet
  /// ([maxAppointmentsPerDay] rendez-vous).
  Future<void> bookAppointment({
    required String name,
    required String phone,
    required DateTime appointmentDate,
    String condition = '',
  }) async {
    final existing = await findPatientByPhoneAndName(phone, name);

    final currentCount = await countAppointmentsForDate(
      appointmentDate,
      excludePatientId: existing?.id,
    );
    if (currentCount >= maxAppointmentsPerDay) {
      throw Exception(
        'Cette date est complète ($maxAppointmentsPerDay rendez-vous maximum). Veuillez choisir un autre jour.',
      );
    }

    if (existing != null) {
      await _patients.doc(existing.id).update({
        'name': name.trim(),
        'nextAppointment': Timestamp.fromDate(appointmentDate),
        if (condition.trim().isNotEmpty) 'condition': condition.trim(),
      });
    } else {
      final patient = Patient(
        name: name.trim(),
        phone: phone.trim(),
        condition: condition.trim(),
        visitDate: DateTime.now(),
        nextAppointment: appointmentDate,
        medications: [],
        price: 0,
        billingStatus: 'pending',
      );
      await addPatient(patient);
    }
  }

  /// Statistiques simples pour le tableau de bord
  Future<Map<String, dynamic>> fetchStats() async {
    final snap = await _patients.get();
    final docs = snap.docs;
    final total = docs.length;
    final pendingBilling = docs
        .where((d) => d.data()['billingStatus'] == 'pending')
        .length;
    final pendingAmount = docs
        .where((d) => d.data()['billingStatus'] != 'settled')
        .fold<double>(0, (sum, d) => sum + ((d.data()['price'] ?? 0) as num));

    return {
      'total': total,
      'pendingBilling': pendingBilling,
      'pendingAmount': pendingAmount,
    };
  }

  // ------------------------------------------------------------------
  // Salle d'attente
  // ------------------------------------------------------------------

  /// Flux en direct de la salle d'attente, triée par ordre d'arrivée
  /// (le patient arrivé en premier apparaît en premier).
  Stream<List<WaitingPatient>> streamWaitingRoom() {
    return _waitingRoom
        .orderBy('arrivalTime')
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => WaitingPatient.fromDoc(d)).toList(),
        );
  }

  /// Ajoute un patient à la salle d'attente (utilisé par la réception à
  /// l'arrivée du patient, mais accessible aussi au médecin si besoin).
  Future<void> addToWaitingRoom({
    required String name,
    required String phone,
    String condition = '',
    String addedBy = 'receptionist',
  }) async {
    final entry = WaitingPatient(
      id: '',
      name: name.trim(),
      phone: phone.trim(),
      condition: condition.trim(),
      arrivalTime: DateTime.now(),
      addedBy: addedBy,
    );
    await _waitingRoom.add(entry.toMap());
  }

  /// Retire un patient de la salle d'attente. Autorisé pour le médecin
  /// (une fois la consultation terminée) comme pour la réception (par
  /// exemple en cas d'erreur de saisie ou de départ du patient).
  Future<void> removeFromWaitingRoom(String waitingId) async {
    await _waitingRoom.doc(waitingId).delete();
  }
}
