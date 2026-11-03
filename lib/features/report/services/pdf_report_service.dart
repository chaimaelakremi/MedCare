import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../medications/data/medication_model.dart';

class PdfReportService {
  static Future<void> generateAndShare(
    List<IntakeLog> logs,
    AppLocalizations l10n,
  ) async {
    final doc = pw.Document();
    final now = DateTime.now();
    final dateRange =
        '${DateFormat('dd/MM/yyyy').format(now.subtract(const Duration(days: 7)))} – '
        '${DateFormat('dd/MM/yyyy').format(now)}';

    final taken = logs.where((l) => l.status == 'taken').length;
    final missed = logs.where((l) => l.status == 'missed').length;
    final total = logs.length;
    final rate = total > 0 ? (taken / total * 100).round() : 0;

    final byMed = <String, Map<String, int>>{};
    for (final log in logs) {
      byMed.putIfAbsent(log.medicationName, () => {'taken': 0, 'missed': 0});
      if (log.status == 'taken') byMed[log.medicationName]!['taken'] = byMed[log.medicationName]!['taken']! + 1;
      if (log.status == 'missed') byMed[log.medicationName]!['missed'] = byMed[log.medicationName]!['missed']! + 1;
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 16),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.purple200, width: 2)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('MedCare',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF9B7EBD),
                      )),
                  pw.Text('Rapport hebdomadaire',
                      style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey600)),
                ],
              ),
              pw.Text(dateRange,
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey500)),
            ],
          ),
        ),
        build: (ctx) => [
          pw.SizedBox(height: 24),
          pw.Text('Résumé de la semaine',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF8F4FF),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _statBlock('$rate%', "Taux d'observance", PdfColors.purple700),
                _statBlock('$taken', 'Médicaments pris', PdfColors.green700),
                _statBlock('$missed', 'Médicaments oubliés', PdfColors.red700),
                _statBlock('$total', 'Total planifiés', PdfColors.grey700),
              ],
            ),
          ),
          pw.SizedBox(height: 28),
          pw.Text('Détail par médicament',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF9B7EBD),
                ),
                children: [
                  _cell('Médicament', isHeader: true),
                  _cell('Pris', isHeader: true),
                  _cell('Oubliés', isHeader: true),
                  _cell('Observance', isHeader: true),
                ],
              ),
              ...byMed.entries.map((e) {
                final t = e.value['taken']!;
                final m = e.value['missed']!;
                final r = (t + m) > 0 ? (t / (t + m) * 100).round() : 0;
                return pw.TableRow(children: [
                  _cell(e.key),
                  _cell('$t'),
                  _cell('$m'),
                  _cell('$r%'),
                ]);
              }),
            ],
          ),
          pw.SizedBox(height: 28),
          pw.Text('Historique quotidien',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          ...List.generate(7, (i) {
            final day = now.subtract(Duration(days: 6 - i));
            final dateStr = DateFormat('yyyy-MM-dd').format(day);
            final dayLabel = DateFormat('EEEE d MMMM', 'fr_FR').format(day);
            final dayLogs = logs.where((l) => l.date == dateStr).toList();
            final dayTaken = dayLogs.where((l) => l.status == 'taken').length;
            final dayTotal = dayLogs.length;
            final dayRate = dayTotal > 0
                ? (dayTaken / dayTotal * 100).round()
                : 0;

            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Row(children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(dayLabel,
                      style: const pw.TextStyle(fontSize: 12)),
                ),
                pw.Expanded(
                  child: pw.Text('$dayTaken/$dayTotal',
                      style: const pw.TextStyle(fontSize: 12)),
                ),
                pw.Expanded(
                  child: pw.Text('$dayRate%',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: dayRate >= 70 ? PdfColors.green700 : PdfColors.red700,
                      )),
                ),
              ]),
            );
          }),
          pw.SizedBox(height: 32),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Text(
              '⚠️ Ce rapport est généré automatiquement par MedCare. '
              'Il ne remplace pas l\'avis d\'un professionnel de santé.',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    final filename =
        'MedCare_Rapport_${DateFormat('yyyy-MM-dd').format(now)}.pdf';
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  static pw.Widget _statBlock(String value, String label, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 22, fontWeight: pw.FontWeight.bold, color: color)),
        pw.SizedBox(height: 4),
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center),
      ],
    );
  }

  static pw.Widget _cell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: isHeader ? pw.FontWeight.bold : null,
          color: isHeader ? PdfColors.white : PdfColors.black,
        ),
      ),
    );
  }
}
