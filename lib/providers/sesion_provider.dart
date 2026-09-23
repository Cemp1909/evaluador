import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../config/auth_config.dart';
import '../models/profesor.dart';
import '../models/evaluacion.dart';
import '../models/estado_evaluacion_profesor.dart';
import '../models/configuracion_notas.dart';
import '../models/contacto_colegio.dart';
import '../models/docente_colegio.dart';
import '../models/student_knowledge_draft.dart';
import '../models/student_knowledge_report.dart';
import '../models/usuario_sesion.dart';
import '../models/visita_programada.dart';
import '../security/rbac.dart';
import '../models/reemplazo_contenido.dart';
import '../models/resumen_seguimiento_profesor.dart';
import '../services/evaluacion_service.dart';
import '../services/academico_repository.dart';
import '../services/offline/offline_store.dart';
import '../services/offline/store_busy.dart';
import '../services/offline/offline_codec.dart';
import '../services/offline/sync_engine.dart';

part 'sesion_offline.dart';

class SesionProvider extends ChangeNotifier {
  SesionProvider(
    this._config, {
    SupabaseClient? supabaseClient,
    this.offlineFactory,
  }) : _supabaseClient = supabaseClient,
       _profesores = [
         for (final profesor in _config.profesoresIniciales)
           Profesor(
             nombre: profesor.nombre,
             usuario: profesor.usuario,
             password: profesor.password,
             zona: profesor.zona,
             aprobado: true,
           ),
       ];

  final Map<String, List<DocenteColegio>> _docentesColegios = {};
  final Map<String, String> _nombresColegios = {};
  final Map<String, ContactoColegio> _contactosColegios = {};
  String _claveColegio(String colegio) => colegio.trim().toLowerCase();
  ContactoColegio contactoColegio(String colegio) =>
      _contactosColegios[_claveColegio(colegio)] ?? const ContactoColegio();

  Future<String?> guardarContactoColegio(
    String colegio,
    ContactoColegio contacto,
  ) async {
    final error = _requiere(Permiso.asignarProfesores);
    if (error != null) return error;
    final clave = _claveColegio(colegio);
    if (!_nombresColegios.containsKey(clave)) {
      return 'Primero registra el colegio.';
    }
    if (_repositorio != null) {
      try {
        await _repositorio.guardarContactoColegio(
          _nombresColegios[clave]!,
          contacto,
        );
      } catch (_) {
        return 'No se pudieron guardar los datos del colegio en Supabase.';
      }
    }
    _contactosColegios[clave] = contacto;
    notifyListeners();
    return null;
  }

  List<DocenteColegio> asignacionesDocentesColegio(
    String colegio, {
    bool incluirInactivas = false,
  }) => List.unmodifiable(
    (_docentesColegios[_claveColegio(colegio)] ?? []).where(
      (asignacion) => incluirInactivas || asignacion.activo,
    ),
  );
  List<DocenteColegio> historialAsignacionesDocente(String profesor) {
    final claveProfesor = profesor.trim().toLowerCase();
    final historial =
        _docentesColegios.values
            .expand((asignaciones) => asignaciones)
            .where(
              (asignacion) =>
                  asignacion.nombre.trim().toLowerCase() == claveProfesor,
            )
            .toList()
          ..sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));
    return List.unmodifiable(historial);
  }

  List<String> docentesColegio(String colegio, {NivelDocente? nivel}) =>
      List.unmodifiable(
        asignacionesDocentesColegio(colegio)
            .where((docente) => nivel == null || docente.nivel == nivel)
            .map((docente) => docente.nombre),
      );
  NivelDocente? nivelDocenteColegio(String colegio, String profesor) =>
      asignacionesDocentesColegio(colegio)
          .where(
            (docente) =>
                docente.nombre.trim().toLowerCase() ==
                profesor.trim().toLowerCase(),
          )
          .firstOrNull
          ?.nivel;
  List<String> get colegiosRegistrados =>
      _nombresColegios.values.toList()..sort();

  List<ResumenSeguimientoProfesor> seguimientoProfesores(String colegio) {
    final claveColegio = _claveColegio(colegio);
    final asignaciones = asignacionesDocentesColegio(
      colegio,
      incluirInactivas: true,
    );
    final evaluaciones = _borradoresEvaluacion.values
        .where(
          (evaluacion) => _claveColegio(evaluacion.colegio) == claveColegio,
        )
        .toList(growable: false);
    final nombres = <String, String>{};
    for (final asignacion in asignaciones) {
      nombres[asignacion.nombre.trim().toLowerCase()] = asignacion.nombre
          .trim();
    }
    for (final evaluacion in evaluaciones) {
      for (final clase in evaluacion.clases) {
        for (final nombre in clase.asistencia.keys) {
          nombres.putIfAbsent(nombre.trim().toLowerCase(), () => nombre.trim());
        }
      }
    }
    final resumenes = <ResumenSeguimientoProfesor>[];
    for (final entry in nombres.entries) {
      final asignacionesProfesor = asignaciones
          .where((item) => item.nombre.trim().toLowerCase() == entry.key)
          .toList(growable: false);
      bool correspondeEvaluacion(Evaluacion evaluacion) =>
          asignacionesProfesor.isEmpty ||
          asignacionesProfesor.any(
            (item) =>
                item.estabaAsignadoEn(evaluacion.fechaCreacion) &&
                _evaluacionCorrespondeNivel(evaluacion, item.nivel),
          );
      var asistidas = 0;
      var inasistencias = 0;
      var pendientes = 0;
      var ensenados = 0;
      var contenidosPendientes = 0;
      var reemplazados = 0;
      final observaciones = <String>[];
      for (final evaluacion in evaluaciones) {
        if (!correspondeEvaluacion(evaluacion)) continue;
        for (final clase in evaluacion.clases) {
          final asistencia = clase.asistencia.entries
              .where((item) => item.key.trim().toLowerCase() == entry.key)
              .firstOrNull
              ?.value;
          if (asistencia == true) {
            asistidas++;
            for (final bloque in clase.bloquesEvaluables) {
              if (bloque.itemsMarcados.isEmpty) {
                bloque.marcado ? ensenados++ : contenidosPendientes++;
              } else {
                ensenados += bloque.itemsMarcados.values
                    .where((valor) => valor)
                    .length;
                contenidosPendientes += bloque.itemsMarcados.values
                    .where((valor) => !valor)
                    .length;
              }
            }
            reemplazados += evaluacion.reemplazos
                .where((item) => item.claseId == '${clase.claseNumero}')
                .length;
            if (clase.observaciones.trim().isNotEmpty) {
              observaciones.add(
                'Clase ${clase.claseNumero}: ${clase.observaciones.trim()}',
              );
            }
          } else if (asistencia == false) {
            inasistencias++;
          } else {
            pendientes++;
          }
        }
      }
      resumenes.add(
        ResumenSeguimientoProfesor(
          profesor: entry.value,
          colegio: colegio,
          nivel:
              asignacionesProfesor
                  .where((item) => item.activo)
                  .firstOrNull
                  ?.nivel ??
              asignacionesProfesor.lastOrNull?.nivel,
          clasesAsistidas: asistidas,
          inasistencias: inasistencias,
          clasesPendientes: pendientes,
          contenidosEnsenados: ensenados,
          contenidosPendientes: contenidosPendientes,
          contenidosReemplazados: reemplazados,
          avancesSalon: _reportesConocimiento
              .where(
                (reporte) =>
                    _claveColegio(reporte.colegio) == claveColegio &&
                    (asignacionesProfesor.isEmpty ||
                        asignacionesProfesor.any(
                          (item) => item.estabaAsignadoEn(reporte.fechaHora),
                        )) &&
                    reporte.profesorResponsableSalon.trim().toLowerCase() ==
                        entry.key,
              )
              .map(
                (reporte) =>
                    '${reporte.grado} · Período ${reporte.periodo}: '
                    '${reporte.notaFinal.toStringAsFixed(1)} (${reporte.desempeno})',
              )
              .toList(growable: false),
          observaciones: observaciones.toSet().toList(growable: false),
        ),
      );
    }
    resumenes.sort((a, b) => a.profesor.compareTo(b.profesor));
    return List.unmodifiable(resumenes);
  }

  List<EstadoEvaluacionProfesor> estadoEvaluacionesProfesores() {
    final estados = <EstadoEvaluacionProfesor>[];
    for (final colegio in colegiosRegistrados) {
      final claveColegio = _claveColegio(colegio);
      for (final asignacion in asignacionesDocentesColegio(
        colegio,
        incluirInactivas: true,
      )) {
        final profesor = asignacion.nombre;
        final claveProfesor = profesor.trim().toLowerCase();
        final clasesProgramadas = _visitas.where(
          (visita) =>
              _claveColegio(visita.colegio) == claveColegio &&
              visita.numeroClase != null &&
              !visita.cancelada &&
              asignacion.estabaAsignadoEn(visita.fecha) &&
              _visitaCorrespondeNivel(visita, asignacion.nivel),
        );
        final totalClases = clasesProgramadas.length;
        final clasesCompletadas = clasesProgramadas
            .where(
              (visita) =>
                  visita.completada || visita.estado == EstadoVisita.realizada,
            )
            .length;
        final reportesProfesor = _reportesConocimiento
            .where(
              (reporte) =>
                  _claveColegio(reporte.colegio) == claveColegio &&
                  asignacion.estabaAsignadoEn(reporte.fechaHora) &&
                  reporte.profesorResponsableSalon.trim().toLowerCase() ==
                      claveProfesor,
            )
            .toList(growable: false);
        final periodos = reportesProfesor
            .map((reporte) => reporte.periodo)
            .toSet();
        final promedioSalones = reportesProfesor.isEmpty
            ? 0.0
            : reportesProfesor.fold<double>(
                    0,
                    (total, reporte) => total + reporte.notaFinal,
                  ) /
                  reportesProfesor.length;
        final porcentajeEvaluacionesPeriodos = reportesProfesor.isEmpty
            ? 0.0
            : reportesProfesor.fold<double>(0, (total, reporte) {
                    final puntajeMaximo =
                        reporte.configuracionNotas.puntosLogrado;
                    if (puntajeMaximo <= 0) return total;
                    return total +
                        (reporte.notaFinal * 100 / puntajeMaximo)
                            .clamp(0, 100)
                            .toDouble();
                  }) /
                  reportesProfesor.length;
        var asistidas = 0;
        var inasistencias = 0;
        for (final evaluacion in _borradoresEvaluacion.values.where(
          (item) =>
              _claveColegio(item.colegio) == claveColegio &&
              asignacion.estabaAsignadoEn(item.fechaCreacion) &&
              _evaluacionCorrespondeNivel(item, asignacion.nivel),
        )) {
          for (final clase in evaluacion.clases) {
            final asistencia = clase.asistencia.entries
                .where((item) => item.key.trim().toLowerCase() == claveProfesor)
                .firstOrNull
                ?.value;
            if (asistencia == true) asistidas++;
            if (asistencia == false) inasistencias++;
          }
        }
        estados.add(
          EstadoEvaluacionProfesor(
            profesor: profesor,
            colegio: colegio,
            nivel: asignacion.nivel,
            fechaInicio: asignacion.fechaInicio,
            fechaFin: asignacion.fechaFin,
            periodosCompletos: Set.unmodifiable(periodos),
            clasesProgramadas: totalClases,
            clasesCompletadas: clasesCompletadas,
            contenidosEvaluables: _contenidosEnsenadosAProfesor(
              colegio,
              asignacion,
            ),
            clasesAsistidas: asistidas,
            inasistencias: inasistencias,
            evaluacionesSalon: reportesProfesor.length,
            promedioSalones: promedioSalones,
            porcentajeEvaluacionesPeriodos: porcentajeEvaluacionesPeriodos,
            asistenciaMinima: _configuracionNotas.asistenciaMinimaProfesor,
            evaluacionPeriodosMinima:
                _configuracionNotas.evaluacionPeriodosMinimaProfesor,
          ),
        );
      }
    }
    estados.sort((a, b) {
      final colegio = a.colegio.compareTo(b.colegio);
      return colegio != 0 ? colegio : a.profesor.compareTo(b.profesor);
    });
    return List.unmodifiable(estados);
  }

  bool _visitaCorrespondeNivel(VisitaProgramada visita, NivelDocente nivel) {
    final tipo = visita.tipo.toLowerCase();
    if (tipo.contains('preescolar')) return nivel == NivelDocente.preescolar;
    if (tipo.contains('primaria')) return nivel == NivelDocente.primaria;
    return true;
  }

  bool _evaluacionCorrespondeNivel(Evaluacion evaluacion, NivelDocente nivel) {
    final tipo = evaluacion.evaluadorTipo.toLowerCase();
    if (tipo.contains('preescolar')) return nivel == NivelDocente.preescolar;
    if (tipo.contains('primaria')) return nivel == NivelDocente.primaria;
    return true;
  }

  List<String> _contenidosEnsenadosAProfesor(
    String colegio,
    DocenteColegio asignacion,
  ) {
    final claveColegio = _claveColegio(colegio);
    final claveProfesor = asignacion.nombre.trim().toLowerCase();
    final contenidos = <String, String>{};
    for (final evaluacion in _borradoresEvaluacion.values.where(
      (item) =>
          _claveColegio(item.colegio) == claveColegio &&
          asignacion.estabaAsignadoEn(item.fechaCreacion) &&
          _evaluacionCorrespondeNivel(item, asignacion.nivel),
    )) {
      for (final clase in evaluacion.clases) {
        final asistio = clase.asistencia.entries
            .where((item) => item.key.trim().toLowerCase() == claveProfesor)
            .firstOrNull
            ?.value;
        if (asistio != true) continue;
        for (final bloque in clase.bloquesEvaluables) {
          for (final item in bloque.itemsMarcados.entries.where(
            (item) => item.value,
          )) {
            final contenidoId = clase.contenidoId(
              bloque.bloqueNombre,
              item.key,
            );
            final reemplazo = evaluacion.reemplazos
                .where((cambio) => cambio.contenidoId == contenidoId)
                .firstOrNull;
            final nombre = reemplazo?.nombreTemporal.trim() ?? item.key.trim();
            contenidos.putIfAbsent(nombre.toLowerCase(), () => nombre);
          }
        }
      }
    }
    return List.unmodifiable(contenidos.values);
  }

  String? asignarDocentesColegio(String colegio, List<String> docentes) {
    return asignarDocentesColegioPorNivel(
      colegio,
      preescolar: docentes,
      primaria: const [],
    );
  }

  String? asignarDocentesColegioPorNivel(
    String colegio, {
    required List<String> preescolar,
    required List<String> primaria,
    DateTime? fechaInicio,
  }) {
    final error = _requiere(Permiso.asignarProfesores);
    if (error != null) return error;
    return _guardarDocentesColegioPorNivel(
      colegio,
      preescolar: preescolar,
      primaria: primaria,
      fechaInicio: fechaInicio,
    );
  }

  Future<String?> asignarDocentesColegioPorNivelPersistente(
    String colegio, {
    required List<String> preescolar,
    required List<String> primaria,
    DateTime? fechaInicio,
  }) => _guardarAsignacionesPersistentes(
    () => asignarDocentesColegioPorNivel(
      colegio,
      preescolar: preescolar,
      primaria: primaria,
      fechaInicio: fechaInicio,
    ),
  );

  bool puedeRegistrarDocentesEnClase(Evaluacion evaluacion) {
    if (tienePermiso(Permiso.asignarProfesores)) return true;
    final usuario = _usuarioActual;
    return usuario?.rol == RolUsuario.profesor &&
        evaluacion.responsableNombre?.trim().toLowerCase() ==
            usuario!.nombre.trim().toLowerCase();
  }

  String? registrarDocentesDesdeClase(
    Evaluacion evaluacion, {
    required List<String> preescolar,
    required List<String> primaria,
  }) {
    if (!puedeRegistrarDocentesEnClase(evaluacion)) {
      return 'Solo el responsable de la clase, el coordinador o el administrador pueden registrar docentes.';
    }
    return _guardarDocentesColegioPorNivel(
      evaluacion.colegio,
      preescolar: preescolar,
      primaria: primaria,
      fechaInicio: DateTime.now(),
    );
  }

  Future<String?> registrarDocentesDesdeClasePersistente(
    Evaluacion evaluacion, {
    required List<String> preescolar,
    required List<String> primaria,
  }) => _guardarAsignacionesPersistentes(
    () => registrarDocentesDesdeClase(
      evaluacion,
      preescolar: preescolar,
      primaria: primaria,
    ),
  );

  Future<String?> _guardarAsignacionesPersistentes(
    String? Function() modificarLocal,
  ) async {
    final anterioresNombres = Map<String, String>.from(_nombresColegios);
    final anterioresAsignaciones = <String, List<DocenteColegio>>{
      for (final item in _docentesColegios.entries)
        item.key: List<DocenteColegio>.from(item.value),
    };
    final error = modificarLocal();
    if (error != null || _supabaseClient == null) return error;
    try {
      await _repositorio!.guardarAsignaciones(
        _nombresColegios,
        _docentesColegios,
      );
      return null;
    } catch (_) {
      _nombresColegios
        ..clear()
        ..addAll(anterioresNombres);
      _docentesColegios
        ..clear()
        ..addAll(anterioresAsignaciones);
      notifyListeners();
      return 'No se pudieron guardar los docentes en Supabase. Revisa los permisos e inténtalo de nuevo.';
    }
  }

  String? transferirDocente({
    required String profesor,
    required String colegioDestino,
    required NivelDocente nivel,
    required DateTime fecha,
  }) {
    final error = _requiere(Permiso.asignarProfesores);
    if (error != null) return error;
    if (profesor.trim().isEmpty) return 'Escribe el nombre del profesor.';
    final actuales = asignacionesDocentesColegio(colegioDestino);
    return _guardarDocentesColegioPorNivel(
      colegioDestino,
      preescolar: [
        ...actuales
            .where((item) => item.nivel == NivelDocente.preescolar)
            .map((item) => item.nombre),
        if (nivel == NivelDocente.preescolar) profesor,
      ],
      primaria: [
        ...actuales
            .where((item) => item.nivel == NivelDocente.primaria)
            .map((item) => item.nombre),
        if (nivel == NivelDocente.primaria) profesor,
      ],
      fechaInicio: fecha,
    );
  }

  String? _guardarDocentesColegioPorNivel(
    String colegio, {
    required List<String> preescolar,
    required List<String> primaria,
    DateTime? fechaInicio,
  }) {
    if (colegio.trim().isEmpty) return 'Escribe el nombre del colegio.';
    final fecha = fechaInicio ?? DateTime.now();
    final deseados = <String, DocenteColegio>{};
    void agregar(Iterable<String> docentes, NivelDocente nivel) {
      for (final nombre in docentes) {
        if (nombre.trim().isNotEmpty) {
          deseados[nombre.trim().toLowerCase()] = DocenteColegio(
            nombre: nombre.trim(),
            nivel: nivel,
            fechaInicio: fecha,
          );
        }
      }
    }

    agregar(preescolar, NivelDocente.preescolar);
    agregar(primaria, NivelDocente.primaria);
    final claveDestino = _claveColegio(colegio);

    for (final entry in _docentesColegios.entries) {
      for (final asignacion in entry.value.where((item) => item.activo)) {
        final claveProfesor = asignacion.nombre.trim().toLowerCase();
        final deseado = deseados[claveProfesor];
        final permanece =
            entry.key == claveDestino &&
            deseado != null &&
            deseado.nivel == asignacion.nivel;
        final debeCerrar =
            !permanece && (entry.key == claveDestino || deseado != null);
        if (debeCerrar && fecha.isBefore(asignacion.fechaInicio)) {
          return 'La fecha del cambio no puede ser anterior al inicio de la asignación de ${asignacion.nombre}.';
        }
      }
    }

    _nombresColegios[claveDestino] = colegio.trim();

    for (final entry in _docentesColegios.entries) {
      for (var i = 0; i < entry.value.length; i++) {
        final asignacion = entry.value[i];
        final claveProfesor = asignacion.nombre.trim().toLowerCase();
        final deseado = deseados[claveProfesor];
        final permanece =
            entry.key == claveDestino &&
            deseado != null &&
            deseado.nivel == asignacion.nivel;
        if (asignacion.activo && permanece) {
          entry.value[i] = DocenteColegio(
            nombre: deseado.nombre,
            nivel: asignacion.nivel,
            fechaInicio: asignacion.fechaInicio,
          );
        }
        if (asignacion.activo &&
            !permanece &&
            (entry.key == claveDestino || deseado != null)) {
          entry.value[i] = asignacion.cerrar(fecha);
        }
      }
    }

    final historialDestino = _docentesColegios.putIfAbsent(
      claveDestino,
      () => [],
    );
    for (final entry in deseados.entries) {
      final yaExiste = historialDestino.any(
        (asignacion) =>
            asignacion.activo &&
            asignacion.nombre.trim().toLowerCase() == entry.key &&
            asignacion.nivel == entry.value.nivel,
      );
      if (!yaExiste) historialDestino.add(entry.value);
    }
    notifyListeners();
    return null;
  }

  final Future<OfflineStore> Function(String usuario)? offlineFactory;
  OfflineStore? _offline;
  SyncEngine? _sync;
  String? _offlineUid;
  DateTime? _validadoEn;
  bool _saliendo = false;
  bool _restaurando = false;
  void _notificarOffline() => notifyListeners();
  final AuthConfig _config;
  final SupabaseClient? _supabaseClient;
  late final AcademicoRepository? _repositorio = _supabaseClient == null
      ? null
      : AcademicoRepository(_supabaseClient);
  final List<Profesor> _profesores;
  List<Profesor> _profesoresRemotos = const [];
  final List<StudentKnowledgeReport> _reportesConocimiento = [];
  final Map<String, Evaluacion> _borradoresEvaluacion = {};
  final List<VisitaProgramada> _visitas = [];
  final Set<DateTime> _fechasBloqueadas = {};
  StudentKnowledgeDraft? _borradorConocimiento;
  Future<void> _colaBorradores = Future<void>.value();
  ConfiguracionNotas _configuracionNotas = const ConfiguracionNotas();
  UsuarioSesion? _usuarioActual;

  List<Profesor> get profesores => List.unmodifiable(_profesores);
  List<StudentKnowledgeReport> get reportesConocimiento =>
      List.unmodifiable(_reportesConocimiento);
  UsuarioSesion? get usuarioActual => _usuarioActual;
  bool get usaSupabase => _supabaseClient != null;
  bool get tieneSesionRemota => _supabaseClient?.auth.currentSession != null;
  bool get estaAutenticado => _usuarioActual != null;
  StudentKnowledgeDraft? get borradorConocimiento => _borradorConocimiento;
  ConfiguracionNotas get configuracionNotas => _configuracionNotas;
  List<VisitaProgramada> get visitas {
    final usuario = _usuarioActual;
    if (usuario?.rol != RolUsuario.profesor) return List.unmodifiable(_visitas);
    return List.unmodifiable(_visitas.where(_visitaAsignadaAlUsuario));
  }

  Set<DateTime> get fechasBloqueadas => Set.unmodifiable(_fechasBloqueadas);
  bool tienePermiso(Permiso permiso) => Rbac.tiene(_usuarioActual, permiso);

  String? _requiere(Permiso permiso) => _saliendo || _restaurando
      ? 'Espera a que termine el cambio de sesión.'
      : sinConexion &&
            !{
              Permiso.crearEvaluaciones,
              Permiso.verResultadosAsignados,
            }.contains(permiso)
      ? 'Esta acción requiere conexión a internet.'
      : tienePermiso(permiso)
      ? null
      : _usuarioActual == null
      ? 'Debes iniciar sesión para realizar esta acción.'
      : 'No tienes permiso para realizar esta acción.';

  bool _visitaAsignadaAlUsuario(VisitaProgramada visita) {
    final nombre = _usuarioActual?.nombre.trim().toLowerCase();
    if (nombre == null || nombre.isEmpty) return false;
    return visita.profesorResponsable.trim().toLowerCase() == nombre ||
        visita.profesoresAcompanantes.any(
          (profesor) => profesor.trim().toLowerCase() == nombre,
        );
  }

  String? _requiereAdministrarAgenda() {
    final error = _requiere(Permiso.gestionarAgenda);
    if (error != null) return error;
    return _usuarioActual?.rol == RolUsuario.profesor
        ? 'El profesor puede consultar, cancelar o marcar como realizada únicamente su agenda asignada.'
        : null;
  }

  String? _requiereVisitaAsignada(VisitaProgramada visita) {
    final error = _requiere(Permiso.gestionarAgenda);
    if (error != null) return error;
    if (_usuarioActual?.rol == RolUsuario.profesor &&
        !_visitaAsignadaAlUsuario(visita)) {
      return 'No tienes permiso para modificar una actividad que no te fue asignada.';
    }
    return null;
  }

  String? bloquearFecha(DateTime fecha) {
    final error = _requiereAdministrarAgenda();
    if (error != null) return error;
    _fechasBloqueadas.add(DateTime(fecha.year, fecha.month, fecha.day));
    notifyListeners();
    return null;
  }

  Future<String?> bloquearFechaPersistente(DateTime fecha) async {
    final error = _requiereAdministrarAgenda();
    if (error != null) return error;
    if (_supabaseClient == null) return bloquearFecha(fecha);
    try {
      await _repositorio!.bloquearFecha(fecha);
      return bloquearFecha(fecha);
    } catch (_) {
      return 'No se pudo bloquear la fecha en Supabase.';
    }
  }

  String? desbloquearFecha(DateTime fecha) {
    final error = _requiereAdministrarAgenda();
    if (error != null) return error;
    _fechasBloqueadas.remove(DateTime(fecha.year, fecha.month, fecha.day));
    notifyListeners();
    return null;
  }

  String? programarVisita(VisitaProgramada visita) {
    final acceso = _requiereAdministrarAgenda();
    if (acceso != null) return acceso;
    final error = _validarVisita(visita, _visitas);
    if (error != null) return error;
    _visitas.add(visita);
    _ordenarVisitas();
    notifyListeners();
    return null;
  }

  Future<String?> programarVisitaPersistente(VisitaProgramada visita) =>
      _guardarVisitasPersistentes(() => programarVisita(visita));

  String? programarSerieClases(
    VisitaProgramada inicial, {
    int intervaloDias = 7,
  }) {
    final acceso = _requiereAdministrarAgenda();
    if (acceso != null) return acceso;
    if (inicial.numeroClase == null ||
        inicial.tipo == 'Evaluación por colegio') {
      return 'La programación automática solo está disponible para clases.';
    }
    final total = inicial.tipo == 'Capacitación preescolar' ? 6 : 11;
    if (intervaloDias != 7 && intervaloDias != 14) {
      return 'La frecuencia debe ser cada 8 o cada 15 días.';
    }
    final serie = <VisitaProgramada>[];
    final serieId = inicial.id;
    for (var clase = inicial.numeroClase!; clase <= total; clase++) {
      final visita = VisitaProgramada(
        id: const Uuid().v4(),
        fecha: inicial.fecha.add(
          Duration(days: intervaloDias * (clase - inicial.numeroClase!)),
        ),
        colegio: inicial.colegio,
        tipo: inicial.tipo,
        profesorResponsable: inicial.profesorResponsable,
        numeroClase: clase,
        observacion: inicial.observacion,
        serieId: serieId,
        intervaloDias: intervaloDias,
        duracionMinutos: inicial.duracionMinutos,
        profesoresAcompanantes: inicial.profesoresAcompanantes,
        ubicacion: inicial.ubicacion,
        estado: inicial.estado,
      );
      final error = _validarVisita(visita, [..._visitas, ...serie]);
      if (error != null) return 'No se pudo crear la serie: $error';
      serie.add(visita);
    }
    _visitas.addAll(serie);
    _ordenarVisitas();
    notifyListeners();
    return null;
  }

  Future<String?> programarSerieClasesPersistente(
    VisitaProgramada inicial, {
    int intervaloDias = 7,
  }) => _guardarVisitasPersistentes(
    () => programarSerieClases(inicial, intervaloDias: intervaloDias),
  );

  Future<String?> _guardarVisitasPersistentes(
    String? Function() modificarLocal,
  ) async {
    final anteriores = List<VisitaProgramada>.from(_visitas);
    final anterioresPorId = {
      for (final visita in anteriores) visita.id: visita,
    };
    final error = modificarLocal();
    if (error != null || _supabaseClient == null) return error;
    final modificadas = _visitas
        .where((visita) => !identical(anterioresPorId[visita.id], visita))
        .toList(growable: false);
    if (modificadas.isEmpty) return null;
    try {
      await _repositorio!.guardarVisitas(modificadas);
      return null;
    } catch (_) {
      _visitas
        ..clear()
        ..addAll(anteriores);
      notifyListeners();
      return 'No se pudo guardar la agenda en Supabase. Revisa la conexión y los permisos.';
    }
  }

  String? _validarVisita(
    VisitaProgramada visita,
    Iterable<VisitaProgramada> existentes,
  ) {
    final colegio = visita.colegio.trim().toLowerCase();
    final dia = DateTime(
      visita.fecha.year,
      visita.fecha.month,
      visita.fecha.day,
    );
    if (_fechasBloqueadas.contains(dia)) {
      return 'La fecha seleccionada está bloqueada en la agenda.';
    }
    final esEnglishDay =
        visita.tipo == 'English Day' || visita.tipo == 'Ensayo de English Day';
    if (esEnglishDay) {
      final cantidad = existentes.where((existente) {
        return !existente.cancelada &&
            existente.colegio.trim().toLowerCase() == colegio &&
            existente.tipo == visita.tipo;
      }).length;
      if (cantidad >= 3) {
        return visita.tipo == 'English Day'
            ? 'Este colegio ya tiene el máximo de 3 fechas de English Day.'
            : 'Este colegio ya tiene el máximo de 3 ensayos de English Day.';
      }
    }
    final duplicada = existentes.any((existente) {
      if (existente.colegio.trim().toLowerCase() != colegio) return false;
      if (visita.periodo != null) {
        return existente.periodo == visita.periodo;
      }
      return visita.numeroClase != null &&
          existente.tipo == visita.tipo &&
          existente.numeroClase == visita.numeroClase;
    });
    if (duplicada) {
      return visita.periodo != null
          ? 'El período ${visita.periodo} ya está programado para este colegio.'
          : 'La clase ${visita.numeroClase} de ${visita.tipo.toLowerCase()} ya está programada para este colegio.';
    }
    final finVisita = visita.fecha.add(
      Duration(minutes: visita.duracionMinutos),
    );
    String? profesorEnConflicto;
    final profesoresVisita = {
      visita.profesorResponsable.trim().toLowerCase(): visita
          .profesorResponsable
          .trim(),
      for (final profesor in visita.profesoresAcompanantes)
        profesor.trim().toLowerCase(): profesor.trim(),
    };
    final cruceHorario = existentes.any((existente) {
      if (existente.cancelada) return false;
      final finExistente = existente.fecha.add(
        Duration(minutes: existente.duracionMinutos),
      );
      final seCruzan =
          visita.fecha.isBefore(finExistente) &&
          finVisita.isAfter(existente.fecha);
      if (!seCruzan) return false;
      final profesoresExistentes = {
        existente.profesorResponsable.trim().toLowerCase(),
        ...existente.profesoresAcompanantes.map(
          (profesor) => profesor.trim().toLowerCase(),
        ),
      };
      for (final entry in profesoresVisita.entries) {
        if (entry.key.isNotEmpty && profesoresExistentes.contains(entry.key)) {
          profesorEnConflicto = entry.value;
          return true;
        }
      }
      return false;
    });
    if (cruceHorario) {
      return '$profesorEnConflicto ya tiene otra actividad durante ese horario.';
    }
    return null;
  }

  void _ordenarVisitas() {
    _visitas.sort((a, b) => a.fecha.compareTo(b.fecha));
  }

  String? alternarVisita(String id) {
    final index = _visitas.indexWhere((visita) => visita.id == id);
    if (index == -1) return 'Actividad no encontrada.';
    final error = _requiereVisitaAsignada(_visitas[index]);
    if (error != null) return error;
    if (_visitas[index].cancelada) {
      return 'No puedes completar una actividad cancelada.';
    }
    _visitas[index] = _visitas[index].copyWith(
      completada: !_visitas[index].completada,
      estado: !_visitas[index].completada
          ? EstadoVisita.realizada
          : EstadoVisita.programada,
    );
    notifyListeners();
    return null;
  }

  String? cancelarVisita(String id, String motivo) {
    final index = _visitas.indexWhere((visita) => visita.id == id);
    if (index == -1) return 'Actividad no encontrada.';
    final error = _requiereVisitaAsignada(_visitas[index]);
    if (error != null) return error;
    if (motivo.trim().isEmpty) return 'Debes indicar el motivo de cancelación.';
    _visitas[index] = _visitas[index].copyWith(
      cancelada: true,
      completada: false,
      motivoCancelacion: motivo.trim(),
      ultimaNovedad: 'Cancelada: ${motivo.trim()}',
      estado: EstadoVisita.cancelada,
    );
    notifyListeners();
    return null;
  }

  String? reprogramarVisita(String id, DateTime fecha, {String? motivo}) {
    final acceso = _requiereAdministrarAgenda();
    if (acceso != null) return acceso;
    final index = _visitas.indexWhere((visita) => visita.id == id);
    if (index == -1) return 'Actividad no encontrada.';
    final actualizada = _visitas[index].copyWith(
      fecha: fecha,
      cancelada: false,
      completada: false,
      motivoCancelacion: '',
      ultimaNovedad: motivo?.trim().isNotEmpty == true
          ? 'Reprogramada: ${motivo!.trim()}'
          : 'Actividad reprogramada',
      estado: EstadoVisita.reprogramada,
    );
    final error = _validarVisita(
      actualizada,
      _visitas.where((visita) => visita.id != id),
    );
    if (error != null) return error;
    _visitas[index] = actualizada;
    _visitas.sort((a, b) => a.fecha.compareTo(b.fecha));
    notifyListeners();
    return null;
  }

  String? actualizarVisita(VisitaProgramada visita) {
    final acceso = _requiereAdministrarAgenda();
    if (acceso != null) return acceso;
    final index = _visitas.indexWhere((actual) => actual.id == visita.id);
    if (index == -1) return 'Actividad no encontrada.';
    final error = _validarVisita(
      visita,
      _visitas.where((actual) => actual.id != visita.id),
    );
    if (error != null) return error;
    _visitas[index] = visita;
    _ordenarVisitas();
    notifyListeners();
    return null;
  }

  String? posponerSerieDesde(String id, String motivo) {
    final acceso = _requiereAdministrarAgenda();
    if (acceso != null) return acceso;
    final indiceReferencia = _visitas.indexWhere((visita) => visita.id == id);
    if (indiceReferencia == -1) return 'Actividad no encontrada.';
    final referencia = _visitas[indiceReferencia];
    if (referencia.serieId == null || referencia.numeroClase == null) {
      cancelarVisita(id, motivo);
      return null;
    }
    final intervalo = referencia.intervaloDias ?? 7;
    return reprogramarSerieDesde(
      id,
      referencia.fecha.add(Duration(days: intervalo)),
      motivo: motivo,
    );
  }

  String? reprogramarSerieDesde(
    String id,
    DateTime nuevaFecha, {
    String? motivo,
  }) {
    final acceso = _requiereAdministrarAgenda();
    if (acceso != null) return acceso;
    final indiceReferencia = _visitas.indexWhere((visita) => visita.id == id);
    if (indiceReferencia == -1) return 'Actividad no encontrada.';
    final referencia = _visitas[indiceReferencia];
    if (referencia.serieId == null || referencia.numeroClase == null) {
      return reprogramarVisita(id, nuevaFecha, motivo: motivo);
    }
    final diferencia = nuevaFecha.difference(referencia.fecha);
    final afectadas = _visitas
        .where(
          (visita) =>
              visita.serieId == referencia.serieId &&
              visita.numeroClase != null &&
              visita.numeroClase! >= referencia.numeroClase!,
        )
        .toList();
    final idsAfectados = afectadas.map((visita) => visita.id).toSet();
    final nuevas = <VisitaProgramada>[];
    for (final visita in afectadas) {
      final nueva = visita.copyWith(
        fecha: visita.fecha.add(diferencia),
        cancelada: false,
        completada: false,
        motivoCancelacion: '',
        ultimaNovedad: visita.id == id
            ? 'Clase reprogramada${motivo?.trim().isNotEmpty == true ? ': ${motivo!.trim()}' : ''}'
            : 'Fecha ajustada por reprogramación de la clase ${referencia.numeroClase}',
        estado: EstadoVisita.reprogramada,
      );
      final error = _validarVisita(nueva, [
        ..._visitas.where((visita) => !idsAfectados.contains(visita.id)),
        ...nuevas,
      ]);
      if (error != null) return error;
      nuevas.add(nueva);
    }
    for (final nueva in nuevas) {
      final index = _visitas.indexWhere((visita) => visita.id == nueva.id);
      _visitas[index] = nueva;
    }
    _ordenarVisitas();
    notifyListeners();
    return null;
  }

  String? actualizarEstadoVisita(String id, EstadoVisita estado) {
    final index = _visitas.indexWhere((visita) => visita.id == id);
    if (index == -1) return 'Actividad no encontrada.';
    final visita = _visitas[index];
    final error = _requiereVisitaAsignada(visita);
    if (error != null) return error;
    if (_usuarioActual?.rol == RolUsuario.profesor &&
        estado != EstadoVisita.realizada) {
      return 'El profesor únicamente puede marcar su actividad como realizada.';
    }
    if (visita.cancelada) {
      return 'No puedes cambiar el estado de una actividad cancelada.';
    }
    _visitas[index] = _visitas[index].copyWith(
      estado: estado,
      completada: estado == EstadoVisita.realizada,
      cancelada: estado == EstadoVisita.cancelada,
    );
    notifyListeners();
    return null;
  }

  String? actualizarResponsablesVisita({
    required String id,
    required String profesor,
    required List<String> acompanantes,
    required String ubicacion,
  }) {
    final error = _requiereAdministrarAgenda();
    if (error != null) return error;
    final index = _visitas.indexWhere((visita) => visita.id == id);
    if (index == -1) return 'Actividad no encontrada.';
    _visitas[index] = _visitas[index].copyWith(
      profesorResponsable: profesor.trim(),
      profesoresAcompanantes: List.unmodifiable(acompanantes),
      ubicacion: ubicacion.trim(),
    );
    notifyListeners();
    return null;
  }

  Future<String?> actualizarEstadoVisitaPersistente(
    String id,
    EstadoVisita estado,
  ) => _guardarVisitasPersistentes(() => actualizarEstadoVisita(id, estado));

  Future<String?> actualizarResponsablesVisitaPersistente({
    required String id,
    required String profesor,
    required List<String> acompanantes,
    required String ubicacion,
  }) => _guardarVisitasPersistentes(
    () => actualizarResponsablesVisita(
      id: id,
      profesor: profesor,
      acompanantes: acompanantes,
      ubicacion: ubicacion,
    ),
  );

  Future<String?> actualizarVisitaPersistente(VisitaProgramada visita) =>
      _guardarVisitasPersistentes(() => actualizarVisita(visita));

  Future<String?> cancelarVisitaPersistente(String id, String motivo) =>
      _guardarVisitasPersistentes(() => cancelarVisita(id, motivo));

  Future<String?> posponerSerieDesdePersistente(String id, String motivo) =>
      _guardarVisitasPersistentes(() => posponerSerieDesde(id, motivo));

  Future<String?> reprogramarSerieDesdePersistente(
    String id,
    DateTime nuevaFecha, {
    String? motivo,
  }) => _guardarVisitasPersistentes(
    () => reprogramarSerieDesde(id, nuevaFecha, motivo: motivo),
  );

  List<VisitaProgramada> actividadesProximas(
    DateTime ahora, {
    Duration ventana = const Duration(days: 7),
  }) => visitas
      .where((visita) {
        final diferencia = visita.fecha.difference(ahora);
        return !visita.cancelada &&
            !visita.completada &&
            !diferencia.isNegative &&
            diferencia <= ventana;
      })
      .toList(growable: false);

  List<VisitaProgramada> actividadesAtrasadas(DateTime ahora) => visitas
      .where(
        (visita) =>
            !visita.cancelada &&
            !visita.completada &&
            visita.fecha.isBefore(ahora),
      )
      .toList(growable: false);

  Evaluacion? borradorEvaluacion(String tipo, {String? colegio}) {
    final candidatas =
        _borradoresEvaluacion.values
            .where(
              (evaluacion) =>
                  evaluacion.evaluadorTipo == tipo &&
                  (colegio == null ||
                      _claveColegio(evaluacion.colegio) ==
                          _claveColegio(colegio)),
            )
            .toList()
          ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
    return candidatas.firstOrNull;
  }

  List<Evaluacion> get evaluacionesCapacitacionVisibles {
    final evaluaciones = _borradoresEvaluacion.values.toList();
    if (_usuarioActual?.rol != RolUsuario.profesor) {
      return List.unmodifiable(evaluaciones);
    }
    final nombre = _usuarioActual!.nombre.trim().toLowerCase();
    return List.unmodifiable(
      evaluaciones.where(
        (evaluacion) =>
            evaluacion.responsableNombre?.trim().toLowerCase() == nombre,
      ),
    );
  }

  String? guardarBorradorEvaluacion(Evaluacion evaluacion) {
    final error = _requiere(Permiso.crearEvaluaciones);
    if (error != null) return error;
    _borradoresEvaluacion[evaluacion.identificador] = evaluacion;
    notifyListeners();
    return null;
  }

  Future<String?> guardarBorradorEvaluacionPersistente(
    Evaluacion evaluacion,
  ) async {
    final error = _requiere(Permiso.crearEvaluaciones);
    if (error != null) return error;
    if (_repositorio == null) {
      return guardarBorradorEvaluacion(evaluacion);
    }
    if (evaluacion.colegio.trim().isEmpty) {
      return 'Selecciona un colegio antes de guardar la evaluación.';
    }
    try {
      await _guardarEvaluacionRemotaOLocal(evaluacion);
      return guardarBorradorEvaluacion(evaluacion);
    } catch (_) {
      return 'No se pudo guardar la evaluación. Comprueba el espacio disponible y vuelve a intentarlo; conserva esta pantalla abierta.';
    }
  }

  String? reemplazarContenidoClase({
    required Evaluacion evaluacion,
    required int claseNumero,
    required String bloque,
    required String contenido,
    required String nombreTemporal,
  }) {
    final error = _requiere(Permiso.crearEvaluaciones);
    if (error != null) return error;
    final usuario = _usuarioActual!;
    if (evaluacion.estado == EstadoEvaluacion.completada) {
      return 'No se puede modificar una evaluación finalizada.';
    }
    if (usuario.rol == RolUsuario.profesor &&
        evaluacion.responsableNombre != usuario.nombre) {
      return 'No tienes permiso para modificar una clase que no te pertenece.';
    }
    if (nombreTemporal.trim().isEmpty) {
      return 'Debes escribir el nombre del contenido que lo reemplazará.';
    }
    if (nombreTemporal.trim().toLowerCase() == contenido.trim().toLowerCase()) {
      return 'El nombre temporal debe ser diferente al contenido original.';
    }
    final clase = evaluacion.clases.firstWhere(
      (c) => c.claseNumero == claseNumero,
    );
    final reemplazo = ReemplazoContenido(
      contenidoId: clase.contenidoId(bloque, contenido),
      nombreOriginal: contenido,
      nombreTemporal: nombreTemporal.trim(),
      bloque: bloque,
      colegio: evaluacion.colegio,
      claseId: '$claseNumero',
      evaluacionId: evaluacion.identificador,
      fecha: DateTime.now(),
      usuarioId: usuario.nombre,
      nombreUsuario: usuario.nombre,
      rolUsuario: usuario.rol,
    );
    final actualizada = EvaluacionService().reemplazarContenido(
      evaluacion: evaluacion,
      reemplazo: reemplazo,
    );
    _borradoresEvaluacion[evaluacion.identificador] = actualizada;
    notifyListeners();
    return null;
  }

  String? deshacerReemplazoContenido(
    Evaluacion evaluacion,
    String contenidoId,
  ) {
    final error = _requiere(Permiso.crearEvaluaciones);
    if (error != null) return error;
    if (evaluacion.estado == EstadoEvaluacion.completada) {
      return 'No se puede modificar una evaluación finalizada.';
    }
    final usuario = _usuarioActual!;
    if (usuario.rol == RolUsuario.profesor &&
        evaluacion.responsableNombre != usuario.nombre) {
      return 'No tienes permiso para modificar una clase que no te pertenece.';
    }
    _borradoresEvaluacion[evaluacion.identificador] = EvaluacionService()
        .deshacerReemplazo(evaluacion: evaluacion, contenidoId: contenidoId);
    notifyListeners();
    return null;
  }

  Future<String?> reemplazarContenidoClasePersistente({
    required Evaluacion evaluacion,
    required int claseNumero,
    required String bloque,
    required String contenido,
    required String nombreTemporal,
  }) async {
    final anterior = _borradoresEvaluacion[evaluacion.identificador];
    final error = reemplazarContenidoClase(
      evaluacion: evaluacion,
      claseNumero: claseNumero,
      bloque: bloque,
      contenido: contenido,
      nombreTemporal: nombreTemporal,
    );
    if (error != null || _repositorio == null) return error;
    try {
      await _guardarEvaluacionRemotaOLocal(
        _borradoresEvaluacion[evaluacion.identificador]!,
      );
      return null;
    } catch (_) {
      if (anterior == null) {
        _borradoresEvaluacion.remove(evaluacion.identificador);
      } else {
        _borradoresEvaluacion[evaluacion.identificador] = anterior;
      }
      notifyListeners();
      return 'No se pudo guardar el reemplazo en Supabase.';
    }
  }

  Future<String?> deshacerReemplazoContenidoPersistente(
    Evaluacion evaluacion,
    String contenidoId,
  ) async {
    final anterior = _borradoresEvaluacion[evaluacion.identificador];
    final error = deshacerReemplazoContenido(evaluacion, contenidoId);
    if (error != null || _repositorio == null) return error;
    try {
      await _guardarEvaluacionRemotaOLocal(
        _borradoresEvaluacion[evaluacion.identificador]!,
      );
      return null;
    } catch (_) {
      if (anterior == null) {
        _borradoresEvaluacion.remove(evaluacion.identificador);
      } else {
        _borradoresEvaluacion[evaluacion.identificador] = anterior;
      }
      notifyListeners();
      return 'No se pudo guardar el cambio en Supabase.';
    }
  }

  String? guardarBorradorConocimiento(StudentKnowledgeDraft borrador) {
    final error = _requiere(Permiso.crearEvaluaciones);
    if (error != null) return error;
    _borradorConocimiento = borrador;
    notifyListeners();
    return null;
  }

  void descartarBorradorConocimiento() {
    _borradorConocimiento = null;
    notifyListeners();
  }

  Future<String?> guardarBorradorConocimientoPersistente(
    StudentKnowledgeDraft borrador,
  ) {
    final usuarioId = _supabaseClient?.auth.currentUser?.id;
    final tarea = _colaBorradores.then((_) async {
      final error = _requiere(Permiso.crearEvaluaciones);
      if (error != null) return error;
      if (_repositorio == null) return guardarBorradorConocimiento(borrador);
      if (usuarioId == null ||
          _supabaseClient?.auth.currentUser?.id != usuarioId) {
        return 'La sesión cambió. Inicia sesión para guardar el borrador.';
      }
      try {
        if (_offline != null) {
          await _encolar('borrador', usuarioId, {
            'eliminado': false,
            'datos': borrador.toJson(),
          });
        } else {
          await _repositorio.guardarBorrador(borrador);
        }
        return guardarBorradorConocimiento(borrador);
      } catch (_) {
        return 'Borrador sin guardar: no se pudo confirmar el guardado en Supabase.';
      }
    });
    _colaBorradores = tarea.then<void>((_) {});
    return tarea;
  }

  Future<String?> descartarBorradorConocimientoPersistente() async {
    await _colaBorradores;
    try {
      if (_offline != null) {
        await _encolar('borrador', _offlineUid!, {
          'eliminado': true,
          'datos': <String, dynamic>{},
        });
      } else {
        await _repositorio?.eliminarBorrador();
      }
      descartarBorradorConocimiento();
      return null;
    } catch (_) {
      return 'El reporte se guardó, pero no se pudo eliminar el borrador. Inténtalo de nuevo.';
    }
  }

  String? actualizarConfiguracionNotas(ConfiguracionNotas configuracion) {
    final error = _requiere(Permiso.configurarSistema);
    if (error != null) return error;
    if (configuracion.asistenciaMinimaProfesor < 0 ||
        configuracion.asistenciaMinimaProfesor > 100 ||
        configuracion.evaluacionPeriodosMinimaProfesor < 0 ||
        configuracion.evaluacionPeriodosMinimaProfesor > 100) {
      return 'Los porcentajes mínimos deben estar entre 0% y 100%.';
    }
    _configuracionNotas = configuracion;
    notifyListeners();
    return null;
  }

  Future<String?> actualizarConfiguracionNotasPersistente(
    ConfiguracionNotas configuracion,
  ) async {
    final error = _requiere(Permiso.configurarSistema);
    if (error != null) return error;
    if (_supabaseClient == null) {
      return actualizarConfiguracionNotas(configuracion);
    }
    if (configuracion.asistenciaMinimaProfesor < 0 ||
        configuracion.asistenciaMinimaProfesor > 100 ||
        configuracion.evaluacionPeriodosMinimaProfesor < 0 ||
        configuracion.evaluacionPeriodosMinimaProfesor > 100) {
      return 'Los porcentajes mínimos deben estar entre 0% y 100%.';
    }
    try {
      await _supabaseClient
          .from('configuracion_academica')
          .update({
            'asistencia_minima_profesor':
                configuracion.asistenciaMinimaProfesor,
            'evaluacion_periodos_minima_profesor':
                configuracion.evaluacionPeriodosMinimaProfesor,
            'notas': configuracion.toJson(),
            'actualizado_en': DateTime.now().toUtc().toIso8601String(),
            'actualizado_por': _supabaseClient.auth.currentUser!.id,
          })
          .eq('id', true)
          .select('id')
          .single();
      _configuracionNotas = configuracion;
      notifyListeners();
      return null;
    } catch (_) {
      return 'No se pudo guardar la configuración en Supabase. Revisa los permisos e inténtalo de nuevo.';
    }
  }

  List<StudentKnowledgeReport> historialEstudiante(String nombre) {
    final buscado = nombre.trim().toLowerCase();
    return _reportesConocimiento
        .where((reporte) => reporte.profesorEvaluado.toLowerCase() == buscado)
        .toList(growable: false)
      ..sort((a, b) => b.fechaHora.compareTo(a.fechaHora));
  }

  List<StudentKnowledgeReport> historialSalon(
    String colegio,
    String grado, {
    String? profesor,
  }) {
    final colegioBuscado = _claveColegio(colegio);
    final gradoBuscado = grado.trim().toLowerCase();
    final profesorBuscado = profesor?.trim().toLowerCase();
    return _reportesConocimiento
        .where(
          (reporte) =>
              _claveColegio(reporte.colegio) == colegioBuscado &&
              reporte.grado.trim().toLowerCase() == gradoBuscado &&
              (profesorBuscado == null ||
                  profesorBuscado.isEmpty ||
                  reporte.profesorResponsableSalon.trim().toLowerCase() ==
                      profesorBuscado),
        )
        .toList(growable: false)
      ..sort((a, b) => b.fechaHora.compareTo(a.fechaHora));
  }

  String? guardarReporteConocimiento(StudentKnowledgeReport reporte) {
    final error = _requiere(Permiso.crearEvaluaciones);
    if (error != null) return error;
    _reportesConocimiento.add(reporte);
    notifyListeners();
    return null;
  }

  Future<String?> guardarReporteConocimientoPersistente(
    StudentKnowledgeReport reporte,
  ) async {
    final error = _requiere(Permiso.crearEvaluaciones);
    if (error != null) return error;
    if (_repositorio == null) return guardarReporteConocimiento(reporte);
    try {
      if (_offline != null) {
        await _encolar('reporte', reporte.id, OfflineCodec.reporte(reporte));
      } else {
        await _repositorio.guardarReporte(reporte);
      }
      _reportesConocimiento.removeWhere((item) => item.id == reporte.id);
      return guardarReporteConocimiento(reporte);
    } catch (_) {
      return 'No se pudo guardar el reporte en Supabase. Revisa la conexión y los permisos.';
    }
  }

  String? aprobarReporteConocimiento({
    required String reporteId,
    required String firma,
  }) {
    if (sinConexion || cambiosPendientes > 0) {
      return 'Conéctate y sincroniza los cambios antes de aprobar.';
    }
    if (!tienePermiso(Permiso.publicarEvaluaciones)) {
      return 'Solo un coordinador o administrador puede aprobar este reporte.';
    }
    final index = _reportesConocimiento.indexWhere(
      (reporte) => reporte.id == reporteId,
    );
    if (index == -1) return 'Reporte no encontrado.';
    _reportesConocimiento[index] = _reportesConocimiento[index].copyWith(
      firmaCoordinador: firma,
      nombreCoordinador: _usuarioActual!.nombre,
      fechaAprobacion: DateTime.now(),
    );
    notifyListeners();
    return null;
  }

  Future<String?> aprobarReporteConocimientoPersistente({
    required String reporteId,
    required String firma,
  }) async {
    if (sinConexion || cambiosPendientes > 0) {
      return 'Conéctate y sincroniza los cambios antes de aprobar.';
    }
    if (!tienePermiso(Permiso.publicarEvaluaciones)) {
      return 'Solo un coordinador o administrador puede aprobar este reporte.';
    }
    if (_repositorio == null) {
      return aprobarReporteConocimiento(reporteId: reporteId, firma: firma);
    }
    try {
      await _repositorio.aprobarReporte(
        codigo: reporteId,
        firma: firma,
        nombreCoordinador: _usuarioActual!.nombre,
      );
      return aprobarReporteConocimiento(reporteId: reporteId, firma: firma);
    } catch (_) {
      return 'No se pudo aprobar el reporte en Supabase. Revisa la conexión y los permisos.';
    }
  }

  String? iniciarSesion({required String usuario, required String password}) {
    if (usaSupabase) {
      return 'Ingresa con tu correo y contraseña de Supabase.';
    }
    final usuarioNormalizado = usuario.trim().toLowerCase();
    _usuarioActual = null;

    if (usuarioNormalizado == _config.adminUsername.trim().toLowerCase() &&
        password == _config.adminPassword) {
      _usuarioActual = const UsuarioSesion(
        rol: RolUsuario.administrador,
        nombre: 'Administrador',
      );
      notifyListeners();
      return null;
    }

    if (usuarioNormalizado ==
            _config.coordinadorUsername.trim().toLowerCase() &&
        password == _config.coordinadorPassword) {
      _usuarioActual = UsuarioSesion(
        rol: RolUsuario.coordinador,
        nombre: 'Coordinador de zona',
        zona: _config.coordinadorZona,
      );
      notifyListeners();
      return null;
    }

    if (_config.demoProfesorUsername.trim().isNotEmpty &&
        usuarioNormalizado ==
            _config.demoProfesorUsername.trim().toLowerCase() &&
        password == _config.demoProfesorPassword) {
      _usuarioActual = UsuarioSesion(
        rol: RolUsuario.profesor,
        nombre: _config.demoProfesorNombre,
        zona: _config.demoProfesorZona,
      );
      notifyListeners();
      return null;
    }

    Profesor? profesor;
    var existeUsuarioProfesor = false;
    for (final candidato in _profesores) {
      if (candidato.usuario.toLowerCase() == usuarioNormalizado) {
        existeUsuarioProfesor = true;
        if (candidato.password == password) {
          profesor = candidato;
          break;
        }
      }
    }
    if (profesor != null) {
      if (!profesor.aprobado) {
        return 'Tu solicitud está pendiente de aprobación del administrador.';
      }
      _usuarioActual = UsuarioSesion(
        rol: RolUsuario.profesor,
        nombre: profesor.nombre,
        zona: profesor.zona,
      );
      notifyListeners();
      return null;
    }

    if (existeUsuarioProfesor) {
      return 'La contraseña del profesor es incorrecta.';
    }
    return 'No existe un profesor con ese usuario en esta sesión. Un administrador debe crearlo primero.';
  }

  Future<String?> iniciarSesionSupabase({
    required String correo,
    required String password,
  }) async {
    final client = _supabaseClient;
    if (client == null) return 'Supabase no está configurado.';
    await suspenderPersistencia();
    _saliendo = false;
    _usuarioActual = null;
    notifyListeners();
    try {
      final respuesta = await client.auth.signInWithPassword(
        email: correo.trim(),
        password: password,
      );
      if (respuesta.user == null) return 'No se pudo iniciar sesión.';
      return await restaurarSesionSupabase();
    } on AuthException {
      return 'Correo o contraseña incorrectos, o cuenta sin confirmar.';
    } catch (_) {
      return 'No se pudo conectar con Supabase. Revisa la conexión y la configuración.';
    }
  }

  Future<String?> registrarCuentaSupabase({
    required String nombre,
    required String correo,
    required String password,
  }) async {
    final client = _supabaseClient;
    if (client == null) return 'Supabase no está configurado.';
    final nombreLimpio = nombre.trim();
    final correoLimpio = correo.trim().toLowerCase();
    if (nombreLimpio.isEmpty || correoLimpio.isEmpty || password.isEmpty) {
      return 'Todos los campos son obligatorios.';
    }
    if (!correoLimpio.contains('@')) return 'Escribe un correo válido.';
    if (password.length < 8) {
      return 'La contraseña debe tener mínimo 8 caracteres.';
    }
    try {
      final respuesta = await client.auth.signUp(
        email: correoLimpio,
        password: password,
        data: {'full_name': nombreLimpio},
      );
      if (respuesta.user == null) return 'No se pudo crear la cuenta.';
      // Si la confirmación de correo está desactivada, signUp inicia sesión.
      // La cerramos para que el usuario vuelva al acceso normal y se cargue el
      // perfil completo creado por el trigger de Supabase.
      if (respuesta.session != null) {
        await client.auth.signOut(scope: SignOutScope.local);
      }
      return null;
    } on AuthException catch (error) {
      final mensaje = error.message.toLowerCase();
      if (mensaje.contains('already') || mensaje.contains('registered')) {
        return 'Ya existe una cuenta con ese correo.';
      }
      if (mensaje.contains('password')) {
        return 'La contraseña no cumple los requisitos de seguridad.';
      }
      if (mensaje.contains('signup') || mensaje.contains('disabled')) {
        return 'El registro de cuentas está desactivado en Supabase.';
      }
      return 'No se pudo crear la cuenta: ${error.message}';
    } catch (_) {
      return 'No se pudo conectar con Supabase. Revisa la conexión.';
    }
  }

  Future<String?> restaurarSesionSupabase() async {
    final client = _supabaseClient;
    final id = client?.auth.currentUser?.id;
    if (client == null || id == null) return 'No hay una sesión activa.';
    _restaurando = true;
    try {
      await _abrirOffline(id);
      await _sync?.cerrar();
      _sync = null;
      final perfil = await client
          .from('perfiles')
          .select('nombre, rol, zona, activo')
          .eq('id', id)
          .maybeSingle();
      if (perfil == null || perfil['activo'] != true) {
        await client.auth.signOut(scope: SignOutScope.local);
        return 'Tu perfil no existe o está inactivo en Supabase.';
      }
      final rol = switch (perfil['rol']) {
        'administrador' => RolUsuario.administrador,
        'coordinador' => RolUsuario.coordinador,
        'profesor' => RolUsuario.profesor,
        _ => null,
      };
      if (rol == null) {
        await client.auth.signOut(scope: SignOutScope.local);
        return 'El rol de tu perfil no es válido.';
      }
      _usuarioActual = UsuarioSesion(
        rol: rol,
        nombre: perfil['nombre'] as String,
        zona: perfil['zona'] as String?,
      );
      if (_offline != null) {
        final version = await client.rpc<int>(
          'version_sincronizacion_academica',
        );
        if (version != 1) {
          throw StateError(
            'Actualiza la base de datos antes de usar esta versión.',
          );
        }
      }
      final configuracion = await client
          .from('configuracion_academica')
          .select(
            'asistencia_minima_profesor, evaluacion_periodos_minima_profesor, notas',
          )
          .eq('id', true)
          .single();
      _configuracionNotas = ConfiguracionNotas.fromDatabase(configuracion);
      final colegios = await _repositorio!.cargarColegios();
      _nombresColegios
        ..clear()
        ..addAll(colegios.nombres);
      _docentesColegios
        ..clear()
        ..addAll(colegios.asignaciones);
      _contactosColegios
        ..clear()
        ..addAll(colegios.contactos);
      final perfiles = await client
          .from('perfiles')
          .select('id, nombre, zona, activo, rol');
      _profesoresRemotos = [
        for (final perfil in perfiles)
          if (perfil['rol'] == 'profesor')
            Profesor(
              nombre: perfil['nombre'] as String,
              usuario: perfil['id'] as String,
              password: '',
              zona: perfil['zona'] as String? ?? '',
              aprobado: perfil['activo'] == true,
            ),
      ];
      _visitas
        ..clear()
        ..addAll(await _repositorio.cargarVisitas());
      _fechasBloqueadas
        ..clear()
        ..addAll(await _repositorio.cargarFechasBloqueadas());
      final evaluaciones = await _repositorio.cargarEvaluaciones();
      _borradoresEvaluacion
        ..clear()
        ..addEntries(
          evaluaciones.map(
            (evaluacion) => MapEntry(evaluacion.identificador, evaluacion),
          ),
        );
      _reportesConocimiento
        ..clear()
        ..addAll(await _repositorio.cargarReportes());
      _borradorConocimiento = await _repositorio.cargarBorrador();
      _validadoEn = DateTime.now();
      if (_offline != null) {
        await _offline!.guardar('sesion', _snapshot());
        await _offline!.limpiarConfirmados();
        await _aplicarPendientes();
        await _iniciarSync();
      }
      notifyListeners();
      return null;
    } catch (error) {
      if (error is OfflineStoreBusy) {
        _usuarioActual = null;
        return error.toString();
      }
      if (errorDeRed(error) && await _restaurarOffline()) {
        notifyListeners();
        return null;
      }
      _usuarioActual = null;
      notifyListeners();
      try {
        await client.auth.signOut(scope: SignOutScope.local);
      } catch (_) {
        // La sesión de la app ya está cerrada aunque falle el cierre remoto.
      }
      return 'No se pudieron cargar los datos de Supabase. Verifica la conexión y aplica la versión actualizada de actualizar_base_existente.sql.';
    } finally {
      _restaurando = false;
    }
  }

  String? crearProfesor({
    required String nombre,
    required String usuario,
    required String password,
    required String zona,
  }) {
    if (usaSupabase) {
      return 'Las cuentas de Supabase se crean en Authentication > Users. Después puedes activar el perfil desde esta app.';
    }
    if (!Rbac.puedeCrearProfesores(_usuarioActual)) {
      return 'No tienes permiso para crear profesores.';
    }
    final zonaLimpia = zona.trim();

    return _registrarProfesor(
      nombre: nombre,
      usuario: usuario,
      password: password,
      zona: zonaLimpia,
    );
  }

  String? registrarSolicitudProfesor({
    required String nombre,
    required String usuario,
    required String password,
    required String zona,
  }) {
    if (usaSupabase) {
      return 'El registro público de Supabase todavía no está habilitado en esta pantalla.';
    }
    if (!Rbac.puedeRegistrarSolicitudProfesor(_usuarioActual)) {
      return 'Acceso no autorizado: no puedes registrar profesores.';
    }
    return _registrarProfesor(
      nombre: nombre,
      usuario: usuario,
      password: password,
      zona: zona,
    );
  }

  String? _registrarProfesor({
    required String nombre,
    required String usuario,
    required String password,
    required String zona,
  }) {
    final nombreLimpio = nombre.trim();
    final usuarioLimpio = usuario.trim();
    final zonaLimpia = zona.trim();

    if (nombreLimpio.isEmpty ||
        usuarioLimpio.isEmpty ||
        password.isEmpty ||
        zonaLimpia.isEmpty) {
      return 'Todos los campos son obligatorios.';
    }
    if (password.length < 6) {
      return 'La contraseña debe tener mínimo 6 caracteres.';
    }
    final usuarioOcupado = _profesores.any(
      (profesor) =>
          profesor.usuario.toLowerCase() == usuarioLimpio.toLowerCase(),
    );
    final usuarioReservado =
        usuarioLimpio.toLowerCase() ==
            _config.adminUsername.trim().toLowerCase() ||
        usuarioLimpio.toLowerCase() ==
            _config.coordinadorUsername.trim().toLowerCase() ||
        (_config.demoProfesorUsername.trim().isNotEmpty &&
            usuarioLimpio.toLowerCase() ==
                _config.demoProfesorUsername.trim().toLowerCase()) ||
        _config.profesoresIniciales.any(
          (profesor) =>
              profesor.usuario.trim().toLowerCase() ==
              usuarioLimpio.toLowerCase(),
        );
    if (usuarioOcupado || usuarioReservado) {
      return 'Ese nombre de usuario ya está en uso.';
    }

    _profesores.add(
      Profesor(
        nombre: nombreLimpio,
        usuario: usuarioLimpio,
        password: password,
        zona: zonaLimpia,
      ),
    );
    notifyListeners();
    return null;
  }

  String? aprobarProfesor(String usuario) {
    if (usaSupabase) {
      return 'Usa la aprobación conectada a Supabase.';
    }
    if (!tienePermiso(Permiso.administrarUsuarios)) {
      return 'Solo el administrador puede aprobar profesores.';
    }
    final index = _profesores.indexWhere(
      (profesor) => profesor.usuario.toLowerCase() == usuario.toLowerCase(),
    );
    if (index == -1) return 'Profesor no encontrado.';
    _profesores[index] = _profesores[index].copyWith(aprobado: true);
    notifyListeners();
    return null;
  }

  Future<String?> aprobarProfesorPersistente(String usuario) async {
    if (!usaSupabase) return aprobarProfesor(usuario);
    if (!tienePermiso(Permiso.administrarUsuarios)) {
      return 'Solo el administrador puede aprobar profesores.';
    }
    try {
      await _supabaseClient!
          .from('perfiles')
          .update({'activo': true})
          .eq('id', usuario)
          .eq('rol', 'profesor')
          .select('id')
          .single();
      final index = _profesoresRemotos.indexWhere(
        (profesor) => profesor.usuario == usuario,
      );
      if (index >= 0) {
        _profesoresRemotos[index] = _profesoresRemotos[index].copyWith(
          aprobado: true,
        );
        notifyListeners();
      }
      return null;
    } catch (_) {
      return 'No se pudo activar el profesor en Supabase.';
    }
  }

  List<Profesor> profesoresVisibles() {
    final actual = _usuarioActual;
    if (_supabaseClient != null) {
      return List.unmodifiable(_profesoresRemotos);
    }
    if (actual?.rol == RolUsuario.administrador) return profesores;
    if (actual?.rol == RolUsuario.coordinador) {
      return profesores
          .where(
            (profesor) =>
                profesor.zona.trim().toLowerCase() ==
                actual!.zona?.trim().toLowerCase(),
          )
          .toList();
    }
    return const [];
  }

  /// Cierra los recursos sin borrar los pendientes ni la sesión del SDK.
  Future<void> suspenderPersistencia() async {
    await _colaBorradores;
    _saliendo = true;
    _sync?.removeListener(_notificarOffline);
    await _sync?.cerrar();
    _sync = null;
    await _offline?.cerrar();
    _offline = null;
    _offlineUid = null;
  }

  @override
  void dispose() {
    _sync?.removeListener(_notificarOffline);
    unawaited(suspenderPersistencia());
    super.dispose();
  }

  Future<void> cerrarSesion() async {
    await _colaBorradores;
    _saliendo = true;
    await _sync?.cerrar();
    _sync = null;
    await _offline?.cerrar();
    _offline = null;
    _offlineUid = null;
    _usuarioActual = null;
    if (usaSupabase) {
      _borradorConocimiento = null;
      _borradoresEvaluacion.clear();
      _reportesConocimiento.clear();
      _visitas.clear();
      _fechasBloqueadas.clear();
      _docentesColegios.clear();
      _nombresColegios.clear();
      _contactosColegios.clear();
      _profesoresRemotos = [];
      _repositorio?.archivos.limpiarCache();
    }
    notifyListeners();
    if (_supabaseClient != null) {
      await _supabaseClient.auth.signOut(scope: SignOutScope.local);
    }
    _saliendo = false;
  }
}
