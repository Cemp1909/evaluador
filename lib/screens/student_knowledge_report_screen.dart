import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../models/student_knowledge_report.dart';
import '../providers/sesion_provider.dart';
import '../theme/app_theme.dart';
import '../services/pdf_export_service.dart';
import '../widgets/report_signature_card.dart';
import '../widgets/evidence_photos_card.dart';
import '../widgets/signature_capture_dialog.dart';

class StudentKnowledgeReportScreen extends StatefulWidget {
  const StudentKnowledgeReportScreen({super.key});

  static const routeName = '/student_knowledge_report';

  @override
  State<StudentKnowledgeReportScreen> createState() =>
      _StudentKnowledgeReportScreenState();
}

class _StudentKnowledgeReportScreenState
    extends State<StudentKnowledgeReportScreen> {
  static const _categorias = [
    'Commands',
    'Songs',
    'Vocabulary',
    'Grammar',
    'Dialogue',
    'Recommendations',
  ];

  final _formKey = GlobalKey<FormState>();
  final _colegioController = TextEditingController();
  final _gradoController = TextEditingController();
  final _profesorEvaluadoController = TextEditingController();
  final _compromisoController = TextEditingController();
  late final Map<String, TextEditingController> _evaluacionControllers = {
    for (final categoria in _categorias) categoria: TextEditingController(),
  };
  final DateTime _fechaHora = DateTime.now();
  CalificacionConocimiento? _calificacion;
  int _periodo = 1;
  String? _firmaColegio;
  String? _firmaDocenteColegio;
  String? _firmaCourseChild;
  final _imagePicker = ImagePicker();
  final List<String> _fotosEvidencia = [];

  @override
  void dispose() {
    _colegioController.dispose();
    _gradoController.dispose();
    _profesorEvaluadoController.dispose();
    _compromisoController.dispose();
    for (final controller in _evaluacionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<SesionProvider>().usuarioActual;
    final docente = usuario?.nombre ?? 'Sin sesión activa';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de conocimiento del estudiante'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
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
              onChanged: (value) => setState(() => _periodo = value ?? 1),
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
            TextFormField(
              controller: _gradoController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Grado',
                prefixIcon: Icon(Icons.class_outlined),
              ),
              validator: _requerido,
            ),
            const SizedBox(height: 28),
            Text(
              'Evaluación del estudiante',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Describe lo observado durante la evaluación.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            for (final categoria in _categorias) ...[
              TextFormField(
                controller: _evaluacionControllers[categoria],
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: categoria,
                  alignLabelWithHint: true,
                  prefixIcon: Icon(_iconoCategoria(categoria)),
                ),
                validator: _requerido,
              ),
              const SizedBox(height: 14),
            ],
            TextFormField(
              controller: _compromisoController,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Compromiso',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.handshake_outlined),
              ),
              validator: _requerido,
            ),
            const SizedBox(height: 28),
            Text(
              'Calificación',
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
        grado: _gradoController.text.trim(),
        periodo: _periodo,
        evaluaciones: {
          for (final entry in _evaluacionControllers.entries)
            entry.key: entry.value.text.trim(),
        },
        compromiso: _compromisoController.text.trim(),
        calificacion: _calificacion!,
        firmaColegio: _firmaColegio!,
        firmaDocenteColegio: _firmaDocenteColegio!,
        firmaDocenteCourseChild: _firmaCourseChild!,
        fotosEvidencia: List.unmodifiable(_fotosEvidencia),
      );

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

  IconData _iconoCategoria(String categoria) => switch (categoria) {
    'Commands' => Icons.touch_app_outlined,
    'Songs' => Icons.music_note_rounded,
    'Vocabulary' => Icons.menu_book_outlined,
    'Grammar' => Icons.spellcheck_rounded,
    'Dialogue' => Icons.forum_outlined,
    _ => Icons.lightbulb_outline_rounded,
  };
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
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 14),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: selected ? AppColors.successContainer : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(
          color: selected ? AppColors.success : AppColors.outline,
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
                  color: selected ? AppColors.success : AppColors.textSecondary,
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
