import 'package:flutter/foundation.dart';

import '../config/auth_config.dart';
import '../models/profesor.dart';
import '../models/evaluacion.dart';
import '../models/configuracion_notas.dart';
import '../models/student_knowledge_draft.dart';
import '../models/student_knowledge_report.dart';
import '../models/usuario_sesion.dart';
import '../models/visita_programada.dart';

class SesionProvider extends ChangeNotifier {
  SesionProvider(this._config);

  final AuthConfig _config;
  final List<Profesor> _profesores = [];
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
  List<VisitaProgramada> get visitas => List.unmodifiable(_visitas);
  Set<DateTime> get fechasBloqueadas => Set.unmodifiable(_fechasBloqueadas);

  void bloquearFecha(DateTime fecha) {
    _fechasBloqueadas.add(DateTime(fecha.year, fecha.month, fecha.day));
    notifyListeners();
  }

  void desbloquearFecha(DateTime fecha) {
    _fechasBloqueadas.remove(DateTime(fecha.year, fecha.month, fecha.day));
    notifyListeners();
  }

  String? programarVisita(VisitaProgramada visita) {
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

  void alternarVisita(String id) {
    final index = _visitas.indexWhere((visita) => visita.id == id);
    if (index == -1) return;
    if (_visitas[index].cancelada) return;
    _visitas[index] = _visitas[index].copyWith(
      completada: !_visitas[index].completada,
      estado: !_visitas[index].completada
          ? EstadoVisita.realizada
          : EstadoVisita.programada,
    );
    notifyListeners();
  }

  void cancelarVisita(String id, String motivo) {
    final index = _visitas.indexWhere((visita) => visita.id == id);
    if (index == -1) return;
    _visitas[index] = _visitas[index].copyWith(
      cancelada: true,
      completada: false,
      motivoCancelacion: motivo.trim(),
      ultimaNovedad: 'Cancelada: ${motivo.trim()}',
      estado: EstadoVisita.cancelada,
    );
    notifyListeners();
  }

  String? reprogramarVisita(String id, DateTime fecha, {String? motivo}) {
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

  String? posponerSerieDesde(String id, String motivo) {
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

  void actualizarEstadoVisita(String id, EstadoVisita estado) {
    final index = _visitas.indexWhere((visita) => visita.id == id);
    if (index == -1) return;
    _visitas[index] = _visitas[index].copyWith(
      estado: estado,
      completada: estado == EstadoVisita.realizada,
      cancelada: estado == EstadoVisita.cancelada,
    );
    notifyListeners();
  }

  void actualizarResponsablesVisita({
    required String id,
    required String profesor,
    required List<String> acompanantes,
    required String ubicacion,
  }) {
    final index = _visitas.indexWhere((visita) => visita.id == id);
    if (index == -1) return;
    _visitas[index] = _visitas[index].copyWith(
      profesorResponsable: profesor.trim(),
      profesoresAcompanantes: List.unmodifiable(acompanantes),
      ubicacion: ubicacion.trim(),
    );
    notifyListeners();
  }

  List<VisitaProgramada> actividadesProximas(
    DateTime ahora, {
    Duration ventana = const Duration(days: 7),
  }) => _visitas
      .where((visita) {
        final diferencia = visita.fecha.difference(ahora);
        return !visita.cancelada &&
            !visita.completada &&
            !diferencia.isNegative &&
            diferencia <= ventana;
      })
      .toList(growable: false);

  List<VisitaProgramada> actividadesAtrasadas(DateTime ahora) => _visitas
      .where(
        (visita) =>
            !visita.cancelada &&
            !visita.completada &&
            visita.fecha.isBefore(ahora),
      )
      .toList(growable: false);

  Evaluacion? borradorEvaluacion(String tipo) => _borradoresEvaluacion[tipo];

  void guardarBorradorEvaluacion(Evaluacion evaluacion) {
    _borradoresEvaluacion[evaluacion.evaluadorTipo] = evaluacion;
    notifyListeners();
  }

  void guardarBorradorConocimiento(StudentKnowledgeDraft borrador) {
    _borradorConocimiento = borrador;
    notifyListeners();
  }

  void descartarBorradorConocimiento() {
    _borradorConocimiento = null;
    notifyListeners();
  }

  void actualizarConfiguracionNotas(ConfiguracionNotas configuracion) {
    _configuracionNotas = configuracion;
    notifyListeners();
  }

  List<StudentKnowledgeReport> historialEstudiante(String nombre) {
    final buscado = nombre.trim().toLowerCase();
    return _reportesConocimiento
        .where((reporte) => reporte.profesorEvaluado.toLowerCase() == buscado)
        .toList(growable: false)
      ..sort((a, b) => b.fechaHora.compareTo(a.fechaHora));
  }

  void guardarReporteConocimiento(StudentKnowledgeReport reporte) {
    _reportesConocimiento.add(reporte);
    notifyListeners();
  }

  String? aprobarReporteConocimiento({
    required String reporteId,
    required String firma,
  }) {
    if (_usuarioActual?.rol != RolUsuario.coordinador) {
      return 'Solo un coordinador puede aprobar este reporte.';
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
    return 'No existe un profesor con ese usuario en esta sesión. Un administrador o coordinador debe crearlo primero.';
  }

  String? crearProfesor({
    required String nombre,
    required String usuario,
    required String password,
    required String zona,
  }) {
    final actual = _usuarioActual;
    if (actual?.rol != RolUsuario.administrador &&
        actual?.rol != RolUsuario.coordinador) {
      return 'No tienes permiso para crear profesores.';
    }
    final zonaLimpia = actual?.rol == RolUsuario.coordinador
        ? (actual?.zona ?? '').trim()
        : zona.trim();

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
  }) => _registrarProfesor(
    nombre: nombre,
    usuario: usuario,
    password: password,
    zona: zona,
  );

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
            _config.coordinadorUsername.trim().toLowerCase();
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
    if (_usuarioActual?.rol != RolUsuario.administrador) {
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
      return _profesores
          .where(
            (profesor) =>
                profesor.zona.toLowerCase() == actual!.zona!.toLowerCase(),
          )
          .toList(growable: false);
    }
    return const [];
  }

  void cerrarSesion() {
    _usuarioActual = null;
    notifyListeners();
  }
}
