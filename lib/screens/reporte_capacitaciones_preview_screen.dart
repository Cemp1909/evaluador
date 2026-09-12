import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/evaluacion.dart';
import '../services/pdf_export_service.dart';

class ReporteCapacitacionesPreviewScreen extends StatefulWidget {
  const ReporteCapacitacionesPreviewScreen({
    super.key,
    required this.evaluaciones,
    required this.inicio,
    required this.fin,
    required this.generadoPor,
  });

  final List<Evaluacion> evaluaciones;
  final DateTime inicio;
  final DateTime fin;
  final String generadoPor;

  @override
  State<ReporteCapacitacionesPreviewScreen> createState() =>
      _ReporteCapacitacionesPreviewScreenState();
}

class _ReporteCapacitacionesPreviewScreenState
    extends State<ReporteCapacitacionesPreviewScreen> {
  bool _compartiendo = false;
  final _servicio = const PdfExportService();

  Future<Uint8List> _generar() => _servicio.generarReporteCapacitaciones(
    evaluaciones: widget.evaluaciones,
    inicio: widget.inicio,
    fin: widget.fin,
    generadoPor: widget.generadoPor,
  );

  Future<void> _guardarOCompartir() async {
    if (_compartiendo) return;
    setState(() => _compartiendo = true);
    try {
      await _servicio.compartirPdf(
        bytes: await _generar(),
        filename: _servicio.nombreArchivoReporteCapacitaciones(
          widget.inicio,
          widget.fin,
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
    appBar: AppBar(title: const Text('Reporte quincenal')),
    body: PdfPreview(
      build: (_) => _generar(),
      pdfFileName: _servicio.nombreArchivoReporteCapacitaciones(
        widget.inicio,
        widget.fin,
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
