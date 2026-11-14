import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/patient.dart';
import '../theme.dart';
import 'prescription_screen.dart';

/// Affiche les informations d'un patient sous forme de fiche/carte organisée
/// (identité, situation clinique, facturation, médicaments), au lieu de
/// réutiliser la mise en page de l'ordonnance imprimable. L'ordonnance reste
/// accessible via le bouton dédié en haut de l'écran, sans rien changer à
/// son fonctionnement d'origine.
class PatientDetailScreen extends StatelessWidget {
  final Patient patient;

  const PatientDetailScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isSettled = patient.billingStatus == 'settled';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlueDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Fiche du patient',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PrescriptionScreen(patient: patient),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE3F1FF),
                foregroundColor: AppColors.primaryBlueDark,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.description_outlined, size: 18),
              label: const Text(
                'Voir l\'ordonnance',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // En-tête : avatar, nom, statut de facturation
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: ContextColors.cardBorder(context)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                        child: Text(
                          patient.name.isNotEmpty ? patient.name[0] : '?',
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: ContextColors.textPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              patient.phone.isNotEmpty
                                  ? patient.phone
                                  : 'Numéro non renseigné',
                              style: const TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSettled
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.pending.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isSettled ? 'Réglé' : 'En attente',
                          style: TextStyle(
                            color: isSettled
                                ? AppColors.success
                                : AppColors.pending,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Informations générales
                _InfoSectionCard(
                  title: 'Informations générales',
                  icon: Icons.person_outline,
                  children: [
                    _InfoRow(
                      label: 'Âge',
                      value: patient.age.isNotEmpty ? patient.age : '—',
                    ),
                    _InfoRow(
                      label: 'Wilaya',
                      value: patient.wilaya.isNotEmpty ? patient.wilaya : '—',
                    ),
                    _InfoRow(
                      label: 'Date de la visite',
                      value: dateFormat.format(patient.visitDate),
                    ),
                    _InfoRow(
                      label: 'Prochain rendez-vous',
                      value: patient.nextAppointment != null
                          ? dateFormat.format(patient.nextAppointment!)
                          : 'Aucun',
                    ),
                    _InfoRow(
                      label: 'Montant (DA)',
                      value: patient.price > 0
                          ? patient.price.toStringAsFixed(0)
                          : '—',
                      isLast: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Observations cliniques
                _InfoSectionCard(
                  title: 'Observations cliniques',
                  icon: Icons.medical_information_outlined,
                  children: [
                    Text(
                      patient.condition.trim().isNotEmpty
                          ? patient.condition
                          : 'Aucune observation enregistrée',
                      style: TextStyle(
                        fontSize: 14,
                        color: patient.condition.trim().isNotEmpty
                            ? ContextColors.textPrimary(context)
                            : AppColors.textGrey,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Médicaments prescrits
                _InfoSectionCard(
                  title: 'Médicaments prescrits',
                  icon: Icons.medication_outlined,
                  children: patient.medications.isEmpty
                      ? [
                          const Text(
                            'Aucun médicament enregistré',
                            style: TextStyle(color: AppColors.textGrey),
                          ),
                        ]
                      : [
                          for (var i = 0; i < patient.medications.length; i++)
                            _MedicationTile(
                              medication: patient.medications[i],
                              isLast: i == patient.medications.length - 1,
                            ),
                        ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoSectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ContextColors.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: ContextColors.textPrimary(context),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: ContextColors.textPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationTile extends StatelessWidget {
  final Medication medication;
  final bool isLast;

  const _MedicationTile({required this.medication, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppDarkColors.background
            : const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ContextColors.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.medication_liquid_outlined,
                size: 16,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  medication.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: ContextColors.textPrimary(context),
                  ),
                ),
              ),
            ],
          ),
          if (medication.instructions.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              medication.instructions,
              style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
            ),
          ],
          if (medication.quantity.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 14,
                  color: AppColors.textGrey,
                ),
                const SizedBox(width: 6),
                Text(
                  'Quantité remise par le pharmacien : ${medication.quantity}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
