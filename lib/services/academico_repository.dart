import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/docente_colegio.dart';
import '../models/visita_programada.dart';
import '../models/evaluacion.dart';
import '../models/evaluacion_clase.dart';
import '../models/evaluacion_bloque.dart';
import '../models/firma_docente.dart';
import '../models/reemplazo_contenido.dart';
import '../models/student_knowledge_report.dart';
import '../models/configuracion_notas.dart';
import '../models/contacto_colegio.dart';
import '../models/student_knowledge_draft.dart';
import 'archivos_academicos_repository.dart';
import 'offline/offline_codec.dart';

class DatosColegios {
  const DatosColegios(this.nombres, this.asignaciones, this.contactos);

  final Map<String, String> nombres;
  final Map<String, List<DocenteColegio>> asignaciones;
  final Map<String, ContactoColegio> contactos;
}

/// Acceso a los colegios y sus docentes escolares. Los identificadores de
/// Postgres nunca se derivan del texto del nombre.
class AcademicoRepository {
  AcademicoRepository(this.client);

  final SupabaseClient client;
  final Map<String, int> revisiones = {};
  late final ArchivosAcademicosRepository archivos =
      ArchivosAcademicosRepository(client);

  static String clave(String texto) => texto.trim().toLowerCase();

  Future<void> guardarBorrador(StudentKnowledgeDraft borrador) async {
    await client
        .from('borradores_reportes')
        .upsert({
          'autor_id': client.auth.currentUser!.id,
          'datos': borrador.toJson(),
        })
        .select('autor_id')
        .single();
  }

  Future<StudentKnowledgeDraft?> cargarBorrador() async {
    final fila = await client
        .from('borradores_reportes')
        .select()
        .eq('autor_id', client.auth.currentUser!.id)
        .maybeSingle();
    revisiones['borrador:${client.auth.currentUser!.id}'] =
        (fila?['revision'] as num?)?.toInt() ?? 0;
    return fila == null || fila['eliminado'] == true
        ? null
        : StudentKnowledgeDraft.fromJson(
            Map<String, dynamic>.from(fila['datos'] as Map),
          );
  }

  Future<void> eliminarBorrador() async {
    await client
        .from('borradores_reportes')
        .delete()
        .eq('autor_id', client.auth.currentUser!.id);
  }

  Future<DatosColegios> cargarColegios() async {
    final colegios = await client
        .from('colegios')
        .select('id, nombre, ciudad, direccion, telefono')
        .order('nombre');
    final asignaciones = await client
        .from('asignaciones_docentes')
        .select('id, colegio_id, docente_id, nivel, fecha_inicio, fecha_fin');
    final docentes = await client.from('docentes_colegio').select('id, nombre');
    final nombresPorId = <String, String>{
      for (final colegio in colegios)
        colegio['id'] as String: colegio['nombre'] as String,
    };
    final docentesPorId = <String, String>{
      for (final docente in docentes)
        docente['id'] as String: docente['nombre'] as String,
    };
    final nombres = <String, String>{
      for (final nombre in nombresPorId.values) clave(nombre): nombre,
    };
    final contactos = <String, ContactoColegio>{
      for (final fila in colegios)
        clave(fila['nombre'] as String): ContactoColegio(
          ciudad: fila['ciudad'] as String? ?? '',
          direccion: fila['direccion'] as String? ?? '',
          telefono: fila['telefono'] as String? ?? '',
        ),
    };
    final historial = <String, List<DocenteColegio>>{};
    for (final fila in asignaciones) {
      final colegio = nombresPorId[fila['colegio_id'] as String];
      final docente = docentesPorId[fila['docente_id'] as String];
      if (colegio == null || docente == null) continue;
      historial
          .putIfAbsent(clave(colegio), () => [])
          .add(
            DocenteColegio(
              nombre: docente,
              nivel: NivelDocente.values.byName(fila['nivel'] as String),
              fechaInicio: DateTime.parse(fila['fecha_inicio'] as String),
              fechaFin: fila['fecha_fin'] == null
                  ? null
                  : DateTime.parse(fila['fecha_fin'] as String),
            ),
          );
    }
    return DatosColegios(nombres, historial, contactos);
  }

  Future<void> guardarContactoColegio(
    String nombre,
    ContactoColegio contacto,
  ) async {
    await client
        .from('colegios')
        .update({
          'ciudad': contacto.ciudad.trim(),
          'direccion': contacto.direccion.trim(),
          'telefono': contacto.telefono.trim(),
        })
        .eq('nombre', nombre.trim())
        .select('id')
        .single();
  }

  Future<void> guardarAsignaciones(
    Map<String, String> nombres,
    Map<String, List<DocenteColegio>> asignaciones,
  ) async {
    await client.rpc<void>(
      'guardar_asignaciones_academicas',
      params: {
        'p_datos': [
          for (final nombre in nombres.values)
            {
              'nombre': nombre,
              'asignaciones': [
                for (final docente in asignaciones[clave(nombre)] ?? const [])
                  docente.toJson(),
              ],
            },
        ],
      },
    );
  }

  Future<List<VisitaProgramada>> cargarVisitas() async {
    final colegios = await client.from('colegios').select('id, nombre');
    final colegiosPorId = <String, String>{
      for (final fila in colegios)
        fila['id'] as String: fila['nombre'] as String,
    };
    final visitas = await client.from('visitas_programadas').select();
    final acompanantes = await client
        .from('visitas_acompanantes')
        .select('visita_id, nombre');
    final nombresPorVisita = <String, List<String>>{};
    for (final fila in acompanantes) {
      nombresPorVisita
          .putIfAbsent(fila['visita_id'] as String, () => [])
          .add(fila['nombre'] as String);
    }
    return [
      for (final fila in visitas)
        if (colegiosPorId[fila['colegio_id'] as String] case final nombre?)
          VisitaProgramada(
            id: fila['id'] as String,
            fecha: DateTime.parse(fila['fecha'] as String),
            colegio: nombre,
            tipo: fila['tipo'] as String,
            profesorResponsable: fila['responsable_nombre'] as String? ?? '',
            periodo: (fila['periodo'] as num?)?.toInt(),
            numeroClase: (fila['numero_clase'] as num?)?.toInt(),
            observacion: fila['observacion'] as String? ?? '',
            completada: fila['estado'] == 'realizada',
            cancelada: fila['estado'] == 'cancelada',
            motivoCancelacion: fila['motivo_cancelacion'] as String? ?? '',
            ultimaNovedad: fila['ultima_novedad'] as String? ?? '',
            serieId: fila['serie_id'] as String?,
            intervaloDias: (fila['intervalo_dias'] as num?)?.toInt(),
            duracionMinutos: (fila['duracion_minutos'] as num?)?.toInt() ?? 60,
            profesoresAcompanantes:
                nombresPorVisita[fila['id'] as String] ?? const [],
            ubicacion: fila['ubicacion'] as String? ?? '',
            estado: EstadoVisita.values.byName(fila['estado'] as String),
          ),
    ];
  }

  Future<void> guardarVisitas(List<VisitaProgramada> visitas) async {
    await client.rpc<void>(
      'guardar_visitas_academicas',
      params: {
        'p_visitas': [
          for (final visita in visitas)
            {
              'id': visita.id,
              'fecha': visita.fecha.toUtc().toIso8601String(),
              'colegio': visita.colegio,
              'tipo': visita.tipo,
              'nivel': visita.tipo.toLowerCase().contains('preescolar')
                  ? 'preescolar'
                  : visita.tipo.toLowerCase().contains('primaria')
                  ? 'primaria'
                  : null,
              'numero_clase': visita.numeroClase,
              'periodo': visita.periodo,
              'serie_id': visita.serieId,
              'intervalo_dias': visita.intervaloDias,
              'duracion_minutos': visita.duracionMinutos,
              'profesor_responsable': visita.profesorResponsable,
              'ubicacion': visita.ubicacion,
              'observacion': visita.observacion,
              'estado': visita.estado.name,
              'motivo_cancelacion': visita.motivoCancelacion,
              'ultima_novedad': visita.ultimaNovedad,
              'acompanantes': visita.profesoresAcompanantes,
            },
        ],
      },
    );
  }

  Future<Set<DateTime>> cargarFechasBloqueadas() async {
    final filas = await client.from('fechas_bloqueadas').select('fecha');
    return {for (final fila in filas) DateTime.parse(fila['fecha'] as String)};
  }

  Future<void> bloquearFecha(DateTime fecha) async {
    final fechaIso =
        '${fecha.year.toString().padLeft(4, '0')}-'
        '${fecha.month.toString().padLeft(2, '0')}-'
        '${fecha.day.toString().padLeft(2, '0')}';
    await client.from('fechas_bloqueadas').upsert({
      'fecha': fechaIso,
      'bloqueada_por': client.auth.currentUser!.id,
    });
  }

  Future<List<Evaluacion>> cargarEvaluaciones() async {
    final colegios = await client.from('colegios').select('id, nombre');
    final nombresColegios = {
      for (final fila in colegios)
        fila['id'] as String: fila['nombre'] as String,
    };
    final perfiles = await client.from('perfiles').select('id, nombre');
    final nombresPerfiles = {
      for (final fila in perfiles)
        fila['id'] as String: fila['nombre'] as String,
    };
    final docentes = await client.from('docentes_colegio').select('id, nombre');
    final nombresDocentes = {
      for (final fila in docentes)
        fila['id'] as String: fila['nombre'] as String,
    };
    final asignaciones = await client
        .from('asignaciones_docentes')
        .select('id, docente_id');
    final nombresAsignaciones = <String, String>{};
    for (final fila in asignaciones) {
      final nombre = nombresDocentes[fila['docente_id'] as String];
      if (nombre != null) nombresAsignaciones[fila['id'] as String] = nombre;
    }
    final evaluaciones = await client
        .from('evaluaciones_capacitacion')
        .select();
    for (final fila in evaluaciones) {
      revisiones['evaluacion:${fila['id']}'] =
          (fila['revision'] as num?)?.toInt() ?? 0;
    }
    final clases = await client.from('clases_capacitacion').select();
    final asistencias = await client
        .from('asistencias')
        .select('clase_id, asignacion_id, asistio');
    final asistenciasPorClase = <String, Map<String, bool>>{};
    for (final fila in asistencias) {
      final nombre = nombresAsignaciones[fila['asignacion_id'] as String];
      if (nombre == null) continue;
      asistenciasPorClase.putIfAbsent(
        fila['clase_id'] as String,
        () => {},
      )[nombre] = fila['asistio'] as bool;
    }
    final clasesPorEvaluacion = <String, List<EvaluacionClase>>{};
    for (final fila in clases) {
      final idClase = fila['id'] as String;
      final firmaRuta = fila['firma_docente_ruta'] as String?;
      final asistentes = <FirmaDocente>[];
      for (final item in fila['firmas_asistentes_rutas'] as List? ?? const []) {
        final datos = Map<String, dynamic>.from(item as Map);
        asistentes.add(
          FirmaDocente(
            nombre: datos['nombre'] as String,
            firmaBase64: await archivos.leerImagen(datos['ruta'] as String),
          ),
        );
      }
      clasesPorEvaluacion
          .putIfAbsent(fila['evaluacion_id'] as String, () => [])
          .add(
            EvaluacionClase(
              id: idClase,
              evaluacionId: fila['evaluacion_id'] as String,
              claseNumero: (fila['numero'] as num).toInt(),
              fecha: fila['fecha'] == null
                  ? null
                  : DateTime.parse(fila['fecha'] as String),
              firmaDocenteUrl: firmaRuta == null
                  ? null
                  : await archivos.leerImagen(firmaRuta),
              firmasAsistentes: asistentes,
              asistencia: asistenciasPorClase[idClase] ?? const {},
              observaciones: fila['observaciones'] as String? ?? '',
              bloqueCancionesSeleccionado:
                  fila['bloque_canciones_seleccionado'] as String?,
              bloques: [
                for (final bloque in fila['bloques'] as List? ?? const [])
                  EvaluacionBloque.fromJson(
                    Map<String, dynamic>.from(bloque as Map),
                  ),
              ],
            ),
          );
    }
    return [
      for (final fila in evaluaciones)
        if (nombresColegios[fila['colegio_id'] as String] case final colegio?)
          Evaluacion(
            id: fila['id'] as String,
            evaluadorTipo: fila['evaluador_tipo'] as String,
            colegio: colegio,
            fechaCreacion: DateTime.parse(fila['fecha_creacion'] as String),
            estado: EstadoEvaluacion.values.byName(fila['estado'] as String),
            clases: clasesPorEvaluacion[fila['id'] as String] ?? const [],
            fotosUrls: [
              for (final ruta in fila['fotos_rutas'] as List? ?? const [])
                await archivos.leerImagen(ruta as String),
            ],
            reemplazos: [
              for (final item in fila['reemplazos'] as List? ?? const [])
                ReemplazoContenido.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
            ],
            responsableNombre:
                nombresPerfiles[fila['responsable_id'] as String?],
          ),
    ];
  }

  Future<void> guardarEvaluacion(Evaluacion evaluacion) async {
    await client.rpc<void>(
      'guardar_evaluacion_academica',
      params: {'p_evaluacion': await prepararEvaluacion(evaluacion)},
    );
  }

  Future<Map<String, dynamic>> prepararEvaluacion(Evaluacion evaluacion) async {
    if (evaluacion.id == null || evaluacion.clases.any((c) => c.id == null)) {
      throw StateError(
        'La evaluación y sus clases necesitan un identificador.',
      );
    }
    final colegios = await client.from('colegios').select('id, nombre');
    final colegio = colegios
        .where(
          (fila) =>
              clave(fila['nombre'] as String) == clave(evaluacion.colegio),
        )
        .firstOrNull;
    if (colegio == null) throw StateError('El colegio no está registrado.');
    final colegioId = colegio['id'] as String;
    final perfiles = await client.from('perfiles').select('id, nombre');
    final responsables = perfiles
        .where(
          (fila) =>
              clave(fila['nombre'] as String) ==
              clave(evaluacion.responsableNombre ?? ''),
        )
        .toList();
    if (responsables.length != 1) {
      throw StateError(
        'El responsable debe tener un perfil único en Supabase.',
      );
    }
    final responsableId = responsables.single['id'] as String;

    final docentes = await client.from('docentes_colegio').select('id, nombre');
    final nombresDocentes = {
      for (final fila in docentes)
        fila['id'] as String: fila['nombre'] as String,
    };
    final asignaciones = await client
        .from('asignaciones_docentes')
        .select('id, colegio_id, docente_id, nivel, fecha_inicio, fecha_fin')
        .eq('colegio_id', colegioId);
    final nivel = evaluacion.evaluadorTipo.toLowerCase().contains('preescolar')
        ? 'preescolar'
        : 'primaria';
    final clases = <Map<String, dynamic>>[];
    for (final clase in evaluacion.clases) {
      final firmas = <Map<String, String>>[];
      for (final firma in clase.firmasAsistentes) {
        firmas.add({
          'nombre': firma.nombre,
          'ruta': await archivos.guardarImagen(
            colegioId: colegioId,
            registroId: clase.id!,
            tipo: 'asistente',
            base64: firma.firmaBase64,
            esFirma: true,
          ),
        });
      }
      final fecha = clase.fecha ?? evaluacion.fechaCreacion;
      final marcas = <Map<String, dynamic>>[];
      for (final marca in clase.asistencia.entries) {
        final candidatas = asignaciones.where((fila) {
          final inicio = DateTime.parse(fila['fecha_inicio'] as String);
          final fin = fila['fecha_fin'] == null
              ? null
              : DateTime.parse(fila['fecha_fin'] as String);
          return clave(nombresDocentes[fila['docente_id'] as String] ?? '') ==
                  clave(marca.key) &&
              fila['nivel'] == nivel &&
              !fecha.isBefore(inicio) &&
              (fin == null || fecha.isBefore(fin));
        }).toList();
        if (candidatas.length != 1) {
          throw StateError('No hay una asignación única para ${marca.key}.');
        }
        marcas.add({
          'asignacion_id': candidatas.single['id'],
          'asistio': marca.value,
        });
      }
      clases.add({
        'id': clase.id,
        'numero': clase.claseNumero,
        'fecha': clase.fecha?.toUtc().toIso8601String(),
        'bloques': clase.bloques.map((b) => b.toJson()).toList(),
        'bloque_canciones_seleccionado': clase.bloqueCancionesSeleccionado,
        'observaciones': clase.observaciones,
        'firma_docente_ruta': clase.firmaDocenteUrl == null
            ? null
            : await archivos.guardarImagen(
                colegioId: colegioId,
                registroId: clase.id!,
                tipo: 'representante',
                base64: clase.firmaDocenteUrl!,
                esFirma: true,
              ),
        'firmas_asistentes_rutas': firmas,
        'asistencias': marcas,
      });
    }
    final fotos = <String>[];
    for (final foto in evaluacion.fotosUrls) {
      fotos.add(
        await archivos.guardarImagen(
          colegioId: colegioId,
          registroId: evaluacion.id!,
          tipo: 'evidencia',
          base64: foto,
        ),
      );
    }
    return {
      'id': evaluacion.id,
      'colegio_id': colegioId,
      'nivel': nivel,
      'evaluador_tipo': evaluacion.evaluadorTipo,
      'responsable_id': responsableId,
      'estado': evaluacion.estado.name,
      'fecha_creacion': evaluacion.fechaCreacion.toUtc().toIso8601String(),
      'reemplazos': evaluacion.reemplazos.map((r) => r.toJson()).toList(),
      'fotos_rutas': fotos,
      'clases': clases,
    };
  }

  Future<List<StudentKnowledgeReport>> cargarReportes() async {
    final colegios = await client.from('colegios').select('id, nombre');
    final nombresColegios = {
      for (final fila in colegios)
        fila['id'] as String: fila['nombre'] as String,
    };
    final filas = await client.from('reportes_periodo').select();
    final reportes = <StudentKnowledgeReport>[];
    for (final fila in filas) {
      revisiones['reporte:${fila['codigo'] ?? fila['id']}'] =
          (fila['revision'] as num?)?.toInt() ?? 0;
      final colegio = nombresColegios[fila['colegio_id'] as String];
      if (colegio == null) continue;
      final datos = Map<String, dynamic>.from(fila['datos'] as Map? ?? {});
      final config = Map<String, dynamic>.from(
        datos['configuracion'] as Map? ?? {},
      );
      final configuracion = ConfiguracionNotas.fromDatabase({
        'notas': config,
        'asistencia_minima_profesor': datos['asistencia_minima_profesor'] ?? 80,
        'evaluacion_periodos_minima_profesor':
            datos['evaluacion_periodos_minima_profesor'] ?? 75,
      });
      Future<String> imagen(String clave) async {
        final ruta = fila[clave] as String?;
        return ruta == null ? '' : archivos.leerImagen(ruta);
      }

      final rutas = (fila['evidencia_rutas'] as List? ?? const [])
          .cast<String>();
      reportes.add(
        StudentKnowledgeReport(
          id: fila['codigo'] as String? ?? fila['id'] as String,
          fechaHora: DateTime.parse(fila['fecha_hora'] as String),
          docente: datos['docente'] as String? ?? '',
          profesorEvaluado:
              datos['profesor_responsable_salon'] as String? ?? '',
          colegio: colegio,
          grado: fila['grado'] as String,
          periodo: (fila['periodo'] as num).toInt(),
          evaluaciones: Map<String, String>.from(
            datos['evaluaciones'] as Map? ?? {},
          ),
          compromiso: datos['compromiso'] as String? ?? '',
          nota: (fila['nota'] as num?)?.toDouble(),
          calificacion: datos['calificacion'] == null
              ? null
              : CalificacionConocimiento.values.byName(
                  datos['calificacion'] as String,
                ),
          contenidosEvaluados:
              (datos['contenidos_evaluados'] as num?)?.toInt() ?? 0,
          totalContenidos: (datos['total_contenidos'] as num?)?.toInt() ?? 0,
          configuracionNotas: configuracion,
          firmaColegio: await imagen('firma_colegio_ruta'),
          firmaDocenteColegio: await imagen('firma_docente_colegio_ruta'),
          firmaDocenteCourseChild: await imagen('firma_course_child_ruta'),
          fotosEvidencia: [
            for (final ruta in rutas) await archivos.leerImagen(ruta),
          ],
          resultadosContenido: (datos['resultados_contenido'] as Map? ?? {})
              .map(
                (clave, valor) => MapEntry(
                  clave as String,
                  ResultadoContenido.values.byName(valor as String),
                ),
              ),
          nombresContenido: Map<String, String>.from(
            datos['nombres_contenido'] as Map? ?? {},
          ),
          comentariosContenido: Map<String, String>.from(
            datos['comentarios_contenido'] as Map? ?? {},
          ),
          referenciasFotos: (datos['referencias_fotos'] as List? ?? const [])
              .map((item) => item as String?)
              .toList(),
          firmaCoordinador: fila['firma_coordinador_ruta'] == null
              ? null
              : await imagen('firma_coordinador_ruta'),
          nombreCoordinador: fila['nombre_coordinador'] as String?,
          fechaAprobacion: fila['aprobado_en'] == null
              ? null
              : DateTime.parse(fila['aprobado_en'] as String),
        ),
      );
    }
    return reportes;
  }

  Future<void> guardarReporte(StudentKnowledgeReport reporte) async {
    await client
        .from('reportes_periodo')
        .upsert(await prepararReporte(reporte), onConflict: 'codigo');
  }

  Future<Map<String, dynamic>> prepararReporte(
    StudentKnowledgeReport reporte,
  ) async {
    final colegios = await client.from('colegios').select('id, nombre');
    final colegio = colegios
        .where(
          (fila) => clave(fila['nombre'] as String) == clave(reporte.colegio),
        )
        .firstOrNull;
    if (colegio == null) throw StateError('El colegio no está registrado.');
    final colegioId = colegio['id'] as String;
    final fotos = <String>[];
    for (final foto in reporte.fotosEvidencia) {
      fotos.add(
        await archivos.guardarImagen(
          colegioId: colegioId,
          registroId: reporte.id,
          tipo: 'reporte-foto',
          base64: foto,
        ),
      );
    }
    Future<String> subirFirma(String contenido, String tipo) =>
        archivos.guardarImagen(
          colegioId: colegioId,
          registroId: reporte.id,
          tipo: tipo,
          base64: contenido,
          esFirma: true,
        );
    final datos = {
      'docente': reporte.docente,
      'profesor_responsable_salon': reporte.profesorResponsableSalon,
      'evaluaciones': reporte.evaluaciones,
      'compromiso': reporte.compromiso,
      'calificacion': reporte.calificacion?.name,
      'contenidos_evaluados': reporte.contenidosEvaluados,
      'total_contenidos': reporte.totalContenidos,
      'configuracion': reporte.configuracionNotas.toJson(),
      'asistencia_minima_profesor':
          reporte.configuracionNotas.asistenciaMinimaProfesor,
      'evaluacion_periodos_minima_profesor':
          reporte.configuracionNotas.evaluacionPeriodosMinimaProfesor,
      'resultados_contenido': reporte.resultadosContenido.map(
        (clave, valor) => MapEntry(clave, valor.name),
      ),
      'nombres_contenido': reporte.nombresContenido,
      'comentarios_contenido': reporte.comentariosContenido,
      'referencias_fotos': reporte.referenciasFotos,
    };
    return {
      'codigo': reporte.id,
      'colegio_id': colegioId,
      'grado': reporte.grado,
      'periodo': reporte.periodo,
      'fecha_hora': reporte.fechaHora.toUtc().toIso8601String(),
      'nota': reporte.notaFinal,
      'puntaje_maximo': reporte.configuracionNotas.puntosLogrado,
      'datos': datos,
      'firma_colegio_ruta': await subirFirma(
        reporte.firmaColegio,
        'firma-colegio',
      ),
      'firma_docente_colegio_ruta': await subirFirma(
        reporte.firmaDocenteColegio,
        'firma-docente-colegio',
      ),
      'firma_course_child_ruta': await subirFirma(
        reporte.firmaDocenteCourseChild,
        'firma-course-child',
      ),
      'evidencia_rutas': fotos,
      'autor_id': client.auth.currentUser!.id,
    };
  }

  Future<int> enviarOperacion(Map<String, dynamic> op) async {
    final datos = Map<String, dynamic>.from(op['datos'] as Map);
    final payload = switch (op['tipo']) {
      'evaluacion' => await prepararEvaluacion(
        OfflineCodec.leerEvaluacion(datos),
      ),
      'reporte' => await prepararReporte(OfflineCodec.leerReporte(datos)),
      'borrador' => datos,
      _ => throw StateError('Tipo de cambio desconocido'),
    };
    final revision = await client.rpc(
      'sincronizar_academico',
      params: {
        'p_operacion': op['id'],
        'p_tipo': op['tipo'],
        'p_recurso': op['recurso'],
        'p_revision': op['revision'],
        'p_datos': payload,
      },
    );
    return (revision as num).toInt();
  }

  Future<void> aprobarReporte({
    required String codigo,
    required String firma,
    required String nombreCoordinador,
  }) async {
    final filas = await client
        .from('reportes_periodo')
        .select('id, colegio_id')
        .eq('codigo', codigo);
    if (filas.length != 1) throw StateError('Reporte no encontrado.');
    final colegioId = filas.single['colegio_id'] as String;
    final ruta = await archivos.guardarImagen(
      colegioId: colegioId,
      registroId: codigo,
      tipo: 'firma-coordinador',
      base64: firma,
      esFirma: true,
    );
    await client
        .from('reportes_periodo')
        .update({
          'firma_coordinador_ruta': ruta,
          'nombre_coordinador': nombreCoordinador,
          'aprobado_por': client.auth.currentUser!.id,
          'aprobado_en': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('codigo', codigo)
        .select('id')
        .single();
  }
}
