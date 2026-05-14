import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meditrack/features/prescription/domain/entities/drug_item_entity.dart';
import 'package:meditrack/features/prescription/domain/entities/prescription_entity.dart';

/// "Currently active" = Firestore status is active and at least one drug still
/// has remaining doses for **this** prescription. Adherence is scoped per
/// reçete: `prescription_id` on the log, or legacy logs without that field
/// only if [taken_at] is on/after the prescription [createdAt] (so older
/// courses for the same ilaç do not zero out a new reçete).
class PrescriptionStatusHelper {
  PrescriptionStatusHelper._();

  static DateTime? _parseTakenAt(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    return null;
  }

  static bool adherenceDocCountsTowardPrescription(
    Map<String, dynamic> data,
    PrescriptionEntity prescription,
  ) {
    final pid = data['prescription_id'] as String?;
    if (pid == prescription.id) return true;
    if (pid != null && pid.isNotEmpty) return false;

    final takenAt = _parseTakenAt(data['taken_at']);
    if (takenAt == null) return false;
    return !takenAt.isBefore(prescription.createdAt);
  }

  /// Doses attributed to this prescription only (see class doc).
  static Map<String, int> takenDoseCountsForPrescription(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    PrescriptionEntity prescription,
  ) {
    final takenDoseCountsByDrug = <String, int>{};
    for (final doc in docs) {
      final data = doc.data();
      if (!adherenceDocCountsTowardPrescription(data, prescription)) continue;
      final drugKey = data['drug_key'] as String?;
      final doseCount = (data['dose_count'] as num?)?.toInt() ?? 1;
      if (drugKey == null || drugKey.isEmpty) continue;
      takenDoseCountsByDrug[drugKey] =
          (takenDoseCountsByDrug[drugKey] ?? 0) + doseCount;
    }
    return takenDoseCountsByDrug;
  }

  static bool isPrescriptionCurrentlyActive(
    PrescriptionEntity prescription,
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> adherenceDocs,
  ) {
    final taken = takenDoseCountsForPrescription(adherenceDocs, prescription);
    return isCurrentlyActive(prescription, taken);
  }

  static bool isCurrentlyActive(
    PrescriptionEntity prescription,
    Map<String, int> takenDoseCountsByDrug,
  ) {
    if (!prescription.isActive || prescription.drugs.isEmpty) return false;

    for (final drug in prescription.drugs) {
      final totalStock = calculateDosesPerDay(drug.frequency) * drug.durationDays;
      if (totalStock <= 0) continue;
      final takenCount = takenDoseCountsByDrug[drugKey(drug)] ?? 0;
      final remaining = (totalStock - takenCount).clamp(0, totalStock);
      if (remaining > 0) return true;
    }
    return false;
  }

  static int todayTakenForDrug(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    PrescriptionEntity prescription,
    DrugItemEntity drug,
  ) {
    final key = drugKey(drug);
    final now = DateTime.now();
    var sum = 0;
    for (final doc in docs) {
      final data = doc.data();
      if (!adherenceDocCountsTowardPrescription(data, prescription)) continue;
      if ((data['drug_key'] as String?) != key) continue;
      final takenAt = _parseTakenAt(data['taken_at']);
      if (takenAt == null) continue;
      if (takenAt.year != now.year ||
          takenAt.month != now.month ||
          takenAt.day != now.day) {
        continue;
      }
      sum += (data['dose_count'] as num?)?.toInt() ?? 1;
    }
    return sum;
  }

  static String drugKey(DrugItemEntity drug) {
    if (drug.barcode.isNotEmpty) {
      return drug.barcode;
    }
    return '${drug.brandName}_${drug.frequency}_${drug.durationDays}'
        .toLowerCase();
  }

  static int calculateDosesPerDay(String frequency) {
    final normalized = frequency.toLowerCase();

    final turkishDailyMatch = RegExp(r'günde\s*(\d+)').firstMatch(normalized);
    if (turkishDailyMatch != null) {
      return int.tryParse(turkishDailyMatch.group(1) ?? '') ?? 1;
    }

    if (normalized.contains('x')) {
      final parts = normalized.split('x');
      if (parts.length == 2) {
        final times = int.tryParse(parts[0].trim()) ?? 1;
        final dose = int.tryParse(parts[1].trim()) ?? 1;
        return times * dose;
      }
    }

    if (normalized.contains('haftada')) {
      return 1;
    }

    return 1;
  }
}
