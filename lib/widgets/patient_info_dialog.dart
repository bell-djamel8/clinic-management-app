import 'package:flutter/material.dart';
import '../theme.dart';

/// Boîte de dialogue générique affichant une liste de champs
/// "libellé : valeur", utilisée pour consulter les informations d'un
/// patient (depuis la salle d'attente ou les rendez-vous), accessible au
/// médecin comme à la réception.
Future<void> showPatientInfoDialog(
  BuildContext context, {
  required String title,
  required List<MapEntry<String, String>> fields,
}) {
  return showDialog(
    context: context,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            for (final field in fields)
              if (field.value.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field.key,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(field.value, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
