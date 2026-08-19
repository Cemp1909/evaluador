import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../config/plan_estudio_parvulos.dart';
import '../config/planes_estudio_adicionales.dart';
import '../models/student_knowledge_report.dart';
import '../models/student_knowledge_draft.dart';
import '../providers/sesion_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/report_signature_card.dart';
import '../widgets/evidence_photos_card.dart';
import '../widgets/signature_capture_dialog.dart';
import '../widgets/app_brand_title.dart';
import 'pdf_preview_screen.dart';

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
  late final String _reporteId =
      'CC-${_fechaHora.millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';
  int _periodo = 1;
  String _grado = 'Párvulos';
  final Map<String, ResultadoContenido> _resultados = {};
  final Set<String> _itemsHabilitados = {};
  final Map<String, String> _comentariosContenido = {};
  String? _firmaColegio;
  String? _firmaDocenteColegio;
  String? _firmaCourseChild;
  final _imagePicker = ImagePicker();
  final List<String> _fotosEvidencia = [];
  final List<String?> _referenciasFotos = [];
  bool _restaurandoBorrador = false;
  bool _modoRapido = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restaurarBorrador());
    _colegioController.addListener(_guardarBorrador);
    _profesorEvaluadoController.addListener(_guardarBorrador);
    _compromisoController.addListener(_guardarBorrador);
  }

  @override
  void dispose() {
    _colegioController.dispose();
    _profesorEvaluadoController.dispose();
    _compromisoController.dispose();
    super.dispose();
  }

  void _restaurarBorrador() {
    final borrador = context.read<SesionProvider>().borradorConocimiento;
    if (borrador == null || !mounted) return;
    _restaurandoBorrador = true;
    setState(() {
      _periodo = borrador.periodo;
      _grado = borrador.grado;
      _resultados
        ..clear()
        ..addAll(borrador.resultados);
      _itemsHabilitados
        ..clear()
        ..addAll(borrador.itemsHabilitados);
      _firmaColegio = borrador.firmaColegio;
      _firmaDocenteColegio = borrador.firmaDocenteColegio;
      _firmaCourseChild = borrador.firmaCourseChild;
      _fotosEvidencia
        ..clear()
        ..addAll(borrador.fotosEvidencia);
      _comentariosContenido
        ..clear()
        ..addAll(borrador.comentariosContenido);
      _referenciasFotos
        ..clear()
        ..addAll(borrador.referenciasFotos);
      _colegioController.text = borrador.colegio;
      _profesorEvaluadoController.text = borrador.profesorEvaluado;
      _compromisoController.text = borrador.compromiso;
    });
    _restaurandoBorrador = false;
    _mensaje('Borrador restaurado · ${_hora(borrador.actualizadoEn)}');
  }

  void _guardarBorrador() {
    if (!mounted || _restaurandoBorrador) return;
    context.read<SesionProvider>().guardarBorradorConocimiento(
      StudentKnowledgeDraft(
        actualizadoEn: DateTime.now(),
        colegio: _colegioController.text,
        profesorEvaluado: _profesorEvaluadoController.text,
        compromiso: _compromisoController.text,
        periodo: _periodo,
        grado: _grado,
        resultados: Map.unmodifiable(_resultados),
        itemsHabilitados: Set.unmodifiable(_itemsHabilitados),
        firmaColegio: _firmaColegio,
        firmaDocenteColegio: _firmaDocenteColegio,
        firmaCourseChild: _firmaCourseChild,
        fotosEvidencia: List.unmodifiable(_fotosEvidencia),
        comentariosContenido: Map.unmodifiable(_comentariosContenido),
        referenciasFotos: List.unmodifiable(_referenciasFotos),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<SesionProvider>().usuarioActual;
    final docente = usuario?.nombre ?? 'Sin sesión activa';
    final plan = planesEstudioPorGrado[_grado]![_periodo]!;

    return Scaffold(
      appBar: AppBar(title: const AppBrandTitle(compact: true)),
      bottomNavigationBar: _ProgressFooter(
        evaluados: _resultados.length,
        total: _totalContenidos(plan),
        nota: _notaFinal,
      ),
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
                _guardarBorrador();
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
                _guardarBorrador();
              }),
            ),
            const SizedBox(height: 28),
            Card(
              child: SwitchListTile(
                value: _modoRapido,
                onChanged: (value) => setState(() => _modoRapido = value),
                secondary: const Icon(Icons.bolt_rounded),
                title: const Text('Modo de evaluación rápida'),
                subtitle: const Text(
                  'Muestra las tres calificaciones directamente y reduce los toques necesarios.',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Plan de estudio · Período $_periodo',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Selecciona el resultado observado en cada contenido. Los contenidos no evaluados no afectan la nota.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (_pendientesPeriodoAnterior().isNotEmpty) ...[
              const SizedBox(height: 14),
              Card(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pendientes del período anterior',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      for (final contenido in _pendientesPeriodoAnterior())
                        Text('• $contenido'),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            for (final categoria in plan.categorias) ...[
              _CategoriaPlanCard(
                categoria: categoria,
                periodo: _periodo,
                resultados: _resultados,
                comentarios: _comentariosContenido,
                itemsHabilitados: _itemsHabilitados,
                modoRapido: _modoRapido,
                onHabilitar: (id) => setState(() {
                  _itemsHabilitados.add(id);
                  _guardarBorrador();
                }),
                onChanged: (id, resultado) => setState(() {
                  if (resultado == null) {
                    _resultados.remove(id);
                    _itemsHabilitados.remove(id);
                  } else {
                    _itemsHabilitados.add(id);
                    _resultados[id] = resultado;
                  }
                  _guardarBorrador();
                }),
                onMarcarTodos: (resultado) =>
                    _marcarCategoria(categoria, resultado),
                onLimpiar: () => _limpiarCategoria(categoria),
                onComentario: (id, item) => _editarComentario(id, item),
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
                firmaActual: _firmaColegio,
              ),
            ),
            const SizedBox(height: 14),
            ReportSignatureCard(
              titulo: 'Docente del colegio',
              firmaBase64: _firmaDocenteColegio,
              onFirmar: () => _firmar(
                'Firma del docente del colegio',
                (firma) => _firmaDocenteColegio = firma,
                firmaActual: _firmaDocenteColegio,
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
                firmaActual: _firmaCourseChild,
              ),
            ),
            const SizedBox(height: 18),
            EvidencePhotosCard(
              fotosBase64: _fotosEvidencia,
              onAdd: _seleccionarOrigenFoto,
              onRemove: _confirmarEliminarFoto,
            ),
            const SizedBox(height: 18),
            _ValidationCard(pendientes: _validacionesPendientes()),
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
    void Function(String firma) asignar, {
    String? firmaActual,
  }) async {
    if (firmaActual?.isNotEmpty == true) {
      final reemplazar = await _confirmar(
        'Reemplazar firma',
        'Ya existe una firma registrada. ¿Deseas reemplazarla?',
      );
      if (!reemplazar || !mounted) return;
    }
    final firma = await SignatureCaptureDialog.show(context, titulo);
    if (firma != null && mounted) {
      setState(() => asignar(firma));
      _guardarBorrador();
    }
  }

  Future<void> _marcarCategoria(
    CategoriaPlanEstudio categoria,
    ResultadoContenido resultado,
  ) async {
    final confirmar = await _confirmar(
      'Aplicar resultado al tema',
      '¿Deseas marcar todos los contenidos de ${categoria.nombre} como ${_nombreResultado(resultado)}?',
    );
    if (!confirmar || !mounted) return;
    setState(() {
      for (final item in categoria.items) {
        final id = _idItem(_periodo, categoria.nombre, item);
        _itemsHabilitados.add(id);
        _resultados[id] = resultado;
      }
    });
    _guardarBorrador();
  }

  Future<void> _limpiarCategoria(CategoriaPlanEstudio categoria) async {
    final confirmar = await _confirmar(
      'Limpiar resultados',
      '¿Deseas eliminar los resultados registrados en ${categoria.nombre}?',
    );
    if (!confirmar || !mounted) return;
    setState(() {
      for (final item in categoria.items) {
        final id = _idItem(_periodo, categoria.nombre, item);
        _itemsHabilitados.remove(id);
        _resultados.remove(id);
        _comentariosContenido.remove(id);
      }
    });
    _guardarBorrador();
  }

  Future<void> _confirmarEliminarFoto(int index) async {
    final confirmar = await _confirmar(
      'Eliminar evidencia',
      '¿Deseas eliminar esta fotografía? Esta acción no se puede deshacer.',
    );
    if (!confirmar || !mounted) return;
    setState(() {
      _fotosEvidencia.removeAt(index);
      if (index < _referenciasFotos.length) _referenciasFotos.removeAt(index);
    });
    _guardarBorrador();
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

  String _nombreResultado(ResultadoContenido resultado) => switch (resultado) {
    ResultadoContenido.logrado => 'Logrado',
    ResultadoContenido.porReforzar => 'Por reforzar',
    ResultadoContenido.noLogrado => 'No logrado',
  };

  Future<void> _editarComentario(String id, ItemPlanEstudio item) async {
    final controller = TextEditingController(text: _comentariosContenido[id]);
    final comentario = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Comentario · ${item.ingles}'),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ejemplo: Confunde blue con green.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (comentario == null || !mounted) return;
    setState(() {
      if (comentario.isEmpty) {
        _comentariosContenido.remove(id);
      } else {
        _comentariosContenido[id] = comentario;
      }
    });
    _guardarBorrador();
  }

  Future<void> _guardar(String docente) async {
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

    final reporte = _crearReporte(docente);
    if (!await _confirmarRevision(reporte) || !mounted) return;
    context.read<SesionProvider>().guardarReporteConocimiento(reporte);
    context.read<SesionProvider>().descartarBorradorConocimiento();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reporte guardado correctamente.')),
    );
    Navigator.pop(context);
  }

  Future<bool> _confirmarRevision(StudentKnowledgeReport reporte) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Resumen antes de finalizar'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Docente evaluado: ${reporte.profesorEvaluado}'),
                Text('Colegio: ${reporte.colegio}'),
                Text('${reporte.grado} · Período ${reporte.periodo}'),
                const Divider(height: 24),
                Text('Nota: ${reporte.notaFinal.toStringAsFixed(1)} / 5,0'),
                Text('Desempeño: ${reporte.desempeno}'),
                Text(
                  'Evaluados: ${reporte.contenidosEvaluados} de ${reporte.totalContenidos}',
                ),
                Text(
                  'Contenido pendiente: ${reporte.totalContenidos - reporte.contenidosEvaluados}',
                ),
                Text('Firmas: 3 completas'),
                Text('Fotos: ${reporte.fotosEvidencia.length} de 2'),
                const SizedBox(height: 12),
                const Text(
                  'Confirma que los datos corresponden a la visita realizada.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Volver y revisar'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Finalizar reporte'),
            ),
          ],
        ),
      ) ??
      false;

  StudentKnowledgeReport _crearReporte(String docente) =>
      StudentKnowledgeReport(
        id: _reporteId,
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
        configuracionNotas: context.read<SesionProvider>().configuracionNotas,
        firmaColegio: _firmaColegio!,
        firmaDocenteColegio: _firmaDocenteColegio!,
        firmaDocenteCourseChild: _firmaCourseChild!,
        fotosEvidencia: List.unmodifiable(_fotosEvidencia),
        resultadosContenido: Map.unmodifiable(_resultados),
        nombresContenido: _nombresContenido(),
        comentariosContenido: Map.unmodifiable(_comentariosContenido),
        referenciasFotos: List.unmodifiable(_referenciasFotos),
      );

  Map<String, String> _resumenEvaluacion() {
    final plan = planesEstudioPorGrado[_grado]![_periodo]!;
    return {
      for (final categoria in plan.categorias)
        categoria.nombre: _resumenCategoria(categoria),
      if (_comentariosContenido.isNotEmpty)
        'Comentarios individuales': _comentariosContenido.entries
            .map(
              (entry) =>
                  '${_nombresContenido()[entry.key] ?? entry.key}: ${entry.value}',
            )
            .join('\n'),
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
        porResultado[resultado]!.add(
          '$ubicacion — ${_orientacionPedagogica(categoria.nombre, resultado)}',
        );
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

  String _orientacionPedagogica(
    String categoria,
    ResultadoContenido resultado,
  ) {
    final accion = switch (resultado) {
      ResultadoContenido.logrado => 'mantener el avance',
      ResultadoContenido.porReforzar => 'practicar y reforzar',
      ResultadoContenido.noLogrado => 'estudiar nuevamente con acompañamiento',
    };
    return switch (categoria) {
      'Songs' => '$accion mediante repetición, ritmo y pronunciación',
      'Commands' => '$accion con instrucciones breves y respuesta física',
      'Vocabulary' => '$accion con imágenes, objetos y tarjetas visuales',
      'Dialogue' => '$accion mediante preguntas y respuestas guiadas',
      'Grammar' => '$accion usando ejemplos y estructuras cortas',
      _ => '$accion mediante actividades prácticas',
    };
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
    final reporte = _crearReporte(docente);
    final continuar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revisar antes de generar'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Docente: ${reporte.profesorEvaluado}'),
              Text('Colegio: ${reporte.colegio}'),
              Text('${reporte.grado} · Período ${reporte.periodo}'),
              Text('Nota: ${reporte.notaFinal.toStringAsFixed(1)} / 5,0'),
              Text('Desempeño: ${reporte.desempeno}'),
              Text(
                'Cobertura: ${reporte.contenidosEvaluados} de ${reporte.totalContenidos}',
              ),
              Text('Firmas: completas'),
              Text('Fotografías: ${reporte.fotosEvidencia.length} de 2'),
              const SizedBox(height: 12),
              const Text(
                'Podrás elegir un informe resumido o detallado en la vista previa.',
              ),
            ],
          ),
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
        builder: (_) => PdfPreviewScreen(reporte: reporte),
      ),
    );
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
      final referencia = await _seleccionarReferenciaFoto();
      if (!mounted) return;
      setState(() {
        _fotosEvidencia.add(fotoBase64);
        _referenciasFotos.add(referencia);
      });
      _guardarBorrador();
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

  Future<String?> _seleccionarReferenciaFoto() async {
    final opciones = _nombresContenido().entries
        .where((entry) => _resultados.containsKey(entry.key))
        .toList();
    return showModalBottomSheet<String?>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            const ListTile(
              title: Text('¿A qué contenido corresponde la foto?'),
              subtitle: Text('Esta referencia aparecerá en el PDF.'),
            ),
            ListTile(
              leading: const Icon(Icons.collections_outlined),
              title: const Text('Evidencia general'),
              onTap: () => Navigator.pop(context, 'Evidencia general'),
            ),
            for (final opcion in opciones)
              ListTile(
                leading: const Icon(Icons.label_outline),
                title: Text(opcion.value),
                onTap: () => Navigator.pop(context, opcion.value),
              ),
          ],
        ),
      ),
    );
  }

  Map<String, String> _nombresContenido() {
    final plan = planesEstudioPorGrado[_grado]![_periodo]!;
    return {
      for (final categoria in plan.categorias)
        for (final item in categoria.items)
          _idItem(
            _periodo,
            categoria.nombre,
            item,
          ): categoria.nombre == 'Vocabulary' && item.tema != null
              ? '${item.tema} · ${item.ingles}'
              : '${categoria.nombre} · ${item.ingles}',
    };
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

  double get _notaFinal => calcularNotaConocimiento(
    _resultados.values,
    context.read<SesionProvider>().configuracionNotas,
  );

  String get _desempeno => desempenoParaNota(
    _notaFinal,
    context.read<SesionProvider>().configuracionNotas,
  );

  List<String> _validacionesPendientes() {
    final pendientes = <String>[];
    if (_profesorEvaluadoController.text.trim().isEmpty) {
      pendientes.add('Falta el nombre del docente evaluado.');
    }
    if (_colegioController.text.trim().isEmpty) {
      pendientes.add('Falta el colegio.');
    }
    if (_resultados.isEmpty) {
      pendientes.add('No hay contenidos calificados.');
    }
    final sinResultado = _itemsHabilitados.difference(_resultados.keys.toSet());
    if (sinResultado.isNotEmpty) {
      pendientes.add(
        '${sinResultado.length} contenidos activados no tienen resultado.',
      );
    }
    if (_compromisoController.text.trim().isEmpty) {
      pendientes.add('Faltan las recomendaciones del docente.');
    }
    final firmas = [
      _firmaColegio,
      _firmaDocenteColegio,
      _firmaCourseChild,
    ].where((firma) => firma?.isNotEmpty == true).length;
    if (firmas < 3) pendientes.add('Faltan ${3 - firmas} firmas.');
    if (_fotosEvidencia.isEmpty) {
      pendientes.add('No se han agregado fotografías de evidencia (opcional).');
    }
    return pendientes;
  }

  List<String> _pendientesPeriodoAnterior() {
    if (_periodo <= 1 || _profesorEvaluadoController.text.trim().isEmpty) {
      return const [];
    }
    final reportes = context.read<SesionProvider>().historialEstudiante(
      _profesorEvaluadoController.text,
    );
    StudentKnowledgeReport? anterior;
    for (final reporte in reportes) {
      if (reporte.grado == _grado && reporte.periodo == _periodo - 1) {
        anterior = reporte;
        break;
      }
    }
    if (anterior == null) return const [];
    return anterior.resultadosContenido.entries
        .where(
          (entry) =>
              entry.value == ResultadoContenido.noLogrado ||
              entry.value == ResultadoContenido.porReforzar,
        )
        .map((entry) => anterior!.nombresContenido[entry.key] ?? entry.key)
        .toList(growable: false);
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
    required this.resultados,
    required this.comentarios,
    required this.itemsHabilitados,
    required this.modoRapido,
    required this.onHabilitar,
    required this.onChanged,
    required this.onMarcarTodos,
    required this.onLimpiar,
    required this.onComentario,
  });

  final CategoriaPlanEstudio categoria;
  final int periodo;
  final Map<String, ResultadoContenido> resultados;
  final Map<String, String> comentarios;
  final Set<String> itemsHabilitados;
  final bool modoRapido;
  final ValueChanged<String> onHabilitar;
  final void Function(String id, ResultadoContenido? resultado) onChanged;
  final ValueChanged<ResultadoContenido> onMarcarTodos;
  final VoidCallback onLimpiar;
  final void Function(String id, ItemPlanEstudio item) onComentario;

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
      child: ExpansionTile(
        initiallyExpanded: categoria.nombre == 'Commands',
        leading: Icon(_iconoCategoria(categoria.nombre), color: color),
        title: Text(
          categoria.nombre,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          '$completados de ${categoria.items.length} contenidos evaluados',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PopupMenuButton<ResultadoContenido>(
                onSelected: onMarcarTodos,
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: ResultadoContenido.logrado,
                    child: Text('Todo como Logrado'),
                  ),
                  PopupMenuItem(
                    value: ResultadoContenido.porReforzar,
                    child: Text('Todo como Por reforzar'),
                  ),
                  PopupMenuItem(
                    value: ResultadoContenido.noLogrado,
                    child: Text('Todo como No logrado'),
                  ),
                ],
                child: const Chip(
                  avatar: Icon(Icons.done_all_rounded, size: 18),
                  label: Text('Evaluar todo el tema'),
                ),
              ),
              ActionChip(
                avatar: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text('Limpiar'),
                onPressed: onLimpiar,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
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
              comentario:
                  comentarios[_idItem(
                    periodo,
                    categoria.nombre,
                    categoria.items[index],
                  )],
              habilitado: itemsHabilitados.contains(
                _idItem(periodo, categoria.nombre, categoria.items[index]),
              ),
              modoRapido: modoRapido,
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
              onComentario: () => onComentario(
                _idItem(periodo, categoria.nombre, categoria.items[index]),
                categoria.items[index],
              ),
            ),
            if (index != categoria.items.length - 1)
              const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _ItemPlanTile extends StatelessWidget {
  const _ItemPlanTile({
    required this.item,
    required this.habilitado,
    required this.modoRapido,
    required this.resultado,
    required this.comentario,
    required this.onHabilitar,
    required this.onChanged,
    required this.onComentario,
  });

  final ItemPlanEstudio item;
  final bool habilitado;
  final bool modoRapido;
  final ResultadoContenido? resultado;
  final String? comentario;
  final VoidCallback onHabilitar;
  final ValueChanged<ResultadoContenido?> onChanged;
  final VoidCallback onComentario;

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
            if (!habilitado && !modoRapido)
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
            if (habilitado && resultado != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onComentario,
                icon: const Icon(Icons.comment_outlined, size: 18),
                label: Text(
                  comentario?.isNotEmpty == true
                      ? 'Editar comentario'
                      : 'Agregar comentario',
                ),
              ),
              if (comentario?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    comentario!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
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
    avatar: Icon(icon, size: 17, color: AppColors.textPrimary),
    label: Text(
      label,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    ),
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

class _ProgressFooter extends StatelessWidget {
  const _ProgressFooter({
    required this.evaluados,
    required this.total,
    required this.nota,
  });

  final int evaluados;
  final int total;
  final double nota;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: Text('Evaluados: $evaluados de $total')),
          Text(
            nota == 0
                ? 'Nota: —'
                : 'Nota provisional: ${nota.toStringAsFixed(1)}',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}

class _ValidationCard extends StatelessWidget {
  const _ValidationCard({required this.pendientes});

  final List<String> pendientes;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                pendientes.isEmpty
                    ? Icons.verified_rounded
                    : Icons.fact_check_outlined,
              ),
              const SizedBox(width: 8),
              Text(
                pendientes.isEmpty
                    ? 'Reporte listo para revisar'
                    : 'Revisión del reporte',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          if (pendientes.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final pendiente in pendientes)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text('• $pendiente'),
              ),
          ],
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
