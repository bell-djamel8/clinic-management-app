import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/patient.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import 'dashboard_screen.dart' show StatCardMini;

/// Périodes disponibles pour le filtrage des statistiques.
enum StatPeriod { today, week, month, year }

extension on StatPeriod {
  String get label {
    switch (this) {
      case StatPeriod.today:
        return 'Aujourd\'hui';
      case StatPeriod.week:
        return 'Cette semaine';
      case StatPeriod.month:
        return 'Ce mois';
      case StatPeriod.year:
        return 'Cette année';
    }
  }
}

/// Écran Statistiques : indicateurs clés de la clinique (patients, visites,
/// rendez-vous, revenus, services les plus demandés) avec des graphiques
/// simples et un sélecteur de période (jour / semaine / mois / année).
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _firestoreService = FirestoreService();
  StatPeriod _period = StatPeriod.month;

  // ------------------------------------------------------------------
  // Calcul des bornes et des tranches (buckets) selon la période choisie
  // ------------------------------------------------------------------

  DateTime _periodStart(DateTime now) {
    switch (_period) {
      case StatPeriod.today:
        return DateTime(now.year, now.month, now.day);
      case StatPeriod.week:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return DateTime(start.year, start.month, start.day);
      case StatPeriod.month:
        return DateTime(now.year, now.month, 1);
      case StatPeriod.year:
        return DateTime(now.year, 1, 1);
    }
  }

  DateTime _periodEnd(DateTime now) {
    switch (_period) {
      case StatPeriod.today:
        return DateTime(now.year, now.month, now.day + 1);
      case StatPeriod.week:
        final start = _periodStart(now);
        return start.add(const Duration(days: 7));
      case StatPeriod.month:
        return DateTime(now.year, now.month + 1, 1);
      case StatPeriod.year:
        return DateTime(now.year + 1, 1, 1);
    }
  }

  /// Nombre de tranches (barres) et leurs libellés pour le graphique.
  List<String> _bucketLabels(DateTime now) {
    switch (_period) {
      case StatPeriod.today:
        return List.generate(24, (h) => '${h}h');
      case StatPeriod.week:
        const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
        return days;
      case StatPeriod.month:
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        return List.generate(daysInMonth, (d) => '${d + 1}');
      case StatPeriod.year:
        const months = [
          'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
          'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc',
        ];
        return months;
    }
  }

  /// Renvoie l'index de tranche correspondant à une date donnée, ou null
  /// si cette date est hors de la période sélectionnée.
  int? _bucketIndex(DateTime date, DateTime now) {
    final start = _periodStart(now);
    final end = _periodEnd(now);
    if (date.isBefore(start) || !date.isBefore(end)) return null;
    switch (_period) {
      case StatPeriod.today:
        return date.hour;
      case StatPeriod.week:
        return date.difference(start).inDays;
      case StatPeriod.month:
        return date.day - 1;
      case StatPeriod.year:
        return date.month - 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = _periodStart(now);
    final end = _periodEnd(now);
    final currencyFormat = NumberFormat.decimalPattern('fr');

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ContextColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Vue d\'ensemble de l\'activité de la clinique',
            style: TextStyle(color: AppColors.textGrey, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Sélecteur de période
          Wrap(
            spacing: 8,
            children: StatPeriod.values.map((p) {
              final selected = p == _period;
              return ChoiceChip(
                label: Text(p.label),
                selected: selected,
                onSelected: (_) => setState(() => _period = p),
                selectedColor: AppColors.primaryBlue,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : ContextColors.textPrimary(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                backgroundColor: Theme.of(context).cardColor,
                side: BorderSide(color: ContextColors.cardBorder(context)),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: FutureBuilder<List<Patient>>(
              future: _firestoreService.fetchAllPatientsOnce(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final patients = snapshot.data!;

                // Visites (et rendez-vous / paiements) dans la période
                final visitsInPeriod = patients
                    .where(
                      (p) =>
                          !p.visitDate.isBefore(start) &&
                          p.visitDate.isBefore(end),
                    )
                    .toList();

                final newPatientsInPeriod = patients
                    .where(
                      (p) =>
                          !p.createdAt.isBefore(start) &&
                          p.createdAt.isBefore(end),
                    )
                    .length;

                final appointmentsInPeriod = patients.where((p) {
                  final appt = p.nextAppointment;
                  return appt != null &&
                      !appt.isBefore(start) &&
                      appt.isBefore(end);
                }).length;

                final revenue = visitsInPeriod
                    .where((p) => p.billingStatus == 'settled')
                    .fold<double>(0, (sum, p) => sum + p.price);

                final pendingAmount = visitsInPeriod
                    .where((p) => p.billingStatus != 'settled')
                    .fold<double>(0, (sum, p) => sum + p.price);

                // Services / médicaments les plus demandés
                final serviceCounts = <String, int>{};
                for (final p in visitsInPeriod) {
                  for (final med in p.medications) {
                    final name = med.name.trim();
                    if (name.isEmpty) continue;
                    serviceCounts[name] = (serviceCounts[name] ?? 0) + 1;
                  }
                }
                final topServices = serviceCounts.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                // Répartition par tranche (jour / heure / mois) pour les
                // graphiques d'évolution des visites et des revenus
                final labels = _bucketLabels(now);
                final visitCounts = List<double>.filled(labels.length, 0);
                final revenueCounts = List<double>.filled(labels.length, 0);
                for (final p in visitsInPeriod) {
                  final idx = _bucketIndex(p.visitDate, now);
                  if (idx == null || idx >= labels.length) continue;
                  visitCounts[idx] += 1;
                  if (p.billingStatus == 'settled') {
                    revenueCounts[idx] += p.price;
                  }
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cartes d'indicateurs
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 2.4,
                        children: [
                          StatCardMini(
                            label: 'Total des patients',
                            value: '${patients.length}',
                          ),
                          StatCardMini(
                            label: 'Nouveaux patients',
                            value: '$newPatientsInPeriod',
                            accentColor: AppColors.success,
                          ),
                          StatCardMini(
                            label: 'Visites',
                            value: '${visitsInPeriod.length}',
                            accentColor: AppColors.primaryBlue,
                          ),
                          StatCardMini(
                            label: 'Rendez-vous',
                            value: '$appointmentsInPeriod',
                            accentColor: AppColors.warning,
                          ),
                          StatCardMini(
                            label: 'Revenus',
                            value: '${currencyFormat.format(revenue)} DA',
                            accentColor: AppColors.success,
                          ),
                          StatCardMini(
                            label: 'Paiements en attente',
                            value:
                                '${currencyFormat.format(pendingAmount)} DA',
                            accentColor: AppColors.pending,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Graphiques d'évolution
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _MiniBarChart(
                              title: 'Évolution des visites',
                              labels: labels,
                              values: visitCounts,
                              color: AppColors.primaryBlue,
                              valueFormatter: (v) => v.toStringAsFixed(0),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _MiniBarChart(
                              title: 'Évolution des revenus (DA)',
                              labels: labels,
                              values: revenueCounts,
                              color: AppColors.success,
                              valueFormatter: (v) =>
                                  currencyFormat.format(v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Services / examens les plus demandés
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: ContextColors.cardBorder(context),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Services / traitements les plus demandés',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: ContextColors.textPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (topServices.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'Aucune donnée pour cette période',
                                  style: TextStyle(
                                    color: AppColors.textGrey,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            else
                              ...topServices.take(5).map((entry) {
                                final maxCount = topServices.first.value;
                                final ratio = maxCount == 0
                                    ? 0.0
                                    : entry.value / maxCount;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 140,
                                        child: Text(
                                          entry.key,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: ContextColors.textPrimary(
                                              context,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: ratio,
                                            minHeight: 10,
                                            backgroundColor:
                                                AppColors.background,
                                            valueColor:
                                                const AlwaysStoppedAnimation(
                                              AppColors.primaryBlue,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      SizedBox(
                                        width: 28,
                                        child: Text(
                                          '${entry.value}',
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Graphique en barres simple (sans dépendance externe), utilisé pour
/// afficher l'évolution des visites et des revenus sur la période choisie.
class _MiniBarChart extends StatelessWidget {
  final String title;
  final List<String> labels;
  final List<double> values;
  final Color color;
  final String Function(double) valueFormatter;

  const _MiniBarChart({
    required this.title,
    required this.labels,
    required this.values,
    required this.color,
    required this.valueFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a > b ? a : b);
    // N'affiche pas tous les libellés s'il y en a trop (ex : 31 jours)
    final labelStep = (labels.length / 8).ceil().clamp(1, 999);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ContextColors.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: ContextColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            maxValue == 0
                ? 'Aucune donnée pour cette période'
                : 'Maximum : ${valueFormatter(maxValue)}',
            style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: maxValue == 0
                ? const SizedBox.shrink()
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(values.length, (i) {
                      final heightRatio =
                          maxValue == 0 ? 0.0 : values[i] / maxValue;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                height: 96 * heightRatio,
                                decoration: BoxDecoration(
                                  color: values[i] == 0
                                      ? color.withOpacity(0.12)
                                      : color,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(3),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                height: 14,
                                child: i % labelStep == 0
                                    ? Text(
                                        labels[i],
                                        style: const TextStyle(
                                          fontSize: 8,
                                          color: AppColors.textGrey,
                                        ),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }
}
