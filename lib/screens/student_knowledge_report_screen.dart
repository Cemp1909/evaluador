import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../config/plan_estudio_parvulos.dart';
import '../config/planes_estudio_adicionales.dart';
import '../models/student_knowledge_report.dart';
import '../providers/sesion_provider.dart';
import '../theme/app_theme.dart';
import '../services/pdf_export_service.dart';
import '../widgets/report_signature_card.dart';
import '../widgets/evidence_photos_card.dart';
import '../widgets/signature_capture_dialog.dart';
import '../widgets/app_brand_title.dart';

class StudentKnowledgeReportScreen extends StatefulWidget {
  const StudentKnowledgeReportScreen({super.key});

  static const routeName = '/student_knowledge_report';

  @override
  State<StudentKnowledgeReportScreen> createState() =>
      _StudentKnowledgeReportScreenState();
}

class _StudentKnowledgeReportScreenState
    extends State<StudentKnowledgeReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _colegioController = TextEditingController();
  final _profesorEvaluadoController = TextEditingController();
  final _compromisoController = TextEditingController();
  final DateTime _fechaHora = DateTime.now();
  CalificacionConocimiento? _calificacion;
  int _periodo = 1;
  String _grado = 'Párvulos';
  final Set<String> _itemsAprobados = {};
  String? _firmaColegio;
  String? _firmaDocenteColegio;
  String? _firmaCourseChild;
  final _imagePicker = ImagePicker();
  final List<String> _fotosEvidencia = [];

  @override
  void dispose() {
    _colegioController.dispose();
    _profesorEvaluadoController.dispose();
    _compromisoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<SesionProvider>().usuarioActual;
    final docente = usuario?.nombre ?? 'Sin sesión activa';
    final plan = planesEstudioPorGrado[_grado]![_periodo]!;

    return Scaffold(
      appBar: AppBar(title: const AppBrandTitle(compact: true)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Text(
              'Evaluación de conocimiento del estudiante',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Selecciona el grado y el período para cargar el plan de estudio correspondiente.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Información de la visita',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Fecha',
                      value: _fecha(_fechaHora),
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.schedule_rounded,
                      label: 'Hora',
                      value: _hora(_fechaHora),
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Docente de Course Child',
                      value: docente,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<int>(
              initialValue: _periodo,
              decoration: const InputDecoration(
                labelText: 'Período de evaluación',
                prefixIcon: Icon(Icons.calendar_view_month_outlined),
              ),
              items: [
                for (var periodo = 1; periodo <= 4; periodo++)
                  DropdownMenuItem(
                    value: periodo,
                    child: Text('Período $periodo'),
                  ),
              ],
              onChanged: (value) => setState(() {
                _periodo = value ?? 1;
                _itemsAprobados.clear();
              }),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _profesorEvaluadoController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Docente evaluado',
                prefixIcon: Icon(Icons.person_search_outlined),
              ),
              validator: _requerido,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _colegioController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Colegio',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              validator: _requerido,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _grado,
              decoration: const InputDecoration(
                labelText: 'Grado',
                prefixIcon: Icon(Icons.class_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'Párvulos', child: Text('Párvulos')),
                DropdownMenuItem(value: 'Prejardín', child: Text('Prejardín')),
                DropdownMenuItem(value: 'Jardín', child: Text('Jardín')),
                DropdownMenuItem(
                  value: 'Transición',
                  child: Text('Transición'),
                ),
              ],
              onChanged: (value) => setState(() {
                _grado = value ?? 'Párvulos';
                _itemsAprobados.clear();
              }),
            ),
            const SizedBox(height: 28),
            Text(
              'Plan de estudio · Período $_periodo',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Marca cada contenido que el estudiante reconoce o realiza correctamente.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            for (final categoria in plan.categorias) ...[
              _CategoriaPlanCard(
                categoria: categoria,
                periodo: _periodo,
                seleccionados: _itemsAprobados,
                onChanged: (id, seleccionado) => setState(() {
                  if (seleccionado) {
                    _itemsAprobados.add(id);
                  } else {
                    _itemsAprobados.remove(id);
                  }
                }),
              ),
              const SizedBox(height: 14),
            ],
            Text(
              'Contenido no evaluado',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Text(
                _observacionAutomatica(plan),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _compromisoController,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Recomendaciones y compromiso',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.handshake_outlined),
              ),
              validator: _requerido,
            ),
            const SizedBox(height: 28),
            Text(
              'Calificación general',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _RatingOption(
                    label: 'Bajo\n20–59%',
                    selected: _calificacion == CalificacionConocimiento.low,
                    onTap: () => _seleccionar(CalificacionConocimiento.low),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _RatingOption(
                    label: 'Regular\n60–79%',
                    selected: _calificacion == CalificacionConocimiento.regular,
                    onTap: () => _seleccionar(CalificacionConocimiento.regular),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _RatingOption(
                    label: 'Alto\n80–100%',
                    selected: _calificacion == CalificacionConocimiento.high,
                    onTap: () => _seleccionar(CalificacionConocimiento.high),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text('Firmas', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            ReportSignatureCard(
              titulo: 'Firma del colegio',
              firmaBase64: _firmaColegio,
              onFirmar: () => _firmar(
                'Firma del colegio',
                (firma) => _firmaColegio = firma,
              ),
            ),
            const SizedBox(height: 14),
            ReportSignatureCard(
              titulo: 'Docente del colegio',
              firmaBase64: _firmaDocenteColegio,
              onFirmar: () => _firmar(
                'Firma del docente del colegio',
                (firma) => _firmaDocenteColegio = firma,
              ),
            ),
            const SizedBox(height: 14),
            ReportSignatureCard(
              titulo: 'Docente de Course Child',
              nombre: docente,
              firmaBase64: _firmaCourseChild,
              onFirmar: () => _firmar(
                'Firma de $docente',
                (firma) => _firmaCourseChild = firma,
              ),
            ),
            const SizedBox(height: 18),
            EvidencePhotosCard(
              fotosBase64: _fotosEvidencia,
              onAdd: _seleccionarOrigenFoto,
              onRemove: (index) =>
                  setState(() => _fotosEvidencia.removeAt(index)),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => _guardar(docente),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar reporte'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _exportarPdf(docente),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Generar PDF'),
            ),
          ],
        ),
      ),
    );
  }

  void _seleccionar(CalificacionConocimiento value) {
    setState(() => _calificacion = value);
  }

  Future<void> _firmar(
    String titulo,
    void Function(String firma) asignar,
  ) async {
    final firma = await SignatureCaptureDialog.show(context, titulo);
    if (firma != null && mounted) setState(() => asignar(firma));
  }

  void _guardar(String docente) {
    if (!_formKey.currentState!.validate()) return;
    if (_calificacion == null) {
      _mensaje('Selecciona una calificación.');
      return;
    }
    if (_firmaColegio == null ||
        _firmaDocenteColegio == null ||
        _firmaCourseChild == null) {
      _mensaje('Debes completar las tres firmas.');
      return;
    }

    context.read<SesionProvider>().guardarReporteConocimiento(
      _crearReporte(docente),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reporte guardado correctamente.')),
    );
    Navigator.pop(context);
  }

  StudentKnowledgeReport _crearReporte(String docente) =>
      StudentKnowledgeReport(
        fechaHora: _fechaHora,
        docente: docente,
        profesorEvaluado: _profesorEvaluadoController.text.trim(),
        colegio: _colegioController.text.trim(),
        grado: _grado,
        periodo: _periodo,
        evaluaciones: _resumenEvaluacion(),
        compromiso: _compromisoController.text.trim(),
        calificacion: _calificacion!,
        firmaColegio: _firmaColegio!,
        firmaDocenteColegio: _firmaDocenteColegio!,
        firmaDocenteCourseChild: _firmaCourseChild!,
        fotosEvidencia: List.unmodifiable(_fotosEvidencia),
      );

  Map<String, String> _resumenEvaluacion() {
    final plan = planesEstudioPorGrado[_grado]![_periodo]!;
    return {
      for (final categoria in plan.categorias)
        categoria.nombre: _resumenCategoria(categoria),
    };
  }

  String _resumenCategoria(CategoriaPlanEstudio categoria) {
    if (categoria.nombre == 'Vocabulary') {
      return _resumenVocabularioPorTemas(categoria);
    }
    final logrados = <String>[];
    final porReforzar = <String>[];
    for (final item in categoria.items) {
      final lista =
          _itemsAprobados.contains(_idItem(_periodo, categoria.nombre, item))
          ? logrados
          : porReforzar;
      lista.add(item.ingles);
    }
    return 'Evaluados satisfactoriamente: '
        '${logrados.isEmpty ? 'Ninguno' : logrados.join(', ')}.\n'
        'No evaluados: '
        '${porReforzar.isEmpty ? 'Ninguno' : porReforzar.join(', ')}.';
  }

  String _resumenVocabularioPorTemas(CategoriaPlanEstudio categoria) {
    final porTema = <String, List<ItemPlanEstudio>>{};
    for (final item in categoria.items) {
      porTema
          .putIfAbsent(item.tema ?? 'Vocabulario general', () => [])
          .add(item);
    }

    return porTema.entries
        .map((entrada) {
          final evaluados = <String>[];
          final noEvaluados = <String>[];
          for (final item in entrada.value) {
            final destino =
                _itemsAprobados.contains(
                  _idItem(_periodo, categoria.nombre, item),
                )
                ? evaluados
                : noEvaluados;
            destino.add(item.ingles);
          }
          return '${entrada.key}:\n'
              'Evaluados satisfactoriamente: '
              '${evaluados.isEmpty ? 'Ninguno' : evaluados.join(', ')}.\n'
              'No evaluados: '
              '${noEvaluados.isEmpty ? 'Ninguno' : noEvaluados.join(', ')}.';
        })
        .join('\n\n');
  }

  String _observacionAutomatica(PeriodoPlanEstudio plan) {
    final pendientes = <String>[];
    for (final categoria in plan.categorias) {
      if (categoria.nombre == 'Vocabulary') {
        final vocabularioPendiente = _vocabularioPendientePorTemas(
          plan.numero,
          categoria,
        );
        if (vocabularioPendiente.isNotEmpty) {
          pendientes.add('• Vocabulary:\n$vocabularioPendiente');
        }
        continue;
      }
      final noEvaluados = categoria.items
          .where((item) {
            return !_itemsAprobados.contains(
              _idItem(plan.numero, categoria.nombre, item),
            );
          })
          .map((item) => item.ingles)
          .toList();
      if (noEvaluados.isNotEmpty) {
        pendientes.add('• ${categoria.nombre}: ${noEvaluados.join(', ')}.');
      }
    }
    if (pendientes.isEmpty) {
      return 'Se evaluó todo el contenido programado para este período.';
    }
    return 'No se evaluaron los siguientes contenidos:\n'
        '${pendientes.join('\n')}';
  }

  String _vocabularioPendientePorTemas(
    int periodo,
    CategoriaPlanEstudio categoria,
  ) {
    final porTema = <String, List<String>>{};
    for (final item in categoria.items) {
      if (_itemsAprobados.contains(_idItem(periodo, categoria.nombre, item))) {
        continue;
      }
      porTema
          .putIfAbsent(item.tema ?? 'Vocabulario general', () => [])
          .add(item.ingles);
    }
    return porTema.entries
        .map((entrada) => '   ◦ ${entrada.key}: ${entrada.value.join(', ')}.')
        .join('\n');
  }

  Future<void> _exportarPdf(String docente) async {
    if (!_formKey.currentState!.validate()) return;
    if (_calificacion == null) {
      _mensaje('Selecciona una calificación.');
      return;
    }
    if (_firmaColegio == null ||
        _firmaDocenteColegio == null ||
        _firmaCourseChild == null) {
      _mensaje('Debes completar las tres firmas.');
      return;
    }
    try {
      await const PdfExportService().compartirReporte(_crearReporte(docente));
    } catch (_) {
      if (mounted) _mensaje('No se pudo generar el PDF. Intenta nuevamente.');
    }
  }

  Future<void> _seleccionarOrigenFoto() async {
    if (_fotosEvidencia.length >= 2) {
      _mensaje('Solo puedes agregar máximo dos fotos.');
      return;
    }
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
      final fotoBase64 = base64Encode(await foto.readAsBytes());
      if (!mounted || _fotosEvidencia.length >= 2) return;
      setState(() => _fotosEvidencia.add(fotoBase64));
    } on PlatformException {
      if (mounted) _mostrarErrorPermiso(source);
    } catch (_) {
      if (mounted) _mensaje('No se pudo agregar la foto.');
    }
  }

  void _mostrarErrorPermiso(ImageSource source) {
    final recurso = source == ImageSource.camera ? 'la cámara' : 'la galería';
    _mensaje(
      'Se necesita acceso a $recurso para agregar una foto. Actívalo en Configuración.',
    );
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  String? _requerido(String? value) => value == null || value.trim().isEmpty
      ? 'Este campo es obligatorio.'
      : null;

  String _fecha(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  String _hora(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${value.hour >= 12 ? 'p.m.' : 'a.m.'}';
  }
}

String _idItem(int periodo, String categoria, ItemPlanEstudio item) =>
    '$periodo|$categoria|${item.id}';

IconData _iconoCategoria(String categoria) => switch (categoria) {
  'Commands' => Icons.touch_app_outlined,
  'Songs' => Icons.music_note_rounded,
  'Vocabulary' => Icons.menu_book_outlined,
  _ => Icons.lightbulb_outline_rounded,
};

class _CategoriaPlanCard extends StatelessWidget {
  const _CategoriaPlanCard({
    required this.categoria,
    required this.periodo,
    required this.seleccionados,
    required this.onChanged,
  });

  final CategoriaPlanEstudio categoria;
  final int periodo;
  final Set<String> seleccionados;
  final void Function(String id, bool seleccionado) onChanged;

  @override
  Widget build(BuildContext context) {
    final color = switch (categoria.nombre) {
      'Songs' => AppColors.accent,
      'Vocabulary' => AppColors.success,
      _ => AppColors.primary,
    };
    final completados = categoria.items.where((item) {
      return seleccionados.contains(_idItem(periodo, categoria.nombre, item));
    }).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(_iconoCategoria(categoria.nombre), color: color),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoria.nombre,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '$completados de ${categoria.items.length} contenidos logrados',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            for (var index = 0; index < categoria.items.length; index++) ...[
              if (categoria.items[index].tema != null &&
                  (index == 0 ||
                      categoria.items[index - 1].tema !=
                          categoria.items[index].tema)) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.xs,
                      bottom: AppSpacing.sm,
                    ),
                    child: Text(
                      categoria.items[index].tema!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
              _ItemPlanTile(
                item: categoria.items[index],
                seleccionado: seleccionados.contains(
                  _idItem(periodo, categoria.nombre, categoria.items[index]),
                ),
                onChanged: (value) => onChanged(
                  _idItem(periodo, categoria.nombre, categoria.items[index]),
                  value,
                ),
              ),
              if (index != categoria.items.length - 1)
                const SizedBox(height: AppSpacing.xs),
            ],
          ],
        ),
      ),
    );
  }
}

class _ItemPlanTile extends StatelessWidget {
  const _ItemPlanTile({
    required this.item,
    required this.seleccionado,
    required this.onChanged,
  });

  final ItemPlanEstudio item;
  final bool seleccionado;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: seleccionado
            ? AppColors.successContainer
            : scheme.surfaceContainerHighest.withValues(alpha: .42),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(
          color: seleccionado
              ? AppColors.success.withValues(alpha: .45)
              : scheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: () => onChanged(!seleccionado),
        borderRadius: BorderRadius.circular(AppRadius.small),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Checkbox(
                value: seleccionado,
                onChanged: (value) => onChanged(value ?? false),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.ingles,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!item.soloIngles &&
                        (item.pronunciacion != null || item.espanol != null))
                      Text(
                        [
                          if (item.pronunciacion != null)
                            '/${item.pronunciacion}/',
                          if (item.espanol != null) item.espanol!,
                        ].join(' · '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: scheme.primary),
        const SizedBox(width: 16),
        Expanded(child: Text(label)),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _RatingOption extends StatelessWidget {
  const _RatingOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 190),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected
            ? (dark ? const Color(0xFF17352D) : AppColors.successContainer)
            : scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(
          color: selected ? AppColors.success : scheme.outline,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.small),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  key: ValueKey(selected),
                  color: selected ? AppColors.success : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
