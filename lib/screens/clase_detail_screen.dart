import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/clase.dart';
import '../models/evaluacion.dart';
import '../models/firma_docente.dart';
import '../services/evaluacion_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bloque_card.dart';
import '../widgets/evidence_photos_card.dart';
import '../widgets/signature_capture_dialog.dart';

class ClaseDetailScreen extends StatefulWidget {
  const ClaseDetailScreen({
    super.key,
    required this.plantilla,
    required this.evaluacion,
    required this.service,
  });

  final Clase plantilla;
  final Evaluacion evaluacion;
  final EvaluacionService service;

  @override
  State<ClaseDetailScreen> createState() => _ClaseDetailScreenState();
}

class _ClaseDetailScreenState extends State<ClaseDetailScreen> {
  late Evaluacion _evaluacion = widget.evaluacion;
  late final TextEditingController _observacionesController;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final clase = widget.evaluacion.clases.firstWhere(
      (clase) => clase.claseNumero == widget.plantilla.numero,
    );
    _observacionesController = TextEditingController(text: clase.observaciones);
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clase = _evaluacion.clases.firstWhere(
      (clase) => clase.claseNumero == widget.plantilla.numero,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).pop(_evaluacion);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Clase ${widget.plantilla.numero}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_evaluacion),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Marca cada contenido que fue enseñado durante la clase.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            for (
              var index = 0;
              index < widget.plantilla.bloques.length;
              index++
            )
              BloqueCard(
                bloque: widget.plantilla.bloques[index],
                marcado: clase.bloques[index].marcado,
                itemsMarcados: clase.bloques[index].itemsMarcados,
                onItemChanged: (itemTexto, marcado) {
                  setState(() {
                    _evaluacion = widget.service.actualizarItem(
                      evaluacion: _evaluacion,
                      claseNumero: widget.plantilla.numero,
                      bloqueNombre: widget.plantilla.bloques[index].nombre,
                      itemTexto: itemTexto,
                      marcado: marcado,
                    );
                  });
                },
                onBloqueChanged: (marcado) {
                  setState(() {
                    _evaluacion = widget.service.actualizarBloque(
                      evaluacion: _evaluacion,
                      claseNumero: widget.plantilla.numero,
                      bloqueNombre: widget.plantilla.bloques[index].nombre,
                      marcado: marcado,
                    );
                  });
                },
              ),
            const SizedBox(height: 8),
            Text(
              'Contenidos pendientes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Text(
                widget.service.crearObservacionAutomatica(clase),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Observaciones de la clase',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Agrega comentarios, novedades o recomendaciones para esta clase.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _observacionesController,
              minLines: 4,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Escribe aquí las observaciones…',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (texto) {
                _evaluacion = widget.service.actualizarObservaciones(
                  evaluacion: _evaluacion,
                  claseNumero: widget.plantilla.numero,
                  observaciones: texto,
                );
              },
            ),
            const SizedBox(height: 28),
            Text(
              'Firmas de asistencia',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _FirmaCard(
              titulo: 'Docente representante',
              firmaBase64: clase.firmaDocenteUrl,
              onFirmar: _capturarFirmaRepresentante,
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.groups_2_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Docentes asistentes',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                    if (clase.firmasAsistentes.isEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Aún no hay docentes asistentes registrados.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    for (
                      var index = 0;
                      index < clase.firmasAsistentes.length;
                      index++
                    ) ...[
                      const SizedBox(height: 14),
                      _FirmaPreview(
                        firma: clase.firmasAsistentes[index],
                        onRemove: () => setState(() {
                          _evaluacion = widget.service.eliminarFirmaAsistente(
                            evaluacion: _evaluacion,
                            claseNumero: widget.plantilla.numero,
                            index: index,
                          );
                        }),
                      ),
                    ],
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _agregarFirmaAsistente,
                      icon: const Icon(Icons.draw_outlined),
                      label: const Text('Agregar docente y firma'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            EvidencePhotosCard(
              fotosBase64: _evaluacion.fotosUrls,
              onAdd: _seleccionarOrigenFoto,
              onRemove: (index) => setState(() {
                _evaluacion = widget.service.eliminarFoto(_evaluacion, index);
              }),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _capturarFirmaRepresentante() async {
    final firma = await SignatureCaptureDialog.show(
      context,
      'Firma del docente representante',
    );
    if (firma == null || !mounted) return;
    setState(() {
      _evaluacion = widget.service.actualizarFirmaRepresentante(
        evaluacion: _evaluacion,
        claseNumero: widget.plantilla.numero,
        firmaBase64: firma,
      );
    });
  }

  Future<void> _agregarFirmaAsistente() async {
    final nombreController = TextEditingController();
    final nombre = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Docente asistente'),
        content: TextField(
          controller: nombreController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nombre completo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final valor = nombreController.text.trim();
              if (valor.isNotEmpty) Navigator.pop(context, valor);
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    nombreController.dispose();
    if (nombre == null || !mounted) return;

    final firma = await SignatureCaptureDialog.show(
      context,
      'Firma de $nombre',
    );
    if (firma == null || !mounted) return;
    setState(() {
      _evaluacion = widget.service.agregarFirmaAsistente(
        evaluacion: _evaluacion,
        claseNumero: widget.plantilla.numero,
        firma: FirmaDocente(nombre: nombre, firmaBase64: firma),
      );
    });
  }

  Future<void> _seleccionarOrigenFoto() async {
    if (_evaluacion.fotosUrls.length >= 2) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Agregar evidencia',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar foto'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir de la galería'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;
    final foto = await _imagePicker.pickImage(
      source: source,
      imageQuality: 78,
      maxWidth: 1600,
    );
    if (foto == null || !mounted) return;
    final base64 = base64Encode(await foto.readAsBytes());
    setState(() {
      _evaluacion = widget.service.agregarFoto(_evaluacion, base64);
    });
  }
}

class _FirmaCard extends StatelessWidget {
  const _FirmaCard({
    required this.titulo,
    required this.firmaBase64,
    required this.onFirmar,
  });

  final String titulo;
  final String? firmaBase64;
  final VoidCallback onFirmar;

  @override
  Widget build(BuildContext context) {
    final tieneFirma = firmaBase64 != null && firmaBase64!.isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.draw_outlined, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titulo,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (tieneFirma)
                  const Chip(
                    avatar: Icon(Icons.check_circle_outline, size: 18),
                    label: Text('Firmado'),
                    side: BorderSide.none,
                    backgroundColor: AppColors.successContainer,
                  ),
              ],
            ),
            if (tieneFirma) ...[
              const SizedBox(height: 14),
              Container(
                height: 120,
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Image.memory(
                  base64Decode(firmaBase64!),
                  fit: BoxFit.contain,
                ),
              ),
            ],
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onFirmar,
              icon: const Icon(Icons.edit_outlined),
              label: Text(tieneFirma ? 'Repetir firma' : 'Firmar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FirmaPreview extends StatelessWidget {
  const _FirmaPreview({required this.firma, required this.onRemove});

  final FirmaDocente firma;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firma.nombre,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 72,
                  child: Image.memory(
                    base64Decode(firma.firmaBase64),
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Eliminar firma',
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}
