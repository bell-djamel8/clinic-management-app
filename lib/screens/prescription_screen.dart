import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/patient.dart';
import '../theme.dart';

/// Informations de la clinique et de la doctoresse, reprenant fidèlement
/// le contenu du papier à en-tête officiel du cabinet (logo, texte arabe
/// et français, adresse en pied de page).

class ClinicInfo {
  static const doctorNameArabic = 'Doctor Name';
  static const specialtyArabic = 'Medical Specialty';
  static const specialtyFrench = 'Medical Specialty';
  static const phone = 'Phone Number';
  static const city = 'City';
  static const addressArabic = 'Clinic Address';
  static const logoAssetPath = 'assets/images/logo.png';
  static const arabicFontRegularPath = 'assets/fonts/Cairo-Regular.ttf';
  static const arabicFontBoldPath = 'assets/fonts/Cairo-Bold.ttf';
}

/// Bleu marine utilisé sur le papier à en-tête original (identique au bleu
/// principal de l'application, [AppColors.primaryBlueDark]).
const PdfColor _navyPdf = PdfColor.fromInt(0xFF13408A);

class PrescriptionScreen extends StatelessWidget {
  final Patient patient;

  const PrescriptionScreen({super.key, required this.patient});

  Future<Uint8List> _generatePdf() async {
    final doc = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final today = dateFormat.format(DateTime.now());

    // Police supportant l'arabe et le français, utilisée pour toute
    // l'ordonnance (nécessaire : les polices de base du PDF ne savent pas
    // afficher l'arabe).
    final arabicRegular = pw.Font.ttf(
      await rootBundle.load(ClinicInfo.arabicFontRegularPath),
    );
    final arabicBold = pw.Font.ttf(
      await rootBundle.load(ClinicInfo.arabicFontBoldPath),
    );
    final logoData = await rootBundle.load(ClinicInfo.logoAssetPath);
    final logoBytes = logoData.buffer.asUint8List(
      logoData.offsetInBytes,
      logoData.lengthInBytes,
    );
    final logoImage = pw.MemoryImage(logoBytes);

    final nomValue = patient.nom.isNotEmpty ? patient.nom : patient.name;
    final prenomValue = patient.prenom;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        theme: pw.ThemeData.withFont(base: arabicRegular, bold: arabicBold),
        margin: const pw.EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête du cabinet : identité (gauche), logo (centre),
              // date et identité du patient (droite) — fidèle au papier
              // à en-tête original.
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 5,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Directionality(
                          textDirection: pw.TextDirection.rtl,
                          child: pw.Text(
                            ClinicInfo.doctorNameArabic,
                            style: pw.TextStyle(
                              fontSize: 12.5,
                              fontWeight: pw.FontWeight.bold,
                              color: _navyPdf,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Directionality(
                          textDirection: pw.TextDirection.rtl,
                          child: pw.Text(
                            ClinicInfo.specialtyArabic,
                            style: pw.TextStyle(fontSize: 8, color: _navyPdf),
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          ClinicInfo.specialtyFrench,
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontStyle: pw.FontStyle.italic,
                            color: _navyPdf,
                          ),
                        ),
                        pw.SizedBox(height: 7),
                        pw.Row(
                          children: [
                            pw.Container(
                              width: 4,
                              height: 4,
                              decoration: const pw.BoxDecoration(
                                color: _navyPdf,
                                shape: pw.BoxShape.circle,
                              ),
                            ),
                            pw.SizedBox(width: 5),
                            pw.Text(
                              ClinicInfo.phone,
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: _navyPdf,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.Container(
                    margin: const pw.EdgeInsets.symmetric(horizontal: 6),
                    width: 52,
                    height: 52,
                    child: pw.Image(logoImage),
                  ),
                  pw.Expanded(
                    flex: 5,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          '${ClinicInfo.city}, le : $today',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontStyle: pw.FontStyle.italic,
                            color: _navyPdf,
                          ),
                        ),
                        pw.SizedBox(height: 7),
                        pw.Text(
                          'Nom : $nomValue',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontStyle: pw.FontStyle.italic,
                            color: _navyPdf,
                          ),
                        ),
                        pw.SizedBox(height: 7),
                        pw.Text(
                          'Prénom : $prenomValue',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontStyle: pw.FontStyle.italic,
                            color: _navyPdf,
                          ),
                        ),
                        pw.SizedBox(height: 7),
                        pw.Text(
                          'Âge : ${patient.age}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontStyle: pw.FontStyle.italic,
                            color: _navyPdf,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Titre
              pw.Center(
                child: pw.Text(
                  'O R D O N N A N C E',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: _navyPdf,
                    decoration: pw.TextDecoration.underline,
                    decorationColor: _navyPdf,
                  ),
                ),
              ),
              pw.SizedBox(height: 16),

              // Liste des médicaments
              ...patient.medications.map(
                (med) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            pw.TextSpan(
                              text: med.name,
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.black,
                              ),
                            ),
                            if (med.quantity.isNotEmpty)
                              pw.TextSpan(
                                text: '   Qté : ${med.quantity}',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.black,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (med.instructions.isNotEmpty)
                        pw.Text(
                          med.instructions,
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.black,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (patient.medications.isEmpty)
                pw.Text(
                  'Aucun médicament enregistré',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),

              pw.Spacer(),

              // Pied de page : adresse du cabinet, fidèle au papier
              // à en-tête original.
              pw.Divider(color: PdfColors.grey400),
              pw.Text(
                'Valable 30 jours à partir de la date de visite ci-dessus',
                style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text(
                        ClinicInfo.addressArabic,
                        style: pw.TextStyle(fontSize: 8.5, color: _navyPdf),
                      ),
                      pw.SizedBox(width: 5),
                      pw.Container(
                        width: 4,
                        height: 4,
                        decoration: const pw.BoxDecoration(
                          color: _navyPdf,
                          shape: pw.BoxShape.circle,
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
    );

    return doc.save();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final today = dateFormat.format(DateTime.now());
    const navy = AppColors.primaryBlueDark;
    final nomValue = patient.nom.isNotEmpty ? patient.nom : patient.name;
    final prenomValue = patient.prenom;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlueDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: ElevatedButton.icon(
          onPressed: () async {
            await Printing.layoutPdf(
              onLayout: (_) => _generatePdf(),
              format: PdfPageFormat.a5,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE3F1FF),
            foregroundColor: AppColors.primaryBlueDark,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.print, size: 18),
          label: const Text(
            'Imprimer l\'ordonnance',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 650,
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête du cabinet : identité (gauche), logo (centre),
                // date et identité du patient (droite)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Directionality(
                            textDirection: ui.TextDirection.rtl,
                            child: const Text(
                              ClinicInfo.doctorNameArabic,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: navy,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Directionality(
                            textDirection: ui.TextDirection.rtl,
                            child: const Text(
                              ClinicInfo.specialtyArabic,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: navy,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            ClinicInfo.specialtyFrench,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11.5,
                              fontStyle: FontStyle.italic,
                              color: navy,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: navy,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                ClinicInfo.phone,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: navy,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Image.asset(
                        ClinicInfo.logoAssetPath,
                        width: 72,
                        height: 72,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${ClinicInfo.city}, le : $today',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: navy,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Nom : $nomValue',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: navy,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Prénom : $prenomValue',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: navy,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Âge : ${patient.age}',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Titre
                const Center(
                  child: Text(
                    'O R D O N N A N C E',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: navy,
                      decoration: TextDecoration.underline,
                      decorationColor: navy,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(thickness: 1, color: Colors.black26),
                const SizedBox(height: 24),

                for (final med in patient.medications)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: med.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black,
                                ),
                              ),
                              if (med.quantity.isNotEmpty)
                                TextSpan(
                                  text: '   Qté : ${med.quantity}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.black,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (med.instructions.isNotEmpty)
                          Text(
                            med.instructions,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                if (patient.medications.isEmpty)
                  const Text(
                    'Aucun médicament enregistré',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                const SizedBox(height: 24),
                const Divider(thickness: 1, color: Colors.black12),
                const SizedBox(height: 8),
                const Text(
                  'Valable 30 jours à partir de la date de visite ci-dessus',
                  style: TextStyle(fontSize: 11, color: AppColors.textGrey),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Directionality(
                    textDirection: ui.TextDirection.rtl,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          ClinicInfo.addressArabic,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            color: navy,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: navy,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
