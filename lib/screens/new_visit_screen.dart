import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/patient.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import 'prescription_screen.dart';

class NewVisitScreen extends StatefulWidget {
  const NewVisitScreen({super.key});

  @override
  State<NewVisitScreen> createState() => _NewVisitScreenState();
}

class _NewVisitScreenState extends State<NewVisitScreen> {
  final _firestoreService = FirestoreService();

  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _wilayaController = TextEditingController();
  final _conditionController = TextEditingController();
  final _priceController = TextEditingController();

  DateTime? _nextAppointment;

  final List<TextEditingController> _medNameControllers = [
    TextEditingController(),
  ];
  final List<TextEditingController> _medInstructionControllers = [
    TextEditingController(),
  ];
  final List<TextEditingController> _medQuantityControllers = [
    TextEditingController(),
  ];

  bool _isSaving = false;

  void _addMedicationField() {
    setState(() {
      _medNameControllers.add(TextEditingController());
      _medInstructionControllers.add(TextEditingController());
      _medQuantityControllers.add(TextEditingController());
    });
  }

  void _removeMedicationField(int index) {
    setState(() {
      _medNameControllers.removeAt(index);
      _medInstructionControllers.removeAt(index);
      _medQuantityControllers.removeAt(index);
    });
  }

  Future<void> _pickNextAppointment() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _nextAppointment = picked);
    }
  }

  Patient? _buildPatientFromForm() {
    final nom = _nomController.text.trim();
    final prenom = _prenomController.text.trim();

    if (nom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir le nom du patient')),
      );
      return null;
    }

    final medications = <Medication>[];
    for (var i = 0; i < _medNameControllers.length; i++) {
      final name = _medNameControllers[i].text.trim();
      if (name.isNotEmpty) {
        medications.add(
          Medication(
            name: name,
            instructions: _medInstructionControllers[i].text.trim(),
            quantity: _medQuantityControllers[i].text.trim(),
          ),
        );
      }
    }

    return Patient(
      name: [prenom, nom].where((s) => s.isNotEmpty).join(' '),
      nom: nom,
      prenom: prenom,
      phone: _phoneController.text.trim(),
      age: _ageController.text.trim(),
      wilaya: _wilayaController.text.trim(),
      condition: _conditionController.text.trim(),
      visitDate: DateTime.now(),
      nextAppointment: _nextAppointment,
      medications: medications,
      price: double.tryParse(_priceController.text.trim()) ?? 0,
    );
  }

  /// Enregistre le patient dans l'archive sans ouvrir l'ordonnance
  /// (utile quand aucun médicament n'est prescrit).
  Future<void> _saveOnly() async {
    final patient = _buildPatientFromForm();
    if (patient == null) return;

    setState(() => _isSaving = true);
    try {
      await _firestoreService.addPatient(patient);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient enregistré avec succès')),
      );
      _clearForm();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Enregistre le patient puis ouvre l'ordonnance prête à imprimer.
  Future<void> _saveAndPrint() async {
    final patient = _buildPatientFromForm();
    if (patient == null) return;

    setState(() => _isSaving = true);

    try {
      await _firestoreService.addPatient(patient);
      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PrescriptionScreen(patient: patient)),
      );

      _clearForm();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _clearForm() {
    _nomController.clear();
    _prenomController.clear();
    _phoneController.clear();
    _ageController.clear();
    _wilayaController.clear();
    _conditionController.clear();
    _priceController.clear();
    setState(() {
      _nextAppointment = null;
      _medNameControllers
        ..clear()
        ..add(TextEditingController());
      _medInstructionControllers
        ..clear()
        ..add(TextEditingController());
      _medQuantityControllers
        ..clear()
        ..add(TextEditingController());
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

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
                      'Nouvelle visite',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Assurez-vous de saisir toutes les informations médicales et l\'ordonnance avec précision',
                      style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : _saveOnly,
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Enregistrer'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveAndPrint,
                    icon: _isSaving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.print_outlined, size: 18),
                    label: const Text('Enregistrer et imprimer'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column: patient identity
                  Expanded(
                    child: _SectionCard(
                      title: 'Informations du patient',
                      icon: Icons.person_outline,
                      children: [
                        _buildLabel('Nom'),
                        TextField(controller: _nomController),
                        const SizedBox(height: 14),
                        _buildLabel('Prénom'),
                        TextField(controller: _prenomController),
                        const SizedBox(height: 14),
                        _buildLabel('Numéro de téléphone'),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Âge'),
                                  TextField(
                                    controller: _ageController,
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Wilaya'),
                                  TextField(controller: _wilayaController),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Right column: clinical notes and next appointment
                  Expanded(
                    child: _SectionCard(
                      title: 'Observations cliniques',
                      icon: Icons.medical_information_outlined,
                      children: [
                        _buildLabel('État et symptômes'),
                        TextField(
                          controller: _conditionController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText:
                                'Décrivez l\'état actuel et les principaux symptômes...',
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildLabel('Date du prochain rendez-vous'),
                        _DatePickerField(
                          value: _nextAppointment != null
                              ? dateFormat.format(_nextAppointment!)
                              : 'Choisir une date (optionnel)',
                          onTap: _pickNextAppointment,
                        ),
                        const SizedBox(height: 14),
                        _buildLabel('Montant (DA)'),
                        TextField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Prescribed medications section
          _SectionCard(
            title: 'Médicaments prescrits',
            icon: Icons.medication_outlined,
            trailing: TextButton.icon(
              onPressed: _addMedicationField,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Ajouter un médicament'),
            ),
            children: [
              for (var i = 0; i < _medNameControllers.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _medNameControllers[i],
                          decoration: const InputDecoration(
                            hintText: 'Nom du médicament et dosage',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _medInstructionControllers[i],
                          decoration: const InputDecoration(
                            hintText: 'Mode d\'emploi',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _medQuantityControllers[i],
                          decoration: const InputDecoration(
                            hintText: 'Quantité remise par le pharmacien',
                          ),
                        ),
                      ),
                      if (_medNameControllers.length > 1)
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: AppColors.pending,
                          ),
                          onPressed: () => _removeMedicationField(i),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ContextColors.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String value;
  final VoidCallback onTap;

  const _DatePickerField({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(color: ContextColors.cardBorder(context)),
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
            Text(value),
          ],
        ),
      ),
    );
  }
}
