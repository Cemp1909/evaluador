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
  bool _compartiendo = false;

  Future<void> _guardarOCompartir() async {
    if (_compartiendo) return;
    setState(() => _compartiendo = true);
    try {
      final servicio = const PdfExportService();
      final bytes = await servicio.generarReporte(
        widget.reporte,
        resumido: _resumido,
      );
      await servicio.compartirPdf(
        bytes: bytes,
        filename: servicio.nombreArchivoReporte(
          widget.reporte,
          resumido: _resumido,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo compartir el PDF.')),
        );
      }
    } finally {
      if (mounted) setState(() => _compartiendo = false);
    }
  }

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
    bottomNavigationBar: SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: FilledButton.icon(
        onPressed: _compartiendo ? null : _guardarOCompartir,
        icon: _compartiendo
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.ios_share_rounded),
        label: Text(_compartiendo ? 'Preparando PDF…' : 'Guardar o compartir'),
      ),
    ),
  );
}
