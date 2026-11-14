import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/patient.dart';
import '../services/firestore_service.dart';
import '../theme.dart';

/// Écran de facturation, utilisé par la réception (sans détails médicaux)
/// et par le médecin pour le suivi financier.
class BillingScreen extends StatefulWidget {
  final bool isReceptionist;

  const BillingScreen({super.key, this.isReceptionist = false});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final _firestoreService = FirestoreService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy - HH:mm');

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Facturation et paiements',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Gérer les visites récentes et les factures en attente',
            style: TextStyle(color: AppColors.textGrey, fontSize: 13),
          ),
          const SizedBox(height: 20),

          FutureBuilder<Map<String, dynamic>>(
            future: _firestoreService.fetchStats(),
            builder: (context, snapshot) {
              final pendingAmount = (snapshot.data?['pendingAmount'] ?? 0)
                  .toStringAsFixed(0);
              return Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: const Border(
                          left: BorderSide(color: AppColors.pending, width: 3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Montants en attente',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textGrey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$pendingAmount DA',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          TextField(
            decoration: const InputDecoration(
              hintText: 'Rechercher par nom ou numéro de téléphone...',
              prefixIcon: Icon(Icons.search, size: 20),
            ),
            onChanged: (value) => setState(() => _searchQuery = value.trim()),
          ),
          const SizedBox(height: 20),

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
                              p.name.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ) ||
                              p.phone.contains(_searchQuery),
                        )
                        .toList();
                  }

                  if (patients.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucune facture pour le moment',
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
                      final isSettled = patient.billingStatus == 'settled';

                      return ListTile(
                        title: Text(
                          patient.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${patient.phone} • ${dateFormat.format(patient.visitDate)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${patient.price.toStringAsFixed(0)} DA',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 16),
                            if (isSettled)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Réglé',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            else
                              ElevatedButton(
                                onPressed: () =>
                                    _firestoreService.updateBillingStatus(
                                      patient.id!,
                                      'settled',
                                    ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text(
                                  'Marquer comme payé',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                          ],
                        ),
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
