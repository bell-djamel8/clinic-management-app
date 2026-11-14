import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/patient.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import '../widgets/patient_info_dialog.dart';

/// Écran des rendez-vous, triés du plus proche au plus lointain,
/// avec recherche par nom ou numéro de téléphone.
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final _firestoreService = FirestoreService();
  String _searchQuery = '';
  DateTime? _searchDate;

  Future<void> _openBookingDialog() async {
    await showDialog(
      context: context,
      builder: (_) =>
          _BookAppointmentDialog(firestoreService: _firestoreService),
    );
  }

  Future<void> _pickSearchDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _searchDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _searchDate = picked);
    }
  }

  void _showPatientInfo(Patient patient) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    showPatientInfoDialog(
      context,
      title: patient.name,
      fields: [
        MapEntry('Téléphone', patient.phone),
        MapEntry('Âge', patient.age),
        MapEntry('Wilaya', patient.wilaya),
        MapEntry('État médical', patient.condition),
        MapEntry(
          'Prochain rendez-vous',
          patient.nextAppointment != null
              ? dateFormat.format(patient.nextAppointment!)
              : '',
        ),
      ],
    );
  }

  Future<void> _confirmCancelAppointment(Patient patient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Annuler ce rendez-vous'),
        content: Text(
          'Confirmez-vous l\'annulation du rendez-vous de ${patient.name} ? '
          'Cette place sera de nouveau disponible pour ce jour-là.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Retour'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.pending),
            child: const Text('Annuler le rendez-vous'),
          ),
        ],
      ),
    );

    if (confirmed == true && patient.id != null) {
      await _firestoreService.cancelAppointment(patient.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

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
                      'Rendez-vous',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: ContextColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Liste des prochains rendez-vous, du plus proche au plus lointain',
                      style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _openBookingDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nouveau rendez-vous'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Rechercher par nom ou numéro de téléphone...',
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.trim()),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _pickSearchDate,
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text(
                  _searchDate != null
                      ? DateFormat('dd/MM/yyyy').format(_searchDate!)
                      : 'Rechercher par date',
                ),
              ),
              if (_searchDate != null)
                IconButton(
                  tooltip: 'Effacer la date',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _searchDate = null),
                ),
            ],
          ),
          if (_searchDate != null) ...[
            const SizedBox(height: 10),
            FutureBuilder<int>(
              future: _firestoreService.countAppointmentsForDate(_searchDate!),
              builder: (context, snapshot) {
                final count = snapshot.data;
                if (count == null) return const SizedBox.shrink();
                final isFull = count >= FirestoreService.maxAppointmentsPerDay;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: (isFull ? AppColors.pending : AppColors.success)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isFull
                        ? 'Jour complet : $count/${FirestoreService.maxAppointmentsPerDay} rendez-vous'
                        : '$count/${FirestoreService.maxAppointmentsPerDay} rendez-vous ce jour-là — encore disponible',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isFull ? AppColors.pending : AppColors.success,
                    ),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 20),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ContextColors.cardBorder(context)),
              ),
              child: StreamBuilder<List<Patient>>(
                stream: _firestoreService.streamAllPatientsForAppointments(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var patients = snapshot.data!
                      .where((p) => p.nextAppointment != null)
                      .toList();

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

                  if (_searchDate != null) {
                    patients = patients
                        .where(
                          (p) =>
                              p.nextAppointment!.year == _searchDate!.year &&
                              p.nextAppointment!.month == _searchDate!.month &&
                              p.nextAppointment!.day == _searchDate!.day,
                        )
                        .toList();
                  }

                  // Sort from nearest to farthest
                  patients.sort(
                    (a, b) => a.nextAppointment!.compareTo(b.nextAppointment!),
                  );

                  if (patients.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucun rendez-vous programmé',
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
                      final appointmentDate = patient.nextAppointment!;
                      final isPast = appointmentDate.isBefore(todayStart);
                      final isToday =
                          appointmentDate.year == today.year &&
                          appointmentDate.month == today.month &&
                          appointmentDate.day == today.day;

                      return ListTile(
                        onTap: () => _showPatientInfo(patient),
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
                        subtitle: Text(patient.phone),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isToday
                                    ? AppColors.warning.withOpacity(0.12)
                                    : (isPast
                                          ? AppColors.pending.withOpacity(0.1)
                                          : AppColors.primaryBlue.withOpacity(
                                              0.08,
                                            )),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isToday
                                    ? 'Aujourd\'hui'
                                    : dateFormat.format(appointmentDate),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isToday
                                      ? AppColors.warning
                                      : (isPast
                                            ? AppColors.pending
                                            : AppColors.primaryBlue),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Annuler ce rendez-vous',
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: AppColors.pending,
                              ),
                              onPressed: () =>
                                  _confirmCancelAppointment(patient),
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

/// Boîte de dialogue de prise de rendez-vous, utilisée par la réception.
/// Si le numéro de téléphone correspond à un patient existant, son prochain
/// rendez-vous est simplement mis à jour ; sinon un nouveau dossier léger
/// est créé (visible ensuite dans l'archive et la facturation).
class _BookAppointmentDialog extends StatefulWidget {
  final FirestoreService firestoreService;

  const _BookAppointmentDialog({required this.firestoreService});

  @override
  State<_BookAppointmentDialog> createState() => _BookAppointmentDialogState();
}

class _BookAppointmentDialogState extends State<_BookAppointmentDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _conditionController = TextEditingController();
  DateTime? _selectedDate;
  int? _selectedDateCount;
  bool _isCheckingDate = false;
  bool _isSaving = false;
  String? _errorMessage;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedDateCount = null;
        _errorMessage = null;
      });
      _checkDateAvailability(picked);
    }
  }

  Future<void> _checkDateAvailability(DateTime date) async {
    setState(() => _isCheckingDate = true);
    try {
      final count = await widget.firestoreService.countAppointmentsForDate(
        date,
      );
      if (!mounted) return;
      setState(() {
        _selectedDateCount = count;
        _isCheckingDate = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isCheckingDate = false);
    }
  }

  Future<void> _confirm() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      setState(
        () =>
            _errorMessage = 'Veuillez saisir le nom et le numéro de téléphone',
      );
      return;
    }
    if (_selectedDate == null) {
      setState(() => _errorMessage = 'Veuillez choisir la date du rendez-vous');
      return;
    }
    if (_selectedDateCount != null &&
        _selectedDateCount! >= FirestoreService.maxAppointmentsPerDay) {
      setState(
        () => _errorMessage =
            'Ce jour est complet, veuillez choisir une autre date',
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.firestoreService.bookAppointment(
        name: name,
        phone: phone,
        appointmentDate: _selectedDate!,
        condition: _conditionController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rendez-vous enregistré avec succès')),
      );
    } catch (e) {
      setState(() => _errorMessage = 'Erreur lors de l\'enregistrement : $e');
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
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nouveau rendez-vous',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Si le même nom existe déjà avec ce numéro, son rendez-vous sera mis à jour. Sinon, un nouveau dossier est créé (utile pour réserver un enfant avec le téléphone d\'un parent).',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 12),
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
                  'Numéro de téléphone',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),

                const Text(
                  'Date du rendez-vous',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.cardBorder),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: AppColors.textGrey,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _selectedDate != null
                              ? dateFormat.format(_selectedDate!)
                              : 'Choisir une date',
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isCheckingDate) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Vérification de la disponibilité...',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                  ),
                ] else if (_selectedDateCount != null) ...[
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final isFull =
                          _selectedDateCount! >=
                          FirestoreService.maxAppointmentsPerDay;
                      return Text(
                        isFull
                            ? 'Jour complet : $_selectedDateCount/${FirestoreService.maxAppointmentsPerDay} — choisissez une autre date'
                            : '$_selectedDateCount/${FirestoreService.maxAppointmentsPerDay} rendez-vous déjà pris ce jour-là',
                        style: TextStyle(
                          color: isFull ? AppColors.pending : AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ],
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
                    hintText: 'Ex : douleur, contrôle, suivi...',
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppColors.pending,
                      fontSize: 13,
                    ),
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
                          : const Text('Confirmer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
