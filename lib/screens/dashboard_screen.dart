import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/patient.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import 'patient_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _firestoreService = FirestoreService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Archive des patients',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ContextColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Base de données complète des visites, traitements et situation financière',
            style: TextStyle(color: AppColors.textGrey, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Statistic cards
          FutureBuilder<Map<String, dynamic>>(
            future: _firestoreService.fetchStats(),
            builder: (context, snapshot) {
              final total = snapshot.data?['total'] ?? 0;
              final pendingBilling = snapshot.data?['pendingBilling'] ?? 0;
              return Row(
                children: [
                  Expanded(
                    child: StatCardMini(
                      label: 'Total des dossiers',
                      value: '$total',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCardMini(
                      label: 'Factures en attente',
                      value: '$pendingBilling',
                      accentColor: AppColors.pending,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCardMini(
                      label: 'Visites du jour',
                      value: dateFormat.format(DateTime.now()),
                      accentColor: AppColors.success,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Search bar
          TextField(
            decoration: const InputDecoration(
              hintText: 'Rechercher par nom ou numéro de téléphone...',
              prefixIcon: Icon(Icons.search, size: 20),
            ),
            onChanged: (value) => setState(() => _searchQuery = value.trim()),
          ),
          const SizedBox(height: 20),

          // Patients table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ContextColors.cardBorder(context)),
              ),
              child: StreamBuilder<List<Patient>>(
                stream: _firestoreService.streamPatients(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var patients = snapshot.data!;
                  if (_searchQuery.isNotEmpty) {
                    patients = patients
                        .where(
                          (p) =>
                              p.name.contains(_searchQuery) ||
                              p.phone.contains(_searchQuery),
                        )
                        .toList();
                  }

                  if (patients.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucun patient enregistré pour le moment',
                        style: TextStyle(color: AppColors.textGrey),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: patients.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.cardBorder),
                    itemBuilder: (context, index) {
                      final patient = patients[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryBlue.withOpacity(
                            0.1,
                          ),
                          child: Text(
                            patient.name.isNotEmpty ? patient.name[0] : '?',
                            style: const TextStyle(
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                        title: Text(
                          patient.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${patient.phone} • ${dateFormat.format(patient.visitDate)}',
                            ),
                            if (patient.condition.trim().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                patient.condition,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textGrey,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: _BillingBadge(status: patient.billingStatus),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  PatientDetailScreen(patient: patient),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StatCardMini extends StatelessWidget {
  final String label;
  final String value;
  final Color? accentColor;

  const StatCardMini({
    super.key,
    required this.label,
    required this.value,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: accentColor ?? AppColors.primaryBlue,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _BillingBadge extends StatelessWidget {
  final String status;
  const _BillingBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isSettled = status == 'settled';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSettled
            ? AppColors.success.withOpacity(0.1)
            : AppColors.pending.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isSettled ? 'Réglé' : 'En attente',
        style: TextStyle(
          color: isSettled ? AppColors.success : AppColors.pending,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
