import 'package:flutter/foundation.dart';

import '../config/auth_config.dart';
import '../models/profesor.dart';
import '../models/evaluacion.dart';
import '../models/configuracion_notas.dart';
import '../models/student_knowledge_draft.dart';
import '../models/student_knowledge_report.dart';
import '../models/usuario_sesion.dart';
import '../models/visita_programada.dart';
import '../security/rbac.dart';
import '../models/reemplazo_contenido.dart';
import '../services/evaluacion_service.dart';

class SesionProvider extends ChangeNotifier {
  SesionProvider(this._config)
    : _profesores = [
        for (final profesor in _config.profesoresIniciales)
          Profesor(
            nombre: profesor.nombre,
            usuario: profesor.usuario,
            password: profesor.password,
            zona: profesor.zona,
            aprobado: true,
          ),
      ];

  final AuthConfig _config;
  final List<Profesor> _profesores;
  final List<StudentKnowledgeReport> _reportesConocimiento = [];
  final Map<String, Evaluacion> _borradoresEvaluacion = {};
  final List<VisitaProgramada> _visitas = [];
  final Set<DateTime> _fechasBloqueadas = {};
  StudentKnowledgeDraft? _borradorConocimiento;
  ConfiguracionNotas _configuracionNotas = const ConfiguracionNotas();
  UsuarioSesion? _usuarioActual;

  List<Profesor> get profesores => List.unmodifiable(_profesores);
  List<StudentKnowledgeReport> get reportesConocimiento =>
      List.unmodifiable(_reportesConocimiento);
  UsuarioSesion? get usuarioActual => _usuarioActual;
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

  String? _requiere(Permiso permiso) => tienePermiso(permiso)
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
        id: '${inicial.id}-$clase',
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

  Evaluacion? borradorEvaluacion(String tipo) => _borradoresEvaluacion[tipo];

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
    _borradoresEvaluacion[evaluacion.evaluadorTipo] = evaluacion;
    notifyListeners();
    return null;
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
    _borradoresEvaluacion[evaluacion.evaluadorTipo] = actualizada;
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
    _borradoresEvaluacion[evaluacion.evaluadorTipo] = EvaluacionService()
        .deshacerReemplazo(evaluacion: evaluacion, contenidoId: contenidoId);
    notifyListeners();
    return null;
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

  String? actualizarConfiguracionNotas(ConfiguracionNotas configuracion) {
    final error = _requiere(Permiso.configurarSistema);
    if (error != null) return error;
    _configuracionNotas = configuracion;
    notifyListeners();
    return null;
  }

  List<StudentKnowledgeReport> historialEstudiante(String nombre) {
    final buscado = nombre.trim().toLowerCase();
    return _reportesConocimiento
        .where((reporte) => reporte.profesorEvaluado.toLowerCase() == buscado)
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

  String? aprobarReporteConocimiento({
    required String reporteId,
    required String firma,
  }) {
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

  String? iniciarSesion({required String usuario, required String password}) {
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

  String? crearProfesor({
    required String nombre,
    required String usuario,
    required String password,
    required String zona,
  }) {
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

  List<Profesor> profesoresVisibles() {
    final actual = _usuarioActual;
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

  void cerrarSesion() {
    _usuarioActual = null;
    notifyListeners();
  }
}
