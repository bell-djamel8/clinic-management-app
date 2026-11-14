import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/waiting_patient.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import '../widgets/patient_info_dialog.dart';

/// Écran de la salle d'attente, partagé entre la réception et le médecin.
/// - La réception y ajoute un patient dès son arrivée à la clinique.
/// - Le médecin (et la réception) peut l'en retirer une fois la
///   consultation terminée.
class WaitingRoomScreen extends StatefulWidget {
  /// Rôle de l'utilisateur courant, uniquement utilisé pour tracer qui a
  /// ajouté l'entrée ('doctor' ou 'receptionist'). Les deux rôles peuvent
  /// ajouter et retirer un patient de la liste.
  final String currentRole;

  const WaitingRoomScreen({super.key, this.currentRole = 'receptionist'});

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  final _firestoreService = FirestoreService();

  Future<void> _openAddDialog() async {
    await showDialog(
      context: context,
      builder: (_) => _AddToWaitingRoomDialog(
        firestoreService: _firestoreService,
        currentRole: widget.currentRole,
      ),
    );
  }

  Future<void> _confirmRemove(WaitingPatient patient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Retirer de la salle d\'attente'),
        content: Text(
          'Confirmez-vous que ${patient.name} a été pris en charge et peut être retiré de la salle d\'attente ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _firestoreService.removeFromWaitingRoom(patient.id);
    }
  }

  String _formatWaitDuration(DateTime arrivalTime) {
    final diff = DateTime.now().difference(arrivalTime);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Depuis ${diff.inMinutes} min';
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return 'Depuis ${hours}h${minutes.toString().padLeft(2, '0')}';
  }

  void _showPatientInfo(WaitingPatient patient) {
    showPatientInfoDialog(
      context,
      title: patient.name,
      fields: [
        MapEntry('Téléphone', patient.phone),
        MapEntry('État médical / motif', patient.condition),
        MapEntry(
          'Heure d\'arrivée',
          DateFormat('HH:mm').format(patient.arrivalTime),
        ),
        MapEntry('Temps d\'attente', _formatWaitDuration(patient.arrivalTime)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Salle d\'attente',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: ContextColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Patients présents à la clinique, en attente de consultation',
                      style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _openAddDialog,
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                label: const Text('Ajouter un patient'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ContextColors.cardBorder(context)),
              ),
              child: StreamBuilder<List<WaitingPatient>>(
                stream: _firestoreService.streamWaitingRoom(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final patients = snapshot.data!;

                  if (patients.isEmpty) {
                    return const Center(
                      child: Text(
                        'La salle d\'attente est vide',
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
                        onTap: () => _showPatientInfo(patient),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.warning.withOpacity(0.12),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          patient.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(patient.phone),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatWaitDuration(patient.arrivalTime),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(
                                Icons.check_circle_outline,
                                color: AppColors.success,
                              ),
                              tooltip: 'Marquer comme pris en charge',
                              onPressed: () => _confirmRemove(patient),
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

class _AddToWaitingRoomDialog extends StatefulWidget {
  final FirestoreService firestoreService;
  final String currentRole;

  const _AddToWaitingRoomDialog({
    required this.firestoreService,
    required this.currentRole,
  });

  @override
  State<_AddToWaitingRoomDialog> createState() =>
      _AddToWaitingRoomDialogState();
}

class _AddToWaitingRoomDialogState extends State<_AddToWaitingRoomDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _conditionController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;

  Future<void> _confirm() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Veuillez saisir le nom du patient');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.firestoreService.addToWaitingRoom(
        name: name,
        phone: phone,
        condition: _conditionController.text.trim(),
        addedBy: widget.currentRole,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _errorMessage = 'Erreur lors de l\'ajout : $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ajouter à la salle d\'attente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            const Text(
              'Nom du patient',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(controller: _nameController),
            const SizedBox(height: 14),

            const Text(
              'Numéro de téléphone (optionnel)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),

            const Text(
              'État médical / motif (optionnel)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _conditionController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Ex : douleur, contrôle, urgence...',
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.pending, fontSize: 13),
              ),
            ],

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isSaving ? null : _confirm,
                  child: _isSaving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Ajouter'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
