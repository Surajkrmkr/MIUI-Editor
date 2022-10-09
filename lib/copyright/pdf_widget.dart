import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';

Future createPdf({String? imgPath, String? themeName}) async {
  final pdf = pw.Document();
  final DateTime now = DateTime.now();
  final DateFormat formatter = DateFormat('d MMMM y');
  final String formatted = formatter.format(now);

  pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a3,
      build: (pw.Context context) {
        return pw.Column(children: [
          pw.Image(pw.MemoryImage(
            File("E:\\Xiaomi Contract\\header.png").readAsBytesSync(),
          )),
          pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Image(
                pw.MemoryImage(
                  File(imgPath!).readAsBytesSync(),
                ),
                fit: pw.BoxFit.cover,
                height: 200,
                width: 200),
          ),
          detailsRow(
              prefix: "License type :",
              suffix: "Free for commercial use WITH ATTRIBUTION license *"),
          detailsRow(
              prefix: "License Author :",
              suffix: "Suraj - MIUI Theme Designer"),
          detailsRow(prefix: "License Theme :", suffix: themeName),
          detailsRow(prefix: "Created date :", suffix: formatted),
          detailsRow(prefix: "Licensee :", suffix: "Team"),
          pw.SizedBox(height: 50),
          pw.Container(
              height: 100,
              width: 1025,
              padding: const pw.EdgeInsets.all(20),
              color: PdfColor.fromHex("#FFEEF8"),
              child: pw.Center(
                  child: pw.Text(
                      "Commercial Registry of Málaga, volume 4994, sheet 217, page number MA-113059, with TaxNumber B-93183366 and registered office at 13 Molina Lario Street, 5th floor, 29015 Málaga, Spain.",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex("#525252")))))
        ]);
      }));
  await Directory(
          "${Directory(imgPath!).parent.parent.parent.path}\\1Copyright\\")
      .create(recursive: true);
  final file = File(
      "${Directory(imgPath).parent.parent.parent.path}\\1Copyright\\$themeName.pdf");
  await file.writeAsBytes(await pdf.save());
}

detailsRow({String? prefix, String? suffix}) {
  return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 5),
      height: 60,
      width: 1025,
      child: pw.Row(children: [
        pw.Container(
            height: 60,
            width: 150,
            padding: const pw.EdgeInsets.all(20),
            color: PdfColor.fromHex("#FFEEF8"),
            child: pw.Text(prefix!,
                style: pw.TextStyle(fontWeight: pw.FontWeight.normal))),
        pw.Expanded(
            child: pw.Container(
                height: 60,
                padding: const pw.EdgeInsets.all(20),
                color: PdfColor.fromHex("#FFDBF1"),
                child: pw.Text(suffix!,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold))))
      ]));
}
