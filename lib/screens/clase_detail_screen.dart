import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/clase.dart';
import '../models/evaluacion.dart';
import '../models/evaluacion_clase.dart';
import '../models/firma_docente.dart';
import '../services/evaluacion_service.dart';
import '../providers/sesion_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/bloque_card.dart';
import '../widgets/app_brand_title.dart';
import '../widgets/evidence_photos_card.dart';
import '../widgets/signature_capture_dialog.dart';
import 'clase_pdf_preview_screen.dart';

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
    final clase = _buscarClase(widget.evaluacion);
    _observacionesController = TextEditingController(
      text: clase?.observaciones ?? '',
    );
    if (clase == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se encontró esta clase. Regresaremos al listado.',
            ),
          ),
        );
        Navigator.of(context).pop();
      });
    }
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clase = _buscarClase(_evaluacion);
    if (clase == null) {
      return const Scaffold(
        body: Center(child: Text('Esta clase ya no está disponible.')),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).pop(_evaluacion);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const AppBrandTitle(compact: true),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_evaluacion),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Clase ${widget.plantilla.numero}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Marca cada contenido que se enseñó durante la clase.',
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
              'Contenido pendiente',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Text(
                _crearObservacionAutomatica(clase),
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
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Escribe aquí tus observaciones…',
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'Terminar de escribir',
                  onPressed: () =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  icon: const Icon(Icons.check_rounded),
                ),
              ),
              onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
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
                        'Todavía no se han registrado docentes asistentes.',
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
                        onRemove: () => _eliminarFirmaAsistente(index),
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
              onRemove: _eliminarFoto,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _exportarPdfClase,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Generar PDF de esta clase'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  EvaluacionClase? _buscarClase(Evaluacion evaluacion) {
    for (final clase in evaluacion.clases) {
      if (clase.claseNumero == widget.plantilla.numero) return clase;
    }
    return null;
  }

  String _crearObservacionAutomatica(EvaluacionClase clase) {
    final pendientes = <String>[];
    for (final bloque in clase.bloques) {
      if (bloque.itemsMarcados.isEmpty) {
        if (!bloque.marcado) {
          pendientes.add('• ${bloque.bloqueNombre}: no se enseñó.');
        }
        continue;
      }
      final items = bloque.itemsMarcados.entries
          .where((entry) => !entry.value)
          .map((entry) => entry.key)
          .toList();
      if (items.isNotEmpty) {
        pendientes.add('• ${bloque.bloqueNombre}: ${items.join(', ')}.');
      }
    }
    if (pendientes.isEmpty) {
      return 'Se enseñó todo el contenido programado.';
    }
    return 'No se enseñaron los siguientes contenidos:\n${pendientes.join('\n')}';
  }

  Future<void> _exportarPdfClase() async {
    final clase = _buscarClase(_evaluacion);
    if (clase == null) return;
    final usuario = context.read<SesionProvider>().usuarioActual;
    final total = clase.bloques.fold<int>(
      0,
      (suma, bloque) =>
          suma +
          (bloque.itemsMarcados.isEmpty ? 1 : bloque.itemsMarcados.length),
    );
    final realizados = clase.bloques.fold<int>(
      0,
      (suma, bloque) =>
          suma +
          (bloque.itemsMarcados.isEmpty
              ? (bloque.marcado ? 1 : 0)
              : bloque.itemsMarcados.values.where((item) => item).length),
    );
    final continuar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revisar antes de generar'),
        content: Text(
          'Clase ${clase.claseNumero}\n'
          'Contenidos realizados: $realizados de $total\n'
          'Firma del representante: ${clase.firmaDocenteUrl?.isNotEmpty == true ? 'completa' : 'pendiente'}\n'
          'Docentes asistentes: ${clase.firmasAsistentes.length}\n'
          'Fotografías: ${_evaluacion.fotosUrls.length} de 2',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver y corregir'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ver PDF'),
          ),
        ],
      ),
    );
    if (continuar != true || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ClasePdfPreviewScreen(
          evaluacion: _evaluacion,
          clase: clase,
          evaluador: usuario?.nombre ?? 'Sin especificar',
        ),
      ),
    );
  }

  Future<void> _capturarFirmaRepresentante() async {
    final claseActual = _buscarClase(_evaluacion);
    if (claseActual?.firmaDocenteUrl?.isNotEmpty == true) {
      final reemplazar = await _confirmar(
        'Reemplazar firma',
        'Ya existe una firma del docente representante. ¿Deseas reemplazarla?',
      );
      if (!reemplazar || !mounted) return;
    }
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

  Future<void> _eliminarFirmaAsistente(int index) async {
    final confirmar = await _confirmar(
      'Eliminar firma',
      '¿Deseas eliminar este docente asistente y su firma?',
    );
    if (!confirmar || !mounted) return;
    setState(() {
      _evaluacion = widget.service.eliminarFirmaAsistente(
        evaluacion: _evaluacion,
        claseNumero: widget.plantilla.numero,
        index: index,
      );
    });
  }

  Future<void> _eliminarFoto(int index) async {
    final confirmar = await _confirmar(
      'Eliminar evidencia',
      '¿Deseas eliminar esta fotografía? Esta acción no se puede deshacer.',
    );
    if (!confirmar || !mounted) return;
    setState(() {
      _evaluacion = widget.service.eliminarFoto(_evaluacion, index);
    });
  }

  Future<bool> _confirmar(String titulo, String mensaje) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(titulo),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _agregarFirmaAsistente() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final nombre = await showDialog<String>(
      context: context,
      builder: (_) => const _NombreDocenteDialog(),
    );
    if (nombre == null || !mounted) return;

    FocusManager.instance.primaryFocus?.unfocus();
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

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
    try {
      final foto = await _imagePicker.pickImage(
        source: source,
        imageQuality: 78,
        maxWidth: 1600,
      );
      if (foto == null) {
        if (mounted) _mostrarErrorPermiso(source);
        return;
      }
      final base64 = base64Encode(await foto.readAsBytes());
      if (!mounted) return;
      setState(() {
        _evaluacion = widget.service.agregarFoto(_evaluacion, base64);
      });
    } on PlatformException {
      if (mounted) _mostrarErrorPermiso(source);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo agregar la foto.')),
      );
    }
  }

  void _mostrarErrorPermiso(ImageSource source) {
    final recurso = source == ImageSource.camera ? 'la cámara' : 'la galería';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Se necesita acceso a $recurso para agregar una foto. Actívalo en Configuración.',
        ),
      ),
    );
  }
}

class _NombreDocenteDialog extends StatefulWidget {
  const _NombreDocenteDialog();

  @override
  State<_NombreDocenteDialog> createState() => _NombreDocenteDialogState();
}

class _NombreDocenteDialogState extends State<_NombreDocenteDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continuar() {
    final nombre = _controller.text.trim();
    if (nombre.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(nombre);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Docente asistente'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _continuar(),
        decoration: const InputDecoration(labelText: 'Nombre completo'),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _continuar, child: const Text('Continuar')),
      ],
    );
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
                  borderRadius: BorderRadius.circular(AppRadius.small),
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
              label: Text(tieneFirma ? 'Firmar nuevamente' : 'Firmar'),
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
        borderRadius: BorderRadius.circular(AppRadius.small),
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
