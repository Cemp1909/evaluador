import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/evaluacion.dart';
import '../models/evaluacion_clase.dart';
import '../services/pdf_export_service.dart';

class ClasePdfPreviewScreen extends StatelessWidget {
  const ClasePdfPreviewScreen({
    super.key,
    required this.evaluacion,
    required this.clase,
    required this.evaluador,
  });

  final Evaluacion evaluacion;
  final EvaluacionClase clase;
  final String evaluador;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Vista previa · Clase ${clase.claseNumero}')),
    body: PdfPreview(
      build: (_) => const PdfExportService().generarClase(
        evaluacion: evaluacion,
        clase: clase,
        evaluador: evaluador,
      ),
      pdfFileName: '${evaluacion.evaluadorTipo}_clase_${clase.claseNumero}.pdf',
      canChangePageFormat: false,
      canChangeOrientation: false,
      canDebug: false,
      allowPrinting: true,
      allowSharing: true,
    ),
  );
}
