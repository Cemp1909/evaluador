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
  int _periodo = 1;
  String _grado = 'Párvulos';
  final Map<String, ResultadoContenido> _resultados = {};
  final Set<String> _itemsHabilitados = {};
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
                _resultados.clear();
                _itemsHabilitados.clear();
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
                _resultados.clear();
                _itemsHabilitados.clear();
              }),
            ),
            const SizedBox(height: 28),
            Text(
              'Plan de estudio · Período $_periodo',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Selecciona el resultado observado en cada contenido. Los contenidos no evaluados no afectan la nota.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            for (final categoria in plan.categorias) ...[
              _CategoriaPlanCard(
                categoria: categoria,
                periodo: _periodo,
                resultados: _resultados,
                itemsHabilitados: _itemsHabilitados,
                onHabilitar: (id) => setState(() {
                  _itemsHabilitados.add(id);
                }),
                onChanged: (id, resultado) => setState(() {
                  if (resultado == null) {
                    _resultados.remove(id);
                    _itemsHabilitados.remove(id);
                  } else {
                    _itemsHabilitados.add(id);
                    _resultados[id] = resultado;
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
            Text(
              'Sugerencias automáticas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: .25),
                ),
              ),
              child: Text(
                _sugerenciasAutomaticas(plan),
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
              'Resultado automático',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            _NotaCard(
              nota: _notaFinal,
              desempeno: _desempeno,
              evaluados: _resultados.length,
              total: _totalContenidos(plan),
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

  Future<void> _firmar(
    String titulo,
    void Function(String firma) asignar,
  ) async {
    final firma = await SignatureCaptureDialog.show(context, titulo);
    if (firma != null && mounted) setState(() => asignar(firma));
  }

  void _guardar(String docente) {
    if (!_formKey.currentState!.validate()) return;
    if (_resultados.isEmpty) {
      _mensaje('Evalúa al menos un contenido para calcular la nota.');
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
        nota: _notaFinal,
        contenidosEvaluados: _resultados.length,
        totalContenidos: _totalContenidos(
          planesEstudioPorGrado[_grado]![_periodo]!,
        ),
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
      'Sugerencias automáticas': _sugerenciasAutomaticas(plan),
    };
  }

  String _resumenCategoria(CategoriaPlanEstudio categoria) {
    if (categoria.nombre == 'Vocabulary') {
      return _resumenVocabularioPorTemas(categoria);
    }
    final grupos = <ResultadoContenido?, List<String>>{
      ResultadoContenido.logrado: [],
      ResultadoContenido.porReforzar: [],
      ResultadoContenido.noLogrado: [],
      null: [],
    };
    for (final item in categoria.items) {
      final resultado = _resultados[_idItem(_periodo, categoria.nombre, item)];
      grupos[resultado]!.add(item.ingles);
    }
    return _textoGruposResultado(grupos);
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
          final grupos = <ResultadoContenido?, List<String>>{
            ResultadoContenido.logrado: [],
            ResultadoContenido.porReforzar: [],
            ResultadoContenido.noLogrado: [],
            null: [],
          };
          for (final item in entrada.value) {
            final resultado =
                _resultados[_idItem(_periodo, categoria.nombre, item)];
            grupos[resultado]!.add(item.ingles);
          }
          return '${entrada.key}:\n${_textoGruposResultado(grupos)}';
        })
        .join('\n\n');
  }

  String _textoGruposResultado(Map<ResultadoContenido?, List<String>> grupos) =>
      'Logrados: ${_listaOninguno(grupos[ResultadoContenido.logrado]!)}.\n'
      'Por reforzar: ${_listaOninguno(grupos[ResultadoContenido.porReforzar]!)}.\n'
      'No logrados: ${_listaOninguno(grupos[ResultadoContenido.noLogrado]!)}.\n'
      'No evaluados: ${_listaOninguno(grupos[null]!)}.';

  String _listaOninguno(List<String> valores) =>
      valores.isEmpty ? 'Ninguno' : valores.join(', ');

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
            return !_resultados.containsKey(
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
      if (_resultados.containsKey(_idItem(periodo, categoria.nombre, item))) {
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

  String _sugerenciasAutomaticas(PeriodoPlanEstudio plan) {
    if (_resultados.isEmpty) {
      return 'Aún no hay contenidos calificados. Selecciona los contenidos que vas a evaluar para generar sugerencias.';
    }

    final porResultado = <ResultadoContenido, List<String>>{
      ResultadoContenido.logrado: [],
      ResultadoContenido.porReforzar: [],
      ResultadoContenido.noLogrado: [],
    };
    for (final categoria in plan.categorias) {
      for (final item in categoria.items) {
        final resultado =
            _resultados[_idItem(plan.numero, categoria.nombre, item)];
        if (resultado == null) continue;
        final ubicacion = categoria.nombre == 'Vocabulary' && item.tema != null
            ? '${item.tema}: ${item.ingles}'
            : '${categoria.nombre}: ${item.ingles}';
        porResultado[resultado]!.add(ubicacion);
      }
    }

    final sugerencias = <String>[
      switch (_desempeno) {
        'Superior' =>
          'Resultado general excelente (${_notaFinal.toStringAsFixed(1)}/5,0). Mantener la práctica y avanzar con contenidos nuevos.',
        'Alto' =>
          'Resultado general alto (${_notaFinal.toStringAsFixed(1)}/5,0). Continuar practicando y reforzar los puntos señalados.',
        'Básico' =>
          'Resultado general medio (${_notaFinal.toStringAsFixed(1)}/5,0). Se recomienda repasar los temas en proceso de aprendizaje.',
        _ =>
          'Resultado general crítico (${_notaFinal.toStringAsFixed(1)}/5,0). Se recomienda estudiar nuevamente y practicar con acompañamiento.',
      },
    ];

    final noLogrados = porResultado[ResultadoContenido.noLogrado]!;
    if (noLogrados.isNotEmpty) {
      sugerencias.add(
        'CRÍTICO — Estudiar nuevamente y repasar con acompañamiento:\n• ${noLogrados.join('\n• ')}',
      );
    }
    final porReforzar = porResultado[ResultadoContenido.porReforzar]!;
    if (porReforzar.isNotEmpty) {
      sugerencias.add(
        'EN PROCESO — Practicar y reforzar estos contenidos:\n• ${porReforzar.join('\n• ')}',
      );
    }
    final logrados = porResultado[ResultadoContenido.logrado]!;
    if (logrados.isNotEmpty) {
      sugerencias.add(
        'EXCELENTE — Mantener y continuar practicando:\n• ${logrados.join('\n• ')}',
      );
    }
    return sugerencias.join('\n\n');
  }

  Future<void> _exportarPdf(String docente) async {
    if (!_formKey.currentState!.validate()) return;
    if (_resultados.isEmpty) {
      _mensaje('Evalúa al menos un contenido para calcular la nota.');
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

  int _totalContenidos(PeriodoPlanEstudio plan) => plan.categorias.fold(
    0,
    (total, categoria) => total + categoria.items.length,
  );

  double get _notaFinal => calcularNotaConocimiento(_resultados.values);

  String get _desempeno => desempenoParaNota(_notaFinal);
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
    required this.resultados,
    required this.itemsHabilitados,
    required this.onHabilitar,
    required this.onChanged,
  });

  final CategoriaPlanEstudio categoria;
  final int periodo;
  final Map<String, ResultadoContenido> resultados;
  final Set<String> itemsHabilitados;
  final ValueChanged<String> onHabilitar;
  final void Function(String id, ResultadoContenido? resultado) onChanged;

  @override
  Widget build(BuildContext context) {
    final color = switch (categoria.nombre) {
      'Songs' => AppColors.accent,
      'Vocabulary' => AppColors.success,
      _ => AppColors.primary,
    };
    final completados = categoria.items.where((item) {
      return resultados.containsKey(_idItem(periodo, categoria.nombre, item));
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
                        '$completados de ${categoria.items.length} contenidos evaluados',
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
                habilitado: itemsHabilitados.contains(
                  _idItem(periodo, categoria.nombre, categoria.items[index]),
                ),
                resultado:
                    resultados[_idItem(
                      periodo,
                      categoria.nombre,
                      categoria.items[index],
                    )],
                onHabilitar: () => onHabilitar(
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
    required this.habilitado,
    required this.resultado,
    required this.onHabilitar,
    required this.onChanged,
  });

  final ItemPlanEstudio item;
  final bool habilitado;
  final ResultadoContenido? resultado;
  final VoidCallback onHabilitar;
  final ValueChanged<ResultadoContenido?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: resultado == ResultadoContenido.logrado
            ? AppColors.successContainer
            : scheme.surfaceContainerHighest.withValues(alpha: .42),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(
          color: resultado == ResultadoContenido.logrado
              ? AppColors.success.withValues(alpha: .45)
              : scheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.ingles,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (!item.soloIngles &&
                (item.pronunciacion != null || item.espanol != null))
              Text(
                [
                  if (item.pronunciacion != null) '/${item.pronunciacion}/',
                  if (item.espanol != null) item.espanol!,
                ].join(' · '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 8),
            if (!habilitado)
              OutlinedButton.icon(
                onPressed: onHabilitar,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Evaluar este contenido'),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _ResultadoChip(
                    label: 'Logrado',
                    icon: Icons.check_circle_outline,
                    selected: resultado == ResultadoContenido.logrado,
                    onTap: () => onChanged(ResultadoContenido.logrado),
                  ),
                  _ResultadoChip(
                    label: 'Por reforzar',
                    icon: Icons.change_circle_outlined,
                    selected: resultado == ResultadoContenido.porReforzar,
                    onTap: () => onChanged(ResultadoContenido.porReforzar),
                  ),
                  _ResultadoChip(
                    label: 'No logrado',
                    icon: Icons.cancel_outlined,
                    selected: resultado == ResultadoContenido.noLogrado,
                    onTap: () => onChanged(ResultadoContenido.noLogrado),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.close_rounded, size: 17),
                    label: const Text('Cancelar evaluación'),
                    onPressed: () => onChanged(null),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultadoChip extends StatelessWidget {
  const _ResultadoChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    selected: selected,
    onSelected: (_) => onTap(),
    avatar: Icon(icon, size: 17),
    label: Text(label),
    visualDensity: VisualDensity.compact,
  );
}

class _NotaCard extends StatelessWidget {
  const _NotaCard({
    required this.nota,
    required this.desempeno,
    required this.evaluados,
    required this.total,
  });

  final double nota;
  final String desempeno;
  final int evaluados;
  final int total;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 31,
            backgroundColor: AppColors.primary,
            child: Text(
              nota == 0 ? '—' : nota.toStringAsFixed(1),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desempeno, style: Theme.of(context).textTheme.titleLarge),
                Text('Nota calculada sobre 5,0'),
                Text('$evaluados de $total contenidos evaluados'),
              ],
            ),
          ),
        ],
      ),
    ),
  );
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
