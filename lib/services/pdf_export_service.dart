import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

import '../models/evaluacion.dart';
import '../models/evaluacion_bloque.dart';
import '../models/evaluacion_clase.dart';
import '../models/student_knowledge_report.dart';

class PdfExportService {
  const PdfExportService();

  static final _primary = PdfColor.fromHex('#176B78');
  static final _primaryDark = PdfColor.fromHex('#0E4F59');
  static final _accent = PdfColor.fromHex('#F29F3D');
  static final _success = PdfColor.fromHex('#2E7D5B');
  static final _background = PdfColor.fromHex('#F5F8F7');
  static final _textPrimary = PdfColor.fromHex('#183033');
  static final _textSecondary = PdfColor.fromHex('#607477');
  static final _outline = PdfColor.fromHex('#D9E4E2');

  Future<void> compartirClase({
    required Evaluacion evaluacion,
    required EvaluacionClase clase,
    required String evaluador,
  }) async {
    final bytes = await generarClase(
      evaluacion: evaluacion,
      clase: clase,
      evaluador: evaluador,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename:
          '${_archivo(evaluacion.evaluadorTipo)}_clase_${clase.claseNumero}_${_fechaArchivo(evaluacion.fechaCreacion)}.pdf',
    );
  }

  Future<Uint8List> generarClase({
    required Evaluacion evaluacion,
    required EvaluacionClase clase,
    required String evaluador,
  }) async {
    final logo = await _cargarLogo();
    final theme = await _cargarTema();
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => _encabezado(
          '${_tituloTipo(evaluacion.evaluadorTipo)} · Clase ${clase.claseNumero}',
          logo,
        ),
        footer: _piePagina,
        build: (_) => [
          _tarjetaResumenClase([
            ('Evaluador', evaluador),
            (
              'Colegio',
              evaluacion.colegio.isEmpty
                  ? 'Sin especificar'
                  : evaluacion.colegio,
            ),
            ('Fecha de creación', _fechaHora(evaluacion.fechaCreacion)),
          ]),
          pw.SizedBox(height: 14),
          ..._clase(clase),
          if (evaluacion.fotosUrls.isNotEmpty) ...[
            _tituloSeccion('Evidencia fotográfica'),
            _imagenes(evaluacion.fotosUrls, height: 210),
          ],
        ],
      ),
    );
    return document.save();
  }

  Future<void> compartirEvaluacion({
    required Evaluacion evaluacion,
    required String evaluador,
  }) async {
    final bytes = await generarEvaluacion(
      evaluacion: evaluacion,
      evaluador: evaluador,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename:
          '${_archivo(evaluacion.evaluadorTipo)}_${_fechaArchivo(evaluacion.fechaCreacion)}.pdf',
    );
  }

  Future<Uint8List> generarEvaluacion({
    required Evaluacion evaluacion,
    required String evaluador,
  }) async {
    final logo = await _cargarLogo();
    final theme = await _cargarTema();
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => _encabezado(evaluacion.evaluadorTipo, logo),
        footer: _piePagina,
        build: (_) => [
          _tarjetaInformacion([
            ('Evaluador', evaluador),
            (
              'Colegio',
              evaluacion.colegio.isEmpty
                  ? 'Sin especificar'
                  : evaluacion.colegio,
            ),
            ('Fecha de creación', _fechaHora(evaluacion.fechaCreacion)),
            ('Estado', _estado(evaluacion.estado)),
          ]),
          pw.SizedBox(height: 18),
          ...evaluacion.clases.expand(_clase),
          if (evaluacion.fotosUrls.isNotEmpty) ...[
            _tituloSeccion('Evidencia fotográfica'),
            _imagenes(evaluacion.fotosUrls, height: 210),
          ],
        ],
      ),
    );
    return document.save();
  }

  Future<void> compartirReporte(StudentKnowledgeReport reporte) async {
    final bytes = await generarReporte(reporte);
    await Printing.sharePdf(
      bytes: bytes,
      filename: nombreArchivoReporte(reporte),
    );
  }

  String nombreArchivoReporte(
    StudentKnowledgeReport reporte, {
    bool resumido = false,
  }) =>
      'CourseChild_${_archivo(reporte.profesorEvaluado)}_${_archivo(reporte.grado)}_P${reporte.periodo}_${_fechaArchivo(reporte.fechaHora)}${resumido ? '_resumido' : '_detallado'}.pdf';

  Future<Uint8List> generarReporte(
    StudentKnowledgeReport reporte, {
    bool resumido = false,
  }) async {
    final logo = await _cargarLogo();
    final theme = await _cargarTema();
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox()
            : _encabezado('Reporte de conocimiento del estudiante', logo),
        footer: _piePagina,
        build: (_) => [
          _portadaReporte(reporte, logo, resumido),
          pw.NewPage(),
          _tarjetaInformacion([
            ('Identificador', reporte.id),
            ('Fecha y hora', _fechaHora(reporte.fechaHora)),
            ('Período', 'Período ${reporte.periodo}'),
            ('Docente de Course Child', reporte.docente),
            ('Docente evaluado', reporte.profesorEvaluado),
            ('Colegio', reporte.colegio),
            ('Grado', reporte.grado),
            ('Nota final', '${reporte.notaFinal.toStringAsFixed(1)} / 5,0'),
            ('Desempeño', reporte.desempeno),
            (
              'Aprobación',
              reporte.aprobadoPorCoordinador
                  ? 'Aprobado por ${reporte.nombreCoordinador}'
                  : 'Pendiente de aprobación del coordinador',
            ),
            (
              'Cobertura',
              '${reporte.contenidosEvaluados} de ${reporte.totalContenidos} contenidos evaluados',
            ),
          ]),
          pw.SizedBox(height: 22),
          _leyendaNotas(reporte),
          pw.SizedBox(height: 18),
          _tituloSeccion(
            resumido ? 'Resumen de la evaluación' : 'Evaluación del estudiante',
          ),
          ...reporte.evaluaciones.entries
              .where(
                (entry) => !resumido || entry.key == 'Sugerencias automáticas',
              )
              .map((entry) => _bloqueEvaluacion(entry.key, entry.value)),
          _bloqueEvaluacion(
            'Compromiso y recomendaciones del docente',
            reporte.compromiso,
          ),
          pw.SizedBox(height: 8),
          _tituloSeccion('Firmas'),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _tarjetaFirma(reporte.colegio, reporte.firmaColegio),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _tarjetaFirma(
                  reporte.profesorEvaluado,
                  reporte.firmaDocenteColegio,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _tarjetaFirma(
                  reporte.docente,
                  reporte.firmaDocenteCourseChild,
                ),
              ),
            ],
          ),
          if (reporte.aprobadoPorCoordinador) ...[
            pw.SizedBox(height: 12),
            _tarjetaFirma(
              '${reporte.nombreCoordinador} · Coordinador aprobador',
              reporte.firmaCoordinador!,
            ),
          ],
          pw.NewPage(),
          _tituloSeccion('Evidencia fotográfica'),
          _cuadriculaFotos(
            reporte.fotosEvidencia,
            referencias: reporte.referenciasFotos,
          ),
        ],
      ),
    );
    return document.save();
  }

  pw.Widget _portadaReporte(
    StudentKnowledgeReport reporte,
    pw.MemoryImage? logo,
    bool resumido,
  ) => pw.Container(
    height: 680,
    alignment: pw.Alignment.center,
    child: pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        if (logo != null)
          pw.Image(logo, width: 125, height: 125, fit: pw.BoxFit.contain),
        pw.SizedBox(height: 28),
        pw.Text(
          'COURSE CHILD',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: _primaryDark,
          ),
        ),
        pw.SizedBox(height: 14),
        pw.Text(
          'Reporte de conocimiento del estudiante',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 21,
            fontWeight: pw.FontWeight.bold,
            color: _textPrimary,
          ),
        ),
        pw.SizedBox(height: 9),
        pw.Text(
          resumido ? 'Informe resumido' : 'Informe detallado',
          style: pw.TextStyle(fontSize: 12, color: _textSecondary),
        ),
        pw.SizedBox(height: 34),
        pw.Container(
          width: 360,
          padding: const pw.EdgeInsets.all(22),
          decoration: pw.BoxDecoration(
            color: _background,
            borderRadius: pw.BorderRadius.circular(12),
            border: pw.Border.all(color: _outline),
          ),
          child: pw.Column(
            children: [
              pw.Text(reporte.profesorEvaluado),
              pw.SizedBox(height: 8),
              pw.Text('${reporte.grado} · Período ${reporte.periodo}'),
              pw.SizedBox(height: 8),
              pw.Text(reporte.colegio),
              pw.SizedBox(height: 14),
              pw.Text(
                'Nota ${reporte.notaFinal.toStringAsFixed(1)} / 5,0 · ${reporte.desempeno}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 24),
        pw.Text(
          'Identificador local: ${reporte.id}',
          style: pw.TextStyle(fontSize: 9, color: _textSecondary),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'La verificación mediante QR estará disponible al conectar el sistema institucional.',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 8.5, color: _textSecondary),
        ),
      ],
    ),
  );

  pw.Widget _leyendaNotas(StudentKnowledgeReport reporte) => pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromHex('#EFF5F5'),
      borderRadius: pw.BorderRadius.circular(8),
      border: pw.Border.all(color: _outline),
    ),
    child: pw.Text(
      'Escala utilizada: Logrado = ${reporte.configuracionNotas.puntosLogrado.toStringAsFixed(1)} · '
      'Por reforzar = ${reporte.configuracionNotas.puntosPorReforzar.toStringAsFixed(1)} · '
      'No logrado = ${reporte.configuracionNotas.puntosNoLogrado.toStringAsFixed(1)} · '
      'No evaluado no participa en la nota.',
      style: pw.TextStyle(fontSize: 9, color: _textPrimary),
    ),
  );

  Iterable<pw.Widget> _clase(EvaluacionClase clase) sync* {
    final total = clase.bloques.fold<int>(
      0,
      (value, bloque) =>
          value +
          (bloque.itemsMarcados.isEmpty ? 1 : bloque.itemsMarcados.length),
    );
    final completos = clase.bloques.fold<int>(
      0,
      (value, bloque) =>
          value +
          (bloque.itemsMarcados.isEmpty
              ? (bloque.marcado ? 1 : 0)
              : bloque.itemsMarcados.values.where((value) => value).length),
    );
    yield _tituloSeccion(
      'Clase ${clase.claseNumero} · $completos de $total contenidos realizados',
    );
    for (final bloque in clase.bloques) {
      yield _tarjetaBloqueClase(bloque);
    }
    yield _recomendacionClase(_observacionAutomatica(clase));
    yield _seccion(
      'Observaciones de la clase',
      clase.observaciones.trim().isEmpty
          ? 'Sin observaciones adicionales.'
          : clase.observaciones,
    );
    if (clase.firmaDocenteUrl?.isNotEmpty == true) {
      yield _firma('Docente representante', clase.firmaDocenteUrl!);
    }
    for (final firma in clase.firmasAsistentes) {
      yield _firma(firma.nombre, firma.firmaBase64);
    }
    yield pw.SizedBox(height: 12);
  }

  pw.Widget _tarjetaResumenClase(List<(String, String)> values) => pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: pw.BoxDecoration(
      color: PdfColors.white,
      borderRadius: pw.BorderRadius.circular(9),
      border: pw.Border.all(color: _outline, width: .8),
      boxShadow: [
        pw.BoxShadow(
          color: PdfColor.fromHex('#E9EEEE'),
          blurRadius: 4,
          offset: const PdfPoint(0, -2),
        ),
      ],
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < values.length; index++) ...[
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  values[index].$1.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                    color: _textSecondary,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  values[index].$2,
                  style: pw.TextStyle(fontSize: 9.5, color: _textPrimary),
                ),
              ],
            ),
          ),
          if (index < values.length - 1) pw.SizedBox(width: 12),
        ],
      ],
    ),
  );

  pw.Widget _tarjetaBloqueClase(EvaluacionBloque bloque) {
    final items = bloque.itemsMarcados.entries.toList();
    final total = items.isEmpty ? 1 : items.length;
    final realizados = items.isEmpty
        ? (bloque.marcado ? 1 : 0)
        : items.where((item) => item.value).length;
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(9),
        border: pw.Border.all(color: _outline, width: .8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  bloque.bloqueNombre,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: pw.BoxDecoration(
                  color: realizados == total
                      ? PdfColor.fromHex('#DDF3EC')
                      : _background,
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.Text(
                  '$realizados/$total',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: realizados == total ? _success : _textSecondary,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 7),
          pw.Divider(color: _outline, thickness: .6, height: 1),
          pw.SizedBox(height: 7),
          if (items.isEmpty)
            _filaCheck(bloque.bloqueNombre, bloque.marcado)
          else
            for (final item in items) ...[
              _filaCheck(item.key, item.value),
              if (item != items.last) pw.SizedBox(height: 6),
            ],
        ],
      ),
    );
  }

  pw.Widget _filaCheck(String texto, bool marcado) => pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Container(
        width: 11,
        height: 11,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          color: marcado ? _primary : PdfColors.white,
          borderRadius: pw.BorderRadius.circular(1.5),
          border: pw.Border.all(
            color: marcado ? _primary : _textSecondary,
            width: .8,
          ),
        ),
        child: marcado
            ? pw.Text(
                'X',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 6.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              )
            : null,
      ),
      pw.SizedBox(width: 9),
      pw.Expanded(
        child: pw.Text(
          texto,
          style: pw.TextStyle(
            fontSize: 9,
            color: marcado ? _textPrimary : _textSecondary,
          ),
        ),
      ),
    ],
  );

  pw.Widget _recomendacionClase(String contenido) => pw.Container(
    width: double.infinity,
    margin: const pw.EdgeInsets.only(top: 5, bottom: 12),
    padding: const pw.EdgeInsets.all(13),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromHex('#FFF4E5'),
      borderRadius: pw.BorderRadius.circular(8),
      border: pw.Border.all(color: PdfColor.fromHex('#F7C98F'), width: .8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 16,
              height: 16,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _accent, width: 1),
                shape: pw.BoxShape.circle,
              ),
              child: pw.Text(
                'i',
                style: pw.TextStyle(
                  color: _accent,
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              'Recomendación automática',
              style: pw.TextStyle(
                fontSize: 10.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#8A4B12'),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 7),
        pw.Text(
          contenido,
          style: pw.TextStyle(
            fontSize: 9,
            lineSpacing: 2.5,
            color: _textPrimary,
          ),
        ),
      ],
    ),
  );

  pw.Widget _encabezado(String titulo, pw.MemoryImage? logo) => pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 20),
    child: pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (logo != null)
              pw.ClipRRect(
                horizontalRadius: 8,
                verticalRadius: 8,
                child: pw.Image(
                  logo,
                  width: 52,
                  height: 52,
                  fit: pw.BoxFit.cover,
                ),
              ),
            pw.SizedBox(width: 12),
            pw.Text(
              'COURSE CHILD',
              style: pw.TextStyle(
                fontSize: 17,
                fontWeight: pw.FontWeight.bold,
                color: _primaryDark,
              ),
            ),
            pw.Spacer(),
            pw.SizedBox(
              width: 250,
              child: pw.Text(
                titulo,
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          height: 5,
          decoration: pw.BoxDecoration(
            borderRadius: pw.BorderRadius.circular(3),
            gradient: pw.LinearGradient(colors: [_primaryDark, _primary]),
            boxShadow: [
              pw.BoxShadow(
                color: PdfColor.fromHex('#D3E7E9'),
                blurRadius: 3,
                offset: const PdfPoint(0, -2),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  pw.Widget _tarjetaInformacion(
    List<(String, String)> values, {
    CalificacionConocimiento? calificacion,
  }) => pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    decoration: pw.BoxDecoration(
      color: _background,
      borderRadius: pw.BorderRadius.circular(12),
      border: pw.Border.all(color: _outline, width: .7),
    ),
    child: pw.Column(
      children: [
        for (var index = 0; index < values.length; index++) ...[
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.SizedBox(
                  width: 150,
                  child: pw.Text(
                    values[index].$1,
                    style: pw.TextStyle(
                      fontSize: 10.5,
                      fontWeight: pw.FontWeight.bold,
                      color: _textSecondary,
                    ),
                  ),
                ),
                pw.Expanded(
                  child:
                      values[index].$1 == 'Calificación' && calificacion != null
                      ? pw.Align(
                          alignment: pw.Alignment.centerLeft,
                          child: _badgeCalificacion(calificacion),
                        )
                      : pw.Text(
                          values[index].$2,
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: _textPrimary,
                          ),
                        ),
                ),
              ],
            ),
          ),
          if (index < values.length - 1)
            pw.Divider(color: _outline, thickness: .6, height: 1),
        ],
      ],
    ),
  );

  pw.Widget _badgeCalificacion(CalificacionConocimiento value) {
    final color = switch (value) {
      CalificacionConocimiento.low => PdfColor.fromHex('#B5472F'),
      CalificacionConocimiento.regular => PdfColor.fromHex('#9A5B13'),
      CalificacionConocimiento.high => _success,
    };
    final background = switch (value) {
      CalificacionConocimiento.low => PdfColor.fromHex('#FBE7E1'),
      CalificacionConocimiento.regular => PdfColor.fromHex('#FFF1DE'),
      CalificacionConocimiento.high => PdfColor.fromHex('#E1F3EA'),
    };
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: pw.BoxDecoration(
        color: background,
        borderRadius: pw.BorderRadius.circular(20),
      ),
      child: pw.Text(
        _calificacion(value),
        style: pw.TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _tituloSeccion(String titulo) => pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 14),
    padding: const pw.EdgeInsets.only(bottom: 7),
    decoration: pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _outline, width: .8)),
    ),
    child: pw.Row(
      children: [
        pw.Container(
          width: 5,
          height: 18,
          decoration: pw.BoxDecoration(
            color: _accent,
            borderRadius: pw.BorderRadius.circular(3),
          ),
        ),
        pw.SizedBox(width: 9),
        pw.Text(
          titulo,
          style: pw.TextStyle(
            fontSize: 15,
            fontWeight: pw.FontWeight.bold,
            color: _primaryDark,
          ),
        ),
      ],
    ),
  );

  pw.Widget _bloqueEvaluacion(String titulo, String contenido) => pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 13),
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: PdfColors.white,
      borderRadius: pw.BorderRadius.circular(9),
      border: pw.Border.all(color: _outline, width: .7),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 24,
              height: 24,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#E5F1F2'),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                _simboloCategoria(titulo),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _primary,
                ),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              titulo,
              style: pw.TextStyle(
                fontSize: 11.5,
                fontWeight: pw.FontWeight.bold,
                color: _textPrimary,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 7),
        pw.Text(
          contenido,
          style: pw.TextStyle(
            fontSize: 10.5,
            lineSpacing: 3,
            color: _textPrimary,
          ),
        ),
      ],
    ),
  );

  pw.Widget _seccion(String titulo, String contenido) =>
      _bloqueEvaluacion(titulo, contenido);

  pw.Widget _firma(String nombre, String base64) =>
      _tarjetaFirma(nombre, base64);

  pw.Widget _tarjetaFirma(String nombre, String base64) {
    final image = _imagen(base64);
    return pw.Container(
      height: 125,
      padding: const pw.EdgeInsets.all(10),
      margin: const pw.EdgeInsets.only(top: 4),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _outline, width: .7),
        boxShadow: [
          pw.BoxShadow(
            color: PdfColor.fromHex('#E8EEEE'),
            blurRadius: 4,
            offset: const PdfPoint(0, -2),
          ),
        ],
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Expanded(
            child: image == null
                ? pw.Center(
                    child: pw.Text(
                      'Sin firma',
                      style: pw.TextStyle(fontSize: 9, color: _textSecondary),
                    ),
                  )
                : pw.Image(image, fit: pw.BoxFit.contain),
          ),
          pw.Container(height: .7, color: _outline),
          pw.SizedBox(height: 6),
          pw.Text(
            nombre,
            maxLines: 2,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _imagenes(List<String> values, {required double height}) =>
      _cuadriculaFotos(values, height: height);

  pw.Widget _cuadriculaFotos(
    List<String> values, {
    double height = 205,
    List<String?> referencias = const [],
  }) {
    final images = values.map(_imagen).whereType<pw.MemoryImage>().toList();
    if (images.isEmpty) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(18),
        decoration: pw.BoxDecoration(
          color: _background,
          borderRadius: pw.BorderRadius.circular(10),
        ),
        child: pw.Text(
          'No se adjuntaron fotografías a esta evaluación.',
          style: pw.TextStyle(fontSize: 10, color: _textSecondary),
        ),
      );
    }
    return pw.Wrap(
      spacing: 12,
      runSpacing: 12,
      children: images.indexed
          .map(
            (entry) => pw.Container(
              width: 245,
              height: height + 24,
              padding: const pw.EdgeInsets.all(4),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: _outline, width: .6),
                boxShadow: [
                  pw.BoxShadow(
                    color: PdfColor.fromHex('#E4EAEA'),
                    blurRadius: 4,
                    offset: const PdfPoint(0, -2),
                  ),
                ],
              ),
              child: pw.Column(
                children: [
                  pw.Expanded(
                    child: pw.ClipRRect(
                      horizontalRadius: 7,
                      verticalRadius: 7,
                      child: pw.Image(entry.$2, fit: pw.BoxFit.cover),
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    entry.$1 < referencias.length
                        ? (referencias[entry.$1] ?? 'Evidencia general')
                        : 'Evidencia general',
                    maxLines: 1,
                    style: pw.TextStyle(fontSize: 8, color: _textSecondary),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  String _simboloCategoria(String categoria) => switch (categoria) {
    'Songs' => 'S',
    'Vocabulary' => 'V',
    'Commands' => 'C',
    'Grammar' => 'G',
    'Dialogue' => 'D',
    'Recommendations' => 'R',
    'Sugerencias automáticas' => 'S',
    'Compromiso y recomendaciones del docente' => 'C',
    'Commitment' => 'CM',
    _ => 'i',
  };

  pw.MemoryImage? _imagen(String value) {
    try {
      return pw.MemoryImage(Uint8List.fromList(base64Decode(value)));
    } catch (_) {
      return null;
    }
  }

  Future<pw.MemoryImage?> _cargarLogo() async {
    try {
      final data = await rootBundle.load('assets/images/course_child_logo.png');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  Future<pw.ThemeData> _cargarTema() async {
    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
    );
    return pw.ThemeData.withFont(base: regular, bold: bold);
  }

  pw.Widget _piePagina(pw.Context context) => pw.Container(
    padding: const pw.EdgeInsets.only(top: 8),
    decoration: pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: _outline, width: .6)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Generado por Course Child App',
          style: pw.TextStyle(fontSize: 8.5, color: _textSecondary),
        ),
        pw.Text(
          'Página ${context.pageNumber} de ${context.pagesCount}',
          style: pw.TextStyle(fontSize: 8.5, color: _textSecondary),
        ),
      ],
    ),
  );

  String _fechaHora(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  String _fechaArchivo(DateTime value) =>
      '${value.year}${value.month.toString().padLeft(2, '0')}${value.day.toString().padLeft(2, '0')}';
  String _archivo(String value) {
    final normalizado = value
        .toLowerCase()
        .replaceAll(RegExp('[áàäâ]'), 'a')
        .replaceAll(RegExp('[éèëê]'), 'e')
        .replaceAll(RegExp('[íìïî]'), 'i')
        .replaceAll(RegExp('[óòöô]'), 'o')
        .replaceAll(RegExp('[úùüû]'), 'u')
        .replaceAll('ñ', 'n');
    return normalizado
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  String _tituloTipo(String value) => switch (value) {
    'capacitacion_preescolar' => 'Capacitación Preescolar',
    'capacitacion_primaria' => 'Capacitación Primaria',
    _ => value,
  };
  String _estado(EstadoEvaluacion value) => switch (value) {
    EstadoEvaluacion.borrador => 'Borrador',
    EstadoEvaluacion.enProgreso => 'En progreso',
    EstadoEvaluacion.completada => 'Completada',
  };
  String _calificacion(CalificacionConocimiento value) => switch (value) {
    CalificacionConocimiento.low => 'Bajo (20-59%)',
    CalificacionConocimiento.regular => 'Regular (60-79%)',
    CalificacionConocimiento.high => 'Alto (80-100%)',
  };

  String _observacionAutomatica(EvaluacionClase clase) {
    final pendientes = <String>[];
    for (final bloque in clase.bloques) {
      final contenidos = bloque.itemsMarcados.entries
          .where((item) => !item.value)
          .map((item) => item.key)
          .toList();
      if (contenidos.isNotEmpty) {
        pendientes.add('${bloque.bloqueNombre}: ${contenidos.join(', ')}.');
      } else if (bloque.itemsMarcados.isEmpty && !bloque.marcado) {
        pendientes.add('${bloque.bloqueNombre}: no se enseñó.');
      }
    }
    return pendientes.isEmpty
        ? 'Se enseñó todo el contenido programado.'
        : 'No se enseñaron los siguientes contenidos:\n- ${pendientes.join('\n- ')}';
  }
}
