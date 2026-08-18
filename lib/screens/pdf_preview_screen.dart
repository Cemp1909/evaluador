import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/student_knowledge_report.dart';
import '../services/pdf_export_service.dart';

class PdfPreviewScreen extends StatefulWidget {
  const PdfPreviewScreen({super.key, required this.reporte});

  final StudentKnowledgeReport reporte;

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  bool _resumido = true;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Vista previa del PDF'),
      actions: [
        PopupMenuButton<bool>(
          initialValue: _resumido,
          onSelected: (value) => setState(() => _resumido = value),
          itemBuilder: (_) => const [
            PopupMenuItem(value: true, child: Text('Informe resumido')),
            PopupMenuItem(value: false, child: Text('Informe detallado')),
          ],
        ),
      ],
    ),
    body: PdfPreview(
      key: ValueKey(_resumido),
      build: (_) => const PdfExportService().generarReporte(
        widget.reporte,
        resumido: _resumido,
      ),
      pdfFileName: const PdfExportService().nombreArchivoReporte(
        widget.reporte,
        resumido: _resumido,
      ),
      canChangePageFormat: false,
      canChangeOrientation: false,
      canDebug: false,
      allowPrinting: true,
      allowSharing: true,
    ),
  );
}
